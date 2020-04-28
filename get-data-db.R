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

regions_of_interest = 
u = "https://github.com/npct/pct-shiny/raw/master/regions_www/www/la-map-resources/la.js"
ul = readLines(url(u))
ul[1]
ul[1] = "{"
writeLines(ul, "/tmp/ul.json")
pct_la_summaries = jsonlite::read_json("/tmp/ul.json")
str(pct_la_summaries)
pct_la_summaries = sf::read_sf("/tmp/ul.json")
head(pct_la_summaries)

summary()

regions = unique(f$region)
dput(regions)
