# ---------------------------------------------------------
# AUTHOR: Audrey Batzel, Emily Linebarger and David Phillips
# PURPOSE: Merge resource tracking, activity, and outputs data. 
# DATE: Last updated January 2019. 
# INSTRUCTIONS: The current working directory should be the root of this repo (set manually by user)
# ----------------------------------------------------------

# ----------------------------------------------------------
# Load data

#drc = readRDS("J:/Project/Evaluation/GF/impact_evaluation/cod/prepped_data/inputs_outputs.RDS") #For comparison

# Read in the previously saved files for resource tracking in 2a
resource_tracking <- readRDS(outputFile2a)
resource_tracking[, year:=floor(date)]
byVars = names(resource_tracking)[!names(resource_tracking)%in%c('date', 'year')]
resource_tracking = resource_tracking[, lapply(.SD, sum), by=year, .SDcols =! 'date']
setnames(resource_tracking, 'year', 'date')

# Read in the previously saved file for outputs/activities in 2b
outputs_activities <- readRDS(outputFile2b)
#Remove errors in names for outputs_activities here - but these need to be addressed earlier! 
names(outputs_activities) <- gsub("_value", "", names(outputs_activities))
# ----------------------------------------------------------


# -----------------------------------------------------------------------------------------------------
# Prep/merge data

# rectangularize before merge
departments = unique(outputs_activities$department)
departments = departments[!is.na(departments)]
frame = expand.grid(date = seq(START_YEAR-1, 2018, by=1), department = departments) #Because RSSH is lagged one year. 

#Inputs 
resource_tracking_rect = merge(frame, resource_tracking, by='date') #Do I need to divide resource tracking dollars here? 
setDT(resource_tracking_rect)
stopifnot(nrow(resource_tracking_rect[is.na(date) | is.na(department), ])==0)

#Outputs/Activities
outputs_activities_rect = merge(frame, outputs_activities, by=c('department','date'), all=TRUE)
setDT(outputs_activities_rect)
stopifnot(nrow(outputs_activities_rect[is.na(date) | is.na(department)])==0)

# Merge rectangularized resource tracking and outputs/activites data 
merge_file <- merge(resource_tracking_rect, outputs_activities_rect, by=c('department','date'), all=TRUE)
setDT(merge_file) #OK to here. 

#Check for uniqueness and NAs here. 
# -----------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------
# Distribute inputs by department proportionally to activities

# list variables that need redistribution
redistribution_mat = data.table(input_var = names(resource_tracking)[!names(resource_tracking)%in%c('date','department', 'year')])

#From diagram review, create redistribution variables (EL 8/13/2019) 
redistribution_mat[, redist_var:=paste0(input_var, "_redist")]

#Calculate redistribution variables in main dataset. 
#These calculations should be made dynamic if possible!! EL 8/13/19
# including date as a control variable in linkage 1 regressions because otherwise all RT variables are positively correlated (when GF and other should be negative)
source(paste0('./impact_evaluation/gtm/models/', modelVersion1, '.r'))

# reduce the data down to only necessary variables
parsedModel = lavParseModelString(model)
lhs = parsedModel$lhs
rhs = parsedModel$rhs
modelVars = data.table(lhs=lhs, rhs=rhs)
finVars = unique(redistribution_mat$input_var)

# For each financial variable, get a vector of what variables it's leading to in the model, 
# and add these together to create a redistribution amount. 
for (v in finVars){
  redist_vars = modelVars[rhs==(paste0(v, "_cumulative")), unique(lhs)] 
  merge_file[, paste0(v, "_redist"):=0]
  for (x in redist_vars){
    x = gsub("_cumulative", "", x)
    merge_file[, paste0(v, "_redist"):=sum(get(paste0(v, "_redist")), get(x), na.rm=T), by=c('date', 'department')]
  }
}

#Make a variable for the number of departments for equal distribution if needed. 
n_depts = length(departments)
equal_division = 1/n_depts 
# loop over financial variables and redistribute subnationally
for(i in 1:nrow(redistribution_mat)) {
  print(i)
	v = redistribution_mat[i, input_var]
	a = redistribution_mat[i, redist_var] #Changed from 'indicator' in DRC code EL 7.8.19

	# disallow zeroes
	# min_calc = merge_file[, min(get(a), na.rm=T)]
	# merge_file[, min:=min_calc]
	# merge_file[, mean:=mean(get(a), na.rm=TRUE), by=department]
	# merge_file[is.na(min), min:=0]
	# merge_file[is.na(mean), mean:=min]
	
	# disallow zeroes #Replaced code above with DRC code on 8/12/19 EL and DP
	min = min(merge_file[get(a)>0][[a]], na.rm=TRUE)
	merge_file[, mean:=mean(get(a), na.rm=TRUE), by=department]
	merge_file[is.na(mean), mean:=min]
	
	# set up redistribution coefficients
	merge_file[, tmp:=get(a)+min]
	merge_file[is.na(tmp), tmp:=mean]
	merge_file[, prop:=tmp/sum(tmp), by=date]
	
	#If there is no data for 'a' for a given year, divide the data equally between departments. 
	a_zeros = merge_file[, .(total=sum(get(a))), by='date']
	a_zeros = a_zeros[total==0]
	if (nrow(a_zeros)!=0){
	  print("Some input variables are being scaled equally among all departments,\nbecause there is no data for the next activity/output indicator for the following years")
	  print(a)
	  print(unique(a_zeros$date))
	  merge_file[date%in%a_zeros$date, prop:=equal_division]
	}

	#Check to make sure these redistribution variables sum to 1 by date (over all departments)
	check = merge_file[, .(prop=round(sum(prop, na.rm=TRUE))), by='date']
	print(paste0("Unique values of 'prop': ", unique(check$prop)))
	stopifnot(unique(check$prop)%in%c(0, 1)) #Changed from stopifnot(unique(check$prop)==1) by EL 8/7/19
	
	#Redistribute
	merge_file[, (v):=get(v)*prop]
	
	# test that it worked using original data
	orig = sum(resource_tracking[date<=2018][[v]], na.rm=TRUE) #Need to limit this to 2018, because RSSH is now going through 2019! 
	new = sum(merge_file[[v]], na.rm=TRUE)
	if (abs(orig-new)>.1) stop(paste0("Orig:", orig, " New:", new, 
	                                  " are not close for variable ", v, " (index ", i, ")")) 
}	
# --------------------------------------------------------------------------


# ----------------------------------------------------------
# Finish and save 

#Restrict years to begin at the global START_YEAR variable, specified in set_up_r
# This should have already happened back in data prep, but OK to leave here (EL 8/12/19) 
merge_file = merge_file[date>=START_YEAR-1] #Resource tracking RSSH is lagged one year. EL 10/2/2019

# drop unnecessary variables
merge_file = merge_file[, -c('mean','tmp','prop')] #Also removing 'min' EL 8/7/19

# save
saveRDS(merge_file, outputFile3)

# save a time-stamped version for reproducibility
archive(outputFile3)
# ----------------------------------------------------------

print("Step 3: merge data completed successfully.")
