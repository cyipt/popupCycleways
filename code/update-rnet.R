library(pct)
library(stplanr)
library(tidyverse)
library(sf)

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


# Duplicates are mostly very short sections within junctions, or dual carriageways.
dupes = r_cyipt_joined[which(duplicated(r_cyipt_joined$idGlobal) == TRUE | duplicated(r_cyipt_joined$idGlobal, fromLast = TRUE) == TRUE),]
dim(dupes) # 10593

# mapview(dupes) + mapview(rnet_buff)

# Max cycling potential is best because on dual carriageways, each carriageway already has its cycle potential half (or less) what it would be if this was a single carriageway road
dupes_max = dupes %>% 
  st_drop_geometry() %>% 
  group_by(idGlobal) %>%
  summarise(cycling_potential_max = max(govtarget_slc)) 

dim(dupes_max) # 3533

##Need to join dupes_max with the rnet. Take cycling potential from dupes_max where duplicates exist. Otherwise take it from the new pct dataset, unless there is no buffer segment that the cyipt segment fits inside. In that case take it from cyipt. 
# Otherwise some segments will be missing. Eg Anchor Road, Cumberland Basin, Gloucester Road Horfields. These go outside the buffer. 
r_joined = left_join(r_cyipt_joined, dupes_max, by = "idGlobal") %>%
  mutate(cycling_potential = ifelse(is.na(cycling_potential_max), ifelse(is.na(govtarget_slc), pctgov, govtarget_slc), cycling_potential_max))
dim(r_joined) # 111865 needs to be the same as dim(r_cyipt_joined). Be careful, this includes large numbers of streets that with 0 cycling potential

r_joined = r_joined %>%
  distinct()

head(r_joined)

r_positive = r_joined[which(r_joined$cycling_potential > 0),] %>%
  select(idGlobal:widthstatus, Existing, length, cycling_potential) %>%
  distinct(.keep_all = TRUE) # remove the duplicates
dim(r_positive) # 31333. This is similar to dim(rnet), but larger because the cyipt segments tend to be smaller than the pct ones. Beware, this can also include areas beyond the geographic range of the new pct data (eg. areas inside the Bristol travel-to-work zone but outside Avon). Also, in places where there was no matching buffer, the occasional use of cyipt cycling potential estimates can produce some sudden jumps in the figures. 
mapview::mapview(r_positive["cycling_potential"])


# Testing on a duplicated segment
# r_cyipt_joined[r_cyipt_joined$idGlobal==708914,]
# dupes_max[dupes_max$idGlobal==708914,]
# r_joined[r_joined$idGlobal == 708914,]
# r_positive[r_positive$idGlobal == 708914,]


# rnet1_buff1 = rnet_buff[12944,]
# cyiptr1 = dupes[rnet1_buff1,]
# mapview(rnet1_buff1) + mapview(cyiptr1)


## Calculate correlation between old and new pctgov numbers

cor(r_positive$pctgov, r_positive$cycling_potential) # 0.6176501 correlation across all segments
matching = r_joined[which(r_joined$govtarget_slc == r_joined$cycling_potential),]
cor(matching$pctgov, matching$govtarget_slc, use = "pairwise.complete.obs") # 0.6019595 excluding segments where cycling_potential was taken from pctgov
match_dupe = r_joined[which(r_joined$cycling_potential_max == r_joined$cycling_potential),]
match_dupe = distinct(match_dupe, .keep_all = TRUE)
cor(match_dupe$pctgov, match_dupe$cycling_potential_max, use = "pairwise.complete.obs") # 0.4311468 for the duplicated segments 


