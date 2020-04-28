# Aim: get, filter and re-upload data for regions

library(sf)
library(dplyr)

# get large datasets ------------------------------------------------------

old = setwd("~/cyipt/cyipt-server-data/malcolm/")
zip("roads.zip", "roads.csv")
piggyback::pb_upload("roads.zip", "cyipt/cyipt-phase-1-data")
f = list.files(pattern = "csv")
f = f[-5]
z = gsub(pattern = ".csv", replacement = ".zip", f)
for(i in seq_along(f)) {
  zip(z[i], f[i])
  piggyback::pb_upload(z[i], "cyipt/cyipt-phase-1-data")
}
setwd(old)

# test read-in as geographic object ---------------------------------------

r = data.table::fread("roads.csv")
names(r)
r1 = r[1, ]
r1$geotext
r1_sf = sf::st_as_sfc(r1$geotext, crs = 4326)
# time-consuming
# r_sfc_all = sf::st_as_sfc(r$geotext, crs = 4326)

# subset for regions of interest ------------------------------------------

regions = unique(r$region)
regions_cyipt_df = data.frame(regions)
View(regions_cyipt_df)
regions_of_interest = c(
  "Leeds", "Liverpool", "London", "Bristol",
  "Birmingham", "Manchester", "Newcastle"
  )
u = "https://github.com/npct/pct-shiny/raw/master/regions_www/www/la-map-resources/la.js"
ul = readLines(url(u))
ul[1]
ul[1] = "{"
writeLines(ul, "/tmp/ul.json")
pct_la_summaries = jsonlite::read_json("/tmp/ul.json")
str(pct_la_summaries)
pct_la_summaries = sf::read_sf("/tmp/ul.json")
head(pct_la_summaries)

summary((s = regions_of_interest %in% pct_la_summaries$name))
regions_of_interest[!s]
summary((s2 = regions_of_interest %in% pct_la_summaries$name))
pct_la_summaries$name[grepl(pattern = "Bristol", pct_la_summaries$name)] = "Bristol"
pct_la_summaries$name[grepl(pattern = "Newcastle u", pct_la_summaries$name)] = "Newcastle"
pct_la_summaries$name[grepl(pattern = "Hull", pct_la_summaries$name)] = "Hull"
summary((s2 = regions_of_interest %in% pct_la_summaries$name))
summary(s2) # 6 out of 8

lnd = spData::lnd

summary(pct_la_summaries$name %in% lnd$NAME)
summary(lnd$NAME %in% pct_la_summaries$name)
lnd$NAME[!lnd$NAME %in% pct_la_summaries$name]
pct_centroids = sf::st_centroid(pct_la_summaries)
pct_london_points = pct_centroids[lnd, ]
pct_london = pct_la_summaries %>% 
  filter(name %in% pct_london_points$name)
plot(pct_london)
pct_london_aggregated = pct_london %>% 
  summarise_if(is.numeric, sum) %>% 
  add_column(name = "London", .before = 1) %>% 
  add_column(CODE = "1", .before = 1)
setdiff(names(pct_london_aggregated), names(las_top))
mapview::mapview(pct_london_aggregated)  

pct_la_summaries %>% 
  filter(!grepl(pattern = "Wand|West|Southw|Lamb|Hack|Towe|Eal|Houns|Wilt|Cheshire E|Sef|Isl|Riding", name)) %>% 
  select(name, all, bicycle, dutch_slc) %>% 
  arrange(desc(dutch_slc)) %>%
  head(15) 

las_top = pct_la_summaries %>% 
  filter(!grepl(pattern = "Wand|West|Southw|Lamb|Hack|Towe|Eal|Houns|Wilt|Cheshire E|Sef|Isl|Riding", name)) %>% 
  arrange(desc(dutch_slc)) %>%
  head(8) 

las_other = pct_la_summaries %>% 
  filter(name == "Newcastle" | name == "Gateshead") %>% 
  summarise_if(is.numeric, sum) %>% 
  add_column(name = "Newcastle", .before = 1) %>% 
  add_column(CODE = "10", .before = 1)

las_other$dutch_slc

names(pct_london_aggregated)
names(las_top)
las_top = rbind(pct_london_aggregated, las_top, las_other) %>% 
  arrange(desc(dutch_slc))

las_top %>% 
  select(name, all, bicycle, dutch_slc) %>% 
  sf::st_drop_geometry() %>%
  knitr::kable()

pct_la_summaries %>% 
  select(name, all, bicycle, dutch_slc) %>% 
  sf::st_drop_geometry() %>%
  filter(name == "Cambridge") %>% 
  knitr::kable()

sum(las_top$all) / sum(pct_la_summaries$all) # 9%
mapview::mapview(las_top)

regions_of_interest[!regions_of_interest %in% regions] # just Cardiff not in there
regions2 = c(regions_of_interest, las_top$name[!las_top$name %in% regions_of_interest])
length(regions2)
regions[!regions %in% regions2]
regions2
regions2[!regions2 %in% regions]
regions2[!regions2 %in% las_top$name]

r_regions = r %>% 
  filter(region %in% regions2)

nrow(r_regions) / nrow(r)
r_regions_sfc = sf::st_as_sfc(r_regions$geotext, crs = 4326)
names(r_regions)
r_subset_of_data = r_regions %>% 
  select(-geotext)
rsf = sf::st_sf(r_subset_of_data, geometry = r_regions_sfc)
write_rds(rsf, "rsf.Rds")
piggyback::pb_upload("rsf.Rds", "cyipt/cyipt-phase-1-data")
write_rds(las_top, "las_top.Rds")
piggyback::pb_upload("las_top.Rds")

# old analysis code -------------------------------------------------------

# library(tidyverse)
# library(sf)
# library(tmap)
# tmap_mode("view")
# 
# # input data --------------------------------------------------------------
# 
# up = "https://github.com/cyipt/cyipt-bigdata/raw/master/osm-prep/Leeds/osm-lines.Rds"
# up = "https://github.com/cyipt/cyipt-bigdata/raw/master/osm-prep/Cambridge/osm-lines.Rds"
# up = "https://github.com/cyipt/cyipt-bigdata/raw/master/osm-prep/Cambridge/osm-lines.Rds"
# up = "https://github.com/cyipt/cyipt-bigdata/raw/master/osm-recc/Hereford/osm-lines.Rds"
# 
# roads = readRDS(url(up))
# names(roads)
# summary(roads$width)
# wide_potential1 = roads %>% filter(width > 10, pct.dutch > 100)
# mapview::mapview(wide_potential1)
# wide_potential2 = roads %>% filter(
#   lanes.forward > 1 |
#     lanes.backward > 1,
#   pct.dutch > 50)
# mapview::mapview(wide_potential2)
# wide_potential3 = roads %>% filter(lanes.forward + lanes.backward > 2, pct.dutch > 100)
# mapview::mapview(wide_potential3)
# 
# # relationship between cycling and 2 way ----------------------------------
# cor(roads$lanes.forward, roads$pct.census) # there is a small correlation
# cor(roads$lanes.forward, roads$pct.dutch) # larger for go dutch scenario
# cor(roads$width, roads$pct.census, use = "complete.obs") # also a positive correlation
# plot(roads$width, roads$lanes.forward + roads$lanes.backward)




# out-takes ---------------------------------------------------------------

# u = "https://github.com/cyipt/cyipt-bigdata/raw/master/osm-clean/Leeds/osm-lines.Rds"
# osm_lines = readRDS(url(u))
# names(osm_lines)
# plot(osm_lines) # long time to plot...
# 
# uz = "https://github.com/cyipt/cyipt-bigdata/raw/master/forDB/roads.zip"
# d = file.path(tempdir(), "roads.zip")
# download.file(uz, d)
# r = readr::read_csv(d)
# head(r$elevation)

