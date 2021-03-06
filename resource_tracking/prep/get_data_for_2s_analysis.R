# Subset Tableau data to the relevant data for the 4S framework analysis
# Only RSSH data for the approved in grant-making budgets
# Down to activity/cost input level
# -----------------------------------------------

# -----------------------------------------------
# set up
# -----------------------------------------------
library(data.table)

#Box filepaths - these should be used to source raw files, and to save final prepped files. 
user=as.character(Sys.info()[7])
box = paste0("C:/Users/",user,"/Box Sync/Global Fund Files/")

inFile = paste0(box, 'tableau_data/all_budget_revisions_activityLevel.csv')
inFile_frs = paste0(box, 'tableau_data/fr_budgets_all.csv')

outFile = paste0(box, 'tableau_data/rssh_2s_analysis_data_', Sys.Date(), '.csv')
outFile = gsub('-', '_', outFile)
# -----------------------------------------------

# -----------------------------------------------
#data for approved budgets
# -----------------------------------------------
dt = as.data.table(read.csv(inFile))
# subset data to just approved and RSSH:
dt = dt[budget_version == 'approved' & disease == 'rssh']
# set language based on country
dt[loc_name %in% c('DRC', 'Senegal'), gf_module_orig := gf_module_fr]
dt[loc_name %in% c('DRC', 'Senegal'), gf_intervention_orig := gf_intervention_fr]
dt[loc_name %in% c('Guatemala'), gf_module_orig := gf_module_esp]
dt[loc_name %in% c('Guatemala'), gf_intervention_orig := gf_intervention_esp]
dt[loc_name %in% c('Uganda'), gf_module_orig := gf_module]
dt[loc_name %in% c('Uganda'), gf_intervention_orig := gf_intervention]
setnames(dt, c('gf_module', 'gf_intervention'), c('gf_module_en', 'gf_intervention_en'))
# keep just the relevant columns
dt = dt[, .(loc_name, budget_version, grant, grant_period, gf_module_orig, gf_module_en, gf_intervention_orig, gf_intervention_en, 
            activity_description, cost_category, budget)]
# sort by country
setorderv(dt, cols = c('loc_name'))
# -----------------------------------------------

# -----------------------------------------------
# data for 2020 FRs
# -----------------------------------------------
dt2 = as.data.table(read.csv(inFile_frs))
# keep only 2020 FRs
dt2 = dt2[grant_period == '2021-2023' & data_source=='funding_request']

# clean implementer
dt2[ implementer == 'Ministry of Finance, Planning and Economic Development of the Government of the Republic of Uganda', pr := 'MoFPED']
dt2[ implementer == 'Ministry of Finance, Planning and Economic Development of the Republic of Uganda', pr := 'MoFPED']
dt2[ implementer == 'The AIDS Support Organisation (Uganda) Limited', pr := 'TASO']
dt2[ implementer == 'Ministry of Health and Population of the Government of the Democratic Republic of Congo', pr := 'MOH']
dt2[ implementer == 'PR Societe Civile' & fr_disease == 'hiv/tb', pr := 'CORDAID']

# # clean loc name 
# dt2[loc_name == 'cod', loc_name := 'DRC']
# dt2[loc_name == 'uga', loc_name := 'Uganda']
# dt2[loc_name == 'sen', loc_name := 'Senegal']
# dt2[loc_name == 'gtm', loc_name := 'Guatemala']

# subset to just RSSH activities
dt2 = dt2[rssh==TRUE]

# sum to activity/cost category level 
dt2 = dt2[, .(budget = sum(budget, na.rm = TRUE)), by = c('loc_name', 'file_name', 'budget_version', 'implementer', 'grant_period', 'gf_module', 
                                                          'gf_intervention','orig_module', 'orig_intervention',  'activity_description', 'cost_category', 'fr_disease')]

# change fr_disease to fr_component
setnames(dt2, "fr_disease", "fr_component")

# add indicator for any rows that weren't in the previous file
previous_file = fread(paste0(box, "tableau_data/rssh_2s_analysis_data_2020_08_19.csv"))
previous_file = previous_file[,addition:="in previous 2s file from 08/19"]
previous_file = previous_file[,.(loc_name, activity_description, addition)]
previous_file = unique(previous_file)

# remove whitespace from merging variables
cols_trim <- c("loc_name","activity_description")
dt2[,(cols_trim) :=lapply(.SD,trimws),.SDcols = cols_trim]
previous_file[,(cols_trim) :=lapply(.SD,trimws),.SDcols = cols_trim]

# merge indicator column onto the new file
dt2 = merge(dt2, previous_file, by=c("loc_name","activity_description"), all.x = TRUE)

setcolorder(dt2, c("loc_name", "budget_version", "implementer", "grant_period", 
                   "file_name", "fr_component", "gf_module", "gf_intervention", "orig_module", "orig_intervention",
                   "activity_description", "cost_category", "budget", "addition"))

# -----------------------------------------------
# # Verify 
# # verified manually that there are no new GTM activities
#dt2[is.na(addition) & loc_name=="Guatemala", addition:="in previous 2s file from 08/19"]

# rename missing from additions column as "newly added activity"
dt2[is.na(addition), addition:= "newly added activity"]

# -----------------------------------------------
# combine and save data - should these actually be combined? implementer could go where grant goes? 
# -----------------------------------------------
write.csv(dt2, outFile, row.names = FALSE)
# -----------------------------------------------
