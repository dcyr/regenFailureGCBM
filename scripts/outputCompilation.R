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
#require(raster)
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






###################################################################
#### create summarized data.frame with pools,
#### by time step, cover type, fertility class, and density class

#### should possibly store info about last disturbances


foo <- list()
for (i in r_pool_indicators$id) {
    
    ### identifying a subset of pools
    poolIndex <- r_pool_indicators %>%
        filter(id == i) %>%
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
    
    ### selecting a subset of pools
    x <-  filter(Pools, poolId %in% poolIndex$pool_id)
    
    ### summarizing the indicator.... by classifier and time steps
    ### (and age class?) ### see what happen with anthropogenic class
    
    DateDimension
    LocationDimension
    ClassifierSetDimension
    
    ### give proper names
    
    
    ##########################
    ### do the same thing for fluxes
    r_flux_indicators
    r_flux_indicator_collections
    r_flux_indicator_collection_flux_indicators
    

    foo <- merge(Pools, poolIndex)
    
    ,
                 by.x)
    
    
    head(Pools)
     %>%
        merge(r_pool_collections)
    r_pool_collections
    poolID_subset <- 
    
    x <- Pools %>%
        
    
    PoolDimension
    r_pool_collections
    r_pool_collection_pools
    
}


foo <- Pools %>%
    
    
    poolCol_GPG_subset <- c("Aboveground Biomass",
                                 "Belowground Biomass",
                                 "Deadwood",
                                 "Litter",
                                 "Soil Carbon")

pool_indicator_subset <- match(poolCol_GPG_subset)

r_pool_collections
r_pool_collection_pools
r_pool_indicators


poolId_Subset <- 

poolsSubset <- 

    poolId

foo <- Pools %>%
    merge(filter )
r_pool_collections_subset
r_pool_collection_pools

                 
                 
                 
                 
                         
                         "HardwoodCoarseRoots",
                         "HardwoodCoarseRoots",
                         )
                         "HardwoodMerch",
                         "HardwoodMerch",
                         "HardwoodMerch",
                         "HardwoodMerch",
                         
                         
                         
                               )
    DOM = c("AboveGroundFastSoil",
                               "AboveGroundSlowSoil",
                               "AboveGroundVeryFastSoil",
                               "BelowGroundFastSoil",
                               "BelowGroundSlowSoil",
                               "BelowGroundVeryFastSoil",
                               "DissolvedOrganicCarbon",
                               
                               
                               
                    "HardwoodBranchSnag",
                    "AboveGroundSlowSoil",
                    "AboveGroundSlowSoil",
                    "AboveGroundSlowSoil",
                    
                    
                    

2   2     AboveGroundSlowSoil
3   3 AboveGroundVeryFastSoil

quantile(Pools$poolValue, c(0, 0.00001, 0.001, 0.01, 0.02,
                  0.95, 0.99, 0.999, 0.99999, 1))


#### Dimension tables
PoolDimension <- as.data.frame(tbl(compiledDB, "PoolDimension"))
LocationDimension <- as.data.frame(tbl(compiledDB, "LocationDimension")) # contains area (in ha)
LandClassDimension <- as.data.frame(tbl(compiledDB, "LandClassDimension")) ## ex. "UNFCCC_FL_R_FL"
ClassifierSetDimension <- as.data.frame(tbl(compiledDB, "ClassifierSetDimension"))
ModuleInfoDimension <- as.data.frame(tbl(compiledDB, "ClassifierSetDimension"))
moduleInfoDimId





poolsEcosystem <- 

#### Pool values 
Pools <- as.data.frame(tbl(compiledDB, "Pools"))
Fluxes <- as.data.frame(tbl(compiledDB, "Fluxes"))
LandClassDimension

as.data.frame(PoolDimension)
df <- ClassifierSetDimension 
head(df)
unique(df$classifierSetDimId)


summary(as.data.frame(pools))

pool1 <- pools %>%
    filter(poolID == 1) %>%
    select(id, locationDimId, poolValue)

#######



outputFiles <- list.files(paste(simDir, "processed_output/spatial", sep ="/"))

###################################################################
###################################################################
### visualizing pools 
pools <- c("AG_Biomass_C",
           "Dead_Organic_Matter_C",
           "Soil_C",
           "Total_Biomass_C",
           "Total_Ecosystem_C")
###################################################################

nClusters <- min(10, length(pools)) ## 10 treads max with 32Gb of RAM
cl <- makeCluster(nClusters, outfile = "")
registerDoSNOW(cl)

x <- foreach(i = seq_along(pools), .combine = "rbind")  %dopar% {#
    require(raster)
    
    v <- pools[i]
    
    out <- paste(simDir, "processed_output/spatial",
               outputFiles[grep(v, outputFiles)], sep = "/")

    ## stacking rasters
    r <- stack(out)
    ## computing averages
    out <- apply(values(r), 2, mean, na.rm = T)
    lNames <- names(out)
    
    out <- data.frame(variable = v,
                      year = as.numeric(substr(lNames,
                                               nchar(lNames)-3, nchar(lNames))),
                      value = out)
    
    return(out)
}
stopCluster(cl)

### summarizing and tidying up
df <- x %>%
    spread(variable, value) %>%
    mutate(BG_Biomass_C = Total_Biomass_C - AG_Biomass_C,
           test =  AG_Biomass_C + BG_Biomass_C + Dead_Organic_Matter_C) %>%
    select(year, AG_Biomass_C, BG_Biomass_C, Dead_Organic_Matter_C) %>%
    gather(key = variable, value = value,
           AG_Biomass_C, BG_Biomass_C, Dead_Organic_Matter_C)

df$variable <- factor(df$variable,
                      levels = c("AG_Biomass_C", "BG_Biomass_C", "Dead_Organic_Matter_C"))


### plotting 
require(ggplot2)

p <- ggplot(df, aes(x = year, y = value,
                    group = variable, fill = variable)) +
    stat_summary(fun.y="sum", geom="area", position="stack", col="black")
    geom_line() 



