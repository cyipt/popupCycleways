# aim: get srn data
srn_posts = readr::read_csv("https://datamillnorth.org/download/strategic-road-network-marker-posts/58ebbe5f-bfb2-4a01-bf30-64587f7a51c4/Gazetteer_All_Mposts_only.csv")
srn_posts
head(srn_posts$TN)

library(sf)
u = "http://data.dft.gov.uk/road-traffic/major-roads-link-network2018.zip"
download.file(u, "major-roads-link-network2018.zip")
unzip("major-roads-link-network2018.zip")
mrn = sf::read_sf("2018-MRDB-minimal.shp")
plot(mrn)
head(mrn$CP_Number)

srn = sf::read_sf("~/hd/data/uk/srn/HAPMS_network_20160929.shp")
sel_unique = duplicated(srn$geometry)
summary(sel_unique)
plot(srn$geometry) 
head(srn$roa_number)
mapview::mapview(srn)
srn_names_df = srn %>% 
  sf::st_drop_geometry() %>% 
  group_by(roa_number) %>% 
  summarise(
    length_km = sum(sec_length)
  )
readr::write_csv(srn_names_df, "input-data/srn_names_df.csv")
summary(str_detect(string = srn_names_df$roa_number, pattern = "A"))
