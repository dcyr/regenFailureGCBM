###############################################################################
###############################################################################
####
#### Piloting GCBM simulations
#### Dominic Cyr
####
###############################################################################
###############################################################################

#rm(list =ls())
#wwd <<- "D:/GCBM_sims/2019-03-04/"
wwd <- getwd()

simInfo <- read.csv("simInfo.csv", colClasses = c(simID = "character"))
simDir <- simInfo$simID

require(parallel)
require(doSNOW)
n <- 1#floor(detectCores() * 0.90)

# #######
cl = makeCluster(n, outfile = "") ## 
registerDoSNOW(cl)

foreach(i = 1:length(simDir)) %dopar% { # length(simDir)
    if (i <= n) {  ### to reduce the probability of several processes
        ### trying to access the same file at the same time
        Sys.sleep(runif(1)*2)
    }
    
    setwd(paste(wwd, simDir[i], sep ="/"))
    shell("run_all.bat", wait = T)
}

stopCluster(cl)
