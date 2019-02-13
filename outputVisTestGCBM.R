###################################################################
###################################################################
### GCBM output visualization
rm(list = ls())
simDir <- "D:/test"
wwd <- paste(simDir, Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)


###################################################################
###################################################################
require(raster)
require(doSNOW)
###################################################################
require(dbplyr)
require(RSQLite)
### good tutorial to query databases using dbplyr
## https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html
require(dplyr)
require(tidyr)


# ###################################################################
# ###################################################################
# #### connect to db
# compiledDB <- dbConnect(drv=RSQLite::SQLite(),
#                         dbname = paste(simDir,
#                                        "processed_output/compiled_gcbm_output.db",
#                                        sep = "/"))
# 
# #### source file and table list
# src_dbi(compiledDB)
# 
# #### querying using dplyr syntax
# pools <- tbl(compiledDB, "Pools")
# summary(as.data.frame(pools))
# 
# pool1 <- pools %>%
#     filter(poolID == 1) %>%
#     select(id, locationDimId, poolValue)
# 
# #######



outputFiles <- list.files(paste(simDir, "processed_output/spatial", sep ="/"))


pools <- c("AG_Biomass_C",
           "Dead_Organic_Matter_C",
           "Soil_C",
           "Total_Biomass_C",
           "Total_Ecosystem_C")


nClusters <- 10 ## 10 treads max with 32Gb of RAM
cl <- makeCluster(nClusters, outfile = "")
registerDoSNOW(cl)

X <- foreach(i = seq_along(pools), .combine = "rbind")  %dopar% {#
    require(raster)
    
    v <- pools[i]
    
    x <- paste(simDir, "processed_output/spatial",
               outputFiles[grep(v, outputFiles)], sep = "/")

    ## stacking rasters
    r <- stack(x)
    ## computing averages
    x <- apply(values(r), 2, mean, na.rm = T)
    lNames <- names(x)
    
    out <- data.frame(variable = v,
                      year = as.numeric(substr(lNames,
                                               nchar(lNames)-3, nchar(lNames))),
                      value = x)
    
    return(out)
}
stopCluster(cl)

df <- X %>%
    spread(variable, value) %>%
    mutate(BG_Biomass_C = Total_Biomass_C - AG_Biomass_C,
           test =  AG_Biomass_C + BG_Biomass_C + Dead_Organic_Matter_C) %>%
    select(year, AG_Biomass_C, BG_Biomass_C, Dead_Organic_Matter_C) %>%
    gather(key = variable, value = value,
           AG_Biomass_C, BG_Biomass_C, Dead_Organic_Matter_C)


require(ggplot2)

ggplot(df, aes(x = year, y = value,
               group = variable, fill = variable)) +
    stat_summary(fun.y="sum", geom="area", position="stack", col="black")
    #geom_line() 



