###################################################################
###################################################################
### GCBM output compilation
rm(list = ls())
simDir <- "D:/test"
wwd <- paste(simDir, Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)

###################################################################
###################################################################
require(doSNOW)
###################################################################
require(dbplyr)
require(dplyr)
require(DBI)
require(RSQLite)
### good tutorial to query databases using dbplyr
## https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html
# require(dplyr)
# require(tidyr)

### see Kurz et al 2009 - Table 2
### GPG: Good Practice Guidance
poolCol_GPG_subset <- c("Aboveground Biomass",
                        "Belowground Biomass",
                        "Deadwood",
                        "Litter",
                        "Soil Carbon")

### load classifyer attribute tables
fert_AT <- read.csv("../classifiersAT/fert_AT.csv")
dens_AT <- read.csv("../classifiersAT/dens_AT.csv")
ct_AT <- read.csv("../classifiersAT/ct_AT.csv")


###################################################################
###################################################################
### some useful functions
###################################################################

#### a function that select the appropriate pools for a given indicator    
indicatorPoolSelect <- function(x) {## where 'x' is the name of the Indicator
    ## example: Total Ecosystem
    
    ### identifying a subset of pools
    poolIndex <- r_pool_indicators %>%
        filter(name == x) %>%
        merge(r_pool_collections,
              by.x = "pool_collection_id",
              by.y = "id") %>%
        merge(r_pool_collection_pools) %>%
        mutate(pool_indicator_id = id) %>%
        select(pool_indicator_id,
               name,
               pool_collection_id,
               description,
               pool_id)
    
    ## formatting outputs into a clean list
    x <- as.list(distinct(poolIndex[,1:4]))
    x[["pool_id"]] <- poolIndex$pool_id
    
    return(x)
}

## A function that filters pools of interest and summarize by location
## and gather relevant information
poolSummarise <- function(x,
                          groupingVar = c(
                              dateDim = T,
                              classifierSetDim = F,
                              landClassDim = F,
                              ageClassDim = F)
) {
    ## where x is the name of the Indicator
    ## and where other variable indicate
    ## whether or not we should use these
    ## variable for grouping
    ## extracting indicator info
    indInfo <- indicatorPoolSelect(x)
    
    ## filtering for pools of interest and summarizing by location
    x <- Pools %>%
        filter(poolId %in% indInfo$pool_id) %>%
        ## summaryizing by location (classifier and time steps, and age class?)
        group_by(locationDimId) %>%
        summarise(indicatorValue = sum(poolValue))
    
    x <- x %>%
        merge(LocationDimension,
              by.x = "locationDimId",
              by.y = "id")
    if (groupingVar["dateDim"]) {
        x <- x %>%
            merge(DateDimension[,c("id", "step", "year", "lengthOfStepInYears")],
                  by.x = "dateDimId",
                  by.y = "id") 
    }
    if (groupingVar["classifierSetDim"]) {
        x <- x %>%
            merge(ClassifierSetDimension,
                  by.x = "classifierSetDimId",
                  by.y = "id")
    }
    
    ## summarizing using selected grouping variables
    grVar <- names(groupingVar)[groupingVar]
    grVar <- paste0(grVar, "Id")
    ##
    x <- x %>%
        group_by(.dots=grVar) %>%
        summarize(totalArea = sum(area),
                  totalC = sum(indicatorValue))
    
    ### tidying up
    cNames <- colnames(x)
    
    if ("landClassDimId" %in% cNames) {
        x <- x %>%
            merge(LandClassDimension,
                  by.x = "landClassDimId",
                  by.y = "id") %>%
            arrange(name)
    }
    if ("ageClassDimId" %in% cNames) {
        x <- x %>%
            merge(AgeClassDimension,
                  by.x = "ageClassDimId",
                  by.y = "id") %>%
            arrange(startAge)
    }
    if ("classifierSetDimId" %in% cNames) {
        x <- x %>%
            merge(ClassifierSetDimension,
                  by.x = "classifierSetDimId",
                  by.y = "id") %>%
            arrange(coverType, relDensity, fertility)
    }
    if("dateDimId" %in% cNames) {
        x <- x %>%
            merge(DateDimension[,c("id", "step", "year", "lengthOfStepInYears")],
                  by.x = "dateDimId",
                  by.y = "id") %>%
            arrange(year)
    }
    
    x <- data.frame(as.data.frame(indInfo[1:4]),
                    x)
    
    return(x)
}

## A function that filters fluxes of interest and summarize by location
## and gather relevant information

fluxSummarise <- function(x, ## where x is a r_stock_changes
                          groupingVar = c(
                              dateDim = T,
                              classifierSetDim = F,
                              landClassDim = F,
                              ageClassDim = F)
) {
    ## where x is the name of the Indicator
    ## and where other variable indicate
    ## whether or not we should use these
    ## variable for grouping
    ## extracting indicator info

    x <- v_stock_change_indicators %>%
        filter(indicator == x)

    grVarExcl <- c("area", "flux_tc")

    if (!groupingVar[["ageClassDim"]]) {
        grVarExcl <- append(grVarExcl, "age_range")
    }
    if (!groupingVar[["landClassDim"]]) {
        grVarExcl <- append(grVarExcl, "unfccc_land_class")
    }
    if (!groupingVar[["classifierSetDim"]]) {
        grVarExcl <- append(grVarExcl, c(colnames(ClassifierSetDimension)[-1]))
    }
    if (!groupingVar[["dateDim"]]) {
        grVarExcl <- append(grVarExcl, "year")
    }


    colIndex <- which(colnames(x) %in% grVarExcl == F)

    x <- x %>%
        group_by(.dots = colnames(x)[colIndex]) %>%
        summarize(area = sum(area),
                  flux_tc = sum(flux_tc))
    return(x)
}

foo <- fluxSummarise("Total Harvest (Biomass + Snags)")
plot(foo$flux_tc)

###################################################################
###################################################################
#### connect to db
gcbmOutputDB <- dbConnect(drv=RSQLite::SQLite(),
                        dbname = paste(simDir,
                                       "processed_output/compiled_gcbm_output.db",
                                       sep = "/"))
###################################################################
#### list of tables
tableNames <- dbListTables(gcbmOutputDB)

###################################################################
#### load all tables (might need to prune a bit...)
for (i in seq_along(tableNames)) {
    x <- tableNames[i]
    assign(x, dbReadTable(gcbmOutputDB, x))
    print(paste0("table '", x, "' loaded"))
}
dbDisconnect(gcbmOutputDB)


# ###################################################################
# #### create summarized data.frame with pools,
# #### by time step, cover type, fertility class, and density class
# 
# poolSummary <- list()
# for (i in r_pool_indicators$id) {
#     
#     index <- which(r_pool_indicators$id == i)
#     x <- r_pool_indicators[index,"name"]
#     print(paste("summarizing pools for", x))
#     poolSummary[[i]] <- poolSummarise(x,
#                                       groupingVar = c(
#                                           dateDim = T,
#                                           classifierSetDim = F,
#                                           landClassDim = F,
#                                           ageClassDim = F))
#     print(paste("Done!"))
# }
# 
# poolSummary <- do.call("rbind", poolSummary)
# 
# 
# # ### quick plot
# require(ggplot2)
# 
# options(scipen=999)
# df <- filter(poolSummary, year >=2016)
# 
# 
# head(df)
# ggplot(df, aes(x = year, y = totalC/totalArea, group = name, color  = name)) +
#     geom_line()




require(raster)
r <- raster("../processed_output/spatial/AG_Biomass_C_2016.tiff")

plot(r)

