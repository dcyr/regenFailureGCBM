################################################################################
################################################################################
##### 
##### Initiating forest inventory spatial data for GCBM simulations
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
distDir <- paste(layerDir, "disturbances", sep = "/")
dir.create(paste(layerDir, "disturbances", sep = "/"))


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


getwd()
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
    
    
    #firePal <- brewer.pal(9, "YlOrRd")
    
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
    fire <- rasterToPoints(fire)
    harv <- rasterToPoints(harv)
    salv <- rasterToPoints(salv)
    
    ## renaming columns
    #cNames <- paste0("y", simYears)
    colnames(fire)[3:ncol(fire)] <- paste0("f", simYears)
    colnames(harv)[3:ncol(harv)] <- paste0("c", simYears)
    colnames(salv)[3:ncol(salv)] <- paste0("s", simYears)

    ## creating master data frame
        
    
        
    df <- rasterToPoints(mask)
    df <- df %>%
        merge(rasterToPoints(coverTypes), all = T)
    
    df$ct <- apply(df, 1,
                   function(x) ifelse(is.na(x["coverTypes"]),
                                      "Non-forested land type",
                                      "Productive forest"))
    
    
    filenames <- character()
    for (y in seq_along(simYears)) {
        year <- simYears[y]
        # adding fire
        eCol <- paste0("f", year)
        df <- df %>%
            merge(fire[,c("x", "y", eCol)], all = T)
        df$ct <- apply(df, 1,
                       function(x) ifelse(!is.na(x[eCol]),
                                          "Wild fire",
                                          x["ct"]))
        # adding clearcut harvesting
        eCol <- paste0("c", year)
        df <- df %>%
            merge(harv[,c("x", "y", eCol)], all = T)
        df$ct <- apply(df, 1,
                       function(x) ifelse(!is.na(x[eCol]),
                                          "Clearcut harvesting",
                                          x["ct"]))
        # adding salvage logging
        eCol <- paste0("s", year)
        df <- df %>%
            merge(salv[,c("x", "y", eCol)], all = T)
        df$ct <- apply(df, 1,
                       function(x) ifelse(!is.na(x[eCol]),
                                          "Fire with salvage logging",
                                          x["ct"]))
        
        ## 
        df$ct <- factor(df$ct, levels = eventLvl)
        
        
        ### plotting 
        p <- ggplot(df, aes(x = x, y = y, fill = ct)) +
            geom_raster() +
            scale_fill_manual(name = "",
                              values = cols) +
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
                               ncol=1, nrow=2, heights=c(7/8,1/8)))
              
        dev.off()

        
        filenames <- append(filenames, fName)
    
    }
    
    
    df <- rasterToPoints(mask)
    
    # adding covertypes
    df <- merge(df, as.data.frame(rasterToPoints(coverTypes)), all = T)
    df <- merge(df, as.data.frame(rasterToPoints(cls_sp)), all = T)
    # adding site index 
    df <- merge(df, as.data.frame(rasterToPoints(cls_fert)), all = T)
    # adding relative density
    df <- merge(df, as.data.frame(rasterToPoints(cls_dens)), all = T)
    
    
    
    # renaming cover types for nicer plotting
    df[, "ct"] <- coverTypes_RAT[match(df$cls_sp, coverTypes_RAT$ID), "AIDBSPP"]
    # other forested land types
    index <- which(is.na(df$ct) &
                       !is.na(df$coverTypes))
    df[index, "ct"] <- "Other productive stand types"
    df[is.na(df$ct), "ct"] <- "Non-forested land types"
    cols = c("Black spruce" = "darkolivegreen",
             "Jack pine" = "gold2",
             "Other productive stand types" = "darkolivegreen1",
             "Non-forested land types" = "grey")
    df$ct <- factor(df$ct, levels = names(cols))
    
    # renaming site index (and reordering levels) for nicer plotting 
    df[,"siteIndex"] <- factor(fert_AT[match(df$cls_fert, fert_AT$ID), "cls_fert"],
                               levels = as.character(fert_AT$cls_fert))
    # renaming relative density (and reordering levels) for nicer plotting                   
    df[,"rho100"] <- factor(dens_AT[match(df$cls_dens, dens_AT$ID), "cls_dens"],
                            levels = as.character(dens_AT$cls_dens))
    
    
    
    
    ###############################
    ### plotting land types
    cols = c("Black spruce" = "darkolivegreen",
             "Jack pine" = "gold2",
             "Other productive stand types" = "darkolivegreen1",
             "Non-forested land types" = "grey")
    
    p <- ggplot(data = df, aes(x, y, fill = ct)) +
        #theme_dark() +
        geom_raster() +
        coord_fixed() +
        scale_fill_manual(name = "",
                          values = cols,
                          na.value = "dodgerblue1") +
        labs(title = "Land types",
             subtitle = "Initial conditions",
             x = "\nx (UTM 18)",
             y = "y (UTM 18)\n") +
        theme(legend.position="top", legend.direction="horizontal")
    
    filename <- "./figures/initCoverTypes.png"
    png(filename = filename,
        width = pWidth, height = pHeight, units = "px", res = 300, pointsize = pointsize,
        bg = "white")
    
    print(p + theme(plot.title = element_text(size = rel(0.6)),
                    plot.subtitle = element_text(size = rel(0.5)),
                    axis.title.x = element_text(size = rel(0.5)),
                    axis.title.y = element_text(size = rel(0.5)),
                    axis.text.x = element_text(size = rel(0.5)),
                    axis.text.y =  element_text(size = rel(0.5), angle = 90, hjust = 0.5),
                    legend.title = element_text(size = rel(0.5)),
                    legend.text = element_text(size = rel(0.5)))
          
    )
    dev.off()
    
    
    ###############################
    ### plotting site index
    
    dfTmp <- df[complete.cases(df),]
    cols <- tail(rev(heat_hcl(n = length(unique(dfTmp$rho100))+1,
                              c = c(80, 30),
                              l = c(30, 90),
                              power = c(1/3, 1.5))),
                 length(unique(dfTmp$rho100)))
    # cols <- brewer.pal(n = length(unique(dfTmp$cls_fert)),
    #                               name = "YlOrBr")
    #tail(brewer.pal(n = 9, name = "YlOrRd"), length(unique(dfTmp$cls_fert)))
    
    p <- ggplot(data = dfTmp, aes(x, y, fill = siteIndex)) +
        #theme_dark() +
        geom_raster() +
        coord_fixed() +
        scale_fill_manual(name = "Site index\n(height at 50 y. old)",
                          values = cols,
                          na.value = "dodgerblue1") +
        labs(title = "Site index",
             subtitle = "Initial conditions",
             x = "\nx (UTM 18)",
             y = "y (UTM 18)\n")  +
        guides(fill = guide_legend(reverse=T))
    #theme(legend.position="top", legend.direction="horizontal")
    
    filename <- "./figures/initSiteIndex.png"
    png(filename = filename,
        width = pWidth, height = pHeight*.8, units = "px", res = 300, pointsize = pointsize,
        bg = "white")
    
    
    print(p + theme(plot.title = element_text(size = rel(0.6)),
                    plot.subtitle = element_text(size = rel(0.5)),
                    axis.title.x = element_text(size = rel(0.5)),
                    axis.title.y = element_text(size = rel(0.5)),
                    axis.text.x = element_text(size = rel(0.5)),
                    axis.text.y =  element_text(size = rel(0.5), angle = 90, hjust = 0.5),
                    legend.title = element_text(size = rel(0.5)),
                    legend.text = element_text(size = rel(0.5)))
    )
    dev.off()
    
    ###############################
    ### plotting relative density at 100 years old
    
    dfTmp <- df[complete.cases(df),]
    cols <- tail(rev(terrain_hcl(n = 12,
                                 c = c(65, 0),
                                 l = c(45, 95),
                                 power = c(1/3, 1.5))),
                 length(unique(dfTmp$rho100)))
    # cols <- brewer.pal(n = length(unique(dfTmp$rho100)),
    #                    name = "YlGn")
    
    p <- ggplot(data = dfTmp, aes(x, y, fill = rho100)) +
        #theme_dark() +
        geom_raster() +
        coord_fixed() +
        scale_fill_manual(name = "Rel. density\nat 100 y. old",
                          values = cols,
                          na.value = "dodgerblue1") +
        labs(title = "Relative density",
             subtitle = "Initial conditions",
             x = "\nx (UTM 18)",
             y = "y (UTM 18)\n") +
        guides(fill = guide_legend(reverse=T))
    #theme(legend.position="rigth", legend.direction="vertical")
    
    filename <- "./figures/initRelDens.png"
    png(filename = filename,
        width = pWidth, height = pHeight*.8, units = "px", res = 300, pointsize = pointsize,
        bg = "white")
    
    print(p + theme(plot.title = element_text(size = rel(0.6)),
                    plot.subtitle = element_text(size = rel(0.5)),
                    axis.title.x = element_text(size = rel(0.5)),
                    axis.title.y = element_text(size = rel(0.5)),
                    axis.text.x = element_text(size = rel(0.5)),
                    axis.text.y =  element_text(size = rel(0.5), angle = 90, hjust = 0.5),
                    legend.title = element_text(size = rel(0.5)),
                    legend.text = element_text(size = rel(0.5)))
          
    )
    dev.off()
    
    
    
}

