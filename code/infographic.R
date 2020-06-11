# Aim: create infographic of top 12 zones by PT/cycling potential

regions = readRDS("regions_top_12.Rds")
regions$html_name = tolower(gsub(pattern = " |, ", replacement = "-", regions$Name))
regions$url = paste0("<a href='", regions$html_name ,"' target='_blank'>", regions$Name, "</a>")
i = 1
top_routes_all = NULL

# for(i in seq(nrow(regions))) {
# for(i in 1:4) {
for(i in 1:6) {
  n = regions$html_name[i]
  top_routes = sf::read_sf(file.path("popupCycleways/release", n, "top_routes.geojson"))[1]
  top_routes$Layer = "Top ranked new cycleways"
  cohesive_network = sf::read_sf(file.path("popupCycleways/release", n, "cohesive_network.geojson"))[1]
  names(cohesive_network)[1] = "name"
  cohesive_network$Layer = "Cohesive network"
  cycleways = sf::read_sf(file.path("popupCycleways/release", n, "cycleways.geojson"))[1]
  names(cycleways)[1] = "name"
  cycleways$Layer = "Cycleways"
  top_routes_region = rbind(top_routes, cohesive_network, cycleways)
  top_routes_region$Region = regions$Name[i]
  top_routes_all = rbind(top_routes_all, top_routes_region)
}

unique(top_routes_all$Region)
# plot(top_routes_all)
top_routes_all$lwd = case_when(
  top_routes_all$Layer == "Cycleways" ~ 1,
  top_routes_all$Layer == "Top ranked new cycleways" ~ 3,
  top_routes_all$Layer == "Cohesive network" ~ 1
)
top_routes_all$Region = gsub("Greater ", "", top_routes_all$Region)
top_routes_all$Region = gsub(" City Region", "", top_routes_all$Region)
top_routes_all$Region = case_when(
  top_routes_all$Region == "North East" ~ "Newcastle",
  top_routes_all$Region == "West Yorkshire" ~ "Leeds",
  top_routes_all$Region == "West Midlands" ~ "Birmingham",
  TRUE ~ top_routes_all$Region
)
summary(as.factor(top_routes_all$Region))

top_routes_all$Layer = factor(
  top_routes_all$Layer,
  levels = c("Cycleways", "Top ranked new cycleways", "Cohesive network")
  )
summary(top_routes_all$Layer)
top_routes_all = top_routes_all %>% 
  filter(name != "A167") %>% 
  filter(name != "Shotton Road")
top_routes_cohesive = top_routes_all %>% 
  filter(Layer == "Cohesive network")

library(tmap)
tmap_mode("plot")
regions$Region = regions$Name

centrepoints = tmaptools::geocode_OSM(q = c(
  "london",
  "newcastle upon tyne",
  "manchester",
  "liverpool",
  "birmingham",
  "leeds"
  ), as.sf = TRUE)
mapview::mapview(centrepoints)
cbs = stplanr::geo_buffer(centrepoints, dist = 10000)
mapview::mapview(cbs)

trb = top_routes_all[cbs, ]

# tm_shape(top_routes_all %>% sample_n(1000)) +
tm_shape(trb) +
  tm_lines(title.col = "",
    col = "Layer",
    palette = c("green", "blue", "purple"),
    lwd = "lwd", scale = 5,
    legend.lwd.show = FALSE
    ) +
  tm_facets("Region", ncol = 3) +
  # tm_shape(regions) + tm_borders() +
  tm_layout(scale = 1.5, 
    # main.title = "Current and possible future cycleway networks. Source: Rapid Cycleway Prioritisation Tool",
            legend.outside.position = "bottom", legend.outside.size = 0.08
            ) +
  tm_scale_bar(breaks = c(0, 1, 2, 5))


tm_shape(top_routes_all %>% sample_n(1000)) +
  tm_lines(
    col = "Layer",
    palette = c("purple", "blue"),
    lwd = "lwd", scale = 5,
    legend.lwd.show = FALSE) +
  tm_facets("Region", ncol = 3) +
  # tm_shape(regions) + tm_borders() +
  tm_layout(legend.outside.size = c(0.1))

top_routes_sample = top_routes_all %>% sample_n(1000)
saveRDS(top_routes_sample, "top_routes_sample.Rds")
piggyback::pb_upload("top_routes_sample.Rds")
piggyback::pb_download_url("top_routes_sample.Rds")

library(tmap)

u = "https://github.com/cyipt/popupCycleways/releases/download/0.3/top_routes_sample.Rds"
top_routes_sample = readRDS(url(u))

tm_shape(top_routes_sample) +
  tm_lines(
    col = "Layer",
    palette = c("purple", "blue"),
    lwd = "lwd", scale = 5,
    legend.lwd.show = FALSE) +
  tm_facets("Region", ncol = 3) 

tm_shape(top_routes_sample) +
  tm_lines(title.col = "",
           col = "Layer",
           palette = c("purple", "blue"),
           lwd = "lwd", scale = 5,
           legend.lwd.show = FALSE) +
  tm_facets("Region", ncol = 3) 


tm_shape(top_routes_sample) +
  tm_lines(title.col = NULL,
    col = "Layer",
    palette = c("purple", "blue"),
    lwd = "lwd", scale = 5,
    legend.lwd.show = FALSE) +
  tm_facets("Region", ncol = 3) 


tm_shape(top_routes_sample) +
  tm_lines(
    col = "Layer",
    palette = c("purple", "blue"),
    lwd = "lwd", scale = 5,
    legend.lwd.show = FALSE) +
  tm_facets("Region", ncol = 3, free.scales = TRUE) 
  # tm_shape(regions) + tm_borders() +

tm_shape(top_routes_sample %>% sample_n(1000)) +
  tm_lines(
    col = "Layer",
    palette = c("purple", "blue"),
    lwd = "lwd", scale = 5,
    legend.lwd.show = FALSE) +
  tm_facets("Region", ncol = 3) +
  # tm_shape(regions) + tm_borders() +
  tm_layout(legend.outside.size = c(0.1))


# issue: very bitty!
# test with view mode

tmap_mode("view")
m1 = tm_shape(top_routes_all) +
  tm_lines() +
  tm_facets("Region", ncol = 2)
ml = m1 %>% tmap_leaflet()
class(ml)



str(ml)


tmap_mode("plot")
m1 = tm_shape()
