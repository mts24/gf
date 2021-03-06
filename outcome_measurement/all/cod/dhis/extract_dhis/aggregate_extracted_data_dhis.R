# DHIS2 Extraction for DRC - SNIS - append extracted files
# Extracts Data from: https://www.snisrdc.com/dhis-web-commons/security/login.action
# Sources dhis_extracting_functions.R on J Drive for dhisextractr package and extraction functions
# Website re-reroutes from https://www.snisdrc.com to https://snisdrc.com

#---------------------------
# Caitlin O'Brien-Carelli
# 1/15/2018

# Audrey Batzel
# 2/22/19 - updated to work around problem of some facilities not downloading still even with changed pace
#---------------------------
# Extract single data sets by specifying the data set number
# Data will be merged with the meta data to create complete data sets
# You must have the source functions and meta data accessible to run 
#---------------------------

#---------------------------
# To run on the cluster:
# Copy shell script into a qlogin session to open an IDE
# request at least 10 slots for extractions 

# sh /ihme/code/jpy_rstudio/jpy_rstudio_qsub_script.sh -i /ihme/singularity-images/rstudio/ihme_rstudio_3501.img -l m_mem_free=50G -l fthread=20 -P proj_pce -q all -t rstudio -l archive=TRUE -l h_rt=72:00:00
#---------------------------
# Set up R
library(data.table)
library(jsonlite)
library(httr)
library(ggplot2)
library(stringr) 
library(RCurl)
library(XML)
library(plyr)
library(openxlsx)
#---------------------------
# Set the directory to download the data
# detect if operating on windows or on the cluster 
root = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')

#---------------------------
# define main directory

dir = paste0(root, '/Project/Evaluation/GF/outcome_measurement/cod/dhis_data/')
#---------------------------

#---------------------------
# Set these to the correct values for the extraction:

# change set_name to the name of the data set you are downloading 
# set_name will change the file names for saving the data
set_name = set

#------------------------
# list the file in the data set's download folder:
files = list.files( paste0(dir, '1_initial_download/', set_name), recursive=TRUE)
files = files[grepl(files, pattern = 'intermediate')]

# keep files for the most recent run - max year and max month:
max_year = lapply(files, function (x) { str_split(x, '_')[[1]][3] }) %>% as.numeric() %>% max() %>% as.character()

files = files[grepl(paste0('intermediate_data_', max_year), files)]

max_month = lapply(files, function (x) { str_split(x, '_')[[1]][4] }) 
max_month = lapply(max_month, function (x) { substr(x, 1, 2) })
max_month = as.numeric(max_month) %>% max() %>% as.character()
if(nchar(max_month)==1) max_month = paste0('0', max_month)

read_dir = paste0(dir, '1_initial_download/', set_name, '/intermediate_data_', max_year, '_', max_month, '/')
files = list.files( read_dir , recursive=TRUE)

# within the most recent run, get the start and finish years/months for saving the data:
start_year = lapply(files, function (x) { str_split(x, '_')[[1]][3] }) %>% as.numeric() %>% min() %>% as.character()
end_year = lapply(files, function (x) { str_split(x, '_')[[1]][5] }) %>% as.numeric() %>% max() %>% as.character()

start_year_files = files[unlist(lapply(files, function (x) { str_split(x, '_')[[1]][3]==start_year }))]
start_month = lapply(start_year_files, function (x) { str_split(x, '_')[[1]][2] }) %>% as.numeric() %>% min() %>% as.character()
if(nchar(start_month)==1) start_month = paste0('0', start_month)

end_year_files = files[unlist(lapply(files, function (x) { str_split(x, '_')[[1]][5]==end_year }))]
end_month = lapply(end_year_files, function (x) { str_split(x, '_')[[1]][4] }) %>% as.numeric() %>% max() %>% as.character()
if(nchar(end_month)==1) end_month = paste0('0', end_month)

start_date = paste(start_month, start_year, sep = '_')
end_date = paste(end_month, end_year, sep = '_')

save_file = paste0(dir, '1_initial_download/', set_name, '/', set_name, '_', start_date, '_', end_date, '_aggregated.rds')

# loop through the files and rbind them together to save one file of data from the most recent download
dt = data.table()
# read in the files 
i = 1
for(f in files) {
  #load the RDs file
  vec = f
  current_data = data.table(readRDS(paste0(read_dir, f)))
  current_data[ , file:=vec ]
  
  # # subset to only the variables needed for large data sets
  # if (folder=='base' | folder=='sigl') {
  #   current_data[ , data_element_ID:=as.character(data_element_ID)]
  #   current_data = current_data[data_element_ID %in% keep_vars]
  # }
  
  # append to the full data 
  if(i==1) dt = current_data
  if(i>1)  dt = rbind(dt, current_data)
  i = i+1 }

if(length(unique(dt$file))!=length(files)) stop('Check the data table, at least one file did not append correctly')

# save the aggregated data
saveRDS(dt, save_file)

#-------------------------