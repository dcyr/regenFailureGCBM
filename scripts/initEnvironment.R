################################################################################
################################################################################
##### 
##### Initiating environment spatial data for GCBM simulations
##### Dominic Cyr
##### 
################################################################################
################################################################################

####
require(raster)
print('Creating environmental spatial data ...')
################################################################################
### creating 'layers' folder
dir.create(paste(layerDir, "environment", sep = "/"))

################################################################################
#### mean annual temperature
#### (could be a sequence of raster)
######## 
print("Fetching and formatting mean annual temperature ...")
# fetching and formatting data
r <- getData('worldclim', var='bio', res=2.5)
r <- projectRaster(r[["bio1"]], studyArea, method = 'ngb')
r <- round(r, 2)
tMean <- r/10
#tMean[is.na(studyArea)] <- NA
#### exporting raster
filename <- paste(".", layerDir, "environment/tempAnnualMean_C.tif", sep = "/")
writeRaster(tMean, filename, overwrite = T)
print(paste0("file '", filename, "' created"))


### optional plotting of initial conditions
if(plotting) {

    ### mean annual temperature
    r <- tMean
    r[lakes] <- NA
    df <- as.data.frame(rasterToPoints(r))
    cutRes <- diff(range(df$layer))/9
    cutRes <- ceiling(cutRes/.05)*.05
    zCuts <- seq(floor(min(df$layer)/cutRes)*cutRes,
                 ceiling(max(df$layer)/cutRes)*cutRes,
                 cutRes)
    p <- ggplot(data = df, aes(x, y, fill = layer)) +
        #theme_dark() +
        geom_raster(aes(fill = cut(layer, zCuts))) +
        coord_fixed() +
        scale_fill_brewer(name = expression(~degree~C),
                          palette = "RdBu",
                          direction = -1,# drop = FALSE,
                          na.value = "grey") +
        geom_polygon(aes(x = long, y = lat, group = group), data = studyAreaF,
                     colour = 'black', fill = NA, size = 0.5) +
        labs(title = "Mean annual temperature",
            x = "\nx (UTM 18)",
             y = "y (UTM 18)\n")
    
    filename <- "./figures/tempAnnualMean_C.png"
    png(filename = filename,
        width = pWidth, height = pHeight*.8, units = "px", res = 300, pointsize = pointsize,
        bg = "white")
    
    print(p + #guide_legend(nrow=2,byrow=TRUE) +
              theme(plot.title = element_text(size = rel(0.6)),
                    axis.title.x = element_text(size = rel(0.5)),
                    axis.title.y = element_text(size = rel(0.5)),
                    axis.text.x = element_text(size = rel(0.5)),
                    axis.text.y =  element_text(size = rel(0.5), angle = 90, hjust = 0.5),
                    legend.title = element_text(size = rel(0.5)),
                    legend.text = element_text(size = rel(0.5))) #+
              #guides(fill=guide_legend(nrow=2,byrow=TRUE))
    )
    dev.off()
    
    print(paste0("file '", filename, "' created"))
}