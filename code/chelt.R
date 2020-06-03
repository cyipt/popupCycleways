# chelt = rg_new4[rg_new4$il == 3 & rg_new4$group == 120 & rg_new4$ref == "A38",]
# 
# chelt = rg_new3[rg_new3$group2 == "3 120 A38",]
# mapview(chelt)
# View(chelt)
# 
# length(unique(rg_new3$group2))
# long = rg_new3[rg_new3$group2_length > 2000,]
# length(unique(long$group2))
# mapview(long)

# Split long roads (with or without ref) into suitable sections -----------

# Select roads with group2_length > 2km
long_roads = rg_new3 %>%
  filter(group2_length > 2000)

# Split into sections by road name, and split these into contiguous sections using buff_dist_large (100m).
lgs = unique(long_roads$name)

i = "Cheltenham Road"

# create per name groups
long_list = lapply(lgs, FUN = function(i) {
  lg = long_roads %>% filter(name == i)
  # mapview::mapview(lg)
  l_buff = lg %>%
    st_transform(27700) %>%
    st_buffer(buff_dist_large) %>%
    st_transform(4326)
  touching_list = st_intersects(l_buff)
  g = igraph::graph.adjlist(touching_list)
  components = igraph::components(g)
  lg$il = components$membership
  lg
})

lg_new = do.call(rbind, long_list)

#Create group IDs for each section
lg_new$group3 = paste(lg_new$name, lg_new$group2, lg_new$il) # Each record now has unique group3
lg_new$il = NULL
# groups(lg_new)

# Calculate length and aggregate
lg_new2 = lg_new %>% 
  group_by(group3) %>%
  mutate(
    group3_length = sum(length),
    new_group3 = group3
  ) %>%
  # summarise(
  #   group2 = first(group2),
  #   group3_length = mean(group3_length),
  #   new_group3 = first(new_group3)
  #   ) %>%
  st_transform(27700)

# groups(lg_new2)

# Find the centroid of each section
lg_c = lg_new2 %>%
  group_by(new_group3) %>%
  summarise(group2 = first(group2),
            group3_length = mean(group3_length)) %>%
  select(group2, group3_length, new_group3) %>%
  sf::st_centroid() 



# If the shortest section is < min_grouped_length (500m), join it together with the section with the closest centroid. Recalculate the length and centroid of this new section. 
# Keep going until all sections are >500m (since this is the minimum length required for top routes) 
# summary(lg_new2$group3_length)
while (min(lg_c$group3_length) < min_grouped_length) {
  shortest_segment = NULL
  shortest_centroid = NULL
  nearest = NULL
  near = NULL
  mindist = NULL
  shortest_l = NULL
  nearest_l = NULL
  new_l = NULL
  new_geom = NULL
  new_joined = NULL
  new_c = NULL
  
  shortest_centroid = lg_c[which.min(lg_c$group3_length), ]
  shortest_segment = lg_new2[which.min(lg_c$group3_length), ]
  if(dim(shortest_centroid)[1] > 1) shortest = shortest[1,]
  near = lg_c %>% 
    filter(group2 == shortest_centroid$group2) %>% 
    filter(new_group3 != shortest_centroid$new_group3) # must remove the point itself from this group
  
  distances = NULL
  
  # nearest = near[shortest_centroid, , op = st_nearest_points]
  # nearest = near %>%
  #   st_nearest_feature()
  
  for(i in 1:dim(near)[1]) {
    distance = sf::st_distance(near[i,], shortest_centroid) # switch to projected
    distances = c(distances, distance)
  }
  
  mindist = which(distances == min(distances))
  if(length(mindist) > 1) mindist = mindist[1]
  
  lg_new2$group3_length[(lg_new2$new_group3 == near$new_group3[mindist]) | lg_new2$new_group3 == shortest_segment$new_group3] =
    sum(mean(shortest_segment$group3_length), mean(lg_new2$group3_length[lg_new2$new_group3 == near$new_group3[mindist]]))

  lg_new2$geometry[(lg_new2$new_group3 == near$new_group3[mindist]) | lg_new2$new_group3 == shortest_segment$new_group3] =
    sf::st_union(
    shortest_segment$geometry, lg_new2$geometry[lg_new2$new_group3 == near$new_group3[mindist]]
    )

  lg_new2$new_group3[lg_new2$new_group3 == shortest_segment$new_group3] = 
    lg_new2$new_group3[lg_new2$new_group3 == near$new_group3[mindist]]
  
  lg_c[(lg_c$new_group3 == near$new_group3[mindist]),] =
    lg_new2 %>% filter(new_group3 == near$new_group3[mindist]) %>%
    group_by(group2, group3_length, new_group3) %>%
    summarise() %>%
    sf::st_centroid()
  
  # lg_c[lg_c$new_group3 == shortest_centroid$new_group3, ] =
  #   lg_new2 %>% filter(new_group3 == near$new_group3[mindist]) %>%
  #   group_by(group2, group3_length, new_group3) %>%
  #   summarise() %>%
  #   sf::st_centroid(lg_new2[lg_new2$new_group3 == near$new_group3[mindist],])
  
  # lg_new2 = lg_new2 %>%
  #   filter(new_group3 != shortest_segment$new_group3) 
  lg_c = lg_c %>%
    filter(new_group3 != shortest_centroid$new_group3)
}

# mapview(lg_new2)
# mapview(lg_c)

lg_new2 = lg_new2 %>%
  st_transform(4326)

lg_segments = st_join(lg_new, lg_new2, op = st_covered_by)

# lg_new2 = lg_new2 %>%
#   st_drop_geometry()

# lg_segments = inner_join(lg_new, lg_new2, by = c("group2", "group3"))


