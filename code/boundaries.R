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
regs$`Original names` = regs$Name
regs_clean = regs %>% 
  mutate(Level_dft = case_when(
    str_detect(Name, "UA") ~ "unitary_authority",
    str_detect(Name, "CA|ITA|tfl") ~ "combined_authority",
    TRUE ~ "other"
    )) %>% 
  mutate(Name = gsub(pattern = " UA| UA2| CA| ITA| Region| City", replacement = " ", Name)) %>% 
  mutate(Name = gsub(pattern = "Kingston upon Hull,  of", replacement = "Kingston upon Hull, City of", Name)) %>% 
  mutate(Name = gsub(pattern = "Liverpool", replacement = "Merseyside", Name)) %>% 
  mutate(Name = gsub(pattern = "Sheffield", replacement = "Sheffield City", Name)) %>% 
  mutate(Name = gsub(pattern = "Cornwall", replacement = "Cornwall and Isles of Scilly", Name)) %>% 
  mutate(Name = gsub(pattern = " and Peterborough", replacement = "", Name)) %>% 
  mutate(Name = gsub(pattern = "Bournemouth, Christchurch snd Poole", replacement = "Bournemouth, Christchurch and Poole", Name)) %>% 
  mutate(Name = gsub(pattern = "tfl", replacement = "Greater London", Name)) %>% 
  mutate(Name = str_trim(Name)) %>% 
  filter(!str_detect(string = Name, pattern = "1|2|Local"))

regs_clean

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
unmatched_names
# [1] "Sheffield"                 "Bedford"                   "Cheshire East"            
# [4] "Cheshire West and Chester" "Central Bedfordshire"
summary(unmatched_names %in% lads$Name) # All of them are local authorities
lads_missing = lads %>% filter(Name %in% unmatched_names)

# names missing from combined geographic levels
summary(r_in_c <- cas_and_uas$Name %in% regs_clean$Name) # 9 missing
unmatched_regions = cas_and_uas$Name[!r_in_c]
unmatched_regions
# [1] "South Yorkshire" "Bedfordshire"    "Cheshire"        "North of Tyne"   "Halton"         
# [6] "Peterborough"  

cas_uas = left_join(cas_and_uas, regs_clean, by = "Name")
cas_uas$included = !is.na(cas_uas$Level_dft)
mapview::mapview(cas_uas[c("included", "Name")], zcol = "included") +
  mapview::mapview(lads_missing)

regions = cas_uas
regions # note missing names
regions$Name[is.na(regions$`Original names`)]


# Suggested solutions, to check:
# Replace geographic region Bedfordshire with d regions of Bedford and west Central Bedfordshire
# Replace geographic region Cheshire with d regions of Chesire East and west Cheshire
# Modify geographic region Cambridgeshire to inclue Peterborough
# Add North of Tyne to d regs

# Update geometry of North East to include Newcastle
north_east_updated = sf::st_union(
  north_of_tyne,
  regions$geometry[regions$Name == "North East"]
)
mapview::mapview(north_east_updated)
regions$geometry[regions$Name == "North East"] = north_east_updated
regions = regions %>% filter(Name != "North of Tyne")

# Split Bedfordshire in two
regions$Name[str_detect(string = regions$Name, pattern = "Bedford")] # only 1 region
bedford_uas = lads_missing %>% filter(str_detect(string = Name, pattern = "Bedford"))
mapview::mapview(bedford_uas)
names(regions)
names(bedford_uas)
bedford_uas_joined = inner_join(bedford_uas, regs_clean)
names(bedford_uas_joined)
bedford_uas_joined$included = TRUE
regions = regions %>% filter(!str_detect(string = regions$Name, pattern = "Bedford"))
regions = rbind(regions, bedford_uas_joined)

# Split Cheshire in two
regions$Name[str_detect(string = regions$Name, pattern = "Cheshire")] # only 1 region
cheshire_uas = lads_missing %>% filter(str_detect(string = Name, pattern = "Cheshire"))
mapview::mapview(cheshire_uas)
names(regions)
names(cheshire_uas)
cheshire_uas_joined = inner_join(cheshire_uas, regs_clean)
names(cheshire_uas_joined)
cheshire_uas_joined$included = TRUE
regions = regions %>% filter(!str_detect(string = regions$Name, pattern = "Cheshire"))
regions = rbind(regions, cheshire_uas_joined)

# Include Peterborough in Cambridgeshire
regions$Name[str_detect(string = regions$Name, pattern = "Cambridgeshire")] # only 1 region
peterborough_uas = lads %>% filter(str_detect(string = Name, pattern = "Peterborough"))
mapview::mapview(peterborough_uas) + mapview::mapview(regions)
cambridgeshire_updated = sf::st_union(
  peterborough_uas,
  # %>% sf::st_transform(27700) %>% sf::st_buffer(500) %>% sf::st_transform(4326),
  # fix gap:
  regions %>% filter(Name == "Cambridgeshire") %>% sf::st_transform(27700) %>% sf::st_buffer(50) %>% sf::st_transform(4326)
)
mapview::mapview(cambridgeshire_updated)
regions$geometry[str_detect(string = regions$Name, pattern = "Cambridgeshire")] = cambridgeshire_updated$geometry
regions = regions %>% filter(!str_detect(string = Name, pattern = "Peter"))

# Include Halton in Liverpool city region
regions$Name[str_detect(string = regions$Name, pattern = "Merseyside")] # only 1 region
halton_uas = lads %>% filter(str_detect(string = Name, pattern = "Halton"))
mapview::mapview(halton_uas) + mapview::mapview(regions)
merseyside_updated = sf::st_union(
  halton_uas,
  regions %>% filter(Name == "Merseyside") %>% sf::st_transform(27700) %>% sf::st_buffer(50) %>% sf::st_transform(4326)
)
mapview::mapview(merseyside_updated)
regions$geometry[str_detect(string = regions$Name, pattern = "Merseyside")] = merseyside_updated$geometry
regions = regions %>% filter(!str_detect(string = Name, pattern = "Halton"))

mapview::mapview(regions, zcol = "included")
regions$Name[! regions$Name %in% regs_clean$Name]
regions$Name[duplicated(regions$Name)] 
# [1] "Cornwall and Isles of Scilly" "Devon"                       
cornwall_and_devon = regions %>% filter(str_detect(string = Name, pattern = "Corn|Dev"))
mapview::mapview(cornwall_and_devon[1, ]) # isle of Scilly
mapview::mapview(cornwall <- cornwall_and_devon[2, ]) 
mapview::mapview(cornwall_and_devon[3, ]) # Another island
mapview::mapview(devon <- cornwall_and_devon[4, ]) 
no_cornwall_and_devon = regions %>% filter(!str_detect(string = Name, pattern = "Corn|Dev"))
regions = rbind(no_cornwall_and_devon, cornwall, devon)

# Update names (WIP)

nrow(regions) == nrow(regs_clean)
summary(regions$Name %in% regs_clean$Name)
regions = regions[order(match(regions$Name, regs_clean$Name)), ]
regions_centroids = sf::st_centroid(regions)
readr::write_csv(sf::st_drop_geometry(regions), "regions.csv")
library(tmap)
tmap_mode("view")
tm_shape(regions) + tm_borders() + tm_shape(regions_centroids) + tm_text("Name", size = 0.7)

# Add on PT numbers and potential switch
msoa_pct = sf::read_sf("https://github.com/npct/pct-outputs-national/raw/master/commute/msoa/z_all.geojson")
msoa_centroids = sf::st_centroid(msoa_pct)
msoas_joined = st_join(msoa_centroids, regions["Name"])
plot(msoas_joined["Name"])
summary(msoas_joined$train_tube)
summary(jsoa)
msoas_aggregated = msoas_joined %>% 
  sf::st_drop_geometry() %>% 
  group_by(Name) %>% 
  summarise(
    n_commuters = sum(all),
    n_pt = sum(train_tube + bus),
    pt_cycle_shift_govtarget = round(sum(- govtarget_sipt)),
    pt_cycle_shift_ebike = round(sum(- ebike_sipt))
  )

msoas_aggregated
regions_census = inner_join(regions, msoas_aggregated)
sf::st_drop_geometry(regions_census)
plot(regions_census["pt_cycle_shift_govtarget"])
readr::write_csv(sf::st_drop_geometry(regions_census), "regions.csv")
sf::write_sf(regions_census, "regions.gpkg")
library(kableExtra)
k = kableExtra::kable(sf::st_drop_geometry(regions_census[1:10, ]))
# writeLines(k, "k.html")
# browseURL("k.html")
# saveRDS(regions, "regions.Rds")
# piggyback::pb_upload("regions.Rds", "cyipt/cyipt-phase-1-data")