# Aim: coordinate regional builds

library(tidyverse)
regions = readRDS("regions.Rds")
mapview::mapview(regions)

sample_to_build_regex = "west|hereford|nott|leic|manc|mers"
region_names_to_build = regions %>% 
  filter(grepl(pattern = sample_to_build_regex, x = Name, ignore.case = TRUE)) %>% 
  pull(Name)

dir.create("popupCycleways/v0.1")
# region_names_to_build = c("West Yorkshire", "Nottingham")

rn = "Greater Manchester"
for(rn in region_names_to_build) {
  t = Sys.time()
  message("Building for ", rn)
  d = file.path("popupCycleways/v0.1", tolower(rn))
  dir.create(d)
  region_name = rn
  # source("code/build.R")
  rmarkdown::render(input = "code/build.R", output_dir = d, knit_root_dir = ".")
  htmlwidgets::saveWidget(m_leaflet, file.path("~/cyipt/tempCycleways/", d, "m.html"))
  time_to_run = Sys.time() - t
  message(round(time_to_run), " seconds to build ", rn)
}
