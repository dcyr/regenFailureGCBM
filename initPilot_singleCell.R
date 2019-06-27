###############################################################################
###############################################################################
####
#### Piloting GCBM initialization using previous simulation experiment 
#### (Based on Splawinski et al post-fire regeneration failure experiment)
#### Dominic Cyr
####
###############################################################################
###############################################################################
rm(list = ls())
home <- path.expand("~")
home <- gsub("/Documents", "", home) # necessary on my Windows machine
setwd("D:/GCBM_sims")
wwd <- paste(getwd(), Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)
#      
sourceDir <- "D:/regenFailureRiskAssessmentData_phase2/2019-01-07_coupe0.62_recup70_contrainteAge"
sourceGCBM <- paste(home, "Sync/Travail/ECCC/regenFailureGCBM", sep = "/")

####
require(stringr)
require(raster)
###############################################################################
#### user defined parameters
###############################################################################
# general input parameters
regenFailure = T
yearInit <- 2015
simDuration <- 300
n <- 1
timestep <- 1 # simulation time step (currently only work with 1)
#siteIndexInt <- 1 # bin width for site index classes
#r100Int <- 1/3 # bin width for relative density classes
ageMax <- 150 # max age for yield curves (after which mechantable volumes remain constants)
#plotting <- F
#nCores <- 12 ## number of cores to use during GCBM simulations

################################################################################
### experimental design
simInfo <- list(yearInit = yearInit,
                simDuration = simDuration,
                siteIndex = 8:15,
                ageinit = 50,
                rho100 = c(0.145, 0.38, 0.735),
                coverTypes = c(1, 2),
                "Wild fire" = c(2115))


#projectName <- "test_extreme"
simInfo <- expand.grid(simInfo,
                       stringsAsFactors = F)
################################################################################
### creating simulation folder
simDir <- ifelse(regenFailure,
                 "singleCellSims_regenFailure",
                 "singleCellSims_noRegenFailure") 
dir.create(simDir)
################################################################################




################################################################################
#### Generating common environmental inputs
layerDir <- "layers"
dir.create(layerDir)
rawDir <- paste(layerDir, "raw", sep = "/")
dir.create(rawDir)
file.copy(paste(sourceGCBM, "wc2-5", sep = "/"),
          "./",
          overwrite = T,
          recursive = T,
          copy.mode = TRUE)

################################################################################
#### creating study area raster
# fetching 'real' study area
studyArea <- raster(paste(sourceDir, "studyArea.tif", sep = "/"))
studyAreaOrigin <- studyArea
## selecting one cell from studyArea (middle cell)
studyAreaMid <- cellFromRowCol(studyArea,
                               rownr =round(nrow(studyArea)/2),
                               colnr = round(ncol(studyArea)/2))
studyArea <- rasterFromCells(studyArea,
                             studyAreaMid,
                             values = F)
## determining size of study area
eSize <- ceiling(nrow(simInfo)^.5)
e <- extent(studyArea)
r <- res(studyArea)

e[1] <- e[1]-(eSize/2*r[1])+r[1]/2
e[2] <- e[2]+(eSize/2*r[1])-r[1]/2
e[3] <- e[3]-(eSize/2*r[2])+r[2]/2
e[4] <- e[4]+(eSize/2*r[2])-r[2]/2

studyArea <- raster(nrows = eSize,
                    ncols = eSize,
                    ext = e,
                    crs = crs(studyArea))
studyArea[] <- NA
studyArea <- setValues(studyArea,
                       c(rep(1, nrow(simInfo)), rep(NA, eSize^2-nrow(simInfo))))

# Environmental variables
source(paste(sourceGCBM, "scripts/initEnvironment_singleCell.R", sep = "/"), local = T)
# Forest inventory inputs
source(paste(sourceGCBM, "scripts/initInventory_singleCell.R", sep ="/"), local = T)
# Generating Disturbance and disturbance related inputs (ex. transitions)
source(paste(sourceGCBM,  "scripts/initDisturbances_singleCell.R", sep = "/"),
       local = T)


################################################################################
#### Creating GCBM simulation file package
source(paste(sourceGCBM, "scripts/initFilePackage_singleCell.R", sep = "/"),
       local = T)

write.csv(simInfo, paste0(simDir, "/simInfo.csv"), row.names = F)
writeRaster(studyArea, file = paste0(simDir, "/studyArea.tif"), overwrite = T)


