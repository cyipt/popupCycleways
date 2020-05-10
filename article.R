## ----setup, include=FALSE--------------------------------------------------------------------
knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE, cache = TRUE)


## ---- echo=FALSE, eval=FALSE-----------------------------------------------------------------
## citr::tidy_bib_file("article.Rmd", "~/uaf/allrefs.bib", file = "ref.bib")
## wordcountaddin::word_count("article.Rmd")


## ----commonplace, fig.cap="Screenshot from the website salfordliveablestreets.commonplace.is to support local responses to the Covid-19 pandemic, including the prioritisation of pop-up active transport infrastructure."----
knitr::include_graphics("https://user-images.githubusercontent.com/1825120/81451234-ed82d200-917b-11ea-977d-fff1665378c5.png")


## ----load------------------------------------------------------------------------------------
library(sf)
library(tidyverse)
library(tmap)
if(!file.exists("rsf_leeds.Rds")) {
  u = "https://github.com/cyipt/tempCycleways/releases/download/0.1/rsf_leeds.Rds"
  download.file(u, "rsf_leeds.Rds")
}
r_original = readRDS("rsf_leeds.Rds")
if(!file.exists("rtid.csv")) {
  ur = "https://github.com/cyipt/tempCycleways/releases/download/0.1/rtid.csv"
  download.file(ur, "rtid.csv")
}
rtid = readr::read_csv("rtid.csv")
# uh = "http://media.nhschoices.nhs.uk/data/foi/Hospital.csv"
# download.file(uh, "uh.csv")
h = readr::read_delim("uh-edited.csv", delim = "|")
# nrow(h) # 1221 hospitals
h_clean = h %>% 
  mutate(Longitude = as.numeric(Longitude)) %>% 
  mutate(Latitude = as.numeric(Latitude)) %>% 
  filter(!is.na(Longitude)) %>% 
  filter(!is.na(Latitude))
hsf = h_clean %>% st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326)
region = ukboundaries::leeds
tmap_mode("plot")


## ----parameters------------------------------------------------------------------------------
regexclude = "welling"
min_cycling_potential = 0
min_grouped_cycling_potential = 100
min_grouped_length = 500
city_centre_buffer_radius_small = 5000
city_centre_buffer_radius = 8000
city_centre_buffer_radius_large = 10000
key_destination_buffer_radius = 5000
city_centre = tmaptools::geocode_OSM("leeds", as.sf = TRUE)
city_centre_buffer_small = stplanr::geo_buffer(city_centre, dist = city_centre_buffer_radius_small)
city_centre_buffer = stplanr::geo_buffer(city_centre, dist = city_centre_buffer_radius)
city_centre_buffer_large = stplanr::geo_buffer(city_centre, dist = city_centre_buffer_radius_large)
h_leeds = hsf[city_centre_buffer, ]
h_leeds_buffer = stplanr::geo_buffer(h_leeds, dist = key_destination_buffer_radius)
city_key_buffer = st_union(city_centre_buffer, st_union(h_leeds_buffer))


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
# rj %>%
#   st_drop_geometry() %>%
#   # select(name, highway_type, maxspeed, cycling_potential, width) %>%
#   table1::table1(~ highway_type + cycling_potential + width + n_lanes | maxspeed, data = ., )
knitr::include_graphics("https://user-images.githubusercontent.com/1825120/81476961-c32d2500-920c-11ea-8430-94c3afc2e27d.png")


## ----hospitals, fig.cap="Overview map of input data, showing the main highway types and location of hospitals in Leeds"----
m1 = r_main_region %>%
  mutate(`Highway type` = highway_type) %>% 
  mutate(`Cycling potential` = case_when(cycling_potential < 100 ~ 100, TRUE ~ cycling_potential)) %>% 
  tm_shape(bbox = st_bbox(city_centre_buffer)) +
  tm_lines(col = "Highway type", palette = c("green", "black", "blue", "grey"),
           lwd = "Cycling potential", scale = 5, lwd.legend = c(100, 200, 500, 1000),
           lwd.legend.labels = c("0 - 100", "100 - 200", "200 - 500", "500+")) +
  tm_shape(h_leeds) + tm_dots(size = 0.5, col = "ParentName", palette = "Dark2", title = "Hospital group") +
  tm_layout(legend.outside = TRUE)
# + tm_text("OrganisationName")
m1


## ----gsub, fig.cap="Illustration of geographic subsetting based on distance to a central point (Leeds city city centre in this case) rather than based on location within somewhat arbitrarily shaped city boundaries. Radii of 5 km, 8 km and 10 km are shown for reference (note that some roads within 10 km of the center are outside the regional boundary)."----
# nrow(r_central)
# nrow(rj)
square = stplanr::geo_bb(shp = city_centre_buffer)
m1 = tm_shape(r_main_region) +
  tm_lines("maxspeed", palette = "-Set1", lwd = "n_lanes_numeric", scale = 5,
           lwd.legend = c(1, 2, 3, 4, 5, 6), title.lwd = "Number of lanes") +
  tm_shape(region) + tm_borders() +
  tm_shape(square) + tm_borders(lty = 3) +
  tm_shape(h_leeds) + tm_dots(size = 0.5) +
  tm_scale_bar() 
# m1
m2 = tm_shape(r_main) +
  tm_lines("maxspeed", palette = "-Set1", lwd = "n_lanes_numeric", scale = 5,
           lwd.legend = c(1, 2, 3, 4, 5, 6), title.lwd = "Number of lanes") +
  tm_shape(city_centre_buffer) + tm_borders(lty = 2) +
  tm_shape(city_centre_buffer_small) + tm_borders(lty = 2) +
  tm_shape(city_centre_buffer_large) + tm_borders(lty = 2) +
  tm_shape(city_key_buffer) + tm_borders() +
  tm_shape(h_leeds) + tm_dots(size = 0.5) +
  tm_scale_bar() +
  tm_layout(legend.show = FALSE)
tmap_arrange(m1, m2, nrow = 1)


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
ma = tmap_arrange(m0, m1, m2, nrow = 1)
ma


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
  mutate(kkm_cycled = round(cycling_potential * group_length / 1000))
# head(r_pct_top$kkm_cycled)

r_pct_lanes_overlap = r_pct_lanes[r_pct_top, , op = sf::st_covered_by] # works
# r_pct_no_overlap = st_difference(r_pct_lanes, r_pct_top) # slow
r_pct_no_overlap = r_pct_lanes %>% 
  filter(!idGlobal %in% r_pct_lanes_overlap$idGlobal)

r_pct_top_n = r_pct_top %>% 
  group_by(name) %>% 
  slice(which.max(kkm_cycled)) %>% 
  filter(name != "") %>% 
  ungroup() %>% 
  top_n(10, wt = kkm_cycled) 
# aim: make the labels go on the longest sections
# %>% 
#   st_cast("LINESTRING") %>% 
#   mutate(length_section = as.numeric(st_length(.))) %>% 
#   group_by(name) %>% 
#   slice(which.max(length_section))
# r_pct_top_n$name
# summary(r_pct_grouped$group_length)


## ----res, fig.cap="Results, showing road segments with a spare lane (light blue) and road groups with a minium threshold length, 1km in this case (dark blue). The top 10 road groups are labelled."----
tmap_mode("view")
tm_shape(r_pct_no_overlap) + tm_lines(col = "lightblue", lwd = 4, alpha = 0.6) +
  tm_shape(r_pct_top) + tm_lines(col = "blue", lwd = 4, alpha = 0.6) +
  tm_shape(r_pct_top_n) + tm_text("name") +
  tm_shape(h_leeds) + tm_dots(size = 0.1)


## --------------------------------------------------------------------------------------------
res_table = r_pct_top_n %>% 
  sf::st_drop_geometry() %>% 
  select(name, length = group_length, cycling_potential, kkm_cycled) %>% 
  arrange(desc(kkm_cycled))
knitr::kable(res_table, caption = "The top 10 candidate roads for space reallocation for pop-up active transport infrastructure according to methods presented in this paper.", digits = 0)


## ---- eval=FALSE-----------------------------------------------------------------------------
## system("")
## # system("iconv -c -f utf-8 -t ascii uh.csv")
## system("iconv -f Latin-1 -t ascii uh.csv -o uh_new.csv")
## system("sd � , uh.csv")
## system("head uh.csv")
## h = readr::read_csv("http://media.nhschoices.nhs.uk/data/foi/Hospital.csv")
## h = read.csv("http://media.nhschoices.nhs.uk/data/foi/Hospital.csv", , fileEncoding="latin1", sep = "¬", colClasses = c(NA, "NULL"))
## h = data.table::fread("http://media.nhschoices.nhs.uk/data/foi/Hospital.csv", encoding = "Latin-1")
## h = data.table::fread("http://media.nhschoices.nhs.uk/data/foi/Hospital.csv", encoding = "UTF-8")
## h$V1 = gsub(pattern = "")

