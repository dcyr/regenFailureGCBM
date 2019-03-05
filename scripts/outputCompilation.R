###################################################################
###################################################################
### GCBM output compilation
rm(list = ls())
simDir <- c("D:/GCBM_sims")
wwd <- paste(simDir, Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)
###
simID <- list.dirs("../sims", recursive = F, full.names = F)
simID <- simID[-grep("old", simID)]
simInfo <- read.csv("../sims/simInfo.csv", colClasses = c(simID = "character"))
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
outputSummary <- foreach(i = seq_along(simID)) %dopar% {
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
        x <- poolSummarise(poolDim[k], c(
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
    
    return(list(pools = pools,
                fluxes  = fluxes))
}
stopCluster(cl)

### put all this into single data.frames (one for pools, one for fluxes)
pools <- do.call("rbind", lapply(outputSummary, function(x) x[["pools"]]))
fluxes <- do.call("rbind", lapply(outputSummary, function(x) x[["fluxes"]]))


require(ggplot2)
require(dplyr)
# df <- pools %>%
#     filter(year != 0)
# 
# png(filename= paste0("poolsSummary.png"),
#     width = 12, height = 8, units = "in", res = 600, pointsize=10)
# 
# options(scipen=999)
# 
# ggplot(df, aes(x = year, y = totalC/totalArea,
#                colour = simID, group = simID)) +
#     facet_wrap(~name) +
#     geom_line()
# dev.off()


df <- fluxes %>%
    filter(year != 0) %>%#,
    #simID %in% c("test_extreme", "test_extreme_wTransition")) %>%
    group_by(simID, indicator, year) %>%
    summarise(flux_tc = sum(flux_tc),
              area = sum(area)) %>%
    merge(simInfo) %>%
    group_by(year, indicator, regenFailure) %>%
    summarize(tonnesPerHaPerYr = mean(flux_tc/area))


png(filename= paste0("fluxesSummary.png"),
    width = 12, height = 8, units = "in", res = 600, pointsize=10)


ggplot(df, aes(x = year, y = tonnesPerHaPerYr,
               colour = regenFailure, group = regenFailure)) +
    theme_dark() +
    facet_wrap(~indicator) +
    scale_color_manual(values = c("steelblue1", "firebrick1")) +
    geom_line() +
    geom_hline(yintercept = 0, linetype = 1,
               color = "grey75", size = 0.15)
dev.off()



################## exploring individual fluxes
df <- fluxes %>%
    filter(year != 0,
           #age_range == "0-19",
           indicator == "NPP"#,
           #simID %in% c("test_wLastPassDist", "test_wTransitions")
           ) %>%
    group_by(simID, year) %>%
    summarise(flux_tc = sum(flux_tc),
              area = sum(area)) %>%
    merge(simInfo) %>%
    group_by(year, regenFailure) %>%
    summarize(tonnesPerHaPerYr = mean(flux_tc/area))


ggplot(df, aes(x = year, y = tonnesPerHaPerYr,
               colour = regenFailure)) +
    theme_dark() +
    #facet_wrap( ~ age_range) +
    geom_line(size = 0.5) +
    scale_color_manual(values = c("steelblue1", "firebrick1")) +
    geom_hline(yintercept = 0, linetype = 1,
               color = "grey75", size = 0.15)


