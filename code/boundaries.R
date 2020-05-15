library(tidyverse)

counties = ukboundaries::duraz("https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/kml/England_ct_2001_clipped.zip")
counties = sf::read_sf("england_ct_2001_clipped.kml")
mapview::mapview(counties)
# Counties and Unitary Authorities (December 2017) Boundaries UK
uas_uk = sf::read_sf("https://opendata.arcgis.com/datasets/6638c31a8e9842f98a037748f72258ed_3.kml?outSR=%7B%22latestWkid%22%3A27700%2C%22wkid%22%3A27700%7D")
uas_uk = uas_uk %>% select(matches("cty"))
plot(uas_uk)
sf::write_sf(uas_uk, "~/hd/data/uk/uas_uk.gpkg")
uas_uk
head(uas_uk$ctyua17cd)
uas_en = uas_uk %>% filter(str_detect(string = ctyua17cd, pattern = "E"))
nrow(uas_en)
saveRDS(uas_en, "uas_en.Rds")
piggyback::pb_upload("uas_en.Rds")
mapview::mapview(uas_en)


# todo: combine counties with UAs and CAs


