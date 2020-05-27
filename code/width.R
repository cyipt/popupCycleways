# Aim: check road withds
library(tidyverse)

devtools::install_github("itsleeds/mastermapr")
# 138,000 records:
# mm_highway = mastermapr::read_mastermap("~/hd/data/os/Download_mastermap-roads-2019_1483661/MasterMap Highways Network_rami_3480319/", n = 3)
# mm_highway = readRDS("~/hd/data/os/Download_mastermap-roads-2019_1483661.Rds")
# April 2020 data:
mm_highway = mastermapr::read_mastermap("~/hd/data/os/MasterMap Highways Network_rami_3549735/", n = 100000)
nrow(mm_highway) # 5151413
saveRDS(mm_highway, "~/hd/data/os/Download_mastermap-roads-2020-04.Rds")
system("ls -hal ~/hd/data/os/Download_mastermap-roads-2020-04.Rds")

names(mm_highway)
table(mm_highway$cycleFacility)
table(mm_highway$formOfWay)

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
