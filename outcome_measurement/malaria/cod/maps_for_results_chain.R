# Audrey Batzel 
# 12-20-18
#
# Convert dt_17_mal names and shapefile names to standardized ones 
setwd('C:/local/gf/')
# ----------------------------------------------

# --------------------
# Set up R / install packages
# --------------------
rm(list=ls())
library(data.table)
library(reshape2)
library(stringr)
library(readxl)
library(rlang)
library(zoo)
library(lubridate)
library(raster)
library(rgeos)
library(data.table)
library(ggplot2)
library(maptools)
library(scales)
library(ggrepel)
library(naniar)
library(grid)
library(gridExtra)
library(lattice)
# --------------------  

# ---------------------------------------------------
# Files and directories
# ---------------------------------------------------
root = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')
dir = paste0(root, '/Project/Evaluation/GF/outcome_measurement/cod/')

dir_pnlp = paste0(dir, 'prepped_data/PNLP/')
# standardized shapefiles and data
# dir = "C:/Users/abatzel/Documents/Audrey_PCE/edited data for Constant/" # change this to somewhere on the J drive
dir ='C:/Users/abatzel/Desktop/malaria_results_chain_copy/prepped_data/'
dir_pnlp ='C:/Users/abatzel/Desktop/Copy of data for J drive shutdown/'

out_dir = paste0(root, "/Project/Evaluation/GF/results_chains/cod/malaria/visualizations/maps/")
  
# input files
pnlp_dps <- "post_imputation/imputedData_run2_agg_dps.rds"
pnlp_hz <- "post_imputation/imputedData_run2_agg_hz.rds"

# output files

source('./core/standardizeDPSNames.R')
source('./core/standardizeHZNames.R')
old_dps_names = "./core/old_dps_names_to_new.csv"
dps_names = read.csv(old_dps_names, stringsAsFactors = FALSE)
# ---------------------------------------------------

# ---------------------------------------------------
# load data
# ---------------------------------------------------
dt = readRDS(paste0(dir, "dt_17_mal_base_data.rds"))
dt = readRDS(paste0(dir, 'snis_base_data_prepped_for_Constant.rds'))

dt_pnlp = readRDS(paste0(dir_pnlp, pnlp_dps))
dt_pnlp <- dt_pnlp[dps != "0",]
dt_pnlp$year <- year(dt_pnlp$date)
dt_pnlp$dps <- standardizeDPSNames(dt_pnlp$dps)
dt_pnlp_17 <- dt_pnlp[year == "2017",]

shp_dps = readRDS(paste0(dir, "dps_shapefile_names_standardized.rds"))

dt_pnlp_hz = readRDS(paste0(dir_pnlp, pnlp_hz))
dt_pnlp_hz <- dt_pnlp_hz[dps != "0",]
dt_pnlp_hz$year <- year(dt_pnlp_hz$date)
dt_pnlp_hz <- dt_pnlp_hz[year == "2017",]
dt_pnlp_hz$dps <- standardizeDPSNames(dt_pnlp_hz$dps)
dt_pnlp_hz$health_zone <- standardizeHZNames(dt_pnlp_hz$health_zone)

shp_hz = readRDS(paste0(dir, "hz_shapefile_names_standardized.rds"))
# ---------------------------------------------------

# ---------------------------------------------------
# map at dps level - pnlp 
# ---------------------------------------------------
# Map ITNs received, 
# ACTs received, 
# RDTs received, and 
# Injectible+suppository ACTs received

coordinates = as.data.table(fortify(shp_dps, region='NAME_1'))
# aggregate data for the year by indicator subpopulation and dps
dt_pnlp_17 = dt_pnlp_17[, .(value = sum(mean, na.rm=TRUE)), by= c("dps", "indicator", "subpopulation") ]

# LLINs received
dt_subset = dt_pnlp_17[indicator == "ITN" & subpopulation == "received", ]
title = "LLINs received"

graphData <- merge(dt_subset, coordinates, by.x=c('dps'), by.y=c('id'), all=TRUE)

