########################################################################################################
# Getting GBD locations and outputs for PCE                                                            
# Audrey Batzel (based on get_gbd_loc_id_and_outputs.R from Jennifer Ross)                               
# November 1, 2018
#
# Run on the cluster to use central functions.
#
########################################################################################################

library(data.table)
library(ggplot2)
#--------------------------------------------

#--------------------------------------------
# Define J header
if (Sys.info()[1]=="Windows"){
  j_head <- "J:/"
} else {
  j_head <- "/home/j/"
}

# Location ids for PCE countries:
# GTM = 128
# COD = 171
# UGA = 190
# SEN = 216

# Source shared functions
source("/home/j/temp/central_comp/libraries/current/r/get_outputs.R")
source("/home/j/temp/central_comp/libraries/current/r/get_population.R")

# Outfile:
outFile = paste0(j_head, ("Project/Evaluation/GF/impact_evaluation/mortality/gbd_estimates_tb_pce_countries.csv"))
outFile2 = paste0(j_head, "Project/Evaluation/GF/impact_evaluation/mortality/gbd_estimates_malaria_pce_countries.csv")
#--------------------------------------------

#--------------------------------------------
#This section uses the central function 'get_outputs' to pull GBD results from the central db

#GBD 2017 results

# topic = "cause"
# gbd_round_id = 5 for 2017 GBD results (so 6 for 2018 GBD?)
# measure_id = 6 for Incidence
#            = 1 for Deaths
#            = 5 for Prevalence
# metric_id = 1 for Number
#           = 3 for Rate
# age_id = 27 for age standardized
#        = 22 for all ages
# sex_id = 3 for both
# cause_id = 298 for HIV/AIDS; 345 for malaria


#Cause IDs are for HIV with drug-susceptible, MDR, and XDR TB respectively
dt = get_outputs("cause", version= "latest", gbd_round_id=5, 
                 cause_id=c(934,946,947,948,949,950), 
                 location_id=c(171, 190, 128, 216),
                 age_group_id=27, 
                 sex_id=3, 
                 year_id=c(2008:2018), 
                 measure_id=c(1, 6), 
                 metric_id=3)

# this set of outputs include age-standardized incidence and mortality rates for both sexes, for the years 2008 to 2018 from the 2018 GBD results

write.csv(dt, outFile)
