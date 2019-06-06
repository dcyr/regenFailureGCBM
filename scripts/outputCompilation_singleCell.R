###################################################################
###################################################################
### GCBM output compilation
rm(list = ls())
simDir <- c("D:/GCBM_sims/singlecellSims")
wwd <- paste(simDir, Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)
###
simID <- c("singleCellSims_regenFailure", "singleCellSims_noRegenFailure")


## copying useful functions to the wd
mainDir <- "C:/Users/cyrdo/Sync/Travail/ECCC/regenFailureGCBM/"
sourceDir <- "D:/regenFailureRiskAssessmentData_phase2/2019-01-07_coupe0.62_recup70_contrainteAge"
file.copy(paste(mainDir, "scripts/outputCompilationFnc.R", sep = "/"),
          ".", overwrite = T)
source("outputCompilationFnc.R")


###################################################################
###################################################################
### pool and fluxes of interest
###################################################################

require(foreach)
# clusterN <- 2

#######
outputSummary <- foreach(i = seq_along(simID)) %do% {
    require(RSQLite)
    require(dbplyr)
    require(dplyr)
    require(doSNOW)
    require(raster)
    require(parallel)
    
    sDir <- paste("..", simID[i], sep = "/")
    studyArea <- raster(paste0(sDir, "/studyArea.tif"))
    simInfo <- read.csv(paste0(sDir, "/simInfo.csv"))
    
    ct_AT <- read.csv(paste(sDir, "classifiersAT/ct_AT.csv", sep = "/"))
    dens_AT <- read.csv(paste(sDir, "classifiersAT/dens_AT.csv", sep = "/"))
    fert_AT <- read.csv(paste(sDir, "classifiersAT/fert_AT.csv", sep = "/"))
    
    
    ###################################################################
    ###################################################################
    ### aspatial outputs
    ## connect to compiled gcbm outputs db
    gcbmOutputDB <- dbConnect(drv=RSQLite::SQLite(),
                              dbname = paste(sDir,
                                             "processed_output/compiled_gcbm_output.db",
                                             sep = "/"))
    
    #### list of tables
    tableNames <- dbListTables(gcbmOutputDB)
    ## load all tables (might want to prune a bit...)
    for (j in seq_along(tableNames)) {
        x <- tableNames[j]
        assign(x, dbReadTable(gcbmOutputDB, x))
        print(paste0("table '", x, "' loaded"))
    }
    dbDisconnect(gcbmOutputDB)
    
    ## defining pools and fluxes of interest
    fluxDim <- unique(r_stock_changes$name)
    poolDim <- unique(r_pool_indicators$name)
    
    pools <- foreach(k = seq_along(poolDim), .combine = "rbind") %do% {
        x <- poolSummarise(poolDim[k], groupingVar = c(
            dateDim = T,
            classifierSetDim = T,
            landClassDim = F,
            ageClassDim = T)) 
        return(x)
    }
    fluxes <- foreach(k = seq_along(fluxDim), .combine = "rbind") %do% {
        x <- fluxSummarise(fluxDim[k], groupingVar = c(
            dateDim = T,
            classifierSetDim = T,
            landClassDim = F,
            ageClassDim = T)) 
        return(x)
    }
    pools <- data.frame(simID = simID[i], pools) %>%
        arrange(pool_indicator_id)
    fluxes <- data.frame(simID = simID[i], fluxes) %>%
        arrange(indicator)
    
    
    ###################################################################
    ###################################################################
    ## spatial outputs

    outputSpatialDir <- paste(sDir, "processed_output/spatial", sep = "/")
    f <- list.files(outputSpatialDir)
    var <- substr(f, 1, nchar(f)-10)
    var <- unique(var)
    
    clusterN <- length(var)# min(length(simID), floor(0.5*detectCores()))  ### choose number of nodes to add to cluster.
    #######
    cl = makeCluster(clusterN, outfile = "") ##
    registerDoSNOW(cl)
    spatialOutputs <- foreach(j = seq_along(var), .combine = "rbind") %dopar% {
        require(raster)
        require(tidyr)
        require(reshape2)
        v <- var[j]
        tmp <- f[grep(v, f)]
        lNames <- gsub(".tiff", "", tmp)
        
        r <- stack(paste(outputSpatialDir, tmp, sep = "/"))
        r <- projectRaster(r, studyArea, method = "ngb")
        
        ## putting everything into a tidy data.frame
        tmp <- values(r)
        #cNames <- rlang::parse_quosures(paste(colnames(simInfo), collapse=";"))
        #cNames <- rlang::syms(lNames)
        #foo <- gather(as.data.frame(x))
        
        tmp <- data.frame(simInfo, tmp[complete.cases(tmp),])
        tmp <- gather(tmp, key = "variable", value = "value",
                      !!lNames)
        tmp[,"year"] <- as.numeric(gsub("[^0-9]", "", tmp$variable))
        tmp[,"variable"] <- gsub("[0-9]", "", tmp$variable)
        tmp[,"variable"] <- substr(tmp$variable, 1, nchar(tmp$variable)-1)
        tmp[,"simID"] <- simID[i]
        
        tmp[,"coverTypes"] <- factor(ct_AT[match(tmp[,"coverTypes"], ct_AT$ID),
                                           "AIDBSPP"])
        colnames(tmp)[which(colnames(tmp)=="rho100")] <- "relDensity"

        return(tmp)
        
    }
    stopCluster(cl)
    
    return(list(pools = pools,
                fluxes  = fluxes,
                spatialOutputs = spatialOutputs))
}


### put all this into single data.frames (one for pools, one for fluxes)
pools <- do.call("rbind", lapply(outputSummary, function(x) x[["pools"]]))
fluxes <- do.call("rbind", lapply(outputSummary, function(x) x[["fluxes"]]))
spatialOutputs <- do.call("rbind", lapply(outputSummary, function(x) x[["spatialOutputs"]]))
save(pools, file = "pools.RData")
save(fluxes, file = "fluxes.RData")
save(spatialOutputs, file = "spatialOutputs.RData")


