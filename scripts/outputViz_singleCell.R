###################################################################
###################################################################
### GCBM output compilation
rm(list = ls())
simDir <- c("D:/GCBM_sims/singlecellSims")
wwd <- paste(simDir, Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)
###

## copying useful functions to the wd
# mainDir <- "C:/Users/cyrdo/Sync/Travail/ECCC/regenFailureGCBM/"
# sourceDir <- "D:/regenFailureRiskAssessmentData_phase2/2019-01-07_coupe0.62_recup70_contrainteAge"
# file.copy(paste(mainDir, "scripts/outputCompilationFnc.R", sep = "/"),
#           ".", overwrite = T)

###

fluxes <- get(load("../outputsCompiled/fluxes.RData"))
pools <- get(load("../outputsCompiled/pools.RData"))
spatialOutputs <- get(load("../outputsCompiled/spatialOutputs.RData"))


require(ggplot2)
require(dplyr)

vars <- unique(spatialOutputs$variable)


siVal <- unique(spatialOutputs$siteIndex)
siLvls <- paste("Site index =", siVal)
ageInit <- unique(spatialOutputs$ageinit)
wfEvent <- unique(spatialOutputs$Wild.fire)
treatmentLvl <- c(singleCellSims_regenFailure = "with transitions",
                  singleCellSims_noRegenFailure = "no transitions")

spatialOutputs <- spatialOutputs %>%
    mutate(relDensity = paste("rho100 =", relDensity),
           siteIndex = factor(paste("Site index =", siteIndex),
                              levels = siLvls),
           simID = treatmentLvl[simID],
           group = paste(simID, coverTypes))



for (v in vars) {
    
    
    df <- spatialOutputs %>%
    filter(variable == v)
    
    p <- ggplot(df, aes(x = year, y = value,
                        colour = coverTypes,
                        linetype = simID)) +
        facet_grid(relDensity ~ siteIndex) +
        # geom_rect(data = dfSummary,inherit.aes = F,
        #           aes(fill = propCls),xmin = -Inf,xmax = Inf,
        #           ymin = -Inf, ymax = Inf, alpha = 0.3) +
       
        xlim(2135, 2195) +
        geom_vline(xintercept = wfEvent,
                   colour = "grey25", linetype = 3, size = 0.5) +
        # scale_fill_manual(name = "Rel. freq.",
        #                   values = cols) +  
        # values = c("(0,0.1] %" = "grey90",
        #            "(0.1,0.5] %" = "grey75",
        #            "(0.5,2] %" = "grey50",
        #            "(2,100] %" = "grey25") ) +
        
        geom_line() +
        scale_colour_manual(name = "Stand type",
                            values = c("Black spruce" = "darkgreen",
                                       "Jack pine" = "chocolate4") ) +
        labs(title = v,
             y= expression("Tonnes C" %.% ha^-1),
             x="",
             caption = paste0("Wild fire event occurs in ", wfEvent,
                             "\nInitial stand age is ", ageInit)) #+
        
        # geom_text(aes(x = 0, y = yMax, group = NULL,
        #               #label = paste0("taux annuel médian: ", round(100*medianRate, 3), "%")),
        #               label = paste0("N = ", freq, " (", round(100*prop, 2), "%)")),
        #           data = dfSummBS,
        #           hjust = 0, size = 1.75, fontface = 1, colour = "darkgreen") +
        # geom_text(aes(x = 0, y = yMax*0.88, group = NULL,
        #               #label = paste0("taux annuel médian: ", round(100*medianRate, 3), "%")),
        #               label = paste0("N = ", freq, " (", round(100*prop, 2), "%)")),
        #           data = dfSummJP,
        #           hjust = 0, size = 1.75, fontface = 1, colour = "chocolate4") 
    
    
    png(filename = paste0(v, ".png"),
        #width = 1800, height = (160*length(unique(df$species))+200), units = "px", pointsize = 16,
        width = (1.2*length(unique(df$siteIndex))+1),
        height = (1*length(unique(df$relDensity))+1),
        res = 300, units = "in", bg = "white")
    
    print(p +
              theme(plot.caption = element_text(size = rel(0.8)),
                    axis.text.x = element_text(size=8, angle = 45, hjust = 1),
                    axis.text.y = element_text(size=8),
                    strip.text.x = element_text(size=6),
                    strip.text.y = element_text(size=6))
    )
    
    dev.off()


}


