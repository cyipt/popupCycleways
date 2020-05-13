hospitals = read_excel("./input-data/HSCA_Active_Locations_May_2020.xlsx", sheet = "HSCA Active Locations")

unique(hospitals$`Provider Primary Inspection Category`)

acute_hospitals = hospitals %>%
  filter(grepl(x = `Location Primary Inspection Category`, pattern = 'Acute'),
         grepl(x = `Location Primary Inspection Category`, pattern = 'NHS')
         ) %>%
  select(c(1,2,4,10:12, 16:19, 28, 29)) 

colnames(acute_hospitals) = str_replace_all(colnames(acute_hospitals)," ", "_")
colnames(acute_hospitals) = str_replace_all(colnames(acute_hospitals),"/", "_")

View(acute_hospitals)

library(sf)
acute_hospitals_sf = st_as_sf(acute_hospitals, coords = c(x =  "Location_Longitude", y = "Location_Latitude"), crs = 4326)

plot(acute_hospitals_sf$geometry)

write_rds(acute_hospitals_sf,"acute_hospitals.Rds")
         