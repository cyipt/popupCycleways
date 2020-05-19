# aim: output results highlighting and ranking roads that have 'spare lanes'

# global parameters ----------------------------------------------------------
library(sf)
library(tidyverse)
library(tmap)
if(!exists("parameters")) {
message("Loading global parameters")  
s = c(
  `Grey` = "Esri.WorldGrayCanvas",
  `PCT (Ebike)` = "https://npttile.vs.mythic-beasts.com/commute/v2/ebike/{z}/{x}/{y}.png",
  `Cycleways` = "https://b.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png",
  `Satellite` = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'"
)
# test basemap:
tmap_mode("view")
tm_shape(spData::lnd) + tm_borders() + tm_basemap(s, tms = c(FALSE, TRUE, FALSE, FALSE))
parameters = read_csv("input-data/parameters.csv")

# read-in national data ---------------------------------------------------
regions = readRDS("regions.Rds")
rj = readRDS("rj.Rds")
region_names = regions$Name
# hospitals:
# hsf = readRDS("hsf.Rds")
nrow(regions)
# mapview::mapview(regions)
# r_original = r_original[st_transform(region, st_crs(r_original)), ]
}

# local parameters --------------------------------------------------------
# i = 1
if(!exists("region_name"))
  region_name = "West Midlands"
region = regions %>% filter(Name == region_name)
r_original = rj[region_to_build, ]
i = which(parameters$name %in% region_name)
if(length(i) == 0) i = 1
p = parameters[i, ]
list2env(p, envir = .GlobalEnv)

is_city = FALSE # Todo: add a new is_city parameter

# buffers -----------------------------------------------------------------
# for(i in seq(length(region_names))) {
city_centre = tmaptools::geocode_OSM(region_name, as.sf = TRUE)
city_centre_buffer = stplanr::geo_buffer(city_centre, dist = city_centre_buffer_radius)
h_city = hsf[city_centre_buffer, ]
h_city_buffer = stplanr::geo_buffer(h_city, dist = key_destination_buffer_radius)
city_key_buffer = st_union(city_centre_buffer, st_union(h_city_buffer))

## ----preprocess------------------------------------------------------------------------------
# remove motorways
r_original$highway_type = r_original$highway
r_original$highway_type = gsub(pattern = "_link", replacement = "", r_original$highway)
highway_table = table(r_original$highway)
highway_rare = highway_table[highway_table < nrow(r_original) / 100]
highway_remove = names(highway_rare)[!grepl(pattern = "motor|living|ped", x = names(highway_rare))]
r_cleaned = r_original %>% 
  filter(!grepl(pattern = "motorway", x = highway)) %>% 
  mutate(highway_type = case_when(
    highway_type %in% highway_remove ~ "other",
    grepl(pattern = "path|track|trunk", highway_type) ~ "other",
    grepl(pattern = "ped|liv", highway_type) ~ "pedestrian/living_street",
    TRUE ~ highway_type
  )) %>% 
  mutate(maxspeed = case_when(
    maxspeed <= 20 ~ "20 mph or less",
    maxspeed > 20 & maxspeed <= 30 ~ "30 mph",
    maxspeed > 30 ~ "40+ mph",
  )) %>% 
  mutate(cycling_potential = as.numeric(pctgov)) 
# table(r_cleaned$maxspeed)
rj = inner_join(r_cleaned, rtid) %>% 
  mutate(lanes_f = abs(lanespsvforward) + abs(lanesforward)) %>% 
  mutate(lanes_b = abs(lanespsvbackward) + abs(lanesbackward)) %>% 
  mutate(n_lanes_numeric = lanes_f + lanes_b) %>% 
  mutate(n_lanes = as.character(n_lanes_numeric))
rj$n_lanes_numeric[rj$n_lanes_numeric <= 0] = 1 
rj$n_lanes[rj$n_lanes == "0"] = "1"
rj$n_lanes[rj$n_lanes == "4"] = "4+"
rj$n_lanes[rj$n_lanes == "5"] = "4+"
rj$n_lanes[rj$n_lanes == "6"] = "4+"
cy = r_cleaned %>% filter(highway == "cycleway")
r_central = rj[city_key_buffer, ]
r_main = r_central %>% 
  filter(grepl(pattern = "cycleway|primary|second|tert", highway_type))
r_main_region = rj %>% 
  filter(grepl(pattern = "cycleway|primary|second|tert", highway_type))

## ----t1, results='asis'----------------------------------------------------------------------
t1 = rj %>%
  st_drop_geometry() %>%
  # select(name, highway_type, maxspeed, cycling_potential, width) %>%
  table1::table1(~ highway_type + cycling_potential + width + n_lanes | maxspeed, data = ., )

## ----hospitals, fig.cap="Overview map of input data, showing the main highway types and location of hospitals in city"----
m1 = r_main_region %>%
  sample_n(1000) %>% 
  mutate(`Highway type` = highway_type) %>% 
  mutate(`Cycling potential` = case_when(cycling_potential < 100 ~ 100, TRUE ~ cycling_potential)) %>% 
  tm_shape(bbox = st_bbox(city_centre_buffer)) +
  tm_lines(col = "Highway type", palette = c("green", "black", "blue", "grey"),
           lwd = "Cycling potential", scale = 5, lwd.legend = c(100, 200, 500, 1000),
           lwd.legend.labels = c("0 - 100", "100 - 200", "200 - 500", "500+")) +
  tm_shape(h_city) + tm_dots(size = 0.5, col = "ParentName", palette = "Dark2", title = "Hospital group") +
  tm_layout(legend.outside = TRUE)
# + tm_text("OrganisationName")
# m1


## ----levels, fig.height=3, fig.cap="Illustration of the 'group then filter' method to identify long sections with spare lanes *and* high cycling potential"----
r_pct_lanes_all = r_central %>% 
  filter(cycling_potential > min_cycling_potential) %>% 
  filter(lanes_f > 1 | lanes_b > 1)
# mapview::mapview(r_pct_lanes)

touching_list = st_touches(r_pct_lanes_all)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_pct_lanes_all$group = components$membership
r_pct_lanes = r_pct_lanes_all %>% 
  group_by(group) %>% 
  mutate(group_length = sum(length)) %>% 
  mutate(cycling_potential_mean = weighted.mean(cycling_potential, w = length, na.rm = TRUE)) %>% 
  filter(cycling_potential_mean > min_grouped_cycling_potential)
r_pct_lanes = r_pct_lanes %>% filter(group_length > min_grouped_length)

r_pct_lanes$graph_group = r_pct_lanes$group
group_table = table(r_pct_lanes$group)
top_groups = tail(sort(group_table), 5)
r_pct_lanes$graph_group[!r_pct_lanes$graph_group %in% names(top_groups)] = "other"

r_filter_before_grouping = rj %>% 
  filter(cycling_potential > min_cycling_potential) %>% 
  filter(lanes_f > 1 | lanes_b > 1) %>% 
  filter(cycling_potential > min_grouped_cycling_potential) %>% 
  filter(length > 100)
tmap_mode("plot")
m0 = tm_shape(city_key_buffer) + tm_borders(col = "grey") +
  tm_shape(r_pct_lanes_all) + tm_lines() +
  tm_layout(title = "Roads on which there are spare lanes.")
m1 = tm_shape(city_key_buffer) + tm_borders(col = "grey") +
  tm_shape(r_filter_before_grouping) + tm_lines() +
  tm_layout(title = "Filter then group:\n(length > 100, cycling_potential > 100)")
m2 = tm_shape(city_key_buffer) + tm_borders(col = "grey") +
  tm_shape(r_pct_lanes) + tm_lines("graph_group", palette = "Dark2") +
  tm_layout(title = "Group then filter:\n(length > 500, cycling_potential > 100)")
# todo show group membership with colours
# ma = tmap_arrange(m0, m1, m2, nrow = 1)
# ma

## ----joining---------------------------------------------------------------------------------
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

## ----res, fig.cap="Results, showing road segments with a spare lane (light blue) and road groups with a minium threshold length, 1km in this case (dark blue). The top 10 road groups are labelled."----
tmap_mode("view")
m = tm_shape(r_pct_no_overlap) + tm_lines(col = "turquoise", lwd = 6, alpha = 0.6) +
  tm_shape(r_pct_top) + tm_lines(col = "blue", lwd = 6, alpha = 0.6) +
  tm_shape(r_pct_top_n) + tm_text("name") +
  tm_shape(h_city) + tm_dots(size = 0.1, col = "red", alpha = 0.4) +
  tm_basemap(server = s) +
  tm_scale_bar()
# m

## --------------------------------------------------------------------------------------------
res_table = r_pct_top_n %>% 
  sf::st_drop_geometry() %>% 
  select(name, length = group_length, cycling_potential, km_cycled) 
knitr::kable(res_table, caption = "The top 10 candidate roads for space reallocation for pop-up active transport infrastructure according to methods presented in this paper.", digits = 0)

# }