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
yearInit <- 2015
simDuration <- 50
n <- 20
timestep <- 1 # simulation time step (currently only work with 1)
siteIndexInt <- 1 # bin width for site index classes
r100Int <- 1/3 # bin width for relative density classes
ageMax <- 150 # max age for yield curves (after which mechantable volumes remain constants)
plotting <- F
###############################################################################
### experimental design (replicates, treatments)
# replicates
x <- list.files(paste(sourceDir, "output", sep = "/"))
replicates <- x[grep("outputFire_", x)]
replicates <- gsub("outputFire_|.RData", "", x)
# experimental design
simInfo <- list(sourceSimID = replicates[1:n],
            regenFailure = c(F, T),
            yearInit = 2015,
            simDuration = 50)
#projectName <- "test_extreme"
simInfo <- expand.grid(simInfo,
                        stringsAsFactors = F)
simInfo <- simInfo[order(simInfo$sourceSimID),]
simInfo <- data.frame(simID = as.character(str_pad(00:(nrow(simInfo)-1),
                                                   nchar(nrow(simInfo)-1),
                                                   pad = "0")),
                      simInfo,
                      stringsAsFactors = F)

if (plotting) { ### loading a few data sets for plotting
    require(ggplot2)
    require(colorspace)
    require(RColorBrewer)
    
    dir.create("figures")
    lakes <- raster(paste(sourceDir, "data/lakes.tif", sep = "/"))
    studyAreaP <- get(load(paste(sourceDir, "data/studyAreaP.RData", sep = "/")))
    studyAreaF <- fortify(studyAreaP)
    
    pWidth <- 1600
    pHeight <- 1300
    pointsize <- 12
    options(scipen=999)
}

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
#### fetching study area and other input layers
#
studyArea <- raster(paste(sourceDir, "studyArea.tif", sep = "/"))
# Environmental variables
source(paste(sourceGCBM, "scripts/initEnvironment.R", sep = "/"), local = T)
# Forest inventory inputs
source(paste(sourceGCBM, "scripts/initInventory.R", sep ="/"), local = T)


require(doSNOW)
require(parallel)
require(foreach)
# clusterN <- 2
clusterN <-  min(nrow(simInfo), floor(0.33*detectCores()))  ### choose number of nodes to add to cluster.
#######
cl = makeCluster(clusterN, outfile = "") ##
registerDoSNOW(cl)

foreach(sim = 1:nrow(simInfo),
        .export = ls()) %dopar% { ##c("rawDir", "cls_sp", "rho100CutOffs", "coverTypes")
    require(raster)
    
    simID <- simInfo[sim, "simID"]
    sourceSimID <- simInfo[sim, "sourceSimID"]
    regenFailure <- simInfo[sim, "regenFailure"]
    yearInit <- simInfo[sim, "yearInit"]
    simDuration <- simInfo[sim, "simDuration"]
    
    simDir <- paste(wwd, simID, sep = "/")
    dir.create(simDir)
    setwd(simDir)
    
    ################################################################################
    #### copying 'layers' folder
    file.copy("../layers",
              "./",
              overwrite = T,
              recursive = T,
              copy.mode = TRUE)
    
    ################################################################################
    #### Generating spatial inputs for GCBM experiment specific to each individual 
    #### simulation

    # Disturbances inputs
    source(paste(sourceGCBM, "scripts/initDisturbances.R", sep = "/"),
           local = T)
    ################################################################################
    #### Creating GCBM simulation file package
    source(paste(sourceGCBM, "scripts/initFilePackage.R", sep = "/"),
           local = T)
}
stopCluster(cl)
  
write.csv(simInfo, "simInfo.csv", row.names = F)
file.copy(paste(sourceGCBM, "simPilot.R", sep = "/"), ".", overwrite = T)


