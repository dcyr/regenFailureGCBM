###################################################################
###################################################################
### GCBM output compilation
rm(list = ls())
simDir <- c("D:/GCBM_sims/singlecellSims")
wwd <- paste(simDir, Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)
###
require(ggplot2)
require(dplyr)
require(doSNOW)
require(parallel)
###

fluxes <- get(load("../outputsCompiled/fluxes_singleCellSims.RData"))
pools <- get(load("../outputsCompiled/pools_singleCellSims.RData"))
spatialOutputs <- get(load("../outputsCompiled/spatialOutputs_singleCellSims.RData"))

###
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


clusterN <- 10#min(length(vars), detectCores()) ### choose number of nodes to add to cluster.
#######
cl = makeCluster(clusterN, outfile = "") ##
registerDoSNOW(cl)

foreach (v = vars) %dopar% {
    
    require(dplyr)
    require(ggplot2)
    
    df <- spatialOutputs %>%
    filter(variable == v)
    
    p <- ggplot(df, aes(x = year-wfEvent, y = value,
                        colour = coverTypes,
                        linetype = simID)) +
        facet_grid(relDensity ~ siteIndex) +
        # geom_rect(data = dfSummary,inherit.aes = F,
        #           aes(fill = propCls),xmin = -Inf,xmax = Inf,
        #           ymin = -Inf, ymax = Inf, alpha = 0.3) +
       
        xlim(-25, 75) +
        geom_vline(xintercept = 0,#wfEvent,
                   colour = "grey25", linetype = 3, size = 0.25) +
        geom_hline(yintercept = 0,#wfEvent,
                   colour = "grey25", linetype = 3, size = 0.25) +
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
             y= expression("Tonnes C" %.% ha^-1),#expression("Tonnes C" %.% ha^-1 %.% yr^-1),
             x="Year\n(relative to wild fire event)"
             #caption = paste0("Wild fire event occurs in ", wfEvent,
                             #"\nInitial stand age is ", ageInit)
        ) #+
        
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
stopCluster(cl)

