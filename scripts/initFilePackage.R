################################################################################
################################################################################
##### 
##### Creating file package for GCBM simulations
##### Dominic Cyr
##### 
################################################################################
################################################################################
dir.create(projectName)

### first, copying existing file package
### (some files may have needed to be modified manually)
print(paste0("Copying existing file package to './", projectName, "'"))
file.copy(sourceCBM,
          ".",
          overwrite = T,
          recursive = T,
          copy.mode = TRUE)
file.rename(gsub("../", "", sourceCBM),
            projectName)

### raw spatial layers
print(paste0("Copying raw spatial layers to './", projectName, "/layers/raw'"))
file.copy(layerDir,
          paste(projectName, "layers", sep ="/"),
          overwrite = T,
          recursive = T)
print(paste0("Copying yield curves spatial layers to './", projectName, "/", inputDbDir, "'"))

### yield curves
file.copy(inputDbDir,
          projectName,
          overwrite = T,
          recursive = T)

print(paste0("Copying figures to './", projectName, "/figures'"))

### associated figures
file.copy("figures",
          projectName,
          overwrite = T,
          recursive = T)

### Pothier-Savard equations
print(paste0("Copying Pothier-Savard equations to './", projectName, "/Pothier-Savard'"))
file.copy("Pothier-Savard",
          projectName,
          overwrite = T,
          recursive = T)


