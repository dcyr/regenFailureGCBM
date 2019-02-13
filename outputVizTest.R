###############################################################################
rm(list = ls())
home <- path.expand("~")
home <- gsub("/Documents", "", home) # necessary on my Windows machine
setwd(paste(home, "Sync/Travail/ECCC/regenFailureGCBM/", sep ="/"))
################################################################################
wwd <- paste(getwd(), Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)

require(raster)


processedOutputDir <- "../Standalone_Template - Copy/processed_output/spatial/"
x <- list.files(processedOutputDir)



Total_Ecosystem_C <- raster(paste(processedOutputDir,
                                  x[grep("Total_Ecosystem_C", x)],
                                  sep = "/"))