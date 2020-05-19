# aim: explore existing infrastructure in relation to pop-up analysis
library(sf)
library(tidyverse)
library(tmap)

country_name = "England"
region_name = "Birmingham"

library(geofabrik)
gfz = geofabrik::geofabrik_zones
e = gfz %>% 
  filter(name == country_name)
f = geofabrik::gf_filename(name = country_name)
download.file(url = e$pbf_url, destfile = f)
cycleways_en = geofabrik::read_pbf(dsn = f, key = "highway", value = "cycleway")
saveRDS(cycleways_en, "cycleways_en.Rds") # 10 MB file
piggyback::pb_upload("cycleways_en.Rds", "cyipt/cyipt-phase-1-data")
plot(sf::st_geometry(cycleways_en))

uas_en = readRDS("uas_en.Rds")

region = uas_en %>% filter(ctyua17nm == region_name)
mapview::mapview(region)
cycleways_region = cycleways_en[region, ]
# cycleways_region_long = cycleways_region %>% 
#   mutate(length = round(as.numeric(st_length(.)))) %>% 
#   filter(length > 50)
# summary(cycleways_region_long$length)
source("code/build.R")
m = tm_shape(r_pct_top) + tm_lines(col = "blue", lwd = 6, alpha = 0.6) +
  tm_shape(r_pct_top_n) + tm_text("name") +
  tm_shape(cycleways_region) + tm_lines() +
  tm_basemap(server = s) +
  tm_scale_bar()
m
cycleway_buffer = stplanr::geo_buffer(cycleways_region, dist = 50) %>% sf::st_union()
r_pct_top_no_cycleways = sf::st_difference(r_pct_top, cycleway_buffer)
# r_pct_top_no_cycleways = r_pct_top[cycleway_buffer, , op = sf::st_disjoint]
r_pct_top_no_cycleways = r_pct_top_no_cycleways %>% 
  st_cast("LINESTRING") %>% 
  mutate(group_length = round(as.numeric(st_length(.)))) %>% 
  filter(group_length > 50)

m = tm_shape(r_pct_top_no_cycleways) + tm_lines(col = "blue", lwd = 6, alpha = 0.6) +
  tm_shape(r_pct_top_n) + tm_text("name") +
  tm_shape(cycleways_region_long) + tm_lines() +
  tm_basemap(server = s) +
  tm_scale_bar()
m
