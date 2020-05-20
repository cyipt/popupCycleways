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

is_city = FALSE # Todo: add a new is_city parameter

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


# Update cycling potential values -----------------------------------------

rnet = pct::get_pct_rnet(region = "avon")
rnet_school = get_pct_rnet(region = "avon", purpose = "school")
rnet_reduce = rnet[,c(1,3)]
rnet_school_reduce = rnet[,c(1,3)]
combine = rbind(rnet_reduce, rnet_school_reduce)
rnet_combined = stplanr::overline2(x = combine, attrib = "govtarget_slc")


rnet_buff = geo_buffer(shp = rnet_combined, dist = 10)
r_cyipt_joined = st_join(r_main_region, rnet_buff, join = st_within)

dupes = r_cyipt_joined[which(duplicated(r_cyipt_joined$idGlobal) == TRUE | duplicated(r_cyipt_joined$idGlobal, fromLast = TRUE) == TRUE),]
dupes_max = dupes %>% 
  st_drop_geometry() %>% 
  group_by(idGlobal) %>%
  summarise(cycling_potential_max = max(govtarget_slc)) 

r_joined = left_join(r_cyipt_joined, dupes_max, by = "idGlobal") %>%
  mutate(cycling_potential = ifelse(is.na(cycling_potential_max), ifelse(is.na(govtarget_slc), pctgov, govtarget_slc), cycling_potential_max),
         cycling_potential_source = ifelse(is.na(cycling_potential_max), ifelse(is.na(govtarget_slc), "cyipt", "updated"), "updated_duplicate"))

r_positive = r_joined[which(r_joined$cycling_potential > 0),] %>%
  select(name:n_lanes, cycling_potential_source) %>%
  distinct(.keep_all = TRUE) # remove the duplicates

## ----levels, fig.height=3, fig.cap="Illustration of the 'group then filter' method to identify long sections with spare lanes *and* high cycling potential"----
r_pct_lanes_all = r_positive %>% 
  filter(cycling_potential > min_cycling_potential) %>% # min_cycling_potential = 0 so this simply selects multilane roads
  filter(lanes_f > 1 | lanes_b > 1)
# mapview::mapview(r_pct_lanes)

##this doesn't work. every segment gets put in its own group
# r_pct_lanes_all_buff = geo_buffer(shp = r_pct_lanes_all, dist = 200) 
# touching_list = st_touches(r_pct_lanes_all_buff)

touching_list = st_touches(r_pct_lanes_all)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_pct_lanes_all$group = components$membership


# Group by cycle potential to nearest 50 ----------------------------------
r_pct_lanes_all$rounded_cycle_potential = RoundTo(r_pct_lanes_all$cycling_potential, 50)

# These groups might be discontiguous
r_pct_lanes = r_pct_lanes_all %>% 
  group_by(group, rounded_cycle_potential) %>% 
  mutate(group_length = sum(length)) %>% 
  mutate(cycling_potential_mean = weighted.mean(cycling_potential, w = length, na.rm = TRUE)) %>% 
  filter(cycling_potential_mean > min_grouped_cycling_potential)
r_pct_lanes$group_index = group_indices(r_pct_lanes, group, rounded_cycle_potential)
# r_pct_lanes = r_pct_lanes %>% filter(group_length > min_grouped_length) # don't filter by group length until we have sorted out how to deal with discontinuous routes 

# this section needs changing since the group definitions have changed
r_pct_lanes$graph_group = r_pct_lanes$group_index
group_table = table(r_pct_lanes$group_index)
top_groups = tail(sort(group_table), 5)
r_pct_lanes$graph_group[!r_pct_lanes$graph_group %in% names(top_groups)] = "other"

tmap_mode("plot")
m2 = tm_shape(city_key_buffer) + tm_borders(col = "grey") +
  tm_shape(r_pct_lanes) + tm_lines("graph_group", palette = "Dark2") +
  tm_layout(title = "Group then filter:\n(length > 500, cycling_potential > 100)")
# m2

r_pct_grouped = r_pct_lanes %>%
  group_by(name, group) %>%
  summarise(
    group_length = sum(length),
    cycling_potential = round(weighted.mean(cycling_potential_mean, length))
  )
# summary(r_pct_grouped$group_length)
r_pct_top = r_pct_grouped %>%
  filter(group_length > min_grouped_length) %>% 
  filter(cycling_potential > min_grouped_cycling_potential) %>% 
  filter(!grepl(pattern = regexclude, name, ignore.case = TRUE)) %>% 
  mutate(km_day = round(cycling_potential * group_length / 1000))

