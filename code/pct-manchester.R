library(tidyverse)

# shown input data
source("code/build.R")
mapview::mapview(r_pct_lanes_all)
corridor_names = c(
  "Chester Road", # (Trafford)
  "A6",
  "A580", #A6/A580 – East Lancs to Chapel Street (Salford)
  "A34", # – Anson road/Birchfield Road (Stockport)
  "A57", # Hyde Road (Tameside)
  "A62", # A62 – Oldham Road (Oldham)
  "A56", # A56 – Bury New Road (Bury)
  "Chorlton Road", # (all Manchester)
  "Princess road" # Princess road (all Manchester)
)
princess_road = r_pct_lanes_all %>% filter(name == "Princess Road")
bury = r_pct_lanes_all %>% filter(name == "Bury New Road")
mapview::mapview(princess_road)

# load all roads using code in "code/get-data-db.R":
rsf = readRDS("rsf.Rds")
unique(rsf$region)
rsf_mcr = rsf %>% filter(region == "Manchester")
rsf_1k = rsf_mcr %>% sample_n(1000)
mapview::mapview(rsf_1k) # ttwa

regexclude_corridors = "A537|A5149|A5102|A5034|A556"

key_corridors_mcr = rsf_mcr %>% 
  filter(name %in% corridor_names | ref %in% corridor_names) %>% 
  filter(str_detect(string = ref, pattern = "A")) %>% 
  filter(!str_detect(string = ref, pattern = regexclude_corridors)) %>% 
  filter(!is.na(width))

summary(key_corridors_mcr$width)
key_corridors_mcr$width_numeric = as.numeric(key_corridors_mcr$width)

mapview::mapview(key_corridors_mcr["width"], lwd = key_corridors_mcr$width)
tm_shape(key_corridors_mcr) +
  tm_lines(lwd = "width", scale = 9)

saveRDS(key_corridors_mcr, "key_corridors_mcr.Rds")
piggyback::pb_upload("key_corridors_mcr.Rds")

# potential analysis ------------------------------------------------------

r$pt_mode_shift = r$ebike_sip * -1
summary(r$pt_mode_shift)
nrow(r) # 16363
rnet_pt = stplanr::overline(r, "pt_mode_shift")
mapview::mapview(rnet_pt)

# since 2011 there has been a doubling


# high percentage of key workers - stats


l = pct::get_desire_lines("greater-manchester")
r = pct::get_pct_routes_fast("greater-manchester")
r_top_pt = r %>% filter(train_tube > 50)
mapview::mapview(r_top_pt["train_tube"])
rnet_top = stplanr::overline(r_top_pt, "train_tube")
mapview::mapview(rnet_top["train_tube"]) + mapview::mapview(r_pct_lanes_all)

# Send over widths of key roads

# outputs: NESW routes - 5 routes then ranking them
