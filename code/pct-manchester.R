library(tidyverse)

# shown input data
source("code/build.R")
mapview::mapview(r_pct_lanes_all)
# key_routes = A56 – Chester Road (Trafford)
# A6/A580 – East Lancs to Chapel Street (Salford)  
# A34 – Anson road/Birchfield Road (Stockport)
# A57 – Hyde Road (Tameside)
# A62 – Oldham Road (Oldham)
# A56 – Bury New Road (Bury)
# Chorlton (all Manchester)
# Princess road (all Manchester)

princess_road = r_pct_lanes_all %>% filter(name == "Princess Road")
bury = r_pct_lanes_all %>% filter(name == "Bury New Road")
mapview::mapview(princess_road)

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
