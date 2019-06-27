################################################################################
################################################################################
####
#### Volume-to-biomass conversion for forested and vegetated land in Canada
#### Equations from Boudewyn et al. 2007
####
################################################################################
################################################################################


#### Stem wood biomass of merchantable-sized trees
# currently assumes everything is in the same spatial unit
volMerch_to_biomass_fnc <- function(x, sp, vol_to_bio_params) {
    # species index
    spId <-  vol_to_bio_params[match(sp, vol_to_bio_params$name), "species_id"]
    
    # extracting parameters
    p <- vol_to_bio_params %>%
        filter(name == sp)
    
    # the model
    b_m <- p[["a"]] * x^p[["b"]]
    return(b_m)
       # return(list(spId, params, b_m))
}

#### Nonmerchantable-sized trees : Stem wood biomass of merchantable-sized trees (ratio)
# currently assume everything is in the same spatial unit
nonmerchfactor_fnc <- function(x, sp, vol_to_bio_params) {
    
    # species index
    spId <-  vol_to_bio_params[match(sp, vol_to_bio_params$name), "species_id"]
   
    # extracting parameters
    p <- vol_to_bio_params %>%
        filter(name == sp)
    a <- p[["a_nonmerch"]]
    b <- p[["b_nonmerch"]]
    k <- p[["k_nonmerch"]]
    cap_nonmerch <- p[["cap_nonmerch"]]
    
    # the model
    nonmerchfactor <- k + a * x^b
    
    # applying cap value
    if(nonmerchfactor > cap_nonmerch) {
        nonmerchfactor <- cap_nonmerch
    }
    
    return(nonmerchfactor)
}
#### Sapling-sized trees : Nonmerchantable-sized trees (ratio)
# currently assume everything is in the same spatial unit
sapling_factor_fnc <-  function(x, sp, vol_to_bio_params) {
    
    # species index
    spId <-  vol_to_bio_params[match(sp, vol_to_bio_params$name), "species_id"]
    
    # extracting parameters
    p <- vol_to_bio_params %>%
        filter(name == sp)
    a <- p[["a_sap"]]
    b <- p[["b_sap"]]
    k <- p[["k_sap"]]
    cap_sap <- p[["cap_sap"]]
    
    # the model
    sapling_factor <- k + a * x^b
    
    # applying cap value
    if(sapling_factor > cap_sap) {
        sapling_factor <- cap_sap
    }
    
    return(sapling_factor)
}

#### Models to predict proportions of total tree biomass found in stem wood,
#### stem bark, branch and foliage for live trees of all sizes
# currently assume everything is in the same spatial unit

propBiomass_liveTrees_fnc <- function(x, sp, vol_to_bio_params) {
    # species index
    spId <-  vol_to_bio_params[match(sp, vol_to_bio_params$name), "species_id"]
    # extracting parameters
    p <- vol_to_bio_params %>%
        filter(name == sp)
    
    a1 <- p[["a1"]]
    a2 <- p[["a2"]]
    a3 <- p[["a3"]]
    b1 <- p[["b1"]]
    b2 <- p[["b2"]]
    b3 <- p[["b3"]]
    c1 <- p[["c1"]]
    c2 <- p[["c2"]]
    c3 <- p[["c3"]]
    
    a <- exp(a1+a2*x+a3*log(x+5))
    b <- exp(b1+b2*x+b3*log(x+5))
    c <- exp(c1+c2*x+c3*log(x+5))
    
    pStemwood <- 1 / (1 + a + b + c)
    pBark <- a / (1 + a + b + c)
    pBranches <- b / (1 + a + b + c)
    pFoliage <- c / (1 + a + b + c)
    
    return(list(Stemwood = pStemwood,
                        Bark = pBark,
                        Branches = pBranches,
                        Foliage = pFoliage))
    
}


