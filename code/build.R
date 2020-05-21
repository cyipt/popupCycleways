# aim: output results highlighting and ranking roads that have 'spare lanes'

# global parameters ----------------------------------------------------------
library(DescTools)
library(sf)
library(tidyverse)
library(tmap)
library(pct)
library(stplanr)
if(!exists("parameters")) {
message("Loading global parameters")  
s = c(
  `Grey` = "Esri.WorldGrayCanvas",
  `PCT commuting, Government Target` = "https://npttile.vs.mythic-beasts.com/commute/v2/govtarget/{z}/{x}/{y}.png",
  `PCT schools, Government Target` = "https://npttile.vs.mythic-beasts.com/school/v2/govtarget/{z}/{x}/{y}.png",
  `PCT commuting, Ebikes, ` = "https://npttile.vs.mythic-beasts.com/commute/v2/ebike/{z}/{x}/{y}.png",
  `PCT schools, Go Dutch, ` = "https://npttile.vs.mythic-beasts.com/school/v2/dutch/{z}/{x}/{y}.png",
  `Cycleways` = "https://b.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png",
  `Satellite` = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'"
)
tms = c(FALSE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE)
# test basemap:
tmap_mode("view")
parameters = read_csv("input-data/parameters.csv")

# read-in national data ---------------------------------------------------
# see preprocess.R for data origins
regions = readRDS("regions.Rds")
rj_all = readRDS("rj.Rds")
region_names = regions$Name
# hospitals:
hsf = readRDS("hsf.Rds")
nrow(regions)
cycleways_en = readRDS("cycleways_en.Rds")
tm_shape(regions) + tm_polygons(alpha = 0.1) + tm_basemap(s, tms = tms) # check basemaps

# get pct data
rnet_url = "https://github.com/npct/pct-outputs-national/raw/master/commute/lsoa/rnet_all.Rds"
rnet_url_school = "https://github.com/npct/pct-outputs-national/raw/master/school/lsoa/rnet_all.Rds"
rnet_all = sf::st_as_sf(readRDS(url(rnet_url)))
rnet_all_school = sf::st_as_sf(readRDS(url(rnet_url_school)))
}

# local parameters --------------------------------------------------------
# i = 1
if(!exists("region_name")) {
  region_name = "West of England"
}
if(region_name == "Nottingham") {
  region = regions %>% filter(str_detect(string = Name, pattern = "Nott")) %>% 
    st_union()
} else {
  region = regions %>% filter(Name == region_name)
}
# time consuming: ~1 minute
rj = rj_all[region, ]
# h_city = hsf[region, ]
i = which(parameters$name %in% region_name)
if(length(i) == 0) i = 1
p = parameters[i, ]
list2env(p, envir = .GlobalEnv)

# additional parameters
is_city = FALSE 
pct_dist_within = 50 
r_min_width_highlighted = 10
min_cycling_potential = 5

# buffers -----------------------------------------------------------------
if(is_city) {
  city_centre = tmaptools::geocode_OSM(region_name, as.sf = TRUE)
  city_centre_buffer = stplanr::geo_buffer(city_centre, dist = city_centre_buffer_radius)
  h_city = hsf[city_centre_buffer, ]
  h_city_buffer = stplanr::geo_buffer(h_city, dist = key_destination_buffer_radius)
  city_key_buffer = st_union(city_centre_buffer, st_union(h_city_buffer))
  r_main_region = rj[city_key_buffer, ]
} else {
  city_key_buffer = sf::st_geometry(region)
  r_main_region = rj
}

## ----t1, results='asis'----------------------------------------------------------------------
t1 = rj %>%
  st_drop_geometry() %>%
  # select(name, highway_type, maxspeed, cycling_potential, width) %>%
  table1::table1(~ highway_type + cycling_potential + width + n_lanes | maxspeed, data = .)


# Identify key corridors --------------------------------------------------
min_pct_99th_percentile = quantile(r_main_region$cycling_potential, probs = 0.99)
min_pct_90th_percentile = quantile(r_main_region$cycling_potential, probs = 0.90)

r_high_pct_99th = r_main_region %>%
  filter(cycling_potential > min_pct_99th_percentile)
table(r_high_pct_99th$ref) # many unnamed
mapview::mapview(r_high_pct_99th)
r_high_pct_90th = r_main_region %>%
  filter(cycling_potential > min_pct_90th_percentile)

r_named_ref = r_high_pct_90th %>% 
  filter(ref != "" & name != "") 

