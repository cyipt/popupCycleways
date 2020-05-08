# Aim: explore data for methods development in Leeds


# set-up and load data ----------------------------------------------------

library(sf)
library(tidyverse)
library(tmap)
tmap_mode("view")

# run once to get leeds
# region_name = "Leeds"
# rsf = readRDS("rsf.Rds")
# r = rsf[rsf$region == "Leeds", ]
# r = r[ukboundaries::leeds, ]
# saveRDS(r, "rsf_leeds.Rds")
# piggyback::pb_upload("rsf_leeds.Rds")
# piggyback::pb_download_url("rsf_leeds.Rds")

u = "https://github.com/cyipt/tempCycleways/releases/download/0.1/rsf_leeds.Rds"
r_original = readRDS(url(u))
nrow(r_original)
plot(r_original$geometry)
head(r_original)
names(r_original)

ur = "https://github.com/cyipt/tempCycleways/releases/download/0.1/rtid.csv"
rtid = readr::read_csv(ur)

# parameters --------------------------------------------------------------

min_pctgov = 0
min_grouped_pctgov = 100
min_grouped_length = 500
city_centre_buffer_radis = 8000
city_centre = tmaptools::geocode_OSM("leeds", as.sf = TRUE)
city_centre_buffer = stplanr::geo_buffer(city_centre, dist = 8000)

# preprocess + filter -----------------------------------------------------

rj = inner_join(r_original, rtid)
summary(as.factor(rj$highway))

# remove motorways
r = rj %>% 
  filter(!grepl(pattern = "motorway", x = highway))
summary(r$length)

# cycleways
cy = r %>% filter(highway == "cycleway")
plot(st_geometry(cy))

# simple pctgov and lanes filter ------------------------------------------

r_pct_lanes = r %>% 
  filter(pctgov > min_pctgov) %>% 
  filter((lanespsvforward + lanesforward) > 1 |
      (lanespsvbackward + lanesbackward) > 1
  )

plot(st_geometry(r_pct_lanes))

# issues: lots of 'bitty' sections, lanes extend way beyond city centre (pct threshold issue?)
# solution: add new variable with groups: https://gis.stackexchange.com/questions/310462
touching_list = st_touches(r_pct_lanes)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
str(components)
r_pct_lanes$group = components$membership
r_pct_lanes = r_pct_lanes %>% 
  group_by(group) %>% 
  mutate(group_length = sum(length)) %>% 
  mutate(pctgov_mean = mean(pctgov, na.rm = TRUE)) %>% 
  filter(pctgov_mean > min_grouped_pctgov)
components$no
r_pct_lanes = r_pct_lanes %>% filter(group_length > min_grouped_length)
plot(st_geometry(r_pct_lanes))
mapview::mapview(r_pct_lanes)

# illustration of before vs after group filtering

r_filter_before_grouping = r %>% 
  filter(pctgov > min_pctgov) %>% 
  filter((lanespsvforward + lanesforward) > 1 |
           (lanespsvbackward + lanesbackward) > 1
  ) %>% 
  filter(pctgov > min_grouped_pctgov) %>% 
  # filter(length > min_grouped_length)
  filter(length > 100)

tmap_mode("plot")
m1 = tm_shape(city_centre_buffer) + tm_borders(col = "grey") +
  tm_shape(r_filter_before_grouping) + tm_lines() +
  tm_layout(title = "Filter then group (length > 100, cycling_potential > 100)")
m1
m2 = tm_shape(city_centre_buffer) + tm_borders(col = "grey") +
  tm_shape(r_pct_lanes) + tm_lines() +
  tm_layout(title = "Group then filter (length > 500, cycling_potential > 100)")
m2
# to go into paper
tmap_arrange(m1, m2)

