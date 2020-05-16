library(tidyverse)


# local authority districts -----------------------------------------------

# https://geoportal.statistics.gov.uk/datasets/local-authority-districts-december-2019-boundaries-uk-bfe-1
# lads_uk_2020 = sf::read_sf("https://opendata.arcgis.com/datasets/a8531598f29f44e7ad455abb6bf59c60_0.kml?outSR=%7B%22latestWkid%22%3A3857%2C%22wkid%22%3A102100%7D")
# lads_uk_simplified = rmapshaper::ms_simplify(lads_uk_2020, sys = TRUE)
# mapview::mapview(lads_uk_simplified)
# lads = lads_uk_simplified %>% 
#   transmute(Name = lad19nm, Level = "Local Authority District")
# saveRDS(lads, "lads.Rds")

# counties ----------------------------------------------------------------

# counties = ukboundaries::duraz("https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/kml/England_ct_2001_clipped.zip")
# counties_full = sf::read_sf("england_ct_2001_clipped.kml")
# counties = rmapshaper::ms_simplify(counties_full, sys = TRUE)
# counties_full$Name
# length(unique(counties_full$Name))
# counties_full$Name[! counties_full$Name %in% counties$Name]
# mapview::mapview(counties)
# counties = counties %>% transmute(Name = Name, Level = "County")
# saveRDS(counties, "counties.Rds")

# counties and unitary authorities ----------------------------------------

# Counties and Unitary Authorities (December 2017) Boundaries UK
# uas_uk = sf::read_sf("https://opendata.arcgis.com/datasets/6638c31a8e9842f98a037748f72258ed_3.kml?outSR=%7B%22latestWkid%22%3A27700%2C%22wkid%22%3A27700%7D")
# uas_uk = uas_uk %>% select(matches("cty"))
# plot(uas_uk)
# sf::write_sf(uas_uk, "~/hd/data/uk/uas_uk.gpkg")
# uas_uk
# head(uas_uk$ctyua17cd)
# uas_en = uas_uk %>% filter(str_detect(string = ctyua17cd, pattern = "E"))
# uas_en = uas_en %>%
#   transmute(Name = ctyua17nm, Level = "County and Unitary Authority")
# nrow(uas_en) 152
# saveRDS(uas_en, "uas_en.Rds")
# piggyback::pb_upload("uas_en.Rds")

# joining onto region names -----------------------------------------------

lads = readRDS("lads.Rds")
uas_en = readRDS("uas_en.Rds")
counties = readRDS("counties.Rds")

# mapview::mapview(uas_en) + mapview::mapview(counties)

# todo: combine counties with UAs and CAs
regs = read_csv("regs.csv")
names(regs) = "Name"
regs_clean = regs %>% 
  mutate(Level_dft = case_when(
    str_detect(Name, "UA") ~ "unitary_authority",
    str_detect(Name, "CA|ITA|tfl") ~ "combined_authority",
    TRUE ~ "other"
    )) %>% 
  mutate(Name = gsub(pattern = " UA| UA2| CA| ITA| Region| City", replacement = " ", Name)) %>% 
  mutate(Name = gsub(pattern = "Kingston upon Hull,  of", replacement = "Kingston upon Hull, City of", Name)) %>% 
  mutate(Name = gsub(pattern = " and Peterborough", replacement = "", Name)) %>% 
  mutate(Name = gsub(pattern = "Bournemouth, Christchurch snd Poole", replacement = "Bournemouth, Christchurch and Poole", Name)) %>% 
  mutate(Name = gsub(pattern = "tfl", replacement = "Greater London", Name)) %>% 
  mutate(Name = str_trim(Name)) %>% 
  filter(!str_detect(string = Name, pattern = "1|2|Local"))

summary(l_in_regs <- regs_clean$Name %in% lads$Name) # 46 las in there
summary(c_in_regs <- regs_clean$Name %in% counties$Name) # 33 counties in there
summary(u_in_regs <- regs_clean$Name %in% uas_en$Name) # 71 uas in there

either_in_regs = c_in_regs | u_in_regs
summary(either_in_regs)
unmatched_names = regs_clean$Name[!either_in_regs]
unmatched_names

# west of england: Bath & North East Somerset, Bristol and South Gloucestershire
# Source: https://www.westofengland-ca.gov.uk/
west_of_england = uas_en %>% 
  filter(str_detect(Name, "Bath|Bristol|South Glouc")) %>% 
  # stplanr::geo_buffer(., dist = 20) %>% 
  sf::st_union()
mapview::mapview(west_of_england)

# Tees Valley: around Middlesbrough
# Darlington, Hartlepool, Middlesbrough, Redcar & Cleveland and Stockton-on-Tees
# Source: https://teesvalley-ca.gov.uk/about/
tees_valley = uas_en %>% 
  filter(str_detect(Name, "Darlington|Hartlepool|Middlesbrough|Redca|Stockton")) %>% 
  # stplanr::geo_buffer(., dist = 20) %>% 
  sf::st_union()
mapview::mapview(tees_valley)
# North East: County Durham, Gateshead, South Tyneside and Sunderland.
north_east = uas_en %>% 
  filter(str_detect(Name, "Durham|Gateshead|South Tyneside|Sunderland")) %>% 
  sf::st_union()
mapview::mapview(north_east)

new_cas = sf::st_as_sf(
  data.frame(
    stringsAsFactors = FALSE,
    Name = c("West of England", "Tees Valley", "North East"),
    geometry = c(west_of_england, tees_valley, north_east)
    )
)
mapview::mapview(new_cas) + mapview::mapview(counties)

counties_all = counties %>% 
  filter(Name != "Durham") %>% # part of North East
  select(Name) %>% 
  rbind(., new_cas)
mapview::mapview(counties_all)

# observation: no CA matching Newcastle:
# North of Tyne describes the area covered by Newcastle, North Tyneside and Northumberland local authorities
# source: https://www.northoftyne-ca.gov.uk/our-mission

north_of_tyne = uas_en %>% 
  filter(str_detect(Name, "Newcastle|North Tyneside|Northumberland")) %>% 
  sf::st_union()

new_cas = sf::st_as_sf(
  data.frame(
    stringsAsFactors = FALSE,
    Name = c("West of England", "Tees Valley", "North East", "North of Tyne"),
    Level = "Combined Authority",
    geometry = c(west_of_england, tees_valley, north_east, north_of_tyne)
  )
)

counties_and_cas = counties %>% 
  filter(Name != "Durham") %>% # part of North East
  filter(Name != "Northumberland") %>% # part of North East
  filter(Name != "Tyne and Wear") %>% # part of North East
  rbind(., new_cas)
mapview::mapview(counties_and_cas)

uas_en_centroids = sf::st_centroid(uas_en)
uas_en_centroids_in_cas = uas_en_centroids[counties_and_cas, ]
uas_outside_cas = uas_en %>% filter(! Name %in% uas_en_centroids_in_cas$Name)
uas_outside_cas2 = uas_outside_cas %>% 
  filter(!Name %in% counties_and_cas$Name) %>% 
  select(Name = Name, Level)
mapview::mapview(uas_outside_cas2) + mapview::mapview(counties_and_cas)

# observation: no CA matching BCP authority:
# From April, the councils currently serving Bournemouth, Christchurch and Poole will be replaced by one new council, responsible for all local government
# source: https://www.bcpcouncil.gov.uk/About-BCP-Council/About-BCP-Council.aspx
bcp = lads %>% filter(str_detect(string = Name, pattern = "Bourn"))
mapview::mapview(bcp) + mapview::mapview(counties) # overlaps with Dorset
bcp_buffer = bcp %>% stplanr::geo_buffer(., dist = 50)
dorset_new = sf::st_difference(counties %>% filter(Name == "Dorset"), bcp_buffer)
mapview::mapview(dorset_new)
uas_outside_cas3 = uas_outside_cas2 %>% filter(!str_detect(string = Name, pattern = "Bourn|Poole"))
# manually update dorset county geometry:
counties_and_cas$geometry[counties_and_cas$Name == "Dorset"] = dorset_new$geometry

cas_and_uas = rbind(counties_and_cas, uas_outside_cas3, bcp)
mapview::mapview(cas_and_uas)
nrow(cas_and_uas) # 82 combined authorities and authorities

# names missing from hardcoded regions
summary(a_in_regs <- regs_clean$Name %in% cas_and_uas$Name)
unmatched_names = regs_clean$Name[!a_in_regs]
summary(unmatched_names %in% lads$Name) # All of them are local authorities


cas_uas = left_join(cas_and_uas, regs_clean, by = "Name")
cas_uas
