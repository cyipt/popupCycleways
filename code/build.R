# aim: output results highlighting and ranking roads that have 'spare lanes'

# global parameters ----------------------------------------------------------
library(DescTools)
library(sf)
library(tidyverse)
library(tmap)
library(pct)
library(stplanr)
if(!exists("s")) {
  message("Loading global parameters")  
  s = c(
    `Grey basemap` = "Esri.WorldGrayCanvas",
    `OSM existing cycle provision (CyclOSM)` = "https://b.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png",
    `PCT commuting, Government Target` = "https://npttile.vs.mythic-beasts.com/commute/v2/govtarget/{z}/{x}/{y}.png",
    `PCT schools, Government Target` = "https://npttile.vs.mythic-beasts.com/school/v2/govtarget/{z}/{x}/{y}.png",
    `Satellite image` = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'"
  )
  tms = c(FALSE, FALSE, TRUE, TRUE, FALSE)
  # test basemap:
  tmap_mode("view")
  if(!exists("parameters")) {
    parameters = read_csv("input-data/parameters.csv")
  }
  
  # read-in national data ---------------------------------------------------
  # see preprocess.R for data origins
  if(!exists("regions")) regions = readRDS("regions_dft.Rds")
  lads_all = readRDS("lads.Rds")
  lads_all_centroids = sf::st_centroid(lads_all)
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
  srn_names_df = readr::read_csv("input-data/srn_names_df.csv")
}

# local parameters --------------------------------------------------------
# i = 1
if(!exists("region_name")) {
  region_name = "West Yorkshire"
}

region = regions %>% filter(Name == region_name)

if(as.numeric(sf::st_area(region)) < 3000000000) {
  region = stplanr::geo_buffer(region, dist = 1000)
}

lads_centroids = lads_all_centroids[region$geometry, ]
lads = lads_all %>% filter(Name %in% lads_centroids$Name)
if(nrow(lads) == 0) {
  lads = region
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
# min_cycling_potential = 5
# min_grouped_cycling_potential = 30
# min_cycling_potential = quantile(x = rj$cycling_potential, probs = 0.5)
# min_grouped_cycling_potential = quantile(x = rj$cycling_potential, probs = 0.8)
# Select cycling potential thresholds based on max potential
# 1000 for West Yorkshire, 200 for Rutland
max_cycling_potential_99th = quantile(x = rj$cycling_potential, probs = 0.99)
min_cycling_potential = round(max_cycling_potential_99th / 250)
min_grouped_cycling_potential = round(max_cycling_potential_99th / 25)
# min_top_cycling_potential = min_grouped_cycling_potential + 10
n_top_roads = (1 + round(nrow(rj) / 60000)) * 10

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
rnet_combined = stplanr::overline2(sf::st_cast(combine, "LINESTRING"), attrib = "govtarget_slc")

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
  filter(group_length > 5 * min_grouped_length) %>% 
  mutate(
    `Estimated width` = case_when(
      width < 10 ~ "<10 m",
      width >= 10 & width < 15 ~ "10-15 m",
      width >= 15 ~ ">15 m"
    )
  ) 
# mapview::mapview(key_network)
# tm_shape(key_network) + tm_lines(lwd = "mean_width", scale = 7, col = "lightsalmon2")

# Identify roads with spare space ---------------------------------------

r_lanes_all = r_main_region %>% 
  filter(cycling_potential > min_cycling_potential) %>% # min_cycling_potential = 0 so this simply selects multilane roads
  mutate(spare_lane = lanes_f > 1 | lanes_b > 1) %>% 
  filter(spare_lane | width >= 9)

# Optionally remove areas outside key network:
# r_lanes_all = r_lanes_all[r_key_network_buffer_large, ]
# mapview::mapview(r_lanes_all)
buff_dist_large = 100
r_lanes_all_buff = geo_buffer(shp = r_lanes_all, dist = buff_dist_large)
touching_list = st_intersects(r_lanes_all_buff)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_lanes_all$group = components$membership
# mapview::mapview(r_lanes_all["group"])

r_linestrings_with_ref = r_lanes_all %>%
  filter(ref != "")

# Roads with no ref -------------------------------------------------------

# Remove segments with cycling potential below 30 (to prevent side street segments)
min_cycling_potential_without_ref = 30
r_linestrings_without_ref =  r_lanes_all %>%
  filter(ref == "") %>% 
  filter(cycling_potential >= min_cycling_potential_without_ref)

# Put into groups, using a 20m buffer (stricter than for roads with a ref, to prevent groups covering multiple streets)
r_linestrings_without_ref_buff = geo_buffer(shp = r_linestrings_without_ref, dist = 20)
touching_list = st_intersects(r_linestrings_without_ref_buff)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_linestrings_without_ref$group2 = components$membership

# mapview::mapview(r_linestrings_without_ref["group2"], lwd = 3)

# Remove groups with length <300m (20m buffer). (these are groups consisting purely of road segments with no ref) this is stricter than for roads with refs, because otherwise too many short segments are picked up. # Remove groups without sufficient width/lanes or cycle potential (the same as for roads with a ref)
r_linestrings_without_ref2 = r_linestrings_without_ref %>%
  group_by(group2) %>%
  mutate(
    group2_length = round(sum(length)),
    mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE)),
    mean_width = round(weighted.mean(width, length, na.rm = TRUE)),
    majority_spare_lane = sum(length[spare_lane]) > sum(length[!spare_lane])
  ) %>% 
  filter(group2_length >= 300) %>%
  filter(mean_cycling_potential > min_grouped_cycling_potential) %>%  # this varies by region
  filter(mean_width >= 10 | majority_spare_lane) %>%
  ungroup() 
