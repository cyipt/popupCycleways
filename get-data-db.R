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

las_top = pct_la_summaries %>% 
  filter(!grepl(pattern = "Wand|West|Southw|Lamb|Hack|Towe|Eal|Houns|Wilt|Cheshire E|Sef|Isl|Riding", name)) %>% 
  arrange(desc(dutch_slc)) %>%
  head(8) 

las_other = pct_la_summaries %>% 
  filter(name == "Newcastle")

names(pct_london_aggregated)
names(las_top)
las_top = rbind(pct_london_aggregated, las_top, las_other)

las_top %>% 
  select(name, all, bicycle, dutch_slc) %>% 
  sf::st_drop_geometry() %>%
  knitr::kable()


sum(las_top$all) / sum(pct_la_summaries$all) # 9%
mapview::mapview(las_top)

regions_of_interest[!regions_of_interest %in% regions] # just Cardiff not in there
regions_of_interest2 = 
regions2 = c(regions_of_interest, las_top$name[!las_top$name %in% regions_of_interest])
length(regions2)
regions[!regions %in% regions2]
regions2
regions2[!regions2 %in% regions]
