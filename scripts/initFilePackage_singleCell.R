################################################################################
################################################################################
##### 
##### Creating file package for GCBM simulations
##### Dominic Cyr
##### 
################################################################################
################################################################################
library(stringr)
require(rjson)

### first, copying existing file package
### (some files may have needed to be modified manually)
print(paste0("Copying existing file package to './'"))
file.copy(list.files(paste(sourceGCBM, "GCBM_initPkg", sep = "/"),
                      recursive = F,
                      full.names = T),
          simDir,
          recursive = T,
          copy.mode = TRUE)

### Pothier-Savard equations
print(paste0("Copying Pothier-Savard equations to './Pothier-Savard'"))
file.copy("./Pothier-Savard",
          simDir,
          overwrite = T,
          recursive = T)

# ### raw spatial layers
print(paste0("Copying raw spatial layers to './layers/raw'"))
file.copy(rawDir,
          paste(simDir, "layers", sep ="/"),
          overwrite = T,
          recursive = T)

# ################################################################################
# #### copying 'layers' folder
# file.copy("./layers",
#           simDir,
#           overwrite = T,
#           recursive = T,
#           copy.mode = TRUE)

### yield curves
print(paste0("Copying yield curves spatial layers to './", inputDbDir, "'"))
file.copy(paste(".", inputDbDir, sep =  "/"),
          simDir,
          overwrite = T,
          recursive = T)


### attribute tables
x <- "classifiersAT"
print(paste0("Copying classifyers attribute tables to './", x, "'"))
dir.create(x)
write.csv(fert_AT, paste(x, "fert_AT.csv", sep ="/"), row.names = F)
write.csv(dens_AT, paste(x, "dens_AT.csv", sep ="/"), row.names = F)
write.csv(ct_AT, paste(x, "ct_AT.csv", sep ="/"), row.names = F)

dir.create(paste(simDir, x, sep = "/"))
file.copy(x,
          simDir,
          overwrite = T,
          recursive = T)

### selecting the right scripts, depending on whether
### transitions occur

if(regenFailure) {
    recliner2gcbmConfig <- paste0(simDir, "/input_database/recliner2gcbm_config_wTransitions.json")
    tiler <- paste0(simDir, "/tools/Tiler/tiler_wTransitions.py")
    file.remove(paste0(simDir, "/input_database/recliner2gcbm_config_noTransitions.json"))
    file.remove(paste0(simDir, "/tools/Tiler/tiler_noTransitions.py"))
} else {
    recliner2gcbmConfig <- paste0(simDir, "/input_database/recliner2gcbm_config_noTransitions.json")
    tiler <- paste0(simDir, "/tools/Tiler/tiler_noTransitions.py")
    file.remove(paste0(simDir, "/input_database/recliner2gcbm_config_wTransitions.json"))
    file.remove(paste0(simDir, "/tools/Tiler/tiler_wTransitions.py"))
}

localdomain <- fromJSON(file = paste0(simDir, "/gcbm_project/templates/localdomain.json"))


### updating start_date, end_date, resolution, etc...

### localdomain: start / end dates, + other stuff
# start_date, end_date
localdomain$LocalDomain$start_date <- paste(yearInit+1, "01", "01", sep = "/")
localdomain$LocalDomain$end_date <- paste(yearInit+simDuration+1,  "01", "01", sep = "/")
#
sink(file = paste(simDir, "gcbm_project/templates/localdomain.json", sep = "/"))
cat(toJSON(localdomain, indent = 4))
cat("\n")
sink()

### 
# # resolution
studyAreaLL <- projectRaster(studyArea, crs = CRS("+init=epsg:4326"))
resolution <- floor(min(res(studyAreaLL))*1000)/1000

### updating resolution in tiler
x <- readLines(tiler)
# finding the line with parameter (only the first instance is updated...)
index <- grep("pixel_size", x)[1]
# replacing resolution value
x[index] <- gsub(str_extract_all(x[index], "[0-9]+\\.[0-9]+"),
                 resolution, x[index]) 
# writing to file
sink(file = paste0(tiler))
writeLines(x)
sink()

### renaming files and removing old ones
file.copy(recliner2gcbmConfig,
            paste0(simDir, "/input_database/recliner2gcbm_config.json"),
          overwrite = T)
file.copy(tiler,
          paste0(simDir, "/tools/Tiler/tiler.py"),
          overwrite = T)
file.remove(recliner2gcbmConfig, tiler)







