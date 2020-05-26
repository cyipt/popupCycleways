r_positive[which(r_positive$ref == "A4320" & r_positive$lanes_f == 1),] = r_positive[which(r_positive$ref == "A4320" & r_positive$lanes_f == 1),] %>%
  mutate(lanes_f = 2, lanesforward = 2)

