# ----------------------------------------------
# AUTHOR: Emily Linebarger, based on code written by Irena Chen
# PURPOSE: Prep commonly-formatted PU/DRs across countries. 
# DATE: Last updated January 2019. 

# For this function to work properly, a file must have a section labeled "Modular approach" with columns for module, intervention, budget, and expenditure. 
# Returns a file called budget dataset with columns for module, intervention, budget, and expenditure. 
# ----------------------------------------------

#Sheet names that don't work so far: "LFA EFR_7", "LFA_Annex-SR Financials", "LFA_Total PR Cash Outflow_3", "LFA_Total PR Cash Outflow_3A"

# start function
prep_cost_category =  function(dir, inFile, sheet_name, start_date, period, qtr_number) {
  
  #TROUBLESHOOTING HELP
  #Uncomment variables below and run line-by-line. 
  # Set up file path 
  # folder = "budgets"
  # folder = ifelse (file_list_subset$data_source[i] == "pudr", "pudrs", folder)
  # if (file_list_subset$file_iteration[i]=="initial"){
  #   version = "iterations"
  # } else if (file_list_subset$file_iteration[i]=="revision"){
  #   version= "revisions"
  # } else {
  #   version = ""
  # }
  # grant_period = file_list_subset$grant_period[i]
  # 
  # file_dir = paste0(master_file_dir, file_list_subset$grant_status[i], "/", file_list_subset$grant[i], "/", grant_period, "/", folder, "/")
  # if (version != ""){
  #   file_dir = paste0(file_dir, version, "/")
  # }
  # dir = file_dir
  # inFile = file_list_subset$file_name[i]
  # sheet_name = file_list_subset$sheet_financial[i]
  # start_date = file_list_subset$start_date_financial[i]
  # period = file_list_subset$period[i]
  # disease = file_list_subset$disease[i]
  # grant = file_list_subset$grant[i]
  # recipient = file_list_subset$primary_recipient
  # source = file_list_subset$data_source[i]
  # qtr_number = file_list_subset$qtr_number[i]

  # -----------------------------------------------------------------------------
  # Test the inputs to make sure that they are the correct type
  if (class(inFile)!='character') stop('Error: inFile argument must be a string!')
  if (class(year)=='character') stop('Error: year argument must be a number!')
  # -----------------------------------------------------------------------------
  # Files and directories
  
  #Sanity check: Is this sheet name one you've checked before? 
  verified_sheet_names <- c('LFA Expenditure_7B', 'LFA AFR_7B', 'PR Expenditure_7A', 'RFA ALF_7B', 'ALF RFR_7')
  if (!sheet_name%in%verified_sheet_names){
    print(sheet_name)
    stop("This sheet name has not been run with this function before - Are you sure you want this function? Add sheet name to verified list within function to proceed.")
  }
  
  # Load/prep data
  gf_data <-data.table(read.xlsx(paste0(dir,inFile), sheet=sheet_name, detectDates=TRUE))

  #General function for grants.
  #-------------------------------------
  # 1. Subset columns.
  #-------------------------------------
  #Find the correct column indices based on a grep condition.
  cost_grouping_col = grep("cost grouping", tolower(gf_data))
  budget_col <- grep("Budget for Reporting Period", gf_data)
  expenditure_col <- grep("Actual Expenditure", gf_data)
  lfa_adjustment_col <- grep("Local Fund Agent Adjustment on Expenditures", gf_data)
  cumulative_budget_col = grep("Cumulative Budget", gf_data)
  cumulative_expenditure_col = grep("Cumulative Expenditure|Cumulative Actual Expenditure", gf_data)
  

  #Remove the 'cumulative expenditure' and 'cumulative budget' columns.
  if (length(expenditure_col)!=1){
    cumulative_expenditure_drop <- grep("Cumulative Expenditure|Cumulative Actual Expenditure", gf_data) #Remove the 'cumulative expenditure' column.
    for (i in 1:length(expenditure_col)){
      if (expenditure_col[i] %in% cumulative_expenditure_drop){
        expenditure_col = expenditure_col[-i]
      }
    }
  }

  if (length(budget_col)!=1){
    cumulative_budget_drop <- grep("Cumulative Budget", gf_data)
    for (i in 1:length(budget_col)){
      if (budget_col[i] %in% cumulative_budget_drop){
        budget_col = budget_col[-i]
      }
    }
  }

  #Validate these column indices, and assign column names.
  stopifnot(length(budget_col)==1 & length(expenditure_col)==1)
  colnames(gf_data)[budget_col] <- "budget"
  colnames(gf_data)[expenditure_col] <- "expenditure"
  if (sheet_name!="PR Expenditure_7A"){
    stopifnot(length(lfa_adjustment_col)==1)
    colnames(gf_data)[lfa_adjustment_col] <- "lfa_exp_adjustment"
  }

  #Check to see if you grabbed cost category correctly
  if (length(cost_grouping_col)>1){
    comments_col = grep("comments", tolower(gf_data))
    cost_grouping_col = cost_grouping_col[!cost_grouping_col%in%comments_col]
  }
  stopifnot(length(cost_grouping_col)==1)
  colnames(gf_data)[cost_grouping_col] <- "cost_category"
  
  
  #Validate cumulative columns 
  if (length(cumulative_budget_col)>1) cumulative_budget_col = cumulative_budget_col[1]
  stopifnot(length(cumulative_budget_col)==1)
  colnames(gf_data)[cumulative_budget_col] <- "cumulative_budget"
  stopifnot(length(cumulative_expenditure_col)==1)
  colnames(gf_data)[cumulative_expenditure_col] <- "cumulative_expenditure"
  
  
  #Subset to only these columns.
  if (sheet_name!="PR Expenditure_7A"){
    gf_data = gf_data[, .(cost_category, budget, expenditure, lfa_exp_adjustment, cumulative_budget, cumulative_expenditure)]
  } else {
    gf_data = gf_data[, .(cost_category, budget, expenditure, cumulative_budget, cumulative_expenditure)]
  }
  
  #Make budget and expenditure numeric, and make LFA expenditure adjustment column 0 if NA (for subtraction later). 
  for (var in c('budget', 'expenditure', 'cumulative_budget', 'cumulative_expenditure')){
    gf_data[, (var):=as.numeric(get(var))]
  } 
  
  if (sheet_name!="PR Expenditure_7A"){
    gf_data[, lfa_exp_adjustment:=as.numeric(lfa_exp_adjustment)]
    gf_data[is.na(lfa_exp_adjustment), lfa_exp_adjustment:=0]
  }

  #-------------------------------------
  # 2. Subset rows
  #-------------------------------------
  #Select only the section of the excel that's broken up by intervention
  start_row <- grep("costing dimension", tolower(gf_data$cost_category))
  end_row <- grep("grand total|total général", tolower(gf_data$cost_category))

  x = 1
  while (end_row[x] < start_row){
    x = x + 1
  }
  end_row = end_row[x]

  #Validate that these are correct
  stopifnot(length(start_row)==1 & length(end_row)==1)
  gf_data = gf_data[start_row:end_row, ]

  #Rename data, and remove invalid rows
  if ('lfa_exp_adjustment'%in%names(gf_data)){
  check_drop <- gf_data[((is.na(cost_category) | cost_category == '0' | cost_category=="Veuillez sélectionner..." ) 
                         & (is.na(budget)|budget==0) & (is.na(expenditure)|expenditure==0) & (is.na(lfa_exp_adjustment) | lfa_exp_adjustment==0)), ]
  } else { 
    check_drop <- gf_data[((is.na(cost_category) | cost_category == '0' | cost_category=="Veuillez sélectionner..." ) 
                           & (is.na(budget)|budget==0) & (is.na(expenditure)|expenditure==0)), ]
  }
  if (verbose == TRUE){
    print(paste0("Invalid rows currently being dropped: (only module and intervention columns shown) ", check_drop[, c('cost_category')]))
  }
  if ('lfa_exp_adjustment'%in%names(gf_data)){
    gf_data =  gf_data[!((is.na(cost_category) | cost_category == '0' | cost_category=="Veuillez sélectionner..." ) 
                        & (is.na(budget)|budget==0) & (is.na(expenditure)|expenditure==0) & (is.na(lfa_exp_adjustment) | lfa_exp_adjustment==0)), ]
  } else {
    gf_data = gf_data[!((is.na(cost_category) | cost_category == '0' | cost_category=="Veuillez sélectionner..." ) 
                       & (is.na(budget)|budget==0) & (is.na(expenditure)|expenditure==0)), ]
  }

  #Some datasets have an extra title row with "[Module]" in the module column.
  #It's easier to find this by grepping the budget column, though.
  extra_category_row <- grep("costing dimension", tolower(gf_data$cost_category))
  if (length(extra_category_row) > 0){
    if (verbose == TRUE){
      print(paste0("Extra rows being dropped in cost category prep function. First column: ", gf_data[extra_category_row, 1]))
    }
    gf_data <- gf_data[-extra_category_row, ,drop = FALSE]
  }

  #Remove 'total' and 'grand total' rows
  total_rows <- grep("total", tolower(gf_data$cost_category))
  if (length(total_rows) > 0){
    if (verbose == TRUE){
      print(paste0("Total rows being dropped in GTM PU/DR prep function. First column: ", gf_data[total_rows, 1]))
    }
    gf_data <- gf_data[-total_rows, ,drop = FALSE]
  }

  #Replace any modules or interventions that didn't have a pair with "Unspecified".
  gf_data[is.na(cost_category) | cost_category == '0' | cost_category == "Veuillez sélectionner..." , cost_category:="Unspecified"]

  #-------------------------------------------------------------------------
  # 3. Generate date variables, and expand data to be at the quarter-level. 
  #-------------------------------------------------------------------------
  #Sum out any duplicates at this point - this should never happen, but it does (example: "LFA_COD-H-MOH_PUDR_2017_v25.05.17_v1_CORRECTIONSLFA_May2018.xlsx") EL 9/24/2019 
  if ('lfa_exp_adjustment'%in%names(gf_data)){
    gf_data = gf_data[, .(budget=sum(budget, na.rm=T), expenditure=sum(expenditure, na.rm=T),
                          lfa_exp_adjustment=sum(lfa_exp_adjustment, na.rm=T), cumulative_budget=sum(cumulative_budget, na.rm=T), 
                          cumulative_expenditure=sum(cumulative_expenditure, na.rm=T)), 
                      by=c('cost_category')]
  } else {
    gf_data = gf_data[, .(budget=sum(budget, na.rm=T), expenditure=sum(expenditure, na.rm=T), cumulative_budget=sum(cumulative_budget, na.rm=T), 
                          cumulative_expenditure=sum(cumulative_expenditure, na.rm=T)), 
                      by=c('cost_category')]
  }
  #Run this check to make sure everything is the same after you divide into quarters. 
  totals_check = gf_data[, .(budget=sum(budget, na.rm = TRUE), expenditure=sum(expenditure, na.rm=TRUE))]
  
  #Add in date variables 
  gf_data[, quarter:=quarter(start_date)]
  gf_data[, year:=year(start_date)]
  
  gf_data[, period:=period]
  gf_data[, qtr_number:=qtr_number]
  gf_data[, qtr_split:=round((period*qtr_number)/90)]
  gf_data[, split:=round((period*qtr_number)/90)] #Create this variable twice so you can divide budget/expenditure after expansion
 
  #Expand data by the number of days, and generate a variable to iterate over
  gf_data <- expandRows(gf_data, "qtr_split")
  byVars = names(gf_data)
  gf_data[, seq:=sequence(.N), by=byVars]
  gf_data[, seq:=seq-1] #Decrement by 1 because sequence indexes at 1. 
  
  #While seq is not 0, go through the loop below.
  #If seq is greater than or equal to 4, add 1 to year and divide everything by 4. Continue this loop while max(seq) > 4.
  # If month + seq + 1 equals 12, than
  gf_data[, new_qtr:=quarter+seq]
  max_quarter = max(gf_data$new_qtr)
  while (max_quarter>4){
    gf_data[new_qtr>4, year:=year+1]
    gf_data[new_qtr>4, new_qtr:=new_qtr-4]
    max_quarter = max(gf_data$new_qtr)
  }

  #Split up budget and expenditure.
  gf_data[, budget:=budget/split]
  gf_data[, expenditure:=expenditure/split]
  gf_data[, cumulative_budget:=cumulative_budget/split]
  gf_data[, cumulative_expenditure:=cumulative_expenditure/split]
  if (sheet_name!="PR Expenditure_7A"){
    gf_data[, lfa_exp_adjustment:=lfa_exp_adjustment/split]
  }

  #Make sure you haven't changed any budget/expenditure numbers, and clean up
  totals_check2 = gf_data[, .(budget=sum(budget, na.rm = TRUE), expenditure=sum(expenditure, na.rm=TRUE))]
  for (i in 1:nrow(totals_check)){
    stopifnot(totals_check$budget[i]==totals_check2$budget[i] | totals_check$expenditure[i]==totals_check2$expenditure[i])
  }
  gf_data = gf_data[, -c('period', 'qtr_number', 'split', 'seq', 'quarter')]
  setnames(gf_data, 'new_qtr', 'quarter')
  
  #Generate new start date variable. 
  gf_data[quarter==1, month:="01"]
  gf_data[quarter==2, month:="04"]
  gf_data[quarter==3, month:="07"]
  gf_data[quarter==4, month:="10"]
  
  gf_data[, start_date:=paste0(month, "-01-", year)]
  gf_data[, start_date:=as.Date(start_date, "%m-%d-%Y")]
  gf_data[, month:=NULL]

  #-------------------------------------
  # 4. Validate data
  #-------------------------------------
  budget_dataset = gf_data

  #Check these by summing the total for the file, and making sure it's not 0.
  check_budgets = budget_dataset[ ,
                  lapply(.SD, sum, na.rm = TRUE),
                  .SDcols = c("budget", "expenditure")]

  verified_0_expenditure <- c("UGA-C-TASO_PU_PEJune2017_LFA_30Nov17.xlsx", "UGA-M-TASO_PU_PEJune2017_LFA_30Nov17.xlsx", 
                              "UGA-S-TASO_PU_PEJune2017_LFA_30Nov17.xlsx", "GTM-T-MSPAS_Progress Report_31Dec2017 LFA REVIEW.xlsx", 
                              "GTM-T-MSPAS_Progress Report jul _31Dec2018_v2  rev LFA.xlsx", "GTM-H-HIVOS_Progress Report_31Dec2018_v1.xlsx", 
                              "GTM-T-MSPAS_Progress Report_LFA18Mar19.xlsx", "Core_SANRU_PU_P3141116.xlsm", "PSI PU NFM S1 2016 09102016.xlsm", 
                              "Core_PUDR_P30_HivosGT_231116_ LFA Signed.xlsx", "Core_PUDR_MALARIA_P12_03-03-17_Revisado ALF.xlsx",  
                              "GTM-T-MSPAS_Progress Report_31Dec2017 LFA REVIEW.XLSX", "GTM-M-MSPAS_Progress Report_30Jun2019_REV LFA.XLSX") #These files have 0 for all expenditure.
  verified_0_budget <- c("Core_SANRU_PU_P3141116.xlsm", "PSI PU NFM S1 2016 09102016.xlsm", "Core_PUDR_P30_HivosGT_231116_ LFA Signed.xlsx", 
                         "Core_PUDR_MALARIA_P12_03-03-17_Revisado ALF.xlsx") #These files have 0 budgeted - maybe this was a draft file. 
  
  if (!inFile%in%verified_0_expenditure){ #If expenditure shouldn't be 0, check it. 
    stopifnot(check_budgets[, 2]>0)
  } else if (!inFile%in%verified_0_budget){ #If budget shouldn't be 0, check it.  
    stopifnot(check_budgets[, 1]>0)
  } else if (!(inFile%in%verified_0_expenditure & inFile%in%verified_0_budget)){ #Check both budget and expenditure 
    stopifnot(check_budgets[, 1]>0 & check_budgets[, 2]>0)
    if (verbose){
      print("File has verified 0 budget and 0 expenditure.")
    }
  } 
  
  if (verbose){
    if (inFile%in%verified_0_expenditure){
      print("File has verified 0 expenditure.")
    } else if (inFile%in%verified_0_budget){
      print("File has verified 0 budget.")
    }
  }

  # -------------------------------


  return(budget_dataset)

}


