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
print("Fetching and formatting forest inventory spatial data ...")

#######
dir.create(paste(layerDir, "inventory", sep = "/"))

################################################################################
#### initial age
######## 
ageInit <- raster(paste(sourceDir, "tsd.tif", sep = "/"))
ageInit[ageInit>ageMax] <- ageMax
#### exporting raster
filename <- paste(".", layerDir, "inventory/ageInit.tif", sep = "/")
writeRaster(ageInit, filename, overwrite = T)
print(paste0("file '", filename, "' created"))

################################################################################
#### coverType
######## 
coverTypes <-  raster(paste(sourceDir, "coverTypes.tif", sep = "/"))
coverTypes_RAT <- read.csv(paste(sourceDir, "coverTypes_RAT.csv", sep = "/"))
# adding CBM spp names
coverTypes_RAT$AIDBSPP <- c(EN = "Black spruce",
                            PG = "Jack pine")[as.character(coverTypes_RAT[,"value"])]
#### file is exported later (some cleanup has to be done first)

################################################################################
#### creating classifiers and assigning yield curves
########
print("Creating classifier layers...")
# fetching initial rho100
rho100 <- raster(paste(sourceDir, "IDR100.tif", sep = "/"))
rho100[rho100>1] <- 1
# fetching site index
siteIndex <- raster(paste(sourceDir, "iqs.tif", sep = "/"))
siteIndex[siteIndex<5] <- NA ## mainly site index == 0, consider them non-forested
# compiling relative density at 100 y-old species and subzones
df <- data.frame(sp = values(coverTypes),
                 rho100 = values(rho100),
                 siteIndex = values(siteIndex),
                 AIDBSPP = coverTypes_RAT[match(values(coverTypes), coverTypes_RAT$ID),
                                          "AIDBSPP"])
# keeping only complete cases
index <- which(complete.cases(df))
df <- df[index,]
# #### volume at 120 years-old (optional)
# df[,"ageAt1m"] <- tFnc(sp = coverTypes_RAT[match(df$sp, coverTypes_RAT$ID), "value"],
#               iqs = df$siteIndex,
#               tCoef = tCoef)
# df[, "volAt120"] <- VFnc(sp = coverTypes_RAT[match(df$sp, coverTypes_RAT$ID), "value"],
#                          iqs = df$siteIndex,
#                          Ac = 120 - df$ageAt1m,
#                          rho100 = df$rho100,
#                          HdCoef = HdCoef, GCoef = GCoef, DqCoef = DqCoef, VCoef = VCoef,
#                          rho100Coef = rho100Coef, merchantable = T,
#                          scenesCoef = NULL, withSenescence = F)
# #cap volAt120 to 150 cubic-meters per ha
# vAt120Max <- 150
# df[which(df$volAt120 > vAt120Max), "volAt120"] <- vAt120Max


####  fertility classifier
siteIndexCutOffs <- seq(floor(min(df$siteIndex)/.5)*.5,
                        ceiling(max(df$siteIndex)/.5)*.5,
                        siteIndexInt)
SiteIndexMidPts <- siteIndexCutOffs[-length(siteIndexCutOffs)] +
    (diff(siteIndexCutOffs)/2)
df[,"cls_fert"] <-  cut(df$siteIndex, siteIndexCutOffs)

####  density classifier
rho100CutOffs <- c(0, round(quantile(df$rho100, seq(r100Int, 1, r100Int)),2))
rho100MidPts <- rho100CutOffs[-length(rho100CutOffs)] + (diff(rho100CutOffs)/2)
df[,"cls_dens"] <- cut(df$rho100, rho100CutOffs)

####  creating classifier atttribute tables (for future reference)
fert_AT <- data.frame(ID = 1:length(levels(df$cls_fert)),
                      cls_fert = levels(df$cls_fert),
                      value = SiteIndexMidPts)
dens_AT <- data.frame(ID = 1:length(levels(df$cls_dens)),
                      cls_dens = levels(df$cls_dens),
                      value = rho100MidPts)

#### creating rasters
# volAt120 (for reference and visualization purposes)
cls_sp <- cls_fert <- cls_dens <- studyArea
cls_sp[] <- cls_fert[] <- cls_dens[] <-  NA
cls_sp[index] <- df$sp
names(cls_sp) <- "cls_sp"
cls_fert[index] <- as.numeric(df$cls_fert)
names(cls_fert) <- "cls_fert"
cls_dens[index] <- as.numeric(df$cls_dens)
names(cls_dens) <- "cls_dens"
#
filename <- paste(".", layerDir, "inventory/coverTypes.tif", sep = "/")
writeRaster(cls_sp, paste(layerDir, "Inventory/coverTypes.tif", sep = "/"), overwrite = T)
print(paste0("file '", filename, "' created"))
#
filename <- paste(".", layerDir, "inventory/fertility.tif", sep = "/")
writeRaster(cls_fert, paste(layerDir, "Inventory/fertility.tif", sep = "/"), overwrite = T)
print(paste0("file '", filename, "' created"))
#
filename <- paste(".", layerDir, "inventory/relDensity.tif", sep = "/")
writeRaster(cls_dens, paste(layerDir, "Inventory/relDensity.tif", sep = "/"), overwrite = T)
print(paste0("file '", filename, "' created"))



# fetching Pothier-Savard models and associated parameters
print('Creating yield curves ...')
psDir <- "C:/Users/cyrdo/Sync/Travail/ECCC/regenFailureRiskAssessment_phase2/data/Pothier-Savard"
file.copy(paste(psDir), ".", recursive=TRUE)
psDir <- strsplit(psDir, "/")[[1]]
psDir <- tail(psDir,1)
source(paste(psDir, "Pothier-Savard.R", sep = "/"))

#### creating yield curves
ageSeq <- seq(0, ageMax, 5)
i <- 1
for (s in unique(df$sp)) {
    for (f in fert_AT$ID) {
        for (d in dens_AT$ID) {
            spName <- coverTypes_RAT[match(s, coverTypes_RAT$ID), "value"]
            AIDBSPP <- coverTypes_RAT[match(s, coverTypes_RAT$ID), "AIDBSPP"]
            iqs <- fert_AT[match(f, fert_AT$ID), "value"] 
            r100 <-  dens_AT[match(d, dens_AT$ID), "value"]
            Ac <- ageSeq - tFnc(sp = spName,
                                 iqs = iqs,
                                 tCoef)
            volMerch <- VFnc(sp = spName,
                             iqs = iqs,
                             Ac = Ac,
                             rho100 = r100,
                             HdCoef = HdCoef, GCoef = GCoef, DqCoef = DqCoef, VCoef = VCoef,
                             rho100Coef = rho100Coef, merchantable = T,
                             scenesCoef = NULL, withSenescence = F)
            volMerch[is.na(volMerch)] <- 0
            volMerch <- round(volMerch, 1)
            names(volMerch) <- as.character(ageSeq)
            
            yCurve <- data.frame(coverType = s,
                                 fertility = f,
                                 relDensity = d,
                                 AIDBSPP = AIDBSPP,
                                 t(volMerch))
                       
            if(i == 1) {
                yieldCurves <- yCurve
            } else {
                yieldCurves <- rbind(yieldCurves, yCurve)
            }
            i <- i + 1
        }
    }    
}

#### creating yield tables
# first, writing column names
inputDbDir <- "input_database"
dir.create(inputDbDir)
fileName <- paste(inputDbDir, "yield.csv", sep = "/")
sink(fileName)
cat(paste(gsub("X", "Age", colnames(yieldCurves)) , collapse=","))
cat("\n")
sink()
## appending yield curves
write.table(yieldCurves, file=fileName,
            append=TRUE, row.names=FALSE, col.names=FALSE, sep=",",
            #quote=FALSE,
            #eol = "\r\n" #will produce Windows' line endings on a Unix-alike OS
            eol = "\n" #default line endings on windows system.
)

if(plotting) {
    require(RColorBrewer)
    
    # mask of all the study area 
    mask <- raster(paste(sourceDir, "data/DUMMY.tif", sep = "/"))
    mask[lakes] <- NA
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


