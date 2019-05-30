# --------------------------------------------------
# David Phillips
# 
# 1/26/2019
# Script that loads packages and file names
# Intended to be called by 1_master_file.r
# This exists just for code organizational purposes
# (use singularity exec /share/singularity-images/health_fin/forecasting/best.img R on IHME's new cluster)
# --------------------------------------------------

# to do
# make this work on the cluster (it fails to load lubridate and other packages)

# ------------------
# Load packages
set.seed(1)
library(data.table)
library(lubridate)
library(readxl)
library(stringr)
library(ggplot2)
library(stats)
library(Rcpp)
library(grid)
library(gridExtra)
library(ggrepel)
library(boot)
library(lavaan)
library(blavaan)
library(viridis)
# library(Hmisc)
# library(lavaanPlot)
# library(semPlot)
library(raster)
library(parallel)
# library(dplyr)
library(splitstackshape)
# ------------------


# ---------------------------------------------------------------------------------
# Directories

# switch J for portability to cluster
j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')

# directories
dir = paste0(j, '/Project/Evaluation/GF/')
ieDir = paste0(dir, 'impact_evaluation/gtm/prepped_data/')
rtDir = paste0(dir, 'resource_tracking/_gf_files_gos/combined_prepped_data/')
fghDir = paste0(dir, 'resource_tracking/_fgh/prepped_data/')
whoDir = paste0(dir, 'resource_tracking/_ghe/who/prepped_data/')
mapDir = paste0(dir, '/mapping/multi_country/intervention_categories')
sicoinDir = paste0(dir, 'resource_tracking/_ghe/sicoin_gtm/prepped_data/')
lbdDir = paste0(j, '/WORK/11_geospatial/01_covariates/00_MBG_STANDARD/')
# ---------------------------------------------------------------------------------


# ------------------------------------------------------------------------
# Supporting Files

# code-friendly version of indicator map file
indicatorMapFile = paste0(ieDir, 'GTM Indicator map.xlsx')

# list of interventions and codes
mfFile = "J:/Project/Evaluation/GF/resource_tracking/modular_framework_mapping/all_interventions.csv"

# archive function
source('./impact_evaluation/_common/archive_function.R')

# function that runs a SEM as unrelated regressions
source('./impact_evaluation/_common/run_lavaan_as_glm.r')
# ------------------------------------------------------------------------


# ---------------------------------------------------------------------------------
# Inputs files

# resource tracking files with prepped budgets, expenditures, disbursements
budgetFile = paste0(rtDir, 'final_budgets.rds')
expendituresFile = paste0(rtDir, 'final_expenditures.rds')
fghFile = paste0(fghDir, 'prepped_current_fgh.rds')
gheMalFile = paste0(fghDir, 'ghe_actuals_malaria.rds')
whoFile = paste0(whoDir, 'who_prepped.rds')
sicoinFile = paste0(sicoinDir, 'prepped_sicoin_data.rds')

# activities/outputs files
actFile = paste0(ieDir, "activities_5.22.19.csv")
outputsFile = paste0(ieDir, "outputs_5.22.19.csv")

# outcomes/impact files
impactFile = paste0(ieDir, "impact_5.22.19.csv")

# shapefiles

# "nodetables" aka "nodetables" 
# listing names of variables in each model, their labels and coordinates for the SEM graph
nodeTableFile1 = './impact_evaluation/drc/visualizations/nodetable_first_half.csv'
nodeTableFile2 = './impact_evaluation/drc/visualizations/nodetable_second_half.csv'
# ---------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------
# Intermediate file locations
if (Sys.info()[1]!='Windows') {
username = Sys.info()[['user']]
clustertmpDir1 = paste0('/ihme/scratch/users/', username, '/impact_evaluation/combined_files/')
clustertmpDir2 = paste0('/ihme/scratch/users/', username, '/impact_evaluation/parallel_files/')
clustertmpDireo = paste0('/ihme/scratch/users/', username, '/impact_evaluation/errors_output/')
if (file.exists(clustertmpDir1)!=TRUE) dir.create(clustertmpDir1) 
if (file.exists(clustertmpDir2)!=TRUE) dir.create(clustertmpDir2) 
if (file.exists(clustertmpDireo)!=TRUE) dir.create(clustertmpDireo) 
}
# ---------------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Output Files

# output file from 2a_prep_resource_tracking.r
outputFile2a = paste0(ieDir, 'prepped_resource_tracking.RDS')

# output file from 2b_prep_activities_outputs.R
outputFile2b = paste0(ieDir, 'outputs_activites_for_pilot.RDS')
outputFile2b_wide = paste0(ieDir, 'outputs_activities_for_pilot_wide.RDS')

# output file from 2c_prep_outcomes_impact.r
outputFile2c_estimates = paste0(ieDir, 'aggregated_rasters.rds')
outputFile2c = paste0(ieDir, 'outcomes_impact.rds')

# output file from 3_merge_data.R
outputFile3 = paste0(ieDir, 'inputs_outputs.RDS')

# output files from 3b_correct_to_models.r
outputFile3b = paste0(ieDir, 'outcomes_impact_corrected.RDS')
outputFile3bGraphs = paste0(ieDir, '../visualizations/outcomes_impact_correction_results.pdf')

# output file from 4a_set_up_for_analysis.r
outputFile4a = paste0(ieDir, 'first_half_pre_model.rdata')
if (Sys.info()[1]!='Windows') { 
	outputFile4a_scratch = paste0(clustertmpDir1, 'first_half_data_pre_model.rdata')
}

# output file from 4b_set_up_for_second_half_analysis.r
outputFile4b = paste0(ieDir, 'second_half_data_pre_model.rdata')
if (Sys.info()[1]!='Windows') { 
	outputFile4b_scratch = paste0(clustertmpDir1, 'second_half_data_pre_model.rdata')
}

# output file from 4c and 4d_explore_data.r (graphs)
outputFile4c = paste0(ieDir, '../visualizations/first_half_exploratory_graphs.pdf')
outputFile4d = paste0(ieDir, '../visualizations/second_half_exploratory_graphs.pdf')

# output file from 5a_run_first_half_analysis.R
outputFile5a = paste0(ieDir, 'first_half_model_results.rdata')

# output file from 5b_run_second_half_analysis.r
outputFile5b = paste0(ieDir, 'second_half_model_results.rdata')

# output file from 6_display_results.r
outputFile6a = paste0(ieDir, '../visualizations/sem_diagrams.pdf')
outputFile6b = paste0(ieDir, '../visualizations/bottleneck_analysis.pdf')
outputFile6c = paste0(ieDir, '../visualizations/impact_analysis.pdf')
outputFile6d = paste0(ieDir, '../visualizations/health_zone_effects.pdf')
# -----------------------------------------------------------------------------