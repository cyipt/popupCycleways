# Update cycling potential values -----------------------------------------

rnet = rnet_all[region, c(1, 3)]
rnet_school = rnet_all_school[region, c(1, 3)]
combine = rbind(rnet, rnet_school)
rnet_combined = stplanr::overline2(x = combine, attrib = "govtarget_slc")

rnet_buff = geo_buffer(shp = rnet_combined, dist = pct_dist_within)
r_cyipt_joined = st_join(r_main_region, rnet_buff, join = st_within) %>% 
  group_by(idGlobal) %>% 
  summarise(cycling_potential = max(cycling_potential))
cor(r_cyipt_joined$govtarget_slc, r_cyipt_joined$cycling_potential, use = "complete.obs")

dupes = r_cyipt_joined[duplicated(r_cyipt_joined$idGlobal) | duplicated(r_cyipt_joined$idGlobal, fromLast = TRUE), ]
dupes_max = dupes %>% 
  st_drop_geometry() %>% 
  group_by(idGlobal) %>%
  summarise(cycling_potential_max = max(govtarget_slc)) 

r_joined = left_join(r_cyipt_joined, dupes_max, by = "idGlobal") %>%
  mutate(cycling_potential = ifelse(is.na(cycling_potential_max), ifelse(is.na(govtarget_slc), pctgov, govtarget_slc), cycling_potential_max),
         cycling_potential_source = ifelse(is.na(cycling_potential_max), ifelse(is.na(govtarget_slc), "cyipt", "updated"), "updated_duplicate"))

r_positive = r_joined[which(r_joined$cycling_potential > 0),] %>%
  select(name:n_lanes, cycling_potential_source) %>%
  distinct(.keep_all = TRUE) # remove the duplicates

r_pct_lanes_all = r_positive %>% 
  filter(cycling_potential > min_cycling_potential) %>% # min_cycling_potential = 0 so this simply selects multilane roads
  filter(lanes_f > 1 | lanes_b > 1)
# mapview::mapview(r_pct_lanes_all)

r_pct_lanes_all_buff = geo_buffer(shp = r_pct_lanes_all, dist = 200)
touching_list = st_intersects(r_pct_lanes_all_buff)
# head(touching_list)

# touching_list = st_touches(r_pct_lanes_all)
g = igraph::graph.adjlist(touching_list)
components = igraph::components(g)
r_pct_lanes_all$group = components$membership

# These groups might be discontiguous
r_pct_lanes = r_pct_lanes_all %>% 
  group_by(group, rounded_cycle_potential) %>% 
  mutate(group_length = sum(length)) %>% 
  mutate(cycling_potential_mean = weighted.mean(cycling_potential, w = length, na.rm = TRUE)) %>% 
  filter(cycling_potential_mean > min_grouped_cycling_potential)
r_pct_lanes$group_index = group_indices(r_pct_lanes)
# dplyr::n_groups(r_pct_lanes)
length(unique(r_pct_lanes$group_index))
# head(r_pct_lanes$group_index)
# Warning message:
#   group_indices_.grouped_df ignores extra arguments 
# r_pct_lanes = r_pct_lanes %>% filter(group_length > min_grouped_length) # don't filter by group length until we have sorted out how to deal with discontinuous routes 

# this section needs changing since the group definitions have changed
r_pct_lanes$graph_group = r_pct_lanes$group_index
group_table = table(r_pct_lanes$group_index)
top_groups = tail(sort(group_table), 5)
r_pct_lanes$graph_group[!r_pct_lanes$graph_group %in% names(top_groups)] = "other"