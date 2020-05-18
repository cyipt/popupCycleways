library(pct)
library(stplanr)
library(tidyverse)

# readRDS(url("https://github.com/npct/pct-outputs-national/blob/master/commute/lsoa/rnet_all.Rds"))
rnet = pct::get_pct_rnet(region = "avon") # LSOA route network
# mapview(rnet["govtarget_slc"])

r_cyipt = readRDS("rsf.Rds")
r_cyipt = r_cyipt[r_cyipt$region == "Bristol",]

# st_crs(rnet)
# st_crs(r_cyipt)

dim(rnet) # 13829 this only has streets which are part of the LSOA route network
dim(r_cyipt) # 104805 this has every street

rnet_buff = geo_buffer(shp = rnet, dist = 10)
# mapview(rnet_buff["govtarget_slc"])

r_cyipt_joined = st_join(r_cyipt, rnet_buff, join = st_within)

dim(r_cyipt_joined) # 111865 
nrow(r_cyipt_joined)/nrow(r_cyipt)

# test_all_present = r_cyipt_joined[which(duplicated(r_cyipt_joined$idGlobal) == TRUE) ,]
# dim(r_cyipt_joined) - dim(test_all_present) # this must equal dim(r_cyipt) if all segments can be joined

dupes = r_cyipt_joined[which(duplicated(r_cyipt_joined$idGlobal) == TRUE | duplicated(r_cyipt_joined$idGlobal, fromLast = TRUE) == TRUE),]
# dim(dupes) # 10593

# mapview(dupes) + mapview(rnet_buff)

dupes_max = dupes %>% 
  group_by(idGlobal) %>%
  summarise(cycling_potential_max = max(govtarget_slc)) %>%
  st_drop_geometry()

dim(dupes_max) # 3533

##Need to join dupes_max with the rnet. Then join the results of that with the r_cyipt/r_cyipt_joined


r_joined = left_join(r_cyipt_joined, dupes_max, by = "idGlobal") %>%
  mutate(cycling_potential = ifelse(is.na(cycling_potential_max), ifelse(is.na(govtarget_slc), pctgov, govtarget_slc), cycling_potential_max))
dim(r_cyipt_joined) # 111865 needs to be the same as dim(r_cyipt_joined)

head(r_joined)

rnna = r_joined[which(!is.na(r_joined$cycling_potential)),]
dim(rnna) # 111865 be careful, this includes large numbers of streets that with 0 cycling potential, and can include streets outside the geographic range of the new pct data
mapview(rnna)

# Why are some segments missing? Eg Anchor Road, Cumberland Basin, Gloucester Road Horfields. These go outside the buffer. 
rnna = rnna %>%
  select(idGlobal:widthstatus, Existing, length, cycling_potential)

dim(rnna) #37587
head(rnna)

rnna = unique(rnna)
dim(rnna) # 30527

mapview(rnna["cycling_potential"])

r_cyipt_joined[r_cyipt_joined$idGlobal==708914,]
dupes_max[dupes_max$idGlobal==708914,]
r_joined[r_joined$idGlobal == 708914,]
rnna[rnna$idGlobal == 708914,]
# 
# 
# mapview(r_cyipt_joined["cycling_potential"])
mapview(rnet_buff["govtarget_slc"]) +  mapview(r_joined["cycling_potential"])


###

# 
# rnet1_buff1 = rnet_buff[12944,]
# cyiptr1 = dupes[rnet1_buff1,]
# mapview(rnet1_buff1) + mapview(cyiptr1)
# 
# dupes[dupes$idGlobal==708914,]

## Calculate correlation between old and new pctgov numbers

cor(r_joined$pctgov, r_joined$cycling_potential) # 0.9133221 correlation across all segments
cor(r_joined$pctgov, r_joined$cycling_potential_max, use = "pairwise.complete.obs") # for the segments where cycling potential has been  correlation


