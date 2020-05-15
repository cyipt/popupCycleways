library(tidyverse)

# counties = ukboundaries::duraz("https://borders.ukdataservice.ac.uk/ukborders/easy_download/prebuilt/kml/England_ct_2001_clipped.zip")
counties_full = sf::read_sf("england_ct_2001_clipped.kml")
counties = rmapshaper::ms_simplify(counties_full, sys = TRUE)
counties_full$Name
length(unique(counties_full$Name))
counties_full$Name[! counties_full$Name %in% counties$Name]
mapview::mapview(counties)
# Counties and Unitary Authorities (December 2017) Boundaries UK
# uas_uk = sf::read_sf("https://opendata.arcgis.com/datasets/6638c31a8e9842f98a037748f72258ed_3.kml?outSR=%7B%22latestWkid%22%3A27700%2C%22wkid%22%3A27700%7D")
# uas_uk = uas_uk %>% select(matches("cty"))
# plot(uas_uk)
# sf::write_sf(uas_uk, "~/hd/data/uk/uas_uk.gpkg")
# uas_uk
# head(uas_uk$ctyua17cd)
# uas_en = uas_uk %>% filter(str_detect(string = ctyua17cd, pattern = "E"))
# nrow(uas_en)
# saveRDS(uas_en, "uas_en.Rds")
# piggyback::pb_upload("uas_en.Rds")
uas_en = readRDS("uas_en.Rds")
mapview::mapview(uas_en)


# todo: combine counties with UAs and CAs

regs = read_csv("regs.csv")
names(regs) = "name"
regs_clean = regs %>% 
  mutate(level = case_when(
    str_detect(name, "UA") ~ "unitary_authority",
    str_detect(name, "CA|ITA|tfl") ~ "combined_authority",
    TRUE ~ "other"
    )) %>% 
  mutate(name = gsub(pattern = " UA| UA2| CA| ITA| Region| City", replacement = " ", name)) %>% 
  mutate(name = gsub(pattern = "Kingston upon Hull,  of", replacement = "Kingston upon Hull, City of", name)) %>% 
  mutate(name = gsub(pattern = " and Peterborough", replacement = "", name)) %>% 
  mutate(name = gsub(pattern = "Bournemouth, Christchurch snd Poole", replacement = "", name)) %>% 
  mutate(name = gsub(pattern = "tfl", replacement = "Greater London", name)) %>% 
  mutate(name = str_trim(name)) %>% 
  filter(!str_detect(string = name, pattern = "1|2|Local"))
summary(c_in_regs <- regs_clean$name %in% counties$Name) # 26 counties in there
summary(u_in_regs <- regs_clean$name %in% uas_en$ctyua17nm) # 26 counties in there

# west of england: avon, bath, northwest somerset

# Tees Valley: around Middlesbrough

# North East: County Durham, Gateshead, South Tyneside and Sunderland.

either_in_regs = c_in_regs | u_in_regs
summary(either_in_regs)
unmatched_names = regs_clean$name[!either_in_regs]
unmatched_names
