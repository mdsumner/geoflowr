library(pacman)
p_load(tidyverse, sf, tmap)
library(tmap)
tmap_mode("view")
# tmap_mode("plot")

set.seed(123)

world <- read_csv("data-raw/world.csv") %>%
  select(admin, iso_n3, Longitude, Latitude)

# world_sf <- st_as_sf(world, wkt = "the_geom")
# qtm(world_sf)


# using USA only for testing
# numeric codes of countries do not work
X201801 <- read_csv("data-raw/201801.csv") %>%
  filter(partner == "United States of America") %>%
  filter(partner != "World") %>%
  select(reporter, reporter_code, partner, partner_code, netweight_kg) %>%
  mutate(partner_code = 840) %>%
  mutate(reporter_code = ifelse(reporter == "Switzerland", 756, reporter_code)) %>%
  mutate(reporter_code = ifelse(reporter == "India", 356, reporter_code))

flows <- left_join(X201801, world, by = c("partner_code" = "iso_n3")) %>%
  dplyr::rename(orig_long = Longitude, orig_lat = Latitude) %>%
  left_join(., world, by = c("reporter_code" = "iso_n3")) %>%
  dplyr::rename(dest_long = Longitude, dest_lat = Latitude) %>%
  select(-starts_with("admin")) %>%
  filter(!is.na(netweight_kg))

orig_dot <- flows %>%
  group_by(partner, orig_long, orig_lat) %>%
  summarise(netweight_total = sum(netweight_kg))

dest_dot <- flows %>%
  group_by(reporter, dest_long, dest_lat) %>%
  summarise(netweight_total = sum(netweight_kg))

# 'fake offset' using white fill & manual dest recalc
ggplot()+
  geom_curve(data = flows,
             aes(x = dest_long - (dest_long * runif(1,min=0.01,max=0.05)),
                 y = dest_lat - (dest_lat * runif(1,min=0.01,max=0.05)),
                 xend = orig_long,
                 yend = orig_lat),
             arrow = arrow(angle = 3, ends = "first",type = "closed"),
             # size = log10(flows$netweight_kg),
             alpha = 0.5, curvature = 0.15) +
  geom_point(data = orig_dot,
             aes(orig_long, orig_lat), size = 5,
             shape=21, fill = "white") +
  geom_point(data = dest_dot,
             aes(dest_long, dest_lat), size = 5,
             shape=21, fill = "white") +
  theme_void()
