# Aim: coordinate regional builds

library(tidyverse)
regions = readRDS("regions.Rds")
mapview::mapview(regions)

sample_to_build_regex = "west|hereford|nott|leic|manc|mers"
region_names_to_build = regions %>% 
  filter(grepl(pattern = sample_to_build_regex, x = Name, ignore.case = TRUE)) %>% 
  pull(Name)

dir.create("popupCycleways/v1")
region_names_to_build = c("West Yorkshire", "Nottingham")

i = "Greater Manchester"
for(i in region_names_to_build) {
  d = file.path("popupCycleways/v1", tolower(i))
  dir.create(d)
  region_name = i
  # source("code/build.R")
  rmarkdown::render(input = "code/build.R", output_dir = d, knit_root_dir = ".")
  tmap_save(m, filename = file.path(d, "m.html"))
}
