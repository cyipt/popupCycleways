# Aim: check road withds
library(tidyverse)

# devtools::install_github("itsleeds/mastermapr")
# 138,000 records:
# mm_highway = mastermapr::read_mastermap("~/hd/data/os/Download_mastermap-roads-2019_1483661/MasterMap Highways Network_rami_3480319/", n = 3)
# mm_highway = readRDS("~/hd/data/os/Download_mastermap-roads-2019_1483661.Rds")
# April 2020 data:
# mm_highway = mastermapr::read_mastermap("~/hd/data/os/MasterMap Highways Network_rami_3549735/", n = 100000)
# nrow(mm_highway) # 5151413
# saveRDS(mm_highway, "~/hd/data/os/Download_mastermap-roads-2020-04.Rds")
# system("ls -hal ~/hd/data/os/Download_mastermap-roads-2020-04.Rds")
system.time({
  mm_highway = readRDS("~/hd/data/os/Download_mastermap-roads-2020-04.Rds")
})
# mm_highway_wgs = sf::st_transform(mm_highway, 4326)
# saveRDS(mm_highway_wgs, "~/hd/data/os/Download_mastermap-roads-2020-04-wgs.Rds")


names(mm_highway)
table(mm_highway$cycleFacility)
# Unknown Type Of Cycle Route Along Road
# 695
table(mm_highway$formOfWay)
# Dual Carriageway           Enclosed Traffic Area                   Guided Busway                           Layby
# 119094                           50522                             195                            4062
# Roundabout          Shared Use Carriageway              Single Carriageway                       Slip Road
# 132630                            3507                         4544037                           25493
# Track             Traffic Island Link Traffic Island Link At Junction
# 46465                           58965                          166443

# Compare with local dataset:
chapel_allerton = tmaptools::geocode_OSM("chapel allerton", as.sf = TRUE, projection = 27700)
sf::st_crs(chapel_allerton) = 27700
chapel_allerton_1km = sf::st_buffer(chapel_allerton, dist = 1000)
mapview::mapview(chapel_allerton_1km)
system.time({
  mm_highway_chapel_allerton = mm_highway[chapel_allerton_1km, ]
})
# user  system elapsed
# 30.936   0.027  30.974
mapview::mapview(mm_highway_chapel_allerton)

# Compare with CyIPT widths (assumes build.R has run for West Yorkshire)
summary(rj_all$length)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
# 0.00   19.89   45.84  101.59   99.76 9450.85
summary(mm_highway$length)
# Min.  1st Qu.   Median     Mean  3rd Qu.     Max.
# 1.01    26.51    54.36   118.86   113.61 18108.55
key_network_buffer = stplanr::geo_buffer(key_network, dist = 10) %>% 
  st_transform(27700)
key_network_buffer_union = sf::st_union(key_network_buffer)
system.time({
  mm_key_network = mm_highway[key_network_buffer_union, ]
})
mm_key_network = mm_key_network[key_network_buffer, , op = sf::st_within]
# user  system elapsed ~ 5 minutes 
# 649.936  54.190 292.033 
nrow(mm_key_network)
# 6742
nrow(key_network)
# 7142 # double the number in the OS data
mapview::mapview(key_network_buffer, zcol = "width") +
  mapview::mapview(mm_key_network, zcol = "averageWidth")

key_network_agg = aggregate(mm_key_network["averageWidth"], key_network_buffer, FUN = mean)
summary(key_network_agg)

mm_key_network_filtered = mm_key_network %>% 
  filter(length > 30, ! stringr::str_detect(formOfWay, "land"))

key_network_agg = aggregate(mm_key_network_filtered["averageWidth"], key_network_buffer, FUN = mean)
cor(key_network_agg$averageWidth, key_network$width, use = "complete.obs")
key_network_buffer_in_filter = key_network_buffer[mm_key_network_filtered, ]
summary(key_network_buffer_in_filter$width)
summary(mm_key_network_filtered$averageWidth)

mapview::mapview(mm_key_network_filtered)
# Tests and out-takes -----------------------------------------------------


# # find dfs with differing column numbers
# mm_ncols = sapply(mm_highway, ncol)
# summary(mm_ncols)
# # Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# # 33.00   38.00   38.00   37.64   38.00   38.00 
# 
# # test rbinding them:
# mm_test_rbind = data.table::rbindlist(mm_highway[1:8], fill = TRUE)
# class(mm_test_rbind)
# mm_test_rbind_sf = sf::st_as_sf(mm_test_rbind)
# 
# names(mm_highway)
# nrow(mm_highway) # 5.1 m
# summary(mm_highway$averageWidth)
# sum(is.na(mm_highway$averageWidth)) / nrow(mm_highway) # 42% NA values
# lds_27700 = sf::st_transform(ukboundaries::leeds, 27700)
# mm_leeds = mm_highway[lds_27700, ]
# mm_leeds_wide = mm_leeds %>% filter(averageWidth > 10)
# mapview::mapview(mm_leeds_wide, zcol = "averageWidth") # shows with
# 
# # issue with differing column names...
# problem_names = names(mm_highway[[8]])
# usual_names = names(mm_highway[[7]])
# diffobj::diffObj(problem_names, usual_names)
# # missing columns in some items:
# # [32] "cycleFacility"                                    
# # [33] "wholeLink" 
# new_data = tibble::tibble(
#   cycleFacility = rep(NA, nrow(mm_highway[[8]])),
#   wholeLink = rep(NA, nrow(mm_highway[[8]]))
# )
# updated_problem_df = tibble::add_column(mm_highway[[8]], .data = new_data, .after = 31)
# nrow(updated_problem_df)
# updated_problem_df = sf::st_as_sf(updated_problem_df)
# test_updated_data = rbind(mm_highway[[7]], updated_problem_df)
# plot(test_updated_data$geometry)
