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

# additional parameters ---------------------------------------------------

is_city = FALSE 
pct_dist_within = 50 
r_min_width_highlighted = 10
min_cycling_potential = 5
min_grouped_cycling_potential = 30
n_top_roads = (1 + round(nrow(rj) / 100000)) * 10

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

r_main_region$cycling_potential = r_main_region$pctgov


# Combine commute and schools route networks ----------------------------------------

rnet_all = rnet_all %>%
  select(local_id, govtarget_slc)
rnet_all_school = rnet_all_school %>%
  select(local_id, govtarget_slc)

# Filter by region
rnet_reg = rnet_all %>% st_intersects(region)
reg_logical = lengths(rnet_reg) > 0
rnet_done = rnet_all[reg_logical, ]

rnet_school_reg = rnet_all_school %>% st_intersects(region)
reg_school_logical = lengths(rnet_school_reg) > 0
rnet_school_done = rnet_all_school[reg_school_logical, ]

# Combine the two
combine = rbind(rnet_done, rnet_school_done) # change to rbindlist
rnet_combined = stplanr::overline2(x = combine, attrib = "govtarget_slc")

# Link the updated cycle potential to the road widths ---------------------

# pct_dist_within at 50 is probably too high
buff_dist = 10
rnet_buff = geo_buffer(shp = rnet_combined, dist = buff_dist)

r_cyipt_joined = st_join(r_main_region, rnet_buff, join = st_within)

dupes = r_cyipt_joined[duplicated(r_cyipt_joined$idGlobal) | duplicated(r_cyipt_joined$idGlobal, fromLast = TRUE), ]
dupes_max = dupes %>% 
  st_drop_geometry() %>% 
  group_by(idGlobal) %>%
  summarise(cycling_potential_max = max(govtarget_slc)) 

r_joined = left_join(r_cyipt_joined, dupes_max, by = "idGlobal") %>%
  mutate(cycling_potential = ifelse(is.na(cycling_potential_max), ifelse(is.na(govtarget_slc), pctgov, govtarget_slc), cycling_potential_max),
         cycling_potential_source = ifelse(is.na(cycling_potential_max), ifelse(is.na(govtarget_slc), "cyipt", "updated"), "updated_duplicate"))

r_positive = r_joined[which(r_joined$cycling_potential > 0),] %>%
  distinct(.keep_all = TRUE) # remove the duplicates

r_main_region = r_positive

# Identify key corridors --------------------------------------------------
min_pct_99th_percentile = quantile(r_main_region$cycling_potential, probs = 0.99)
min_pct_90th_percentile = quantile(r_main_region$cycling_potential, probs = 0.90)
min_pct_85th_percentile = quantile(r_main_region$cycling_potential, probs = 0.85)

r_high_pct_99th = r_main_region %>%
  filter(cycling_potential > min_pct_99th_percentile)
table(r_high_pct_99th$ref) # many unnamed
# mapview::mapview(r_high_pct_99th)
# r_high_pct_90th = r_main_region %>%
#   filter(cycling_potential > min_pct_90th_percentile)
# mapview::mapview(r_high_pct_90th)
r_high_pct_85th = r_main_region %>%
  filter(cycling_potential > min_pct_85th_percentile)
# mapview::mapview(r_high_pct_85th)

r_named_ref = r_high_pct_85th %>% 
  filter(ref != "" & name != "") 

# identify key road references:
top_refs_table = sort(table(r_named_ref$ref), decreasing = TRUE)
key_corridor_names = names(head(top_refs_table, n = n_top_roads))
r_key_corridors = r_named_ref %>% filter(ref %in% key_corridor_names)
r_high_not_in_key_corridors = r_high_pct_99th %>% filter(! ref %in% key_corridor_names)
r_key_network_all = rbind(r_high_not_in_key_corridors, r_key_corridors)

r_key_buffer = stplanr::geo_buffer(r_key_network_all, dist = 50)
touching_list = st_intersects(r_key_buffer)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_key_network_all$group = components$membership
# mapview::mapview(r_key_network_all, zcol = "group")
group_table = sort(table(r_key_network_all$group), decreasing = TRUE)
# select groups to include with careful selection of n
# see https://github.com/cyipt/popupCycleways/issues/38
length(group_table)
groups_to_include = names(group_table[group_table > n_top_roads])
r_key_network_igroups = r_key_network_all %>% 
  filter(group %in% groups_to_include)
# mapview::mapview(r_key_network_igroups)

r_key_network = r_key_network_igroups %>% 
  group_by(group) %>% 
  summarise(
    group_length = sum(length),
    km_cycled_potential = weighted.mean(cycling_potential, length)
    ) %>% 
  ungroup() %>% 
  filter(group_length > min_grouped_length) %>% 
  st_cast("LINESTRING")
summary(r_key_network$group_length)
# mapview::mapview(r_key_network, zcol = "km_cycled_potential")

# r_key_network_buffer_small = stplanr::geo_buffer(r_key_network, dist = 10)
r_key_network_buffer = stplanr::geo_buffer(r_key_network, dist = 1000)
r_key_network_buffer_large = stplanr::geo_buffer(r_key_network, dist = 2000)
# mapview::mapview(r_key_network, zcol = "km_cycled_potential")
# r_in_key_network = r_high_pct_90th[r_key_network, , op = st_within]
# mapview::mapview(r_in_key_network)
r_key_roads = r_main_region %>%
  filter(ref %in% key_corridor_names)
# mapview::mapview(r_key_roads)
r_key_roads_near = r_key_roads[r_key_network_buffer_large, ]
# mapview::mapview(r_key_roads_near)
r_high_g_not_ref = r_key_network_igroups %>% filter(! ref %in% key_corridor_names)
r_key_roads_plus_high_pct = rbind(r_key_roads_near, r_high_g_not_ref[-ncol(r_high_g_not_ref)])
# mapview::mapview(r_key_roads_plus_high_pct)

# tackle the issue of isolated segments
r_key_buffer = stplanr::geo_buffer(r_key_roads_plus_high_pct, dist = 10)
touching_list = st_intersects(r_key_buffer)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_key_roads_plus_high_pct$group = components$membership
group_table = sort(table(r_key_roads_plus_high_pct$group), decreasing = TRUE)
# select groups to include with careful selection of n
# see https://github.com/cyipt/popupCycleways/issues/38

key_network = r_key_roads_plus_high_pct %>%
  group_by(group) %>% 
  mutate(group_length = sum(length)) %>% 
  filter(group_length > 5 * min_grouped_length)
# mapview::mapview(key_network)
# tm_shape(key_network) + tm_lines(lwd = "mean_width", scale = 7, col = "lightsalmon2")

# Identify roads with spare space ---------------------------------------

r_lanes_all = r_main_region %>% 
  filter(cycling_potential > min_cycling_potential) %>% # min_cycling_potential = 0 so this simply selects multilane roads
  mutate(spare_lane = lanes_f > 1 | lanes_b > 1) %>% 
  filter(spare_lane | width >= 10)

# Optionally remove areas outside key network:
# r_lanes_all = r_lanes_all[r_key_network_buffer_large, ]
# mapview::mapview(r_lanes_all)

r_lanes_all_buff = geo_buffer(shp = r_lanes_all, dist = 50)
touching_list = st_intersects(r_lanes_all_buff)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_lanes_all$group = components$membership
# mapview::mapview(r_lanes_all["group"])

r_linestrings_with_ref = r_lanes_all %>%
  filter(ref != "")

# to optionally create and filter by group characteristics:
# %>%
#   group_by(ref, group) %>%
#   mutate(
#     group_length = round(sum(length)),
#     mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE)),
#     mean_width = round(weighted.mean(width, length, na.rm = TRUE)),
#     majority_spare_lane = sum(length[spare_lane]) > sum(length[!spare_lane]),
#     main_road_name = names(table(name))[which.max(table(name))],
#     width_status = case_when(
#       mean_width >= 10 ~ "Width >= 10 m",
#       spare_lane ~ "Spare lane"
#       # spare_lane & mean_width > 10 ~ "Spare lane & width > 10 m"
#     )
#   ) %>% 
#   ungroup() %>% 
# filter(group_length > min_grouped_length) 
# mapview::mapview(r_linestrings, zcol = "group_length", lwd = 5)

