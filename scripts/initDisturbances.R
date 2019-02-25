################################################################################
################################################################################
##### 
##### Initiating disturbance history for GCBM simulations
##### Dominic Cyr
##### 
################################################################################
################################################################################

####
require(raster)
require(reshape2)
require(dplyr)
################################################################################
print("Fetching and formatting disturbance spatial data ...")
######## 

#######
distDir <- paste(rawDir, "disturbances", sep = "/")
dir.create(paste(rawDir, "disturbances", sep = "/"))


distFiles <- list.files(paste0(sourceDir, "/output"))

################################################################################
#### all included disturbances
###################################################################
fire <- get(load(paste0(sourceDir, "/output/outputFire_", replicates, ".RData")))
harv <- get(load(paste0(sourceDir, "/output/outputHarvest_", replicates, ".RData")))
salv <- get(load(paste0(sourceDir, "/output/outputSalvage_", replicates, ".RData")))
rho100 <- get(load(paste0(sourceDir, "/output/outputRho100_", replicates, ".RData")))
### reclassify rho100 based on dens_AT
rho100ReClass <- rho100
rho100ReClass[] <- as.numeric(cut(values(rho100), rho100CutOffs))

### for verifying reclassifcation
# foo <- data.frame(rho100 = values(rho100[[1]]),
#                   rho100ID = values(rho100ReClass[[1]]))
# foo <-  foo[complete.cases(foo),]
# foo[,"cls"] <- dens_AT[match(foo$rho100ID, dens_AT$ID),"cls_dens"]
# head(foo, 10)



index <- is.na(cls_sp)
fire[index] <- harv[index] <- salv[index] <- rho100[index] <- NA

for (l in 1:nlayers(fire)) {
    
    year <- yearInit + l
    
    ## clearcut harvesting
    cc <- harv[[l]]
    if(sum(values(cc), na.rm = T) > 0) {
        lName <- paste("cc", year, sep = "_")
        names(cc) <- lName
        writeRaster(cc, filename = paste0(distDir, "/", lName, ".tif"),
                    overwrite = TRUE)
    }
    
    ## wild fires
    s <- salv[[l]]
    if(sum(values(s), na.rm = T) > 0) {
        lName <- paste("salv", year, sep = "_")
        names(s) <- lName
        writeRaster(s, filename = paste0(distDir, "/", lName, ".tif"),
                    overwrite = TRUE)
    }
    
    ## wild fires
    f <- rho100ReClass[[l]]
    f[is.na(fire[[l]])] <- NA

    if(sum(values(f), na.rm = T) > 0) {
        lName <- paste("fire", year, sep = "_")
        names(f) <- lName
        writeRaster(f, filename = paste0(distDir, "/", lName, ".tif"),
                    overwrite = TRUE)
    }
}

fire_AT <- data.frame(ID = dens_AT$ID,
                      #name = "Post-fire regeneration density transition",
                      type = "absolute", ## “absolute”, “relative” , or "yield"
                      disturbanceType = "Wild Fire",
                      fertilityUpdate =  "?",
                      coverTypeUpdate = "?",
                      relDensityUpdate = dens_AT$ID)
write.csv(fire_AT, file = paste0(distDir, "/fire_AT.csv"), row.names = F)
################################################################################
####  last_pass_disturbance_type
###################################################################
origin <- raster(paste(sourceDir, "data/Inv/ORIGINE.tif", sep = "/"))
origin_AT <-  read.csv(paste(sourceDir, "data/Inv/ORIGINE_RAT.csv", sep = "/"))
    
origin_to_CbmDist <- c(BR = "Wild Fire", ## Brûlis total
                       CPA = "97% clearcut", ##
                       CHT = "generic 90% mortality", ## Chablis total
                       CPR = "97% clearcut", ## Coupe avec protection de la régénération
                       CRB = "Fire with salvage logging", ## Coupe de récupération dans un brûlis
                       CRR = "97% clearcut", ## ??? Récolte des tiges résiduelles et des rebuts
                       CT = "97% clearcut", ## Coupe totale
                       DT = "Wild Fire", ## Dépérissement total
                       ES = "Insect Disturbance", ## Épidémie grave
                       P = "97% clearcut", ## Plantation de semis cultivés (à racines nues ou en récipients) ou de boutures
                       PRR = "97% clearcut", ## ?? un type de plantation, après récup?
                       REA = "Wild Fire", ## Régénération d’une aire d’ébranchage
                       RPS = "Fire with salvage logging") ## Récupération en vertu d’un plan spécial d’aménagement
 
last_pass_disturbance_type_AT <- data.frame(ID = 1:length(unique(origin_to_CbmDist)),
                                            value = unique(origin_to_CbmDist))

## matching ORIGINE values with CBM disturbances types
x <- values(origin)
x <- origin_AT[match(x , origin_AT$ID), "value"]
x <- origin_to_CbmDist[match(as.character(x), names(origin_to_CbmDist))]

x <- last_pass_disturbance_type_AT[match(x, last_pass_disturbance_type_AT$value), "ID"]




## creating raster
last_pass_disturbance_type <- origin
last_pass_disturbance_type[] <- x
## default NA's to "Wild Fire"
last_pass_disturbance_type[is.na(last_pass_disturbance_type)] <-
    last_pass_disturbance_type_AT[which(last_pass_disturbance_type_AT$value == "Wild Fire"), "ID"]
last_pass_disturbance_type[is.na(coverTypes)] <- NA

## 
dir.create(paste(rawDir, "last_pass_disturbance", sep = "/"))
writeRaster(last_pass_disturbance_type,
            file = paste0(rawDir, "/last_pass_disturbance/last_pass_disturbance_type.tif"),
            overwrite = T)
write.csv(last_pass_disturbance_type_AT,
          file = paste0(rawDir, "/last_pass_disturbance/last_pass_disturbance_type_AT.csv"),
          row.names = F)

################################################################################
####  plotting
###################################################################
if(plotting) {
    
    ### 
    library(gridExtra)
    g_legend<-function(a.gplot){
        tmp <- ggplot_gtable(ggplot_build(a.gplot))
        leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
        legend <- tmp$grobs[[leg]]
        legend
    }
    
    require(RColorBrewer)
    
    cols = c("Productive forest" = "darkolivegreen",
             "Non-forested land type" = "grey",
             "Wild fire" = "red",
             "Fire with salvage logging" = "darkorange",
             "Clearcut harvesting" = "blue")
    eventLvl <- names(cols)
    
    
    # mask of all the study area 
    mask <- raster(paste(sourceDir, "data/DUMMY.tif", sep = "/"))
    mask[lakes] <- NA
    
    ### reload them to get full info
    fire <- get(load(paste0(sourceDir, "/output/outputFire_", replicates, ".RData")))
    harv <- get(load(paste0(sourceDir, "/output/outputHarvest_", replicates, ".RData")))
    salv <- get(load(paste0(sourceDir, "/output/outputSalvage_", replicates, ".RData")))
    
    fire[is.na(mask)] <- harv[is.na(mask)] <- salv[is.na(mask)] <- NA
    
    simYears <- seq(yearInit+1, yearInit + nlayers(fire))
    
    ### converting to data frame
    fire <- as.data.frame(rasterToPoints(fire))
    harv <- as.data.frame(rasterToPoints(harv))
    salv <- as.data.frame(rasterToPoints(salv))
    
    ## renaming columns
    #cNames <- paste0("y", simYears)
    colIndex <- 3:ncol(fire)
    colnames(fire)[colIndex] <- paste0("f", simYears)
    colnames(harv)[colIndex] <- paste0("c", simYears)
    colnames(salv)[colIndex] <- paste0("s", simYears)
    
    #### computing sum for each event type
    x <- fire[, colIndex]
    x[is.na(x)] <- 0
    fire[,colIndex] <- x
    fire[,"cumulFire"] <- apply(x, 1, sum)
    
    x <- harv[, colIndex]
    x[is.na(x)] <- 0
    harv[,colIndex] <- x
    harv[,"cumulHarv"] <- apply(x, 1, sum)
    
    x <- salv[, colIndex]
    x[is.na(x)] <- 0
    salv[,colIndex] <- x
    salv[,"cumulSalv"] <- apply(x, 1, sum)
    
    ## creating master data frame
    df <- rasterToPoints(mask)
    df <- df %>%
        merge(rasterToPoints(coverTypes), all = T) %>%
        merge(fire[,c("x", "y", "cumulFire")], all = T) %>%
        merge(harv[,c("x", "y", "cumulHarv")], all = T) %>%
        merge(salv[,c("x", "y", "cumulSalv")], all = T)
    
    
    
    
    df$ctInit <- apply(df, 1,
                   function(x) ifelse(is.na(x["coverTypes"]),
                                      "Non-forested land type",
                                      "Productive forest"))
    
    ## defining colors for cumulative figure
    colFire <- c(cols["Wild fire"], tail(brewer.pal(9, "YlOrRd"), 2))
    colHarv <- cols["Clearcut harvesting"]
    colSalv <- cols["Fire with salvage logging"]
    
    df[,"col"] <- cols[df$ctInit]
    cFire <- colFire[df$cumulFire]
    index <- !is.na(cFire)
    df[index, "col"] <- cFire[index]
    df$col <- apply(df, 1, function(x) ifelse(is.na(x["cumulHarv"]),
                                              x["col"],
                                              colHarv))
    df$col <- apply(df, 1, function(x) ifelse(is.na(x["cumulSalv"]),
                                              x["col"],
                                              colSalv))
    
    
    filenames <- character()
    for (y in seq_along(simYears)) {
        ########## also need to work out the cumulative color palettes
        ### reInitiate 'ct'
        df$ct <- df$ctInit
        
        year <- simYears[y]
        # adding fire
        eCol <- paste0("f", year)
        df <- df %>%
            merge(fire[,c("x", "y", eCol)], all = T)
        df[which(df[,eCol] == 0) ,eCol] <- NA
        df$ct <- apply(df, 1,
                       function(x) ifelse(!is.na(x[eCol]),
                                          "Wild fire",
                                          x["ct"]))
        df <- df[,-(which(colnames(df)==eCol))]
        
        # adding clearcut harvesting
        eCol <- paste0("c", year)
        df <- df %>%
            merge(harv[,c("x", "y", eCol)], all = T)
        df[which(df[,eCol] == 0) ,eCol] <- NA
        df$ct <- apply(df, 1,
                       function(x) ifelse(!is.na(x[eCol]),
                                          "Clearcut harvesting",
                                          x["ct"]))
        df <- df[,-(which(colnames(df)==eCol))]
        
        # adding salvage logging
        eCol <- paste0("s", year)
        df <- df %>%
            merge(salv[,c("x", "y", eCol)], all = T)
        df[which(df[,eCol] == 0) ,eCol] <- NA
        df$ct <- apply(df, 1,
                       function(x) ifelse(!is.na(x[eCol]),
                                          "Fire with salvage logging",
                                          x["ct"]))
        df <- df[,-(which(colnames(df)==eCol))]
        
        ## 
        df$ct <- factor(df$ct, levels = eventLvl)
        
        
        ### plotting 
        p <- ggplot(df, aes(x = x, y = y, fill = ct)) +
            geom_raster() +
            scale_fill_manual(name = "",
                              values = cols,
                              drop = F) +
            labs(title = "Disturbance history",
                 subtitle = paste("Year:", year),
                 x = "\nx (UTM 18)",
                 y = "y (UTM 18)\n") +
            theme(legend.position="top", legend.direction="horizontal")
        
        p <- p + theme(#legend.position="none",
            plot.title = element_text(size = rel(0.6)),
            plot.subtitle = element_text(size = rel(0.5)),
            axis.title.x = element_text(size = rel(0.5)),
            axis.title.y = element_text(size = rel(0.5)),
            axis.text.x = element_text(size = rel(0.5)),
            axis.text.y =  element_text(size = rel(0.5), angle = 90, hjust = 0.5),
            legend.title = element_text(size = rel(0.5)),
            legend.text = element_text(size = rel(0.4)),
            legend.key.size = unit(0.4, "cm"))
        
        if (y == 1) {
            legend <- g_legend(p)    
        }
        
        fName <-  paste0("./figures/disturbances_", year, ".png")
        
        png(filename = fName,
            width = pWidth, height = pHeight, units = "px", res = 300, pointsize = pointsize,
            bg = "white")
        
        #print(p)
            print(grid.arrange(p + theme(legend.position="none"), legend, 
                               ncol=1, nrow=2,
                               heights=c(7/8,1/8)))
              
        dev.off()
        
        filenames <- append(filenames, fName)

    }

        
    ###################################################################
    ### plotting cumulative figure
    cols <- unique(df$col)
    names(cols) <- cols
    
    p <- ggplot(df, aes(x = x, y = y, fill = col)) +
        geom_raster() +
        scale_fill_manual(name = "",
                           values = cols) +
        labs(title = "Disturbance history",
             subtitle = paste0("Entire sim. duration (",
                               yearInit, " - ", max(simYears), ")"),
             x = "\nx (UTM 18)",
             y = "y (UTM 18)\n") +
        theme(legend.position="top", legend.direction="horizontal")
    
    p <- p + theme(#legend.position="none",
        plot.title = element_text(size = rel(0.6)),
        plot.subtitle = element_text(size = rel(0.5)),
        axis.title.x = element_text(size = rel(0.5)),
        axis.title.y = element_text(size = rel(0.5)),
        axis.text.x = element_text(size = rel(0.5)),
        axis.text.y =  element_text(size = rel(0.5), angle = 90, hjust = 0.5),
        legend.title = element_text(size = rel(0.5)),
        legend.text = element_text(size = rel(0.4)),
        legend.key.size = unit(0.4, "cm"))
    
    
    fName <-  paste0("./figures/disturbances_cumul.png")
    
    png(filename = fName,
        width = pWidth, height = pHeight, units = "px", res = 300, pointsize = pointsize,
        bg = "white")
    
    #print(p)
    print(grid.arrange(p + theme(legend.position="none"), legend, 
                       ncol=1, nrow=2,
                       heights=c(7/8,1/8)))
    
    dev.off()
    filenames <- append(filenames, fName)
    
    
    ###################################################################
    ###################################################################
    ### plotting animated gif
    require(animation)
    oopt = ani.options(ani.dev="png", ani.type="png", interval = 0.5, autobrowse = FALSE)
    ### (Windows users may want to add):  ani.options(convert = 'c:/program files/imagemagick/convert.exe')
    im.convert(c(filenames, rep(filenames[length(filenames)], 10)),
               output = "./figures/disturbances_anim.gif",
               extra.opts = "", clean = F)
    file.rename("disturbances_anim.gif", "./figures/disturbances_anim.gif")
    
    dir.create("./figures/individualTimeSteps")
    file.rename(filenames[-length(filenames)],
                paste("./figures/individualTimeSteps",
                      basename(filenames[-length(filenames)]), sep = "/"))
}


