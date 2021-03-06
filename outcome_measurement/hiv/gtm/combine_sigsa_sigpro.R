#----------------------------------------
# Audrey Batzel
# 6/26/2019
# Combine SIGSA / SIGPRO data
#----------------------------------------

#-----------------------
# Install packages 
# ----------------------
rm(list=ls())
library(lubridate)
library(data.table)
library(ggplot2)
library(stringr)
# ----------------------

#----------------------------------------
# Set up directories 
#----------------------------------------
# detect if operating on windows or on the cluster 
j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')

# set working and output directories
dir = paste0(j, '/Project/Evaluation/GF/outcome_measurement/gtm/hiv/prepped/')

sigpro_files = list.files(paste0(dir, 'intermediate_prepped/sigpro/'), recursive=TRUE)
sigsa_files  = list.files(paste0(dir, 'intermediate_prepped/sigsa/'), recursive=TRUE)

outFile = paste0(dir, "combined_sigsa_sigpro_updated_12_03_19.rds")
#----------------------------------------

#----------------------------------------
# read in the data 
#----------------------------------------
# list existing files
sigsa = readRDS(paste0(dir, 'intermediate_prepped/sigsa/', sigsa_files[[1]]))

# import the files into distinct data tables
f2 = readRDS(paste0(dir, 'intermediate_prepped/sigpro/', sigpro_files[[1]]))
f3 = readRDS(paste0(dir, 'intermediate_prepped/sigpro/', sigpro_files[[2]]))
f4 = readRDS(paste0(dir, 'intermediate_prepped/sigpro/', sigpro_files[[3]]))

#combine sigpro files
sigpro = rbindlist(list(f2, f3, f4), use.names = TRUE, fill = TRUE)

# like Guillermo said to do - remove where servicio tipo is Global Fund in sigsa
sigsa[, id := .I]
rm = sigsa[ service_type %in% c('Fondo Global SIDA (FGS)', 'Fondo Global SIDA'), ]
rm = rm[ date %in% sigpro$date, ]
nrow(rm)/nrow(sigsa)*100
sigsa = sigsa[!id %in% rm$id, ]
sigsa[, id := NULL]
#----------------------------------------

#----------------------------------------
# update kvp specifications in the sigpro data
#----------------------------------------
# create a gender category
sigpro[set %in% c("sigpro_f2_completo 2018.xlsx", "sigpro_f3_completo 2018.xlsx"), gender:=str_sub(cui, 1, 1)]
sigpro[gender=='m', gender:='Male']
sigpro[gender=='f', gender:='Female']
sigpro[gender=='t', gender:='Trans']
sigpro[is.na(gender), gender:='unknown']

# translate populations 
sigpro[pop=='hsh', pop:='msm']
sigpro[pop=='mts', pop:='csw'] #using commercial sex worker rather than 'female' because this is GF teminology 
sigpro[pop=='ppl', pop:='prisoner'] #ppl = personas privadas de la libertad

# changes based on discussion with Caitlin:
# where pop is trans, make gender = trans so we can analyse cross sectional risk groups
sigpro[pop=='trans', gender := "Trans"]
sigpro[grep('trans', subpop), gender := "Trans"]

# now that we have Trans as a gender category, set pop based on other risk groups for cross sectional analysis
sigpro[grep('hsh', subpop), pop := "msm"]
sigpro[subpop=='trans privadas de libertad', pop:='prisoner']
sigpro[subpop %in% c('trans trabajadora sexual', 'trans trabajadoras sexuales'), pop := 'csw']

#************ CHANGES TO DOUBLE CHECK/ASK CAITLIN: ************
# what to do about cases where mujeres = trans or male? and mixup of prisoners/ppl subpop and gender
# en via publica = csw for Female/mujeres but not for hsh?
sigpro[gender == "Female" & pop == "msm", gender := "Trans"]
# other specific risk groups...?
sigpro[ subpop=='hsh trabajador sexual' & pop=='msm', pop := 'msm_csw']
sigpro[grepl(subpop, pattern = "trans migrant"), gender := "Trans"]
sigpro[grepl(subpop, pattern = "trans migrant"), pop := "migrant"]

check = setorderv( unique(sigpro[, .(pop, subpop, gender)]), 'pop')
#----------------------------------------

#----------------------------------------
# create risk groups from in data
#----------------------------------------
unique(sigsa$risk_condition)
sigsa[ risk_condition == 'Trabajador Sexual', pop := 'csw']
sigsa[ risk_condition == 'Uniformado', pop := 'military']
sigsa[ risk_condition == 'Migrante ', pop := 'migrant']
sigsa[ risk_condition == 'Migrante', pop := 'migrant']
sigsa[ risk_condition == 'Privado de Libertad', pop := 'prisoner']

# where sexual orientation == trans, change gender to trans
sigsa[sexual_orientation == "Trans", gender:="Trans"]

#************ CHANGES TO DOUBLE CHECK/ASK CAITLIN: ************
# create msm category from sexual orientation: # should we exlude where MSM is pop and gender is Trans from MSM analysis, and include just in Trans? 
sigsa[gender == "Male" & sexual_orientation %in% c("Homosexual", "Bisexual"), unique(pop)]
sigsa[gender == "Male" & sexual_orientation %in% c("Homosexual", "Bisexual") & pop == "csw", pop := 'msm_csw']
sigsa[gender == "Male" & sexual_orientation %in% c("Homosexual", "Bisexual") & is.na(pop), pop := 'msm']
sigsa[gender == "Male" & sexual_orientation %in% c("Homosexual", "Bisexual") & pop == "prisoner", pop := 'msm_prisoner']
sigsa[gender == "Male" & sexual_orientation %in% c("Homosexual", "Bisexual") & pop == "military", pop := 'msm_military']
sigsa[gender == "Male" & sexual_orientation %in% c("Homosexual", "Bisexual") & pop == "migrant", pop := 'msm_migrant']
#----------------------------------------

#----------------------------------------
# format departments so they are the same between data sources
#----------------------------------------
setnames(sigsa, "health_area", "dept")
setnames(sigpro, "department", "dept")

sigsa[, match_dept := dept]
sigpro[, match_dept := dept]

sigpro[ match_dept == 'quich�', match_dept := "quich�"]
sigpro[ match_dept == 'solol�', match_dept := "solol�"]
sigpro[ match_dept == 'pet�n', match_dept := "pet�n"]
sigpro[ match_dept == 'solola', match_dept := "solol�"]
sigpro[ match_dept == 'suchitep�quez', match_dept := "suchitep�quez"]
sigpro[ match_dept == 'sacatep�quez', match_dept := "sacatep�quez"]
sigpro[ match_dept == 'suchitepequez', match_dept := "suchitep�quez"]
sigpro[ match_dept == 'sacatepequez', match_dept := "sacatep�quez"]
sigpro[ match_dept == 'quiche', match_dept := "quich�"]
sigpro[ match_dept == 'peten', match_dept := "pet�n"]
sigpro[ match_dept == 'quiche', match_dept := "quich�"]
sigpro[ match_dept == 'peten', match_dept := "pet�n"]
sigpro[ match_dept == 'pet�n', match_dept := "pet�n"]

sigsa[ match_dept == 'guatemala sur', match_dept := "guatemala"]
sigsa[ match_dept == 'guatemala nor-oriente', match_dept := "guatemala"]
sigsa[ match_dept == 'guatemala central', match_dept := "guatemala"]
sigsa[ match_dept == 'guatemala nor-occidente', match_dept := "guatemala"]
sigsa[ match_dept == 'pet�n sur oriental', match_dept := "pet�n"]
sigsa[ match_dept == 'pet�n sur occidental', match_dept := "pet�n"]
sigsa[ match_dept == 'pet�n norte', match_dept := "pet�n"]

sigpro[ match_dept == 'totonicap�n', match_dept := "totonicap�n"]
sigpro[ match_dept == 'totonicapan', match_dept := "totonicap�n"]

dept_sigsa = unique(sigsa$match_dept)
dept_sigpro = unique(sigpro$match_dept)

dept_sigsa[!dept_sigsa %in% dept_sigpro]
dept_sigpro[!dept_sigpro %in% dept_sigsa]
#----------------------------------------

#----------------------------------------
# combine sigsa and sigpro data sources - go back and make these changes in prep code so they're
# standardized from the get-go
#----------------------------------------
setnames(sigpro, "set", "file")
sigpro[, set := "sigpro"]
sigsa[, set := "sigsa"]

sigpro[ , month_date:=as.Date(paste0(year(date), '-', month(date), '-01'), '%Y-%m-%d')]

sigsa[hiv_testResult == 1, hiv_testResult := "reactive"]
sigsa[hiv_testResult == 0, hiv_testResult := "nonreactive"]

setnames(sigpro, "result", "hiv_testResult")
setnames(sigpro, "test_completed", "hiv_test")

sigpro[ referral == 'n', referred := '0']
sigpro[ referral == 's', referred := '1']

names(sigpro)[!names(sigpro) %in% names(sigsa)]

dt = rbindlist(list(sigsa, sigpro), use.names = TRUE, fill = TRUE)
drop_vars = c('test_done', 'pre_test', 'pre_test_completed', 'year', 'month')
dt[ , c(drop_vars) := NULL]
non_testing_vars = c('condoms_delivered', 'female_condoms_delivered', 'lube_tubes_delivered', 'lube_packets_delivered', 'pamphlets_delivered', 'informed_of_sif_result',
                     'condoms', 'female_condoms', 'flavored_condoms', 'lube_packets', 'lube_tubes', 'sif_result', 'referral')
dt[ , c(non_testing_vars) := NULL]

# # don't need date by day, we can make figures by month
# setnames(dt, 'month_date', 'date')

saveRDS(dt, outFile)
#----------------------------------------