r_key_corridors = r_named_ref %>% 
  group_by(ref) %>% 
  summarise(
    length = sum(length),
    km_cycled_potential = sum(cycling_potential * length) / 1000
  ) %>% 
  top_n(n = 20, wt = km_cycled_potential) %>%
  sf::st_cast("LINESTRING") 

r_high_in_key_corridors = r_high_pct_99th[r_key_corridors, , op = sf::st_within]
r_high_not_in_key_corridors = r_high_pct_99th %>%
  filter(!idGlobal %in% r_high_in_key_corridors$idGlobal) %>% 
  transmute(
    ref = ref,
    length = length,
    km_cycled_potential = cycling_potential * length / 1000
    )

r_key_network_all = rbind(r_high_not_in_key_corridors, r_key_corridors)

key_corridor_table = sort(table(r_key_network_all$ref),decreasing=TRUE)
key_corridor_names = names(key_corridor_table[names(key_corridor_table) != ""])[1:10]

r_key_buffer = stplanr::geo_buffer(r_key_network_all, dist = 10)
touching_list = st_intersects(r_key_buffer)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_key_network_all$group = components$membership
group_table = table(r_key_network_all$group)
median(group_table)

r_key_network_all$length = as.numeric(sf::st_length(r_key_network_all))
r_key_network = r_key_network_all %>% 
  group_by(group) %>% 
  summarise(
    group_length = sum(length),
    km_cycled_potential = weighted.mean(km_cycled_potential, length)
    ) %>% 
  ungroup() %>% 
  filter(group_length > min_grouped_length * 10)
summary(r_key_network$group_length)

r_key_network_buffer_small = stplanr::geo_buffer(r_key_network, dist = 10)
r_key_network_buffer = stplanr::geo_buffer(r_key_network, dist = 1000)
r_key_network_buffer_large = stplanr::geo_buffer(r_key_network, dist = 2000)
mapview::mapview(r_key_network, zcol = "km_cycled_potential")
r_in_key_network = r_high_pct_90th[r_key_network, , op = st_within]
mapview::mapview(r_in_key_network)
r_key_roads = r_main_region %>%
  filter(ref %in% key_corridor_names)
mapview::mapview(r_key_roads)
r_key_roads_near_key_network = r_key_roads[r_key_network_buffer, ]
mapview::mapview(r_key_roads_near_key_network)
# %>% 
#   filter(!idGlobal %in% r_in_key_network$idGlobal)

r_key_network_final = r_key_roads_near_key_network %>%
  group_by(ref, name) %>% 
  summarise(
    group_length = round(sum(length)),
    mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE)),
    mean_width = round(weighted.mean(width, length, na.rm = TRUE))
    )
mapview::mapview(r_key_network_final)
# tm_shape(r_key_network_final) + tm_lines(lwd = "mean_width", scale = 7, col = "lightsalmon2")
tm_shape(r_key_network_final) + tm_lines(lwd = "mean_width", scale = 7, col = "ref", palette = "Dark2")


# show lanes roads with spare space ---------------------------------------

r_lanes_all_no_buffer = r_main_region %>% 
  filter(cycling_potential > min_cycling_potential) %>% # min_cycling_potential = 0 so this simply selects multilane roads
  mutate(spare_lane = lanes_f > 1 | lanes_b > 1) %>% 
  filter(spare_lane | width >= 9)
r_lanes_all = r_lanes_all_no_buffer[r_key_network_buffer_large, ]
# mapview::mapview(r_lanes_all_no_buffer) +
mapview::mapview(r_lanes_all)

r_lanes_all_buff = geo_buffer(shp = r_lanes_all, dist = 50)
touching_list = st_intersects(r_lanes_all_buff)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_lanes_all$group = components$membership
mapview::mapview(r_lanes_all["group"])

r_lanes_grouped = r_lanes_all %>%
  filter(ref != "") %>% 
  group_by(ref, name, group) %>%
  summarise(
    group_length = round(sum(length)),
    mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE)),
    mean_width = round(weighted.mean(width, length, na.rm = TRUE)),
    spare_lane = sum(length[spare_lane]) > sum(length[!spare_lane]),
    # road_name = names(table(name))[which.max(table(name))]
  ) %>% 
  filter(group_length > min_grouped_length) %>% 
  mutate(width_status = case_when(
    mean_width >= 9 ~ "Width > 9 m",
    spare_lane ~ "Spare lane"
    # spare_lane & mean_width > 10 ~ "Spare lane & width > 10 m"
  )) 

mapview::mapview(r_lanes_grouped, zcol = "group_length", lwd = 5)

r_lanes_grouped_linestrings = st_cast(r_lanes_grouped, "LINESTRING")
# mapview::mapview(r_lanes_grouped_linestrings, zcol = "group_length")
touching_list = st_intersects((r_lanes_grouped_linestrings))
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_lanes_grouped_linestrings$igroup = components$membership
r_lanes_grouped2 = r_lanes_grouped_linestrings %>% 
  group_by(igroup) %>% 
  mutate(n_in_group = n()) %>% 
  filter(!(n_in_group < 5 & name == "")) %>% 
  group_by(ref, group) 

summary(r_lanes_grouped2$n_in_group)
mapview::mapview(r_lanes_grouped2, zcol = "group", lwd = 3)

# mapview::mapview(r_lanes_grouped["width_status"])
# mapview::mapview(r_lanes_grouped["group"])

# Generate lists of top segments ------------------------------------------------------------

r_lanes_top = r_lanes_grouped %>%
  filter(mean_cycling_potential > min_grouped_cycling_potential) %>% 
  filter(!grepl(pattern = regexclude, name, ignore.case = TRUE)) %>% 
  mutate(km_cycled = round(mean_cycling_potential * group_length / 1000))
mapview::mapview(r_lanes_grouped)
mapview::mapview(r_lanes_top)
# head(r_lanes_top$kkm_cycled)

# r_lanes_overlap = r_lanes_all[r_lanes_top, , op = sf::st_covered_by] # works
# r_lanes_no_overlap = st_difference(r_lanes, r_lanes_top) # slow
# r_lanes_no_overlap = r_lanes_all %>% 
#   filter(!idGlobal %in% r_lanes_overlap$idGlobal)

# r_lanes_top_n = r_lanes_top %>% 
#   group_by(ref, group, name) %>% 
#   slice(which.max(km_cycled)) %>% 
#   filter(name != "") %>% 
#   ungroup() %>% 
#   arrange(desc(km_cycled)) %>% 
#   slice(1:50)
# 
# mapview::mapview(r_lanes_top_n)

# get existing infrastructure ---------------------------------------------
cycleways = cycleways_en[region, ]

cycleway_buffer = stplanr::geo_buffer(cycleways, dist = pct_dist_within) %>% sf::st_union()
# r_lanes_top_no_cycleways = sf::st_difference(r_lanes_top, cycleway_buffer)
# r_lanes_top_no_cycleways = r_lanes_top_no_cycleways %>%
#   st_cast("LINESTRING") %>%
#   mutate(group_length = round(as.numeric(st_length(.)))) %>%
#   filter(group_length > 50)

r_lanes_grouped_in_cycleway = st_intersection(r_lanes_grouped, cycleway_buffer) %>% 
  transmute(id = id, length_in_cycleway = round(as.numeric(st_length(.)))) %>% 
  st_drop_geometry()

minp_exclude = 0.75
r_lanes_joined = left_join(r_lanes_grouped, r_lanes_grouped_in_cycleway)
# only roads in which a high proportion are not already cycleways should be selected:
sel = (r_lanes_joined$group_length * minp_exclude) > r_lanes_joined$length_in_cycleway 
sel[is.na(sel)] = TRUE
sel_highlighted = sel & r_lanes_grouped$id %in% r_lanes_top_n$id
r_lanes_grouped$ref[sel_highlighted]

r_lanes_grouped$width_status[sel_highlighted] = "Highlighted route"
table(r_lanes_grouped$width_status)

cols_status = c("blue", "turquoise", "green")

tmap_mode("view")
m =
  tm_shape(r_key_network_final) + tm_lines(lwd = "mean_width", scale = 9, col = "lightsalmon2", palette = "Dark2") +
  # tm_shape(r_lanes_grouped) + tm_lines(col = "width_status", lwd = 3, alpha = 0.6, palette = cols_status) +
  # tm_text("ref") +
  tm_shape(r_lanes_top) + tm_lines(col = "blue", lwd = 2, alpha = 0.6) +
  # tm_shape(r_lanes_top_n) + tm_lines(col = "width_status", lwd = 2, alpha = 0.6) +
  tm_shape(cycleways) + tm_lines() +
  # tm_shape(r_lanes_top_n) + tm_text("name") + # clutters map, removed
  tm_basemap(server = s, tms = tms) +
  tm_scale_bar()
m

res_table = r_lanes_top_n %>% 
  sf::st_drop_geometry() %>% 
  select(name, length = group_length, mean_cycling_potential, km_cycled) 
knitr::kable(res_table, caption = "The top 10 candidate roads for space reallocation for pop-up active transport infrastructure according to methods presented in this paper.", digits = 0)

