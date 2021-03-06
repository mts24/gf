# ----------------------------------------------
# AUTHOR: Audrey Batzel and Francisco Rios Casas based on code by Emily Linebarger and Irena Chen
# PURPOSE: Prep commonly-formatted FR budgets
# DATE: Last updated June 2020.

# TO DO: 
# ----------------------------------------------
# PREP FR BUDGETS code taken directly from the prep general detail budget code and modified slightly

prep_target_populations = function(dir, inFile, sheet_name, start_date, period, qtr_num, language) {
  
  # # TROUBLESHOOTING HELP
  dir = file_dir
  inFile = file_list$file_name[i]
  sheet_name = "Population"
  start_date = file_list$start_date_financial[i]
  period = file_list$period_financial[i]
  disease = file_list$disease[i]
  qtr_num = file_list$qtr_number[i]
  language = file_list$language_financial[i]
  # -------------------------------------
  #Sanity check: Is this sheet name one you've checked before? 
  # verified_sheet_names <- c('Detailed Budget', 'Detailed budget')
  # if (!sheet_name%in%verified_sheet_names){
  #   print(paste0("Sheet name: '", sheet_name, "'"))
  #   stop("This sheet name has not been run with this function before - Are you sure you want this function? Add sheet name to verified list within function to proceed.")
  # }
  # 
  # KEEP_COLS = 5 #Number of columns that are extracted before the budget columns (Module, intervention, activity, cost category, and implementer)
  # 
  # # Load data
  gf_data = data.table(read.xlsx(paste0(dir,inFile), sheet=sheet_name, detectDates=TRUE))
  initial_rows = nrow(gf_data) #Save to run a check on later.
  # 
  # #-------------------------------------
  # # Remove diacritical marks
  # #-------------------------------------
  gf_data = gf_data[, lapply(gf_data, fix_diacritics)]
  # 
  # if (language == 'fr'){
  #   qtr_text = 'sorties de tresorerie'
  # } else if (language == 'eng'){
  #   qtr_text = 'cash outflow'
  # } else if (language=='esp'){
  #   qtr_text = "salida de efectivo"
  # }
  # 
  # #General function for grants.
  # #-------------------------------------
  # # 1. Subset columns.
  # #-------------------------------------
  # #Find the correct column indices based on a grep condition. (Want to keep module, intervention, and budget for all subpopuations)
  # 
  #General function for grants.
  #-------------------------------------
  # 1. Subset columns.
  #-------------------------------------
  #Find the correct column indices based on a grep condition.
  module_col <- grep("modul", tolower(gf_data))
  intervention_col <- grep("intervention|intervencion", tolower(gf_data))
  # create a breakdown for each year of the grant

  
  #Check to see if this file has module and intervention.
  if (is.na(module_col)){
    gf_data$module <- "Unspecified"
  } else {
    stopifnot(length(module_col)==1)
    colnames(gf_data)[module_col] <- "module"
  }
  
  if (is.na(intervention_col)){
    gf_data$intervention <- "Unspecified"
  } else {
    stopifnot(length(intervention_col)==1)
    colnames(gf_data)[intervention_col] <- "intervention"
  }
  
  # create a column for each key population
  ns_col <- grep("no espec", tolower(gf_data))
  agyw_col <- grep("adolescentes y mujeres jovenes", tolower(gf_data))
  msm_col <- grep("hsh", tolower(gf_data))
  
  # assign column names
  
  # break up data into table for each year
  
  # add indicator column for year
  
  # rbind the data together
  
  # create a breakdown for each year of the grant
  # there should be some code for this in the performance indicator data
  
  

  
  

  # #Remove "Module ID and Intervention Sub ID columns" 
  # mod_id_col = grep("module id|moduleid", names)
  # intervention_id_col = grep("intervention sub id|intervention salesforce id", names)
  # cat_budget_col = grep("catalytic budget", names)
  # 
  # # Remove columns that talk about conditional formatting
  # cond_format_col = grep('conditional formatting', names)
  # pop_breakdown_col = grep('interventions requiring population breakdown', names)
  # 
  # module_col = module_col[!module_col%in% c(mod_id_col, cond_format_col)]
  # intervention_col = intervention_col[!intervention_col%in% c(intervention_id_col, cat_budget_col, cond_format_col, pop_breakdown_col)] 
  # 
  # stopifnot(length(module_col)==1 & length(intervention_col)==1)
  # 

 # total_subset = c(module_col, intervention_col, activity_col, cost_category_col, implementer_col, budget_cols)
  # gf_data = gf_data[, total_subset, with=FALSE]
  # 
  # #Change column names using the name row you found before. 
  # names = names[total_subset]
  # names(gf_data) = names
  # #Do a sanity check here. 
  # if (language == 'eng' | language == 'fr'){
  #   if (inFile == "COD_M_SANRU NMF2 ANNEXE FINANCES  FORECAST  budget revisé 2018.xlsx"){
  #     stopifnot(names(gf_data[, 1]) == 'module' & names(gf_data[, 2]) == 'intervention revise')
  #   }else{
  #     stopifnot(names(gf_data[, 1]) == 'module' & names(gf_data[, 2]) == 'intervention')
  #   }
  # } else if (language == 'esp'){
  #   stopifnot(names(gf_data[, 1]) == 'modulo' & names(gf_data[, 2]) == 'intervencion')
  # }
  # 
  # #Do one more subset to grab only the budget columns with quarter-level data. (Keep the first 4 columns and everything that matches this condition)
  # budget_periods = names[KEEP_COLS:length(names)]
  # budget_periods = gsub(qtr_text, "", budget_periods)
  # 
  # if (language == "eng" | language == "esp"){ 
  #   quarter_cols = grep("q", names(gf_data))
  # } else if (language == 'fr'){
  #   quarter_cols = budget_periods[nchar(budget_periods)<=4] #Don't grab any total rows 
  #   quarter_cols = quarter_cols[!grepl("a", quarter_cols)]
  #   quarter_cols = paste0(qtr_text, quarter_cols)
  #   quarter_cols = as.character(quarter_cols)
  #   quarter_cols = grep(paste(quarter_cols, collapse="|"), names(gf_data))
  # }
  # 
  # second_subset = c(1:KEEP_COLS, quarter_cols) #Only keep module, intervention, activity description, and the budget columns by quarter
  # gf_data = gf_data[, second_subset, with = FALSE]
  # 
  # if (inFile=="COD_M_SANRU NMF2 ANNEXE FINANCES  FORECAST  budget revisé 2018.xlsx"){ # drop extra columns at the end of this file --Francisco 02.28.2020
  #   gf_data[,c("sorties de tresorerie t1  a t3 2018", "sorties de tresorerie t3 2018"):=NULL]
  # }
  # 
  # #Reset names for the whole thing 
  # quarters = ncol(gf_data)-KEEP_COLS
  # old_qtr_names = c()
  # for (i in 1:quarters){
  #   if(language == "eng" | language == "esp"){
  #     old_qtr_names[i] = paste0("q", i, " ", qtr_text)
  #   } else if (language == "fr"){
  #     old_qtr_names[i] = paste0(qtr_text, " t", i)
  #   }
  # }
  # 
  # new_qtr_names = c()
  # for (i in 1:quarters){
  #   new_qtr_names[i] = paste0("budget_q", i)
  # }
  # 
  # if (language == "eng"){
  #   if ('recipient'%in%names){
  #     old_names = c('activity description', 'cost input', 'recipient', old_qtr_names)
  #     new_names = c('activity_description', 'cost_category', 'implementer', new_qtr_names)
  #   } else {
  #     old_names = c('activity description', 'cost input', old_qtr_names)
  #     new_names = c('activity_description', 'cost_category', new_qtr_names)
  #   }
  # } else if (language == "fr") {
  #   if (inFile == "COD_M_SANRU NMF2 ANNEXE FINANCES  FORECAST  budget revisé 2018.xlsx"){ # added in to check specific file
  #     old_names = c("intervention revise", "description de l'activite", "element de cout", "entite de mise en œuvre", old_qtr_names)
  #     new_names = c("intervention", "activity_description", "cost_category", "implementer", new_qtr_names)
  #   } else if ("maitre d'œuvre"%in%names){
  #     old_names = c("description de l'activite", "element de cout", "maitre d'œuvre", old_qtr_names)
  #     new_names = c("activity_description", "cost_category", "implementer", new_qtr_names)
  #   } else if ("recipiendaire"%in%names){
  #     old_names = c("description de l'activite", "element de cout", "recipiendaire", old_qtr_names)
  #     new_names = c('activity_description', 'cost_category', "implementer", new_qtr_names)
  #   } else {
  #     old_names = c("description de l'activite", "element de cout", old_qtr_names)
  #     new_names = c('activity_description', 'cost_category', new_qtr_names)
  #   } 
  # } else if (language == "esp"){
  #   if ('implementador'%in% names){
  #     old_names = c('modulo', 'intervencion', 'descripcion de la actividad', 'categoria de gastos', "implementador", old_qtr_names)
  #     new_names = c('module', 'intervention', 'activity_description', 'cost_category', "implementer", new_qtr_names)
  #   } else if ('entidad ejecutora'%in%names){
  #     old_names = c('modulo', 'intervencion', 'descripcion de la actividad', 'categoria de gastos', "entidad ejecutora", old_qtr_names)
  #     new_names = c('module', 'intervention', 'activity_description', 'cost_category', "implementer", new_qtr_names)
  #   } else{
  #     old_names = c('modulo', 'intervencion', 'descripcion de la actividad', 'categoria de gastos', "receptor", old_qtr_names)
  #     new_names = c('module', 'intervention', 'activity_description', 'cost_category', "implementer", new_qtr_names)
  #   }
  # }
  # 
  # 
  # #If there is any whitespace in column names, remove it. 
  # names(gf_data) = trimws(names(gf_data))
  # if (inFile=="COD_M_SANRU NMF2 ANNEXE FINANCES  FORECAST  budget revisé 2018.xlsx"){
  #   names(gf_data) <- c("module", new_names) # this is because there are duplicate names in this specific file --Francisco 02.27.2020
  # } else {
  #   setnames(gf_data, old=old_names, new=new_names)
  # }
  # 
  # #-------------------------------------
  # # 2. Subset rows
  # #-------------------------------------
   stopifnot(nrow(gf_data)==initial_rows) #Make sure you haven't dropped anything until this point. 
  # #Remove the name row and everything before it, because we know the spreadsheet hasn't started before that point
  target_population_row = grep()
  # if(name_row!=1){
  #   gf_data = gf_data[-(1:name_row)]
  # }
  # 
  # #Remove rows where first 4 variables (module, intervention, activity, and cost category) are NA, checking that their sum is 0 for key variables first. 
  # check_na_sum = gf_data[is.na(module) & is.na(intervention) & is.na(activity_description) & is.na(cost_category)]
  # check_na_sum = melt(check_na_sum, id.vars = c('module', 'intervention', 'activity_description', 'cost_category'), value.name = "budget")
  # check_na_sum[, budget:=as.numeric(budget)]
  # na_budget = check_na_sum[, sum(budget, na.rm = TRUE)]
  # if (na_budget!=0){
  #   stop("Budgeted line items have NA for all key variables - review drop conditions before dropping NAs in module and intervention")
  # }
  # gf_data = gf_data[!(is.na(module) & is.na(intervention) & is.na(activity_description) & is.na(cost_category))]
  # 
  # # this Guatemala and Senegal file have extra blank row with only an activity description but that activity description already has a budget item (with mod and interv elsewhere)
  # if (inFile%in%c("05.Presupuesto_detallado_final.xlsx", "FR909-SEN-H_DB_template_Master_conso   Version finale du  29062020.xlsx",
  #                 "FR909-SEN-H_DB_template_Master_conso   Version finale du   07072020   - VF090720_19H30.xlsx")){
  #   gf_data = gf_data[!(is.na(module) & is.na(intervention))]
  # }
  # 
  # # this file has a blank row with a module and intervention filled in (as unspecified so I am removing)
  # if (inFile%in%c("FR909-SEN-H_DB_template_Master_conso   Version finale du  29062020.xlsx", 
  #                 "FR909-SEN-H_DB_template_Master_conso   Version finale du   07072020   - VF090720_19H30.xlsx")){
  #   gf_data = gf_data[!is.na(activity_description)]
  # }
  # 
  # # check empty module and interventions
  # check_empty <- nrow(gf_data[is.na(module) & is.na(intervention)])
  # if (check_empty>0){
  #   stop("Some Funding Requests are contain missing data check the module and intervention columns should both be blank.")
  # }
  # 
  # #Replace any modules or interventions that didn't have a pair with "Unspecified".
  # gf_data[is.na(module) & !is.na(intervention), module:="Unspecified"]
  # gf_data[!is.na(module) & is.na(intervention), intervention:="Unspecified"]
  # 
  # #Some datasets have an extra title row with "[Module]" in the module column.
  # #It's easier to find this by grepping the module column, though.
  # extra_module_row <- grep("module", tolower(gf_data$module))
  # if (length(extra_module_row) > 0){
  #   if (verbose == TRUE){
  #     print(paste0("Extra rows being dropped in FR prep function. First column: ", gf_data[extra_module_row, 1]))
  #   }
  #   gf_data <- gf_data[-extra_module_row, ,drop = FALSE]
  # }
  # 
  # 
  # #-------------------------------------
  # # 3. Reshape data long
  # #-------------------------------------
  # date_range = rep(start_date, quarters) #Make a vector of the date variables the quarters correspond to. 
  # for (i in 2:quarters){ 
  #   month(date_range[i]) = month(date_range[i]) + 3*(i-1) 
  # }
  # budget_dataset = melt(gf_data, id.vars = c('module', 'intervention', 'activity_description', 'cost_category', 'implementer'), 
  #                       value.name = "budget")
  # budget_dataset[, budget:=as.numeric(budget)] #Go ahead and make budget numeric at this point
  # 
  # #Replace "budget q1", etc. with the actual date it corresponds to. 
  # old_quarters = unique(budget_dataset$variable)
  # new_quarters = date_range
  # 
  # #For every value of old_quarters, if variable equals old_quarter
  # for (i in 1:length(old_quarters)){
  #   budget_dataset[variable == old_quarters[i], start_date:=new_quarters[i]]
  # }
  # 
  # budget_dataset = budget_dataset[, -c('variable')]
  # 
  # #Add quarter and year variables 
  # budget_dataset[, quarter:=quarter(start_date)]
  # budget_dataset[, year:=year(start_date)]
  # 
  # #-------------------------------------
  # # 4. Validate data
  # #-------------------------------------
  # #Drop rows of budgets that we know are invalid (File COD-M-PSI-SB2 has some extra rows at the bottom of the spreadsheet)
  # budget_dataset = budget_dataset[!(inFile == "COD-M-PSI_SB2.xlsx" & (module == "6" | module == "4"))]
  # 
  # #Make sure that the total budget is not 0 (was not converted from numeric correctly, or wrong column was grabbed.)
  # check_budgets = budget_dataset[ ,
  #                                 lapply(.SD, sum, na.rm = TRUE),
  #                                 .SDcols = c("budget")]
  # 
  # stopifnot(check_budgets[, 1]>0)
  # 
  # #Check column names, and that you have at least some valid data for the file.
  # if (nrow(budget_dataset)==0){
  #   stop(paste0("All data dropped for ", inFile))
  # }
  # 
  # #Make sure you have all the columns you need for analysis
  # check_names = c('module', 'intervention', 'cost_category', 'activity_description', 'budget', 'start_date', 'implementer')
  # stopifnot(check_names%in%names(budget_dataset))
  # 
  # #--------------------------------
  # # Note: Are there any other checks I could add here? #EKL
  # # -------------------------------
  # 
  # return(budget_dataset)
}