### creating summary tables (freq and props)
dfSummary <- df %>%
    filter(ct %in% c("Jack pine", "Black spruce")) %>%
    group_by(ct, siteIndex, rho100) %>%
    summarise(freq = n()) %>%
    ungroup() %>%
    mutate(prop = freq/sum(freq),
           relDensity = rho100)

#### plotting (optional)
# converting to tall format
yCurves <- melt(yieldCurves, id.vars = c("coverType", "AIDBSPP", "fertility", "relDensity"),
                variable.name = "age",
                value.name = "volMerch_cubicMeterPerHa")
yCurves$age <- as.numeric(gsub("X", "", yCurves$age))
#yCurve$coverType <- coverTypes_RAT[match(yCurve$coverType, coverTypes_RAT$ID), "value"]
# reordering levels for nicer plotting
prefix <- "Site index ="
yCurves$siteIndex <- paste(prefix, fert_AT[match(yCurves$fertility, fert_AT$ID), "value"])
lvl <- unique(yCurves$siteIndex)
lvl <- lvl[order(as.numeric(gsub(prefix, "", lvl)))]
yCurves$siteIndex <- factor(yCurves$siteIndex, levels = lvl)
# renaming levels in summary table
dfSummary$siteIndex <- paste(prefix,
                             fert_AT[match(dfSummary$siteIndex, fert_AT$cls_fert), "value"])