max = max(graphData$value, na.rm=TRUE)
min = min(graphData$value, na.rm=TRUE)
med = max/2

m1 <- ggplot() + 
  geom_polygon(data=graphData, aes(x=long, y=lat, group=group, fill=value)) + 
  coord_equal() +
  geom_path(data=graphData, aes(x=long, y=lat, group=group), color="black", size=0.2, alpha=0.2) +
  theme_void() +  
  scale_fill_gradient2(low='#9aeaea', mid='#216fff', high='#0606aa', 
                       na.value = "grey70", space = "Lab", midpoint = med, ## play around with this to get the gradient that you want, depending on data values 
                       breaks=round(seq(0, max, by=((max-min)/4)), digits = -3), 
                       limits=c(0,max), labels = scales :: comma) +
  labs(title= title, 
       fill='Count', caption = "") + 
  theme( plot.caption = element_text(size = 12), plot.title = element_text(size = 16))

# ACTS received
dt_subset2 = dt_pnlp_17[ indicator %in% c("ASAQreceived", "ArtLum") & subpopulation %in% c("received", "14yrsAndOlder", "1to5yrs", "2to11mos", "6to13yrs"), ]
dt_subset2 <- dt_subset2[, .(value = sum(value, na.rm=TRUE)), by = c('dps')]
title = "ACTs received"

graphData2 <- merge(dt_subset2, coordinates, by.x=c('dps'), by.y=c('id'), all=TRUE)

max = max(graphData2$value, na.rm=TRUE)
min = min(graphData2$value, na.rm=TRUE)
med = max/2

m2 <- ggplot() + 
  geom_polygon(data=graphData2, aes(x=long, y=lat, group=group, fill=value)) + 
  coord_equal() +
  geom_path(data=graphData2, aes(x=long, y=lat, group=group), color="black", size=0.2, alpha=0.2) +
  theme_void() +  
  scale_fill_gradient2(low='#9aeaea', mid='#216fff', high='#0606aa', 
                       na.value = "grey70", space = "Lab", midpoint = med, ## play around with this to get the gradient that you want, depending on data values 
                       breaks=round(seq(0, max, by=((max-min)/4)), digits = -3), 
                       limits=c(0,max), labels = scales :: comma) +
  labs(title= title, 
       fill='Count', caption = "") + 
  theme( plot.caption = element_text(size = 12), plot.title = element_text(size = 16))

# RDTs received
dt_subset3 = dt_pnlp_17[indicator == "RDT" & subpopulation == "received", ]
title = "RDTs received"

graphData3 <- merge(dt_subset3, coordinates, by.x=c('dps'), by.y=c('id'), all=TRUE)

max = max(graphData3$value, na.rm=TRUE)
min = min(graphData3$value, na.rm=TRUE)
med = max/2

m3 <- ggplot() + 
  geom_polygon(data=graphData3, aes(x=long, y=lat, group=group, fill=value)) + 
  coord_equal() +
  geom_path(data=graphData3, aes(x=long, y=lat, group=group), color="black", size=0.2, alpha=0.2) +
  theme_void() +  
  scale_fill_gradient2(low='#9aeaea', mid='#216fff', high='#0606aa', 
                       na.value = "grey70", space = "Lab", midpoint = med, ## play around with this to get the gradient that you want, depending on data values 
                       breaks=round(seq(0, max, by=((max-min)/4)), digits = -3), 
                       limits=c(0,max), labels = scales :: comma) +
  labs(title= title, 
       fill='Count', caption = "Source: Programme National de Lutte contre le Paludisme (PNLP)") + 
  theme( plot.caption = element_text(size = 12), plot.title = element_text(size = 16))

g <- grid.arrange(m1, m2, m3, ncol = 3)

file_name = "Commodities received by DPS, 2017"
pdf( paste0(out_dir, file_name, ".pdf"), height = 8, width = 16 )
grid.draw(g)
dev.off()
# ---------------------------------------------------

# ---------------------------------------------------
# further prep snis
# ---------------------------------------------------
dt_17 <- dt[ year == "2017", ]
dt_17$type <- trimws(dt_17$type)  # for some reason there is both "malaria" and "malaria " in the type unique values
dt_17_mal <- dt_17[ type== "malaria", ]

dt_17_mal$element <- trimws(dt_17_mal$element)
dt_17_mal$element_eng <- trimws(dt_17_mal$element_eng)

# get rid of outliers 
snis <- copy(dt_17_mal)
check <- snis[element_eng %in% c("A 1.4 Confirmed simple malaria", "A 1.5 Confirmed simple malaria - pregnant woman", "A 1.4 Confirmed simple malaria treated", "A 1.5 Confirmed simple malaria treated - pregnant woman")]
remove <- check[value >100000, .(date, org_unit, org_unit_id, element_eng, category, value)]
snis[element_eng %in% c("A 1.4 Confirmed simple malaria", "A 1.5 Confirmed simple malaria - pregnant woman", "A 1.4 Confirmed simple malaria treated", "A 1.5 Confirmed simple malaria treated - pregnant woman")
     & date == "2017-08-01" & org_unit_id == "IPKBcNL59e6" & category == "default", value := NA]
snis[element_eng %in% c("A 1.4 Confirmed simple malaria", "A 1.5 Confirmed simple malaria - pregnant woman", "A 1.4 Confirmed simple malaria treated", "A 1.5 Confirmed simple malaria treated - pregnant woman")
     & date == "2017-04-01" & org_unit_id == "R07kYRGTVuV" & category %in% c('>5 ans', '<5 ans'), value := NA]
dt_17_mal <- copy(snis)

dt_17_mal[element== "A 2.1 MILD distribu�s a la CPN2+", element_eng := "LLIN_distAtANC"]
dt_17_mal[element== "A 2.1 MILD distribu�s a la CPN1", element_eng := "LLIN_distAtANC"]
dt_17_mal[element== "A 1.4 TDR positif", element_eng := "RDT_positive"]
dt_17_mal[element== "A 1.4 TDR r�alis�", element_eng := "RDT_completed"]
dt_17_mal[element== "A 2.1 Sulfadox. + Pyrim�t 1�re dose re�ue", element_eng := "SP_1st"]
dt_17_mal[element== "A 2.1 Sulfadox. + Pyrim�t 2�me dose re�ue", element_eng := "SP_2nd"]
dt_17_mal[element== "A 2.1 Sulfadox. + Pyrim�t 3�me dose re�ue", element_eng := "SP_3rd"]
dt_17_mal[element== "A 2.1 Sulfadox. + Pyrim�t 4�me dose re�ue", element_eng := "SP_4th"]
dt_17_mal[element_eng== "A 1.4 Severe malaria", element_eng := "newCasesMalariaSevere_combinedAges"]
dt_17_mal[element_eng== "A 1.4 Severe malaria treated", element_eng := "severeMalariaTreated_combinedAges"]
dt_17_mal[element_eng== "A 1.4 Confirmed simple malaria", element_eng := "newCasesMalariaMild_combinedAges"]
dt_17_mal[element_eng== "A 1.4 Confirmed simple malaria treated", element_eng := "mildMalariaTreated_combinedAges"]
dt_17_mal[element_eng== "A 1.5 Confirmed simple malaria - pregnant woman", element_eng := "newCasesMalariaMild_pregnantWomen" ]
dt_17_mal[element_eng== "A 1.5 Confirmed simple malaria treated - pregnant woman", element_eng := "mildMalariaTreated_pregnantWomen" ]
dt_17_mal[element_eng== "A 1.5 Severe malaria - pregnant woman", element_eng := "newCasesMalariaSevere_pregnantWomen" ]
dt_17_mal[element_eng== "A 1.5 Severe malaria treated - pregnant woman", element_eng := "severeMalariaTreated_pregnantWomen" ]

# need to sum to health zone level
dt_snis_hz <- dt_17_mal[, .(value = sum(value, na.rm=TRUE)), by= c("date", "health_zone", "dps", "former_dps_name", "element_eng") ]

dt_snis_hz <- dt_snis_hz[, c("indicator", "subpopulation") := tstrsplit(element_eng, "_", fixed=TRUE)]
# ---------------------------------------------------

# ---------------------------------------------------
# map at health zone level
# ---------------------------------------------------
coordinates = as.data.table(fortify(shp_hz, region='index'))
shp_hz@data$index <- as.character(shp_hz@data$index)
coordinates <- merge(coordinates, shp_hz@data, by.x='id', by.y='index', all.x=TRUE)

dps_names <- as.data.table(dps_names)
dps_names <- dps_names[, .(old_name, new_name)]
setnames(dps_names, "old_name", "former_dps_name")
dt_pnlp_hz <- merge(dt_pnlp_hz, dps_names, by.x="dps", by.y="new_name", all.x=TRUE)

# 3. Map showing Patients treated divided by cases notified, 
#       Severe cases treated divided by severe cases notified and 
#       ACTs used during ANC divided by ANC visits

# subset
snis_subset <- dt_snis_hz[ indicator %in% c( "newCasesMalariaMild",  "mildMalariaTreated", "newCasesMalariaSevere", "severeMalariaTreated") &
                             !(subpopulation %in% c("2nd", "4th", "3rd")),]
pnlp_subset <- dt_pnlp_hz[ indicator %in% c( "newCasesMalariaMild",  "mildMalariaTreated", "newCasesMalariaSevere", "severeMalariaTreated", "malariaDeaths", "SP", "ANC") &
                             !(subpopulation %in% c("2nd", "4th", "3rd")),]

# sum each across subpops
snis_subset <- snis_subset[, .(value = sum(value, na.rm=TRUE)), by= c("health_zone", "dps", "former_dps_name", "indicator") ]
setnames(pnlp_subset, "mean", "value")
pnlp_subset <- pnlp_subset[, .(value = sum(value, na.rm=TRUE)), by= c("health_zone", "dps", "former_dps_name", "indicator") ]

# cast
snis_subset <- dcast.data.table(snis_subset, health_zone + dps + former_dps_name ~ indicator)
pnlp_subset <- dcast.data.table(pnlp_subset, health_zone + dps + former_dps_name ~ indicator)

# calculation
snis_subset <- snis_subset[, .(pct_mild_treated = ((mildMalariaTreated / newCasesMalariaMild)*100), 
                               pct_severe_treated = ((severeMalariaTreated / newCasesMalariaSevere)*100)), 
                           by= c("health_zone", "dps", "former_dps_name")]
pnlp_subset <- pnlp_subset[, .(pct_mild_treated = (mildMalariaTreated / newCasesMalariaMild), 
                               pct_severe_treated = (severeMalariaTreated / newCasesMalariaSevere), 
                               SP_over_ANC = ((SP / ANC)*100),
                               deaths_per_1kcases_all = (malariaDeaths / (newCasesMalariaMild + newCasesMalariaSevere)) * 1000),
                           by= c("health_zone", "dps", "former_dps_name")]
# # melt
# snis_subset <- melt.data.table(snis_subset, id.vars = c("health_zone", "dps", "former_dps_name"), variable.name = "indicator")
# pnlp_subset <- melt.data.table(pnlp_subset, id.vars = c("health_zone", "dps", "former_dps_name"), variable.name = "indicator")

# # CHANGE THIS LINE TO MAKE EACH SUBSEQUENT SET OF FIGURES
# dt_subset <- snis_subset[ indicator == "pct_mild_treated", ]

#change outliers
snis_subset[pct_mild_treated > 400, pct_mild_treated := NA]
snis_subset[pct_mild_treated > 100, pct_mild_treated := 100]
snis_subset[pct_severe_treated > 100, pct_severe_treated := 100]
snis_subset[pct_mild_treated < 80, pct_mild_treated := 80]
snis_subset[pct_severe_treated < 50, pct_severe_treated := 50]
pnlp_subset[SP_over_ANC > 100, SP_over_ANC := 100]

graphData <- merge(snis_subset, coordinates, by.x=c('health_zone', 'former_dps_name'), by.y=c('Name', 'PROVNAME'), all=TRUE)

library(RColorBrewer)
mapColors = brewer.pal(10, 'RdYlBu')

# % uncomplicated cases treated
max = max(graphData$pct_mild_treated, na.rm=TRUE)
min = min(graphData$pct_mild_treated, na.rm=TRUE)

m1_snis <- ggplot() + 
  geom_polygon(data=graphData, aes(x=long, y=lat, group=group, fill=pct_mild_treated)) + 
  coord_equal() +
  geom_path(data=graphData, aes(x=long, y=lat, group=group), color="black", size=0.2, alpha=0.2) +
  theme_void() +  
  scale_fill_gradientn(colors=mapColors, 
                       na.value = "grey70", space = "Lab", 
                       breaks=c(80, 85, 90, 95, 100), 
                       limits=c(min,max)) +
  labs(title="A) Percent of uncomplicated malaria cases treated", 
       fill='Percent treated', 
       caption= "    ")+ 
  theme(  plot.caption = element_text(size = 16), plot.title = element_text(size = 20) )
m1_snis

# % severe cases treated
max = max(graphData$pct_severe_treated, na.rm=TRUE)
min = min(graphData$pct_severe_treated, na.rm=TRUE)

m2_snis <- ggplot() + 
  geom_polygon(data=graphData, aes(x=long, y=lat, group=group, fill=pct_severe_treated)) + 
  coord_equal() +
  geom_path(data=graphData, aes(x=long, y=lat, group=group), color="black", size=0.2, alpha=0.2) +
  theme_void() +  
  scale_fill_gradientn(colors=mapColors, 
                       na.value = "grey70", space = "Lab", 
                       breaks=c(50, 60, 70, 80, 90, 95), 
                       limits=c(min,max)) +
  labs(title="B) Percent of severe malaria cases treated", 
       fill='Percent treated', 
       caption='Source: SNIS') + 
  theme(  plot.caption = element_text(size = 16), plot.title = element_text(size = 20) )
m2_snis

file_name = "map_test"
pdf( paste0(out_dir, file_name, ".pdf"), height = 9, width = 14 )
print(m1_snis)
print(m2_snis)
dev.off() 

# # % ANC visits with SP administered
# graphData2 <- merge(pnlp_subset, coordinates, by.x=c('health_zone', 'former_dps_name'), by.y=c('Name', 'PROVNAME'), all=TRUE)
# 
# max = max(graphData2$SP_over_ANC, na.rm=TRUE)
# min = min(graphData2$SP_over_ANC, na.rm=TRUE)
# 
# m3_pnlp <- ggplot() + 
#   geom_polygon(data=graphData2, aes(x=long, y=lat, group=group, fill=SP_over_ANC)) + 
#   coord_equal() +
#   geom_path(data=graphData2, aes(x=long, y=lat, group=group), color="black", size=0.2, alpha=0.2) +
#   theme_void() +  
#   scale_fill_gradientn(colors=mapColors, 
#                        na.value = "grey70", space = "Lab", 
#                        breaks=c(30, 60, 80, 95, 100), 
#                        limits=c(min,max)) +
#   labs(title="Percent of ANC visits with \nSP administered, 2017", 
#        fill='Percent', 
#        caption= "Source: PNLP")+ 
#   theme(  plot.caption = element_text(size = 16), plot.title = element_text(size = 20) )
# m3_pnlp


g <- grid.arrange(m1_snis, m2_snis, ncol = 2)

out_dir = 'C:/Users/abatzel/Desktop/malaria_results_chain_copy/added_vis_off_J/'
file_name = "maps_figure3"
pdf( paste0(out_dir, file_name, ".pdf"), height = 9, width = 14 )
grid.draw(g)
dev.off() 

# 4. Map showing Deaths divided by cases notified, 
#       Maternal deaths (or deaths among reproductive-aged women if necessary) divided by maternal cases notified and 
#       Cases notified divided by lag(cases notified) over time since the start of the data




