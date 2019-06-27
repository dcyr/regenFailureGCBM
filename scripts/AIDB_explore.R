###################################################################
###################################################################
### GCBM Archive Index Database (various exploration)
rm(list = ls())
simDir <- c("D:/GCBM_sims/singlecellSims")
wwd <- paste(simDir, Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)
###
simID <- c("singleCellSims_regenFailure", "singleCellSims_noRegenFailure")

source("C:/Users/cyrdo/Sync/Travail/ECCC/regenFailureGCBM/scripts/Boudewyn.R")

###################################################################
require(dbplyr)
require(dplyr)
require(DBI)
require(tidyr)


sDir <- paste(simDir, simID[1], sep = "/")

ct_AT <- read.csv(paste(sDir,"classifiersAT/ct_AT.csv",
                                sep = "/"))
dens_AT <- read.csv(paste(sDir,"classifiersAT/dens_AT.csv",
                        sep = "/"))
fert_AT <- read.csv(paste(sDir,"classifiersAT/fert_AT.csv",
                        sep = "/"))

densLvls <- paste("Rho100 =", dens_AT$value)
fertLvls <- paste("Site index =", fert_AT$value)


###################################################################
### Connect to Archive Index Database
# AIDB <- dbConnect(Microsoft Access Driver (*.mdb, *.accdb)),
#                   dbname = paste(sDir,
#                                  "input_database/ArchiveIndex_Beta_Install.mdb",
#                                  sep = "/"))
gcbm_input <- dbConnect(drv=RSQLite::SQLite(),
                  dbname = paste(sDir,
                                 "input_database/gcbm_input.db",
                                 sep = "/"))

#### list of tables
tableNames <- dbListTables(gcbm_input)
## load all tables (might want to prune a bit...)
for (j in seq_along(tableNames)) {
    x <- tableNames[j]
    assign(x, dbReadTable(gcbm_input, x))
    print(paste0("table '", x, "' loaded"))
}
dbDisconnect(gcbm_input)


#### fetching yield curves
yield <- read.csv(paste0(sDir, "/input_database/yield.csv"))
cIndex <- grep("Age", colnames(yield))
yield <- yield %>%
    gather(key = "age", value = "volMerch", !!colnames(yield)[cIndex]) %>%
    mutate(age = as.numeric(gsub("[^0-9]", "", age)))
#### fetching parameters
#### growth curves components
#spatial unit-specific parameters 
spu_params <- spatial_unit %>%
    rename(spuID = id) %>%
    merge(admin_boundary, by.x = "admin_boundary_id", by.y = "id") %>%
    rename(provinceName = name) %>%
    merge(eco_boundary, by.x = "eco_boundary_id", by.y = "id") %>%
    rename(ecozoneName = name) %>%
    filter(provinceName %in% "Quebec",
           ecozoneName %in% "Boreal Shield East")

####
# yield curve-specific parameters
speciesID  <- species[species$name %in% as.character(unique(yield$AIDBSPP)),]

vol_to_bio_params <- vol_to_bio_factor_association %>%
    filter(spatial_unit_id %in% unique(spu_params$spuID),
           species_id %in% unique(speciesID$id)) %>% 
    merge(vol_to_bio_factor,
          by.x = "vol_to_bio_factor_id",
          by.y = "id") %>%
    merge(speciesID,
          by.x = "species_id",
          by.y = "id")
##


yield[,"b_m"] <- apply(yield, 1, function(x)
    volMerch_to_biomass_fnc(x = as.numeric(x["volMerch"]),
                        sp = as.character(x["AIDBSPP"]),
                        vol_to_bio_params = vol_to_bio_params))

yield[,"nonmerchfactor"] <- apply(yield, 1, function(x)
    nonmerchfactor_fnc(x = as.numeric(x["b_m"]),
                            sp = as.character(x["AIDBSPP"]),
                            vol_to_bio_params = vol_to_bio_params))

yield <- yield %>%
    mutate(b_nm = b_m * nonmerchfactor)

yield[,"saplingfactor"] <- apply(yield, 1, function(x)
    sapling_factor_fnc(x = as.numeric(x["b_nm"]),
                       sp = as.character(x["AIDBSPP"]),
                       vol_to_bio_params = vol_to_bio_params))


yield <- yield %>%
    mutate(b_s = b_nm * saplingfactor, ## saplings
           stemwood_total = b_m + b_nm + b_s) ## total stemwood livetrees 

###
yieldVolMerch <-  yield %>%
    select(coverType, fertility, relDensity, AIDBSPP,
           age, volMerch) %>%
    rename(volMerch_m3PerHa = volMerch)