# mapview::mapview(r_linestrings_without_ref2, zcol = "mean_cycling_potential")

# Roads with a ref --------------------------------------------------------

gs = unique(r_linestrings_with_ref$ref)
# i = g[2]
i = "A4174"

# create per ref groups
rg_list = lapply(gs, FUN = function(i) {
  rg = r_linestrings_with_ref %>% filter(ref == i)
  # mapview::mapview(rg)
  r_lanes_all_buff = rg %>%
    st_transform(27700) %>%
    st_buffer(buff_dist_large) %>%
    st_transform(4326)
  touching_list = st_intersects(r_lanes_all_buff)
  g = igraph::graph.adjlist(touching_list)
  components = igraph::components(g)
  rg$ig = components$membership
  rg
})

rg_new = do.call(rbind, rg_list)
# mapview::mapview(rg_new)

#Create group IDs for the roads with a ref
rg_new$group2 = paste(rg_new$ig, rg_new$group, rg_new$ref)
rg_new$ig = NULL

# Only keep groups of sufficient width/lanes and cycling potential
rg_new2 = rg_new %>% 
  group_by(group2) %>%
  mutate(
    group2_length = round(sum(length)),
    mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE)),
    mean_width = round(weighted.mean(width, length, na.rm = TRUE)),
    majority_spare_lane = sum(length[spare_lane]) > sum(length[!spare_lane])
  ) %>%
  filter(mean_width >= 10 | majority_spare_lane) %>%
  filter(mean_cycling_potential >= min_grouped_cycling_potential) %>%
  ungroup()
# mapview::mapview(rg_new2)

# Now rejoin the roads with no ref together with the roads with a ref
r_lanes = rbind(rg_new2, r_linestrings_without_ref2)
# mapview::mapview(r_lanes, zcol = "group2")

gs = unique(r_lanes$ref)
# i = g[2]
i = "A4174"

# create per ref groups
rg_list = lapply(gs, FUN = function(i) {
  rg = r_lanes %>% filter(ref == i)
  # mapview::mapview(rg)
  r_lanes_all_buff = rg %>%
    st_transform(27700) %>%
    st_buffer(buff_dist_large) %>%
    st_transform(4326)
  touching_list = st_intersects(r_lanes_all_buff)
  g = igraph::graph.adjlist(touching_list)
  components = igraph::components(g)
  rg$ig = components$membership
  rg
})

