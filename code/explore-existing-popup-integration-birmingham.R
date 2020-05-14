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
plot(sf::st_geometry(cycleways_en))

uas_en = readRDS("uas_en.Rds")

region = uas_en %>% filter(ctyua17nm == region_name)
mapview::mapview(region)
cycleways_region = cycleways_en[region, ]
source("code/build.R")
