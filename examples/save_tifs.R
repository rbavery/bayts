data(s1vv_lndvi_raster)
layer_filename = format(as.Date(substr(names(lndvi),10,16), format="%Y%j"))
for(i in 1:291) {
  single_band <- raster(lndvi, layer = i)
  writeRaster(single_band, layer_filenames[i])
}
# get observation dates from raster brick
lndvi_date <- as.Date(substr(names(lndvi),10,16), format="%Y%j")
lndvi_date
s1vv_date <- as.Date(substr(names(s1vv),2,11), format="%Y.%m.%d")
s1vv_date
