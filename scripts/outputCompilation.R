###################################################################
###################################################################
### GCBM output compilation
rm(list = ls())
simDir <- c("D:/GCBM_sims")
wwd <- paste(simDir, Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)
###
simID <- list.dirs(paste(simDir,"sims", sep = "/"), recursive = F, full.names = F)
## copying useful functions to the wd
scriptDir <- "C:/Users/cyrdo/Sync/Travail/ECCC/regenFailureGCBM/scripts/"
file.copy(paste(scriptDir, "outputCompilationFnc.R", sep = "/"),
          ".", overwrite = T)
source("outputCompilationFnc.R")



###################################################################
###################################################################
### pool and fluxes of interest
###################################################################
require(doSNOW)
require(parallel)
require(foreach)
# clusterN <- 2
clusterN <-  min(length(simID), floor(0.5*detectCores()))  ### choose number of nodes to add to cluster.
#######
cl = makeCluster(clusterN, outfile = "") ##
registerDoSNOW(cl)
#######
outputSummary <- foreach(i = c(1:2,4)) %dopar% {#seq_along(simID)) %dopar% {
    require(RSQLite)
    require(dbplyr)
    require(dplyr)
    require(doSNOW)
    
    sDir <- paste("../sims", simID[i], sep = "/")
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
        x <- poolSummarise(poolDim[k]) 
        return(x)
    }
    fluxes <- foreach(k = seq_along(fluxDim), .combine = "rbind") %do% {
        x <- fluxSummarise(fluxDim[k]) 
        return(x)
    }
    pools <- data.frame(simID = simID[i], pools) %>%
        arrange(pool_indicator_id)
    fluxes <- data.frame(simID = simID[i], fluxes) %>%
        arrange(indicator)
    
    return(list(pools = pools,
                fluxes  = fluxes))
}


### put all this into single data.frames (one for pools, one for fluxes)
pools <- do.call("rbind", lapply(outputSummary, function(x) x[["pools"]]))
fluxes <- do.call("rbind", lapply(outputSummary, function(x) x[["fluxes"]]))


require(ggplot2)
require(dplyr)
df <- pools %>%
    filter(year != 0)

png(filename= paste0("poolsSummary.png"),
    width = 12, height = 8, units = "in", res = 600, pointsize=10)

options(scipen=999)

ggplot(df, aes(x = year, y = totalC/totalArea,
               colour = simID, group = simID)) +
    facet_wrap(~name) +
    geom_line()
dev.off()


## remove year 0, (might want to deal with this )
df <- fluxes %>%
    filter(year != 0)

png(filename= paste0("fluxesSummary.png"),
    width = 12, height = 8, units = "in", res = 600, pointsize=10)


ggplot(df, aes(x = year, y = flux_tc/area,
               colour = simID, group = simID)) +
    theme_dark() +
    facet_wrap(~indicator) +
    geom_line() +
    geom_hline(yintercept = 0, linetype = 1,
               color = "grey75", size = 0.15)
dev.off()