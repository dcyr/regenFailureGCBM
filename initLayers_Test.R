################################################################################
################################################################################
##### 
##### Initiating spatial layers for GCBM - Test script
##### Dominic Cyr
##### 
################################################################################
################################################################################
rm(list = ls())
home <- path.expand("~")
home <- gsub("/Documents", "", home) # necessary on my Windows machine
setwd(paste(home, "Sync/Travail/ECCC/regenFailureGCBM/", sep ="/"))
################################################################################
wwd <- paste(getwd(), Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)
####

####
sourceDir <- "D:/regenFailureRiskAssessmentData_phase2/2019-01-07_coupe0.62_recup70_contrainteAge/"


require(raster)
require(rgdal)
source(paste(sourceDir, "scripts/Pothier-Savard.R", sep = "/"))

projectName <- "test"



################################################################################
#### fetching study area and other input layers

#
studyArea <- raster(paste(sourceDir, "studyArea.tif", sep = "/"))
coverTypes <-  raster(paste(sourceDir, "coverTypes.tif", sep = "/"))
coverTypes_RAT <- read.csv(paste(sourceDir, "coverTypes_RAT.csv", sep = "/"))
# other layers useful for visualization
studyAreaP <- get(load(paste(sourceDir, "studyAreaP.RData", sep = "/")))
lakes <- raster(paste(sourceDir, "data/lakes.tif", sep = "/"))


# # optional
# dem <- raster(paste(sourceDir, "data/Geo/dem_originalRes.tif", sep = "/"))
# dem <- resample(dem, studyArea)

# # # optional
# inventory <- readOGR(dsn = "../Standalone_Template/layers/raw/inventory", layer = "inventory")
# disturbances <- readOGR(dsn = "../Standalone_Template/layers/raw/disturbances", layer = "disturbances")



################################################################################
### creating 'layers' folder
layerDir <- "layers"
dir.create(layerDir)
layerDir <- paste(layerDir, "raw", sep = "/")
dir.create(layerDir)
dir.create(paste(layerDir, "inventory", sep = "/"))
dir.create(paste(layerDir, "disturbances", sep = "/"))


################################################################################
#### mean annual temperature
#### (could be a sequence of raster)
######## 
# studyArea mean Lat Long
r <- projectRaster(studyArea, crs = CRS("+init=epsg:4326")) ## lat long WGS 84
# fetching and formatting data
r <- getData('worldclim', var='bio', res=2.5)
r <- projectRaster(r[["bio1"]], studyArea)
r <- round(resample(r, studyArea), 2)
tMean <- r/10
#tMean[is.na(studyArea)] <- NA
#### exporting raster
writeRaster(tMean, paste(layerDir, "inventory/tempAnnualMean_C.tif", sep = "/"), overwrite = T)
# #### visualizing mean temperature
# plot(tMean)
# plot(studyAreaP, add = T)
# plot(lakes, add = T, col = "blue")


################################################################################
#### initial age
######## 
ageInit <- raster(paste(sourceDir, "tsd.tif", sep = "/"))
ageInit[ageInit>150] <- 150
#### exporting raster
writeRaster(ageInit, paste(layerDir, "inventory/ageInit.tif", sep = "/"), overwrite = T)


################################################################################
#### coverType
######## 
coverTypes <-  raster(paste(sourceDir, "coverTypes.tif", sep = "/"))
coverTypes_RAT <- read.csv(paste(sourceDir, "coverTypes_RAT.csv", sep = "/"))
#### exporting raster
writeRaster(coverTypes, paste(layerDir, "inventory/coverTypes.tif", sep = "/"), overwrite = T)


################################################################################
#### initial volume at 120 years-old
########
# fetching initial rho100
rho100 <- raster(paste(sourceDir, "IDR100.tif", sep = "/"))
rho100[rho100>1] <- 1
# fetching site index
siteIndex <- raster(paste(sourceDir, "iqs.tif", sep = "/"))
siteIndex[siteIndex<5] <- NA ## mainly site index == 0, consider them non-forested
# compiling relative density at 100 y-old species and subzones
df <- data.frame(sp = values(coverTypes),
                  rho100 = values(rho100),
                  siteIndex = values(siteIndex))
df[,"ageAt1m"] <- tFnc(sp = coverTypes_RAT[match(df$sp, coverTypes_RAT$ID), "value"],
              iqs = df$siteIndex,
              tCoef = tCoef)

index <- which(complete.cases(df))
df <- df[index,]

df[, "volAt120"] <- VFnc(sp = coverTypes_RAT[match(df$sp, coverTypes_RAT$ID), "value"],
                         iqs = df$siteIndex,
                         Ac = 120 - df$ageAt1m,
                         rho100 = df$rho100,
                         HdCoef = HdCoef, GCoef = GCoef, DqCoef = DqCoef, VCoef = VCoef,
                         rho100Coef = rho100Coef, merchantable = T,
                         scenesCoef = NULL, withSenescence = F)

# cap volAt120 to 150 cubic-meters per ha
vAt120Max <- 200
df[which(df$volAt120 > vAt120Max), "volAt120"] <- vAt120Max
# hist(df$volAt120, breaks = seq(0,vAt120Max,10))


########################
#### create 