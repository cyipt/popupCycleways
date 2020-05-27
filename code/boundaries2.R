# Aim: generate boundaries based on LA/CA data, building on boundaries.R
library(tidyverse)

la_ca_list = readxl::read_excel("~/onedrive/projects-all/covid-19/tempcycle/Book3.xlsx", skip = 1)
names(la_ca_list) = c("ca_name_original", "lad_name_original")
lads = readRDS("lads.Rds")
uas_en = readRDS("uas_en.Rds")
regions = readRDS("regions.Rds")

summary(la_ca_list$ca_name_original %in% regions$Name) # no matches
summary(la_ca_list$lad_name_original %in% regions$Name) # 27 matches

la_ca = la_ca_list %>% 
  mutate(
    Name = str_replace_all(string = ca_name_original, pattern = " CA| ITA", ""),
    Name_la = str_replace_all(string = lad_name_original, pattern = " UA", ""),
    Name_la = str_replace_all(string = Name_la, pattern = "Bournemouth, Christchurch snd Poole", "Bournemouth, Christchurch and Poole"),
    Level = case_when(
      str_detect(lad_name_original, pattern = "UA") ~ "UA",
      TRUE ~ "County"
    ),
    Part_of_combined_authority = !is.na(ca_name_original)
  )

# hardcode fix for westminster
la_ca$Name_la[la_ca$Name_la == "Westminster (& City of London)"] = "Westminster"

summary(la_ca$Name_la %in% regions$Name) # 68 matches
summary(la_ca$Name_la %in% lads$Name) # 122 matches, 28 not matching...
summary(la_ca$Name_la %in% uas_en$Name) # 148 matches, 2 not matching
uas_en$Name[!uas_en$Name %in% la_ca$Name_la]
# [1] "Bournemouth"    "Poole"          "City of London" "Westminster"   
la_ca$Name_la[!la_ca$Name_la %in% uas_en$Name]
# [1] "Bournemouth, Christchurch snd Poole" "Westminster (& City of London)"     
uas_en %>% filter(str_detect(string = Name, pattern = "Bourn|Westmin")) %>% pull(Name)
# [1] "Bournemouth" "Westminster"
uas_en %>% filter(str_detect(string = Name, pattern = "Bourn|Westmin"))

# Make the missing uas_en match
bcp = lads %>% filter(str_detect(string = Name, pattern = "Bourn"))
uas_en_without_bournmouth = uas_en %>% filter(!str_detect(string = Name, "Bourn|Pool"))
uas_updated = rbind(uas_en_without_bournmouth, bcp)

westminster = lads %>% filter(str_detect(string = Name, pattern = "Westmin|City of L")) %>% 
  st_union() %>% 
  sf::st_as_sf(
    sf::st_drop_geometry(lads %>% filter(str_detect(Name, "Westminster"))),
    geometry = .
  )
uas_en_without_westminster = uas_updated %>% filter(!str_detect(string = Name, "Westmin|City of London"))
uas_updated = rbind(uas_en_without_westminster, westminster)
nrow(uas_updated) == nrow(la_ca)
la_ca$Name_la[!la_ca$Name_la %in% uas_updated$Name]

# update dorset la definition
dorset_updated_geometry = sf::st_difference(
  uas_updated$geometry[uas_updated$Name_la == "Dorset"],
  uas_updated$geometry[uas_updated$Name_la == "Bournemouth, Christchurch and Poole"] 
)
dorset_updated_geometry_polygons = sf::st_cast(dorset_updated_geometry, "POLYGON")
polygon_sizes = sf::st_area(dorset_updated_geometry_polygons)
dorset_updated_geometry = dorset_updated_geometry_polygons[which.max(polygon_sizes)]
mapview::mapview(dorset_updated_geometry)
uas_updated$geometry[uas_updated$Name_la == "Dorset"] = dorset_updated_geometry

# uas_updated$Name[! uas_updated$Name %in% la_ca$Name_la]
uas_updated = uas_updated %>% select(Name_la = Name)
la_ca_sf = left_join(uas_updated, la_ca)
mapview::mapview(la_ca_sf)
saveRDS(la_ca_sf, "la_ca_sf.Rds")
cas_all = la_ca_sf %>% filter(Part_of_combined_authority)
cas = cas_all %>% 
  group_by(Name) %>% 
  summarise(
    n = n(),
    LA_names = paste(Name_la, collapse = ",")
  ) %>% 
  mutate(Level = "Combined authority")
mapview::mapview(cas)
regions_dft = rbind(
  cas,
  la_ca_sf %>% 
    filter(!Part_of_combined_authority) %>% 
    transmute(
      Name = Name_la,
      n = 1,
      LA_names = "",
      Level = Level
      )
)
mapview::mapview(regions_dft, zcol = "Level")

regions_dft %>% filter(Level == "County") %>% pull(Name)

tm_shape(regions) + tm_polygons("Level") + tm_shape(regions_centroids) + tm_text("Name", size = 0.7)
regions_dft_centroids = sf::st_point_on_surface(regions_dft)
tm_shape(regions_dft) + tm_polygons("Level") + tm_shape(regions_dft_centroids) + tm_text("Name", size = 0.7)