rg_new = do.call(rbind, rg_list)
# mapview::mapview(rg_new)

# Only keep groups of sufficient width and cycling potential
rg_new2 = rg_new %>% 
  group_by(ig, group, ref) %>%
  mutate(
    mean_width = round(weighted.mean(width, length, na.rm = TRUE)),
    mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE)),
    majority_spare_lane = sum(length[spare_lane]) > sum(length[!spare_lane])
    ) %>%
  filter(mean_width >= 10 | majority_spare_lane) %>%
  filter(mean_cycling_potential >= min_grouped_cycling_potential) %>%
  ungroup()
# mapview::mapview(rg_new2, zcol = "mean_cycling_potential")

rg_buff = geo_buffer(shp = rg_new2, dist = buff_dist_large)
touching_list = st_intersects(rg_buff)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
rg_new2$lastgroup = components$membership

# Only keep segments which are part of a wider group (including roads with different refs/names) of >500m length (100m buffer)
rg_new3 = rg_new2 %>% 
  group_by(lastgroup) %>%
  mutate(last_length = round(sum(length))) %>%
  filter(last_length >= min_grouped_length) %>% 
  ungroup()

# mapview::mapview(rg_new3, zcol = "lastgroup")
# create a new group to capture long continuous sections with the same name
min_length_named_road = min_grouped_length
rg_new4 = rg_new3 %>%
  group_by(ref, group, ig, name) %>%
  mutate(long_named_section = case_when(
    sum(length) > min_length_named_road & name != "" ~ name,
    TRUE ~ "Other"
  )
  ) %>%
  ungroup()
# mapview::mapview(rg_new4, zcol = "long_named_section")
table(rg_new4$long_named_section)
# new approach

# Split into sections by road name, and split these into contiguous sections using buff_dist_large (100m).
lgs = unique(rg_new4$long_named_section)

i = "Melbourn bypass"

# create per name groups
long_list = lapply(lgs, FUN = function(i) {
  lg = rg_new4 %>% filter(long_named_section == i)
  # mapview::mapview(lg)
  l_buff = lg %>%
    st_transform(27700) %>%
    st_buffer(buff_dist_large) %>%
    st_transform(4326)
  touching_list = st_intersects(l_buff)
  g = igraph::graph.adjlist(touching_list)
  components = igraph::components(g)
  lg$long_named_group = components$membership
  lg
})

lg_new = do.call(rbind, long_list)

# other_roads = rg_new4[rg_new4$long_named_section == "Other", ]
# other_roads$long_named_group = NA
# rejoined = rbind(lg_new, other_roads)

# find group membership of top named roads
r_lanes_grouped2 = lg_new %>%
  group_by(ref, group, ig, long_named_section, long_named_group) %>% 
  summarise(
    name = case_when(
      length(table(name)) > 4 ~ "Unnamed road",
      names(table(name))[which.max(table(name))] != "" ~
        names(table(name))[which.max(table(name))],
      names(table(ref))[which.max(table(ref))] != "" ~
        names(table(ref))[which.max(table(ref))],
      TRUE ~ "Unnamed road"
      ), 
    group_length = round(sum(length)),
    mean_cycling_potential = round(weighted.mean(cycling_potential, length, na.rm = TRUE)),
    mean_width = round(weighted.mean(width, length, na.rm = TRUE)),
    majority_spare_lane = sum(length[spare_lane]) > sum(length[!spare_lane]),
    speed_limit = names(which.max(table(maxspeed)))
  ) %>% 
  filter(mean_cycling_potential > min_grouped_cycling_potential | group_length > min_grouped_length) %>%
  ungroup() %>% 
  mutate(group_id = 1:nrow(.))