# Roads with no ref -------------------------------------------------------

# Remove segments with cycling potential <50. (this is stricter than the rules for roads with refs, because otherwise rogue segments from nearby side streets are likely to be added into the groups)
# todo: move to parameters
min_cycling_potential_without_ref = 30
r_linestrings_without_ref =  r_lanes_all %>%
  filter(ref == "") %>% 
  filter(cycling_potential >= min_cycling_potential_without_ref)
r_linestrings_without_ref_buff = geo_buffer(shp = r_linestrings_without_ref, dist = 20)
touching_list = st_intersects(r_linestrings_without_ref_buff)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_linestrings_without_ref$nogroup = components$membership

# mapview::mapview(r_linestrings_without_ref["nogroup"], lwd = 3)

# Remove groups with length <300m (20m buffer). (these are groups consisting purely of road segments with no ref) this is stricter than for roads with refs, because otherwise too many short segments are picked up. 
r_linestrings_without_ref2 = r_linestrings_without_ref %>%
  group_by(nogroup) %>%
  mutate(
    group_length = round(sum(length)),
    mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE))
    ) %>% 
  filter(group_length >= 300) %>%
  filter(mean_cycling_potential > min_grouped_cycling_potential) %>%  # this is currently 50
  ungroup() %>% 
  select(-nogroup, -group_length, -mean_cycling_potential)
# mapview::(no_ref_grouped["mean_cycling_potential"])

r_lanes = rbind(r_linestrings_with_ref, r_linestrings_without_ref2)
# mapview::mapview(r_lanes)

gs = unique(r_lanes$ref)
# i = g[2]
i = "A4174"

rg_list = lapply(gs, FUN = function(i) {
  rg = r_lanes %>% filter(ref == i)
  # mapview::mapview(rg)
  r_lanes_all_buff =   r_lanes_all_buff = rg %>% st_transform(27700) %>% st_buffer(100) %>% st_transform(4326)
  touching_list = st_intersects(r_lanes_all_buff)
  g = igraph::graph.adjlist(touching_list)
  components = igraph::components(g)
  rg$ig = components$membership
  rg
})

rg_new = do.call(rbind, rg_list)
# mapview::mapview(rg_new)

# Only keep groups with mean cycling potential >min_grouped_cycling_potential
rg_new2= rg_new %>% 
  group_by(ig, group, ref) %>%
  mutate(
    mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE))
    ) %>%
  filter(mean_cycling_potential >= min_grouped_cycling_potential) %>%
  ungroup()

rg_buff = geo_buffer(shp = rg_new2, dist = 100)
touching_list = st_intersects(rg_buff)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
rg_new2$lastgroup = components$membership

# Only keep segments which are part of a wider group (including roads with different refs/names) of >500m length (100m buffer)
rg_long = rg_new2 %>% 
  group_by(lastgroup) %>%
  summarise(last_length = round(sum(length))) %>%
  filter(last_length >= min_grouped_length)

rg_new3 = rg_new2[rg_new2$lastgroup %in% rg_long$lastgroup,]

# mapview::mapview(rg_new3)

r_lanes_grouped2 = rg_new3 %>% 
  group_by(ref, group, ig) %>% 
  summarise(
    name = names(table(name))[which.max(table(name))],
    group_length = round(sum(length)),
    mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE)),
    mean_width = round(weighted.mean(width, length, na.rm = TRUE)),
    spare_lane = sum(length[spare_lane]) > sum(length[!spare_lane])
  ) %>% 
  filter(mean_cycling_potential > min_grouped_cycling_potential | group_length > min_grouped_length) %>%
  # filter(group_length > min_grouped_length |
           #  mean_cycling_potential > min_grouped_cycling_potential &
           # (group_length * 2 > min_grouped_length)) %>% 
  ungroup() %>% 
  mutate(group_id = 1:nrow(.))

# mapview::mapview(r_lanes_grouped2, zcol = "mean_cycling_potential", lwd = 3)

# Generate lists of top segments ------------------------------------------------------------

cycleways = cycleways_en[region, ]
cycleways = cycleways %>% select(surface, name, lit, osm_id)
cycleway_buffer = stplanr::geo_buffer(cycleways, dist = pct_dist_within) %>% sf::st_union()

r_lanes_grouped_in_cycleway = st_intersection(r_lanes_grouped2, cycleway_buffer) %>% 
  mutate(length_in_cycleway = round(as.numeric(st_length(.))))
# mapview::mapview(r_lanes_grouped_in_cycleway["length_in_cycleway"]) +
#   mapview::mapview(cycleways)
r_lanes_grouped_in_cycleway = r_lanes_grouped_in_cycleway %>% 
  st_drop_geometry() 

minp_exclude = 0.75
r_lanes_joined = left_join(r_lanes_grouped2, r_lanes_grouped_in_cycleway) %>% 
  mutate(km_cycled = round(mean_cycling_potential * group_length / 1000)) 
r_lanes_joined$proportion_on_cycleway = r_lanes_joined$length_in_cycleway / r_lanes_joined$group_length
summary(r_lanes_joined$proportion_on_cycleway) # all between 0 and 1
# mapview::mapview(r_lanes_joined["proportion_on_cycleway"])

# we need to add in all segments within the grey key roads, and usethe combined dataset to pick the top routes 
r_lanes_top = r_lanes_joined %>%
  ungroup() %>% 
  filter(name != "" & ref != "") %>%
  filter(mean_cycling_potential > min_grouped_cycling_potential) %>% 
  filter(!grepl(pattern = regexclude, name, ignore.case = TRUE)) %>% 
  filter(proportion_on_cycleway < minp_exclude) %>% 
  arrange(desc(km_cycled)) %>% 
  slice(1:20)
nrow(r_lanes_top)

# classify roads to visualise
r_lanes_joined = r_lanes_joined %>% 
  mutate(
    Status = case_when(
      group_id %in% r_lanes_top$group_id ~ "Top route",
      spare_lane ~ "Spare lane(s)",
      mean_width >= 10 ~ "Width > 10"
    ) 
  ) %>% 
  select(name, ref, Status, mean_cycling_potential, spare_lane, mean_width, group_id)
r_lanes_joined$Status = factor(r_lanes_joined$Status, levels = c("Top route", "Spare lane(s)", "Width > 10"))

table(r_lanes_joined$Status)
summary(factor(r_lanes_joined$Status))

pvars_key = c("ref", "name", "width",
              "highway_type", "cycling_potential",
              "n_lanes")
key_network = key_network[pvars_key]
cols_status = c("blue", "turquoise", "purple")
tmap_mode("view")
m =
  tm_shape(key_network) +
  tm_lines(lwd = "width", scale = 9, col = "darkgrey", popup.vars = pvars_key) +
  tm_shape(r_lanes_joined) +
  tm_lines(col = "Status", 
           lwd = "mean_cycling_potential",
           alpha = 0.6, scale = 10,
           popup.vars = popup.vars,
           palette = cols_status
           # palette = "Dark2"
           ) +
  # tm_shape(r_lanes_top_n) + tm_lines(col = "width_status", lwd = 2, alpha = 0.6) +
  tm_shape(cycleways) + tm_lines(popup.vars = c("surface", "name", "osm_id"), col = "darkgreen", lwd = 1.3) +
  tm_basemap(server = s, tms = tms) +
  tm_scale_bar()
# m
m_leaflet = tmap_leaflet(m)
htmlwidgets::saveWidget(m_leaflet, "/tmp/m.html")
# system("ls -hal /tmp/m.html") # 15 MB for West Yorkshire
# browseURL("/tmp/m.html")

res_table = r_lanes_top %>% 
  sf::st_drop_geometry() %>% 
  select(name, ref, length = group_length, mean_cycling_potential, km_cycled) 
# knitr::kable(res_table, caption = "The top 10 candidate roads for space reallocation for pop-up active transport infrastructure according to methods presented in this paper.", digits = 0)

