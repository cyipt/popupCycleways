library(sf)
library(pct)
l = pct::get_pct_routes_fast(region = "london")
write_sf(l, "l.gpkg")
saveRDS(l, "l.Rds")

bench::press(
  n = c(10, 1000, 10000, nrow(l)),
  {
    bench::mark(check = FALSE,
                # readRDS("l.Rds"),
                # read_sf("l.gpkg"),
                saveRDS(l[1:n, ], paste0(runif(n = 1), ".Rds")),
                write_sf(l[1:n, ], paste0(runif(n = 1), ".gpkg"))
    )
  }
)
bench::mark(check = FALSE,
            readRDS("l.Rds"),
            read_sf("l.gpkg"),
            saveRDS(l, paste0(runif(n = 1), ".Rds")),
            write_sf(l, paste0(runif(n = 1), ".gpkg"))
            )

# library(rgdal)
# install.packages("rgdal") # fail with:
# /usr/lib/R/etc/Makeconf:168: recipe for target 'inverser.o' failed
# inverser.c:5:10: fatal error: projects.h: No such file or directory
# #include <projects.h>
# ^~~~~~~~~~~~
#   compilation terminated.
# /usr/lib/R/etc/Makeconf:168: recipe for target 'inverser.o' failed
# make: *** [inverser.o] Error 1
# ERROR: compilation failed for package ‘rgdal’
# * removing ‘/home/robin/R/x86_64-pc-linux-gnu-library/3.6/rgdal’
# * restoring previous ‘/home/robin/R/x86_64-pc-linux-gnu-library/3.6/rgdal’


# remotes::install_version(package = "rgdal", version = "1.4-8") # works
# remotes::install_version(package = "rgdal", version = "1.4-7") # works
# remotes::install_version(package = "rgdal", version = "1.5-8") # fails

# remotes::install_cran("pct")
# remotes::install_github("r-spatial/sf")
# library(sf)
# l = pct::get_pct_routes_fast(region = "london")
#
# # test writing both ways
# f = function(x) file.path(tempdir(), paste0(x, ".gpkg"))
# f("l1")
# tm = system.time(
#   st_write(l[1:5, ], f("l4"), layer_options = "")
# )
# system.time(
#   st_write(l, f("l2"), layer_options = "SPATIAL_INDEX=NO")
# )
#
# 
# # ?bench::press
# bench::press(
#   n = c(10, 100, 1000, 10000),
#   layer_options = c("", "SPATIAL_INDEX=NO"),
#   {
#     bench::mark(
#       time_unit = "ms",
#       sf = st_write(l[1:n, ], f(paste0(n, layer_options, runif(1))), layer_options = layer_options)
#       )
#   }
# )

# system.time({
#   mm_roads_uk = readRDS("~/hd/data/os/Download_mastermap-roads-2020-04.Rds")
# })

# mm_subset = mm_roads_uk[1:100000, ]
# # bench::press(
# #   n = c(10, 100, 1000, 100000),
# #   layer_options = c("", "SPATIAL_INDEX=NO"),
# #   {
# #     bench::mark(
# #       time_unit = "ms",
# #       sf = write_sf(mm_subset[1:n, ], f(paste0(n, layer_options, runif(1))), layer_options = layer_options)
# #     )
# #   }
# # )
# 
# t1 = system.time({
#   write_sf(mm_roads_uk[1:500000, ], "/tmp/test1.gpkg")
# })
# 500000 / t1[3]
# 500000 / t3[3]
# 
# t2 = system.time({
#   write_sf(mm_roads_uk[1:500000, ], "/tmp/test2.gpkg", layer_options = "SPATIAL_INDEX=NO")
# })
# 
# t3 = system.time({
#   saveRDS(mm_roads_uk[1:500000, ], "/tmp/test3.Rds")
# })
# 
# 
# t11 = system.time({
#   write_sf(mm_roads_uk[1:5000, ], "/tmp/test11.gpkg")
# })
# 5000 / t11[3]
# 
# system.time({
#   write_sf(mm_roads_uk[1:5000, ], "/tmp/test11.shp")
# })
# 
# system.time({
#   geojsonsf::sf_geojson(mm_roads_uk[1:5000, ], "/tmp/test11.geojson")
# })

t12 = system.time({
  write_sf(mm_roads_uk, "~/hd/data/os/Download_mastermap-roads-2020-04-all.gpkg", layer_options = "SPATIAL_INDEX=NO")
})

# t13 = system.time({
#   saveRDS(mm_roads_uk[1:5000, ], "/tmp/test13.Rds")
# })

system.time({
  rf = sf::read_sf("~/hd/data/osm/Isle of Wight.osm.pbf")
})

library(reticulate)
o = setwd("~/hd/data/osm/")
os = import("os")
os$listdir(".")
gp = import("geopandas")
res = gp$read_file("andorra.osm.pbf")
# Error in py_call_impl(callable, dots$args, dots$keywords) : 
#   DriverError: unsupported driver: 'OSM' 
setwd("~/hd/data/os/Download_dl-central-leeds-mm-topo_1483657/mastermap-topo_3480314/")
os$listdir()
system.time({
  res = gp$read_file("mastermap-topo_3480314_0.gpkg")
})
system.time({
  res_sf = sf::read_sf("mastermap-topo_3480314_0.gpkg")
})
reticulate::py_install("pydriosm")