## ----Grouping - work in progress---------------------------------------------------------------------------------

# commented-out for now (RL)
# r_pct_lanes$rounded_cycle_potential = RoundTo(r_pct_lanes$cycling_potential, 50)
# 
# ## Take segments (which are already grouped by the initial igraph list) and group by cycle potential rounded to the nearest 50
# 
# agg_var = st_sfc(list(r_pct_lanes$group), list(r_pct_lanes$rounded_cycle_potential))
# r_pct_group1 = r_pct_lanes %>%
#   group_by(group, rounded_cycle_potential) %>%
#   select(group, rounded_cycle_potential) %>%
#   st_drop_geometry() %>%
#   aggregate(by = list(r_pct_lanes$group, r_pct_lanes$rounded_cycle_potential), FUN = mean)
# 
# # Now need to separate non-adjacent groups with the same cycle potential
# 
# touching_list2 = st_touches(r_pct_group1)
# g2 = igraph::graph.adjlist(touching_list2)
# components2 = igraph::components(g2)
# r_pct_group1$group2 = components2$membership
# 
# 
# # This one should be shown on the map
# r_pct_grouped = r_pct_group1 %>%
#   group_by(group2) %>%
#   summarise(
#     group_length = sum(length),
#     cycling_potential = round(weighted.mean(cycling_potential, length))
#   )

# Generate lists of top segments ------------------------------------------------------------



# summary(r_pct_grouped$group_length)
r_pct_top = r_pct_grouped %>%
  filter(group_length > min_grouped_length) %>% 
  filter(cycling_potential > min_grouped_cycling_potential) %>% 
  filter(!grepl(pattern = regexclude, name, ignore.case = TRUE)) %>% 
  mutate(km_cycled = round(cycling_potential * group_length / 1000))
# head(r_pct_top$kkm_cycled)

r_pct_lanes_overlap = r_pct_lanes[r_pct_top, , op = sf::st_covered_by] # works
# r_pct_no_overlap = st_difference(r_pct_lanes, r_pct_top) # slow
r_pct_no_overlap = r_pct_lanes %>% 
  filter(!idGlobal %in% r_pct_lanes_overlap$idGlobal)

r_pct_top_n = r_pct_top %>% 
  group_by(name) %>% 
  slice(which.max(km_cycled)) %>% 
  filter(name != "") %>% 
  ungroup() %>% 
  arrange(desc(km_cycled)) %>% 
  slice(1:10)


# get existing infrastructure ---------------------------------------------
cycleways = cycleways_en[region, ]

# note: dist could be a parameter (RL)
cycleway_buffer = stplanr::geo_buffer(cycleways, dist = 50) %>% sf::st_union()
r_pct_top_no_cycleways = sf::st_difference(r_pct_top, cycleway_buffer)
r_pct_top_no_cycleways = r_pct_top_no_cycleways %>% 
  st_cast("LINESTRING") %>% 
  mutate(group_length = round(as.numeric(st_length(.)))) %>% 
  filter(group_length > 50)

## ----res, fig.cap="Results, showing road segments with a spare lane (light blue) and road groups with a minium threshold length, 1km in this case (dark blue). The top 10 road groups are labelled."----
tmap_mode("view")
m =
  tm_shape(r_pct_no_overlap) + tm_lines(col = "turquoise", lwd = 6, alpha = 0.6) +
  tm_shape(r_pct_top_no_cycleways) + tm_lines(col = "blue", lwd = 6, alpha = 0.6) +
  tm_shape(r_pct_top) + tm_lines(col = "red", lwd = 6, alpha = 0.6) +
  tm_shape(cycleways) + tm_lines() +
  tm_shape(r_pct_top_n) + tm_text("name") +
  tm_shape(h_city) + tm_dots(size = 0.1, col = "red", alpha = 0.4) +
  tm_basemap(server = s, tms = tms) +
  tm_scale_bar()
m

## --------------------------------------------------------------------------------------------
res_table = r_pct_top_n %>% 
  sf::st_drop_geometry() %>% 
  select(name, length = group_length, cycling_potential, km_cycled) 
knitr::kable(res_table, caption = "The top 10 candidate roads for space reallocation for pop-up active transport infrastructure according to methods presented in this paper.", digits = 0)

# }