###
yieldStemwood <- yield %>%
    select(coverType, fertility, relDensity, AIDBSPP,
           age,
           b_m, b_nm, b_s, stemwood_total)  %>%
    gather(key = "swComponent", value = "biomassSW_tonnesPerHa",
           b_m, b_nm, b_s, stemwood_total)#,
###
yieldBiomassProp <- do.call("rbind", apply(yield, 1, function(x)
    propBiomass_liveTrees_fnc(x = as.numeric(x[["stemwood_total"]]),
                              sp = as.character(x[["AIDBSPP"]]),
                              vol_to_bio_params = vol_to_bio_params)))
yieldBiomassProp <- apply(yieldBiomassProp, 2, unlist)
yieldBiomassProp <- data.frame(yieldVolMerch,
                               yieldBiomassProp) %>%
    select(coverType, fertility, relDensity, AIDBSPP, age,
           Stemwood, Bark, Branches, Foliage)  %>%
    gather(key = "treeComponent", value = "biomass_Proportions",
           Stemwood, Bark, Branches, Foliage)
                               
                               
### putting everything in a nice data.frame

standComponentLvls <- c(b_m = "Merchantable",
                        b_nm = "Non-Merchantable",
                        b_s = "Saplings",
                        stemwood_total = "Total")

yieldBiomass <- yieldStemwood %>%
    merge(yieldBiomassProp) %>%
    group_by(coverType, fertility, relDensity, AIDBSPP,
             age, swComponent) %>%
    mutate(multFact = biomass_Proportions/biomass_Proportions[which(treeComponent == "Stemwood")]) %>%
    ungroup() %>%
    mutate(biomass_tonnesPerHa = biomassSW_tonnesPerHa * multFact) %>%
    select(-one_of(c("biomassSW_tonnesPerHa", "biomass_Proportions"))) %>%
    mutate(fertility = factor(paste("Site index =",
                                    fert_AT[match(fertility, fert_AT$ID), "value"]),
                              levels = fertLvls),
           relDensity = factor(paste("Rho100 =",
                                     dens_AT[match(relDensity, dens_AT$ID), "value"]),
                               levels = densLvls),
           treeComponent = factor(treeComponent,
                                  levels = c("Foliage", "Branches",
                                             "Bark", "Stemwood")),
           swComponent = factor(standComponentLvls[swComponent],
                                levels = standComponentLvls))




###################################
require(ggplot2)
cols <- c(Stemwood = "lightsalmon4",
          Foliage = "olivedrab3",
          Bark = "tomato4",
          Branches = "lightsalmon3")#"sandybrown")

### treeComponent
for (sp in as.character(unique(yieldBiomass$AIDBSPP))){
    
    df <- yieldBiomass %>% 
        filter(AIDBSPP == sp,
               swComponent == "Total")
    spCode <- as.character(ct_AT[which(ct_AT$AIDBSPP == sp), "value"])
    
    ### stacks
    pStack <- ggplot(df, aes(x = age, y = biomass_tonnesPerHa,
                             fill = treeComponent)) +
        facet_grid(relDensity ~ fertility) +
        stat_summary(fun.y="sum", geom="area",
                     col="black",
                     position = position_stack(reverse = F)) +
        scale_fill_manual(values=cols) +
        labs(title = paste0("Distribution of live aboveground biomass"),
             subtitle = paste0(sp, "\nNo extrapolation for merch. vol = 0"),
             y = expression("Biomass - Tonnes" %.% ha^-1),
             x = "Age")
    
    ### fill
    pFill <- ggplot(df, aes(x = age, y = biomass_tonnesPerHa,
                             fill = treeComponent)) +
        facet_grid(relDensity ~ fertility) +
        stat_summary(fun.y="sum", geom="area",
                     col="black",
                     position = position_fill(reverse = F)) +
        scale_fill_manual(values=cols) +
        labs(title = paste0("Distribution of live aboveground biomass"),
             subtitle = paste0(sp, "\nNo extrapolation for merch. vol = 0"),
             y = expression("Biomass - Tonnes" %.% ha^-1),
             x = "Age")
    
    
    ### lines
    pLine <- ggplot(df, aes(x = age, y = biomass_tonnesPerHa,
                             color = treeComponent)) +
        facet_grid(relDensity ~ fertility) +
        stat_summary(fun.y="sum", geom="line", size=1) +
        scale_colour_manual(values=cols) +
        labs(title = paste0("Distribution of live aboveground biomass"),
             subtitle = paste0(sp, "\nNo extrapolation for merch. vol = 0"),
             y = expression("Biomass - Tonnes" %.% ha^-1),
             x = "Age")
    
    png(filename = paste0("biomassAG_treeComponent_", spCode, "_stack.png"),
        width = (1.2*length(unique(df$fertility))+1),
        height = (1*length(unique(df$relDensity))+1),
        res = 300, units = "in", bg = "white")
    
    print(pStack +
              theme_dark() + 
              theme(strip.text.y = element_text(size=rel(0.75))))
    dev.off()
    
    png(filename = paste0("biomassAG_treeComponent_", spCode, "_fill.png"),
        width = (1.2*length(unique(df$fertility))+1),
        height = (1*length(unique(df$relDensity))+1),
        res = 300, units = "in", bg = "white")
    
    print(pFill +
              theme_dark() +
              theme(strip.text.y = element_text(size=rel(0.75))))
    dev.off()
    
    png(filename = paste0("biomassAG_treeComponent_", spCode, "_line.png"),
        width = (1.2*length(unique(df$fertility))+1),
        height = (1*length(unique(df$relDensity))+1),
        res = 300, units = "in", bg = "white")
    
    print(pLine +
              theme_dark() +
              theme(strip.text.y = element_text(size=rel(0.75))))
    dev.off()
}



### stand Component
cols <- c(Saplings = "darkseagreen1",
          "Non-Merchantable" = "darkseagreen3",
          Merchantable = "darkseagreen4")

for (sp in as.character(unique(yieldBiomass$AIDBSPP))){
    
    df <- yieldBiomass %>% 
        filter(AIDBSPP == sp,
               swComponent != "Total")
    
    spCode <- as.character(ct_AT[which(ct_AT$AIDBSPP == sp), "value"])
    
    ### stacks
    pStack <- ggplot(df, aes(x = age, y = biomass_tonnesPerHa,
                             fill = swComponent)) +
        facet_grid(relDensity ~ fertility) +
        stat_summary(fun.y="sum", geom="area",
                     col="black",
                     position = position_stack(reverse = F)) +
        scale_fill_manual(values=cols) +
        labs(title = paste0("Distribution of live aboveground biomass"),
             subtitle = paste0(sp, "\nNo extrapolation for merch. vol = 0"),
             y = expression("Biomass - Tonnes" %.% ha^-1),
             x = "Age")
    
    ### fill
    pFill <- ggplot(df, aes(x = age, y = biomass_tonnesPerHa,
                            fill = swComponent)) +
        facet_grid(relDensity ~ fertility) +
        stat_summary(fun.y="sum", geom="area",
                     col="black",
                     position = position_fill(reverse = F)) +
        scale_fill_manual(values=cols) +
        labs(title = paste0("Distribution of live aboveground biomass"),
             subtitle = paste0(sp, "\nNo extrapolation for merch. vol = 0"),
             y = expression("Biomass - Tonnes" %.% ha^-1),
             x = "Age")
    
    
    ### lines
    pLine <- ggplot(df, aes(x = age, y = biomass_tonnesPerHa,
                            color = swComponent)) +
        facet_grid(relDensity ~ fertility) +
        stat_summary(fun.y="sum", geom="line", size=1) +
        scale_colour_manual(values=cols) +
        labs(title = paste0("Distribution of live aboveground biomass"),
             subtitle = paste0(sp, "\nNo extrapolation for merch. vol = 0"),
             y = expression("Biomass - Tonnes" %.% ha^-1),
             x = "Age")
    
    png(filename = paste0("biomassAG_standComponent", spCode, "_stack.png"),
        width = (1.2*length(unique(df$fertility))+1),
        height = (1*length(unique(df$relDensity))+1),
        res = 300, units = "in", bg = "white")
    
    print(pStack +
              theme_dark() + 
              theme(strip.text.y = element_text(size=rel(0.75))))
    dev.off()
    
    png(filename = paste0("biomassAG_standComponent", spCode, "_fill.png"),
        width = (1.2*length(unique(df$fertility))+1),
        height = (1*length(unique(df$relDensity))+1),
        res = 300, units = "in", bg = "white")
    
    print(pFill +
              theme_dark() +
              theme(strip.text.y = element_text(size=rel(0.75))))
    dev.off()
    
    png(filename = paste0("biomassAG_standComponent", spCode, "_line.png"),
        width = (1.2*length(unique(df$fertility))+1),
        height = (1*length(unique(df$relDensity))+1),
        res = 300, units = "in", bg = "white")
    
    print(pLine +
              theme_dark() +
              theme(strip.text.y = element_text(size=rel(0.75))))
    dev.off()
}