# mapview::mapview(r_lanes_grouped2, zcol = "mean_cycling_potential")
# mapview::mapview(r_lanes_grouped2, zcol = "name")

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

minp_exclude = 0.8
r_lanes_joined = left_join(r_lanes_grouped2, r_lanes_grouped_in_cycleway) %>% 
  mutate(km_cycled = round(mean_cycling_potential * group_length / 1000)) 
r_lanes_joined$length_in_cycleway[is.na(r_lanes_joined$length_in_cycleway)] = 0
r_lanes_joined$proportion_on_cycleway = r_lanes_joined$length_in_cycleway / r_lanes_joined$group_length
summary(r_lanes_joined$proportion_on_cycleway) # all between 0 and 1
# mapview::mapview(r_lanes_joined["proportion_on_cycleway"])

# we need to add in all segments within the grey key roads, and usethe combined dataset to pick the top routes 
r_lanes_top = r_lanes_joined %>%
  # filter(name != "Unnamed road" & ref != "") %>%
  filter(name != "Unnamed road") %>%
  # filter(!str_detect(string = name, pattern = "^A[1-9]")) %>%
  filter(group_length > min_grouped_length) %>%
  filter(mean_cycling_potential > min_grouped_cycling_potential) %>% 
  filter(!grepl(pattern = regexclude, name, ignore.case = TRUE)) %>% 
  filter(proportion_on_cycleway < minp_exclude) %>% 
  mutate(
    length_up_to_1km = if_else(group_length > 1000, true = 1000, false = group_length),
    km_cycled_1km = length_up_to_1km * mean_cycling_potential,
    srn = name %in% srn_names_df$roa_number
    ) %>% 
  arrange(desc(mean_cycling_potential)) %>% 
  slice(1:n_top_roads) 
nrow(r_lanes_top)

# classify roads to visualise
labels = c("Top ranked new cycleways", "Spare lane(s)", "Estimated width > 10m")
cycleways_name = "Existing cycleways"

r_lanes_final = r_lanes_joined %>% 
  mutate(
    Status = case_when(
      group_id %in% r_lanes_top$group_id ~ labels[1],
      majority_spare_lane ~ labels[2],
      mean_width >= 10 ~ labels[3]
    ),
    `Estimated width` = case_when(
      mean_width < 10 ~ "<10 m",
      mean_width >= 10 & mean_width < 15 ~ "10-15 m",
      mean_width >= 15 ~ ">15 m"
    )
  ) %>% 
  select(name, ref, Status, mean_cycling_potential, spare_lane = majority_spare_lane, `Estimated width`, `length (m)` = group_length, group_id, speed_limit)
r_lanes_final$Status = factor(r_lanes_final$Status, levels = c(labels[1], labels[2], labels[3]))

table(r_lanes_final$name)
table(r_lanes_final$Status)
summary(factor(r_lanes_final$Status))

# Post-processing and set-up for map --------------------------------------

summary(r_lanes_final$Status)
top_routes = r_lanes_final %>% filter(Status == labels[1])
# show spare lane segments not groups:
spare_lane_groups = r_lanes_final %>% filter(Status == labels[2])
route_segments_final = rg_new4 %>% 
  mutate(
    `Estimated width` = case_when(
      mean_width < 10 ~ "<10 m",
      mean_width >= 10 & mean_width < 15 ~ "10-15 m",
      mean_width >= 15 ~ ">15 m"
    )
  )
spare_lane_segments = route_segments_final[spare_lane_groups, , op = sf::st_within]
spare_lanes = spare_lane_segments %>%
  filter(spare_lane) %>% 
  mutate(Status = labels[2])
# edge case: there are no spare lanes
if(nrow(spare_lanes) == 0) {
  spare_lanes = route_segments_final %>%
    top_n(n = 1, wt = width) %>% 
    mutate(Status = labels[2]) 
}
# show wide segments not groups:
# width_10m = r_lanes_final %>% filter(Status == labels[1])
wide_lane_groups = r_lanes_final %>% filter(Status == labels[3])
wide_lane_segments = route_segments_final[wide_lane_groups, , op = sf::st_within]
wide_lanes = wide_lane_segments %>%
  filter(width >= 10 & !idGlobal %in% spare_lanes$idGlobal) %>% 
  mutate(Status = labels[3])
# edge case: there are no wide lanes
if(nrow(wide_lanes) == 0) {
  wide_lanes = route_segments_final %>%
    top_n(n = 1, wt = width) %>% 
    mutate(Status = labels[3]) 
}
spare_wide_lanes = rbind(wide_lanes, spare_lanes)

tmap_mode("view")

pvars_top = c(
  "name",
  "ref",
  "spare_lane",
  "Estimated width",
  "mean_cycling_potential",
  "speed_limit",
  "length (m)"
)
pvars_key = c("ref", "name", "highway_type", "cycling_potential", "n_lanes", "Estimated width", "maxspeed")
key_network_final = key_network[pvars_key]
pvars_spare = c("name", "ref", "maxspeed", "cycling_potential", "n_lanes")
spare_lanes_final = spare_lanes[pvars_spare]
wide_lanes_final = wide_lanes[pvars_spare]
legend_labels = c(cycleways_name, labels[1], "Cohesive network", labels[2], labels[3])
cols_status = c("blue", "#B91F48", "#FF7F00")
legend_colours = c("darkgreen", cols_status[1], "darkgrey", cols_status[2:3])

m =
  tm_shape(lads, name = "Local authority district boundaries") + tm_borders() +
  tm_shape(key_network_final, name = "Cohesive network") +
  tm_lines(lwd = 5, col = "darkgrey", popup.vars = pvars_key) +
  tm_shape(spare_lanes_final, name = labels[2]) +
  tm_lines(legend.col.show = FALSE,
           col = cols_status[2], 
           lwd = 3,
           alpha = 1,
           popup.vars = pvars_spare,
           group = labels[2]
           ) +
  tm_shape(wide_lanes_final, name = labels[2]) +
  tm_lines(legend.col.show = FALSE,
           col = cols_status[3], 
           lwd = 3,
           alpha = 1,
           popup.vars = pvars_spare,
           group = labels[3]
  ) +
  tm_shape(cycleways, name = cycleways_name) + tm_lines(popup.vars = c("surface", "name", "osm_id"), col = "darkgreen", lwd = 1.3) +
  tm_shape(top_routes, name = "Top routes") +
  tm_lines(legend.col.show = FALSE,
           col = cols_status[1], 
           lwd = 5,
           alpha = 1,
           popup.vars = pvars_top
  ) +
  tm_basemap(server = s, tms = tms) +
  tm_add_legend(type = "fill", labels = legend_labels[1:3], col = legend_colours[1:3]) +
  tm_add_legend(type = "fill", labels = labels[2], col = legend_colours[4], group = labels[2]) +
  tm_add_legend(type = "fill", labels = labels[3], col = legend_colours[5], group = labels[3]) +
  tm_scale_bar() 
# m
m_leaflet = tmap_leaflet(m) %>% leaflet::hideGroup(labels[2:3])
# htmlwidgets::saveWidget(m_leaflet, "/tmp/m.html")
# system("ls -hal /tmp/m.html") # 15 MB for West Yorkshire
# browseURL("/tmp/m.html")

res_table = r_lanes_top %>% 
  sf::st_drop_geometry() %>% 
  select(
    Name = name,
    Reference = ref,
    `Length (m)` = group_length,
    `Cycling potential` = mean_cycling_potential,
    `Length * potential (km)` = km_cycled,
    # `SRN` = srn,
    `Speed limit` = speed_limit
    ) 
res_table
# knitr::kable(res_table, caption = "The top 10 candidate roads for space reallocation for pop-up active transport infrastructure according to methods presented in this paper.", digits = 0)

