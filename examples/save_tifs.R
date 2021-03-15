data(s1vv_lndvi_raster)
layer_dates = format(as.Date(substr(names(lndvi),10,16), format="%Y%j"))
layer_filenames = paste(layer_dates, "-lndvi.tif", sep="")
for(i in 1:length(layer_filenames)) {
  single_band <- raster(lndvi, layer = i)
  writeRaster(single_band, layer_filenames[i], overwrite=TRUE)
}

layer_dates = format(as.Date(substr(names(s1vv),2,11), format="%Y.%m.%d"))
layer_filenames = paste(layer_dates, "-s1vv.tif", sep="")
for(i in 1:length(layer_filenames)) {
  single_band <- raster(s1vv, layer = i)
  writeRaster(single_band, layer_filenames[i], overwrite=TRUE)
}