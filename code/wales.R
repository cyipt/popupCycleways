# Aim: find spare lanes in Wales

remotes::install_github("itsleeds/geofabrik")
library(geofabrik)
library(tidyverse)
library(tmap)
tmap_mode("view")
city_centre = tmaptools::geocode_OSM("cardiff", as.sf = TRUE)
mapview::mapview(city_centre)

osm_data = geofabrik::get_geofabrik(city_centre)
nrow(osm_data) # 700,000+ filas
summary(osm_data$lanes)
table(osm_data$lanes)
osm_spare_lanes = osm_data %>%
  mutate(n_lanes = as.numeric(lanes)) %>%
  filter(n_lanes >= 2)
osm_cycleways = osm_data %>%
  filter(highway == "cycleway")
nrow(osm_spare_lanes)

mapview::mapview(osm_spare_lanes)
buffer_distance = 20 # km
sf::st_crs(city_centre)
# city_centre_geographic = sf::st_buffer(city_centre, 1) # incorrect
# mapview::mapview(city_centre_geographic)
# city_buffer = stplanr::geo_buffer(city_centre, buffer_distance * 1000) # fails
city_buffer = city_centre %>%
  sf::st_transform(crs = 5361) %>%
  sf::st_buffer(dist = buffer_distance * 1000) %>%
  sf::st_transform(4326)
osm_spare_city = sf::st_intersection(osm_spare_lanes, city_buffer)
osm_cycleways_city = sf::st_intersection(osm_cycleways, city_buffer) %>%
  mutate(n_lanes = 1) %>%
  select(name, highway, n_lanes, maxspeed, oneway)
osm_spare_clean = osm_spare_city %>%
  select(name, highway, n_lanes, maxspeed, oneway) %>%
  filter((n_lanes >= 2 & oneway == "yes") | (n_lanes >= 3)) %>% 
  filter(highway != "residential") %>% 
  filter(highway != "unclassified") %>% 
  filter(highway != "motorway") 
  

names(osm_cycleways_city)
names(osm_spare_clean)
osm_popup = rbind(osm_cycleways_city, osm_spare_clean)
s = c(
  "Esri.WorldGrayCanvas",
  "https://b.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png",
  "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'"
)
tm_shape(osm_popup) +
  tm_lines(col = "highway", lwd = "n_lanes", scale = 5) +
  tm_scale_bar() +
  tm_basemap(server = s)