dfSummary$siteIndex <- factor(dfSummary$siteIndex, levels = lvl)
#
prefix <- "rho100 ="
yCurves$relDensity <- paste(prefix, dens_AT[match(yCurves$relDensity, dens_AT$ID), "value"])
lvl <- unique(yCurves$relDensity)
lvl <- lvl[order(as.numeric(gsub(prefix, "", lvl)))]
yCurves$relDensity <- factor(yCurves$relDensity, levels = lvl)
# renaming levels in summary table
dfSummary$relDensity <-  paste(prefix,
                               dens_AT[match(dfSummary$relDensity, dens_AT$cls_dens), "value"])

dfSummary$relDensity <- factor(dfSummary$relDensity, levels = lvl)
dfSummBS <- filter(dfSummary, ct == "Black spruce")
dfSummJP <- filter(dfSummary, ct == "Jack pine")
dfSummary <- dfSummary %>%
    group_by(relDensity, siteIndex) %>%
    summarise(prop = sum(prop, na.rm = T),
              propCls = cut(100*prop, c(0,0.1, 1, 3, 100))) %>%
    mutate(propCls = factor(paste(propCls, "%"),
                            levels = c("(0,0.1] %", "(0.1,1] %","(1,3] %", "(3,100] %")))


# plotting

yMax <- max(yCurves$volMerch_cubicMeterPerHa)

cols <- tail(brewer.pal(n = length(unique(dfSummary$propCls)) + 1, name = "YlOrBr"),
             length(unique(dfSummary$propCls)))

p <- ggplot(yCurves, aes(x = age, y = volMerch_cubicMeterPerHa, group = AIDBSPP, colour = AIDBSPP)) +
    facet_grid(relDensity ~ siteIndex ) +
    geom_rect(data = dfSummary,inherit.aes = F,
              aes(fill = propCls),xmin = -Inf,xmax = Inf,
              ymin = -Inf, ymax = Inf, alpha = 0.3) +
    geom_line() +
    scale_colour_manual(name = "Stand type",
                        values = c("Black spruce" = "darkgreen",
                                   "Jack pine" = "chocolate4") ) +
    scale_fill_manual(name = "Rel. freq.",
                      values = cols) +  
    # values = c("(0,0.1] %" = "grey90",
    #            "(0.1,0.5] %" = "grey75",
    #            "(0.5,2] %" = "grey50",
    #            "(2,100] %" = "grey25") ) +
    labs(title = paste("Yield curves"),
         y= expression(paste("Merchantable volume ", (m^3 %.% ha^-1), sep="")),
         x="/nAge",
         caption = "Yield curves based on Pothier-Savard (1998)") +
    
    geom_text(aes(x = 0, y = yMax, group = NULL,
                  #label = paste0("taux annuel médian: ", round(100*medianRate, 3), "%")),
                  label = paste0("N = ", freq, " (", round(100*prop, 2), "%)")),
              data = dfSummBS,
              hjust = 0, size = 1.75, fontface = 1, colour = "darkgreen") +
    geom_text(aes(x = 0, y = yMax*0.88, group = NULL,
                  #label = paste0("taux annuel médian: ", round(100*medianRate, 3), "%")),
                  label = paste0("N = ", freq, " (", round(100*prop, 2), "%)")),
              data = dfSummJP,
              hjust = 0, size = 1.75, fontface = 1, colour = "chocolate4") 


png(filename = paste0("figures/yieldCurves.png"),
    #width = 1800, height = (160*length(unique(df$species))+200), units = "px", pointsize = 16,
    width = (1*length(unique(yCurves$fertility))+1),
    height = (0.85*length(unique(yCurves$relDensity))+1),
    res = 300, units = "in", bg = "white")

print(p +
          theme(plot.caption = element_text(size = rel(0.8)),
                axis.text.x = element_text(size=8, angle = 45, hjust = 1),
                axis.text.y = element_text(size=8),
                strip.text.x = element_text(size=6),
                strip.text.y = element_text(size=6))
)

dev.off()


