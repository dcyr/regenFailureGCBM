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
#### mean annual temperature
#### (could be a sequence of raster)
######## 
print("Fetching and formatting disturbance spatial data ...")

#######
distDir <- paste(rawDir, "disturbances", sep = "/")
dir.create(paste(rawDir, "disturbances", sep = "/"))


distFiles <- list.files(paste0(sourceDir, "/output"))

################################################################################
#### fire
######## 
fire <- get(load(paste0(sourceDir, "/output/outputFire_", replicates, ".RData")))
harv <- get(load(paste0(sourceDir, "/output/outputHarvest_", replicates, ".RData")))
salv <- get(load(paste0(sourceDir, "/output/outputSalvage_", replicates, ".RData")))

index <- is.na(cls_sp)
fire[index] <- harv[index] <- salv[index] <- NA

for (l in 1:nlayers(fire)) {
    
    year <- yearInit + l
    
    ## wild fires
    r <- fire[[l]]
    if(sum(values(r), na.rm = T) > 0) {
        lName <- paste("fire", year, sep = "_")
        names(r) <- lName
        writeRaster(r, filename = paste0(distDir, "/", lName, ".tif"),
                    overwrite = TRUE)
    }
    
    ## clearcut harvesting
    r <- harv[[l]]
    if(sum(values(r), na.rm = T) > 0) {
        lName <- paste("cc", year, sep = "_")
        names(r) <- lName
        writeRaster(r, filename = paste0(distDir, "/", lName, ".tif"),
                    overwrite = TRUE)
    }
    
    ## wild fires
    r <- salv[[l]]
    if(sum(values(r), na.rm = T) > 0) {
        lName <- paste("salv", year, sep = "_")
        names(r) <- lName
        writeRaster(r, filename = paste0(distDir, "/", lName, ".tif"),
                    overwrite = TRUE)
    }
}


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







