# Aim: preprocess national roads data for pop-up analysis
# This is an updated and tidier version of code in get-data-db.R

library(tidyverse)

# The data relies on roads.csv, a 2 GB file generated for the CyIPT project
r = data.table::fread("roads.csv")
names(r)
# time-consuming
r_sfc_all = sf::st_as_sfc(r$geotext, crs = 4326)
r_subset_of_data = r %>% select(-geotext)
rsf = sf::st_sf(r_subset_of_data, geometry = r_sfc_all)
