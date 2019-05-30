################################################################################
################################################################################
##### 
##### Initiating environment spatial data for GCBM simulations
##### Dominic Cyr
##### 
################################################################################
################################################################################

####
require(raster)
print('Creating environmental spatial data ...')
################################################################################
### creating 'layers' folder
dir.create(paste(rawDir, "environment", sep = "/"))

################################################################################
#### mean annual temperature
#### (could be a sequence of raster)
######## 
print("Fetching and formatting mean annual temperature ...")
# fetching and formatting data
r <- getData('worldclim', var='bio', res=2.5)
r <- projectRaster(r[["bio1"]], studyAreaOrigin, method = 'ngb')
r <- round(r, 2)
tMean <- r/10
rVal <- extract(tMean, studyAreaMid)
tMean <- projectRaster(tMean, studyArea, method = 'ngb')
tMean[] <- rVal
#tMean[is.na(studyArea)] <- NA
#### exporting raster
filename <- paste(".", rawDir, "environment/tempAnnualMean_C.tif", sep = "/")
writeRaster(tMean, filename, overwrite = T)
print(paste0("file '", filename, "' created"))
