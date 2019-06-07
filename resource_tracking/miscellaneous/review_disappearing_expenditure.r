# Reviewing "Disappearing" expenditure from subsequent PUDRs. 

cod = fread("J:/Project/Evaluation/GF/resource_tracking/_gf_files_gos/cod/visualizations/cod_negative_expenditure.csv")
sen = fread("J:/Project/Evaluation/GF/resource_tracking/_gf_files_gos/sen/visualizations/sen_negative_expenditure.csv")
uga = fread("J:/Project/Evaluation/GF/resource_tracking/_gf_files_gos/uga/visualizations/uga_negative_expenditure.csv")

uga_exp = readRDS("J:/Project/Evaluation/GF/resource_tracking/_gf_files_gos/uga/prepped_data/final_expenditures.rds")

#There are no cases in Guatemala. 

all = rbind(cod, sen, uga, fill=TRUE)
nrow(all)

print(nrow(all[grant_period=="2018-2020"]))
