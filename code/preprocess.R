# Aim: preprocess national roads data for pop-up analysis
# This is an updated and tidier version of code in get-data-db.R

library(tidyverse)

# The data relies on roads.csv, a 2 GB file generated for the CyIPT project
r = data.table::fread("roads.csv")
rtid = readr::read_csv("rtid.csv")

# Create geometries
r_sfc_all = sf::st_as_sfc(r$geotext, crs = 4326)
r_subset_of_data = r %>% select(-geotext)
rsf = sf::st_sf(r_subset_of_data, geometry = r_sfc_all)
names(rsf)
r_original = rsf %>%
  select(name, ref, highway, maxspeed, pctgov, pctdutch, pctebike, width, Existing, length, aadt, idGlobal, rtid) 

## ----preprocess------------------------------------------------------------------------------
r_original$highway_type = r_original$highway
r_original$highway_type = gsub(pattern = "_link", replacement = "", r_original$highway)
highway_table = table(r_original$highway_type)
highway_rare = highway_table[highway_table < nrow(r_original) / 100]
highway_rare
# bus_guideway living_street      motorway    pedestrian          road         steps 
# 137          7792         14062         17898          3379         41168
highway_remove = names(highway_rare)[!grepl(pattern = "motor|living|pedestrian|bus", x = names(highway_rare))]
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
  mutate(cycling_potential = as.numeric(pctebike)) 
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

saveRDS(cy, "cy.Rds")
saveRDS(rj, "rj.Rds") # 300 MB file
rj_sample = rj %>% sample_n(1000)
mapview::mapview(rj_sample) # national coverage
system("ls -hal *.Rds")
piggyback::pb_upload("rj.Rds", "cyipt/cyipt-phase-1-data")
