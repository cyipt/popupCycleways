library(pct)
library(stplanr)
library(tidyverse)

# readRDS(url("https://github.com/npct/pct-outputs-national/blob/master/commute/lsoa/rnet_all.Rds"))
rnet = pct::get_pct_rnet # LSOA route network
mapview(rnet["govtarget_slc"])

r_cyipt = readRDS("rsf.Rds")
r_cyipt = r_cyipt[r_cyipt$region == "Bristol",]

st_crs(rnet)
st_crs(r_cyipt)

dim(rnet) # 13829 this only has streets which are part of the LSOA route network
dim(r_cyipt) # 104805 this has every street

rnet_buff = geo_buffer(shp = rnet, dist = 10)
mapview(rnet_buff["govtarget_slc"])

rnet_buff2 = geo_buffer(rnet, dist = 2)
mapview(rnet_buff2["govtarget_slc"])

rnet_joined = st_join(rnet_buff, r_cyipt, join = st_within)

dim(rnet_joined) # 13829 same as rnet

## Calculate correlation between old and new pctgov numbers