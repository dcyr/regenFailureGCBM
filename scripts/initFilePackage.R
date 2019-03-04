################################################################################
################################################################################
##### 
##### Creating file package for GCBM simulations
##### Dominic Cyr
##### 
################################################################################
################################################################################


### first, copying existing file package
### (some files may have needed to be modified manually)
print(paste0("Copying existing file package to './'"))
file.copy(list.files(paste(sourceGCBM, "GCBM_initPkg", sep = "/"),
                      recursive = F,
                      full.names = T),
          "./",
          recursive = T,
          copy.mode = TRUE)

### Pothier-Savard equations
print(paste0("Copying Pothier-Savard equations to './Pothier-Savard'"))
file.copy("../Pothier-Savard",
          "./",
          overwrite = T,
          recursive = T)

# ### raw spatial layers
# print(paste0("Copying raw spatial layers to './layers/raw'"))
# file.copy(rawDir,
#           paste("layers", sep ="/"),
#           overwrite = T,
#           recursive = T)

### yield curves
print(paste0("Copying yield curves spatial layers to './", inputDbDir, "'"))
file.copy(paste("..", inputDbDir, sep =  "/"),
          "./",
          overwrite = T,
          recursive = T)


### attribute tables
x <- "classifiersAT"
print(paste0("Copying classifyers attribute tables to './", x, "'"))
dir.create(x)
write.csv(fert_AT, paste(x, "fert_AT.csv", sep ="/"), row.names = F)
write.csv(dens_AT, paste(x, "dens_AT.csv", sep ="/"), row.names = F)
write.csv(coverTypes_RAT, paste(x, "ct_AT.csv", sep ="/"), row.names = F)

### selecting the right scripts, depending on whether
### transitions occur

if (regenFailure) {
    recliner2gcbmConfig <- "input_database/recliner2gcbm_config_wTransitions.json"
    tiler <- "tools/Tiler/tiler_wTransitions.py"
    file.remove("input_database/recliner2gcbm_config_noTransitions.json")
    file.remove("tools/Tiler/tiler_noTransitions.py")

} else {
    recliner2gcbmConfig <- "input_database/recliner2gcbm_config_noTransitions.json"
    tiler <- "tools/Tiler/tiler_noTransitions.py"
    file.remove("input_database/recliner2gcbm_config_wTransitions.json")
    file.remove("tools/Tiler/tiler_wTransitions.py")
}
file.copy(recliner2gcbmConfig,
            "input_database/recliner2gcbm_config.json",
          overwrite = T)
file.copy(tiler,
            "tools/Tiler/tiler.py",
          overwrite = T)
file.remove(recliner2gcbmConfig, tiler)

# 
# ### figures
# if(plotting) {
#     print(paste0("Copying figures to './figures'"))
#     ### associated figures
#     file.copy("figures",
#               "./",
#               overwrite = T,
#               recursive = T)  
# }


# ### modifying input parameters contained in json config files
# require(jsonlite)
# foo <- read_json(file.choose())
# write_json(foo, "foo.json", pretty = T)
# all.equal(mtcars, fromJSON(toJSON(mtcars)))





