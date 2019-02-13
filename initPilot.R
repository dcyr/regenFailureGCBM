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
setwd(paste(home, "Sync/Travail/ECCC/regenFailureGCBM/", sep ="/"))
################################################################################
wwd <- paste(getwd(), Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)
####
require(raster)
#### user defined parameters
# 'sourceDir' is where 
sourceDir <- "D:/regenFailureRiskAssessmentData_phase2/2019-01-07_coupe0.62_recup70_contrainteAge"
replicates <- "001"  ### may also be a vector, a loop would be needed for multiple simulations
simID <- replicates
yearInit <- 2015
simDuration <- 50

# copying Pothier-Savard files
projectName <- "test"
timestep <- 1 # simulation time step (currently only work with 1)


siteIndexInt <- 1 # bin width for site index classes
r100Int <- 1/9 # bin width for relative density classes
ageMax <- 150 # max age for yield curves (after which mechantable volumes remain constants)
plotting <- TRUE
if(plotting) {
    require(ggplot2)
    require(colorspace)
    require(RColorBrewer)
    dir.create("figures")
    #dir.create("figures/initialConditions")
    studyAreaP <- get(load(paste(sourceDir, "studyAreaP.RData", sep = "/")))
    studyAreaF <- fortify(studyAreaP)
    lakes <- raster(paste(sourceDir, "data/lakes.tif", sep = "/"))
    pWidth  <- 1400
    pHeight <- 1200
    pointsize <- 8
    options(scipen=999)
}
################################################################################
#### fetching study area and other input layers
#
studyArea <- raster(paste(sourceDir, "studyArea.tif", sep = "/"))


################################################################################
#### creating 'layers' folder
layerDir <- "layers"
dir.create(layerDir)
layerDir <- paste(layerDir, "raw", sep = "/")
dir.create(layerDir)

################################################################################
#### Generating spatial inputs for GCBM experiment
# Environmental inputs
source("../scripts/initEnvironment.R")
# Forest inventory inputs
source("../scripts/initInventory.R")
# Disturbances inputs
source("../scripts/initDisturbances.R")
