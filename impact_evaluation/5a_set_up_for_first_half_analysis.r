# ------------------------------------------------
# David Phillips
# 
# 1/18/2019
# Final pre-processing for impact evaluation model
# This is built for the pilot dataset
# The current working directory should be the root of this repo (set manually by user)
# ------------------------------------------------

# TO DO
# how to implement counterfactual before calculating cumulatives and standardizing variance???

source('./impact_evaluation/_common/set_up_r.r')

# -----------------------------------------------------------------
# Load/prep data

# load
data = readRDS(outputFile3)

# make unique health zone names for convenience
data[, orig_health_zone:=health_zone]
data[, health_zone:=paste0(health_zone, '_', dps)]
data$dps = NULL

# last-minute prep that shouldn't be necessary after bugs are fixed
	# combine the two ITN budget categories since FGH can't distinguish
	data[, other_dah_M1_1:=other_dah_M1_1+other_dah_M1_2]
	data$other_dah_M1_2 = NULL
	
	# combine M2 (all case management) with M2_1 (facility tx) for GF budgets (one summary budget from 2015-2017 has it)
	data[, exp_M2_1:=exp_M2_1+exp_M2]
	data$exp_M2 = NULL
	
	# set other_dah to NA (not 0) after 2016
	for(v in names(data)[grepl('other_dah',names(data))]) data[date>=2017 & get(v)==0, (v):=NA]
	
	# drop M2_3 from other_dah for now because it's identifcal to M2_1
	# data$other_dah_M2_3 = NULL
	
	# iccm didn't exist prior to 2014, wasn't reported until 2015, consider it zero
	data[date<2015, value_ACTs_SSC:=0]
	
	# completeness reported as a percentage not proportion
	complVars = names(data)[grepl('completeness',names(data))]
	for(v in complVars) data[get(v)>1, (v):=get(v)/100]

# compute cumulative budgets
rtVars = names(data)
rtVars = rtVars[grepl('exp|other_dah', rtVars)]
for(v in rtVars) data[, (paste0(v,'_cumulative')):=cumsum(get(v)), by='health_zone']

# subset dates now that cumulative variables are computed
data = data[date>=2010 & date<2018.75]
# -----------------------------------------------------------------


# -----------------------------------------------------------------------
# Data transformations and other fixes for Heywood cases

# drop zero-variance variables
numVars = names(data)[!names(data)%in%c('orig_health_zone','health_zone')]
for(v in numVars) if (all(is.na(data[[v]]))) data[[v]] = NULL

# extrapolate where necessary TEMPORARY
i=1
for(v in numVars) {
	for(h in unique(data$health_zone)) { 
		i=i+1
		if (!any(is.na(data[health_zone==h][[v]]))) next
		if (!any(!is.na(data[health_zone==h][[v]]))) next
		form = as.formula(paste0(v,'~date'))
		lmFit = glm(form, data[health_zone==h], family='poisson')
		data[health_zone==h, tmp:=exp(predict(lmFit, newdata=data[health_zone==h]))]
		lim = max(data[health_zone==h][[v]], na.rm=T)+sd(data[health_zone==h][[v]], na.rm=T)
		data[health_zone==h & tmp>lim, tmp:=lim]
		# print(ggplot(data[health_zone==h], aes_string(y=v,x='date')) + geom_point() + geom_line(aes(y=tmp)) + labs(title=v))
		data[health_zone==h & is.na(get(v)), (v):=tmp]
		pct_complete = floor(i/(length(numVars)*length(unique(data$health_zone)))*100)
		cat(paste0('\r', pct_complete, '% Complete'))
		flush.console() 
	}
}
data$tmp = NULL

# now remake ghe_cumulative TEMPORARY
data[, ghe_cumulative:=cumsum(ghe), by='health_zone']
# data[, oop_cumulative:=cumsum(oop), by='health_zone']
data[, ITN_received_cumulative:=cumsum(value_ITN_received), by='health_zone']
data[, RDT_received_cumulative:=cumsum(value_RDT_received), by='health_zone']
data[, ACT_received_cumulative:=cumsum(value_ACT_received), by='health_zone']
data[, ITN_consumed_cumulative:=cumsum(value_ITN_consumed), by='health_zone']
data[, ACTs_SSC_cumulative:=cumsum(value_ACTs_SSC), by='health_zone']
data[, RDT_completed_cumulative:=cumsum(value_RDT_completed), by='health_zone']
data[, SP_cumulative:=cumsum(value_SP), by='health_zone']
data[, severeMalariaTreated_cumulative:=cumsum(value_severeMalariaTreated), by='health_zone']
data[, totalPatientsTreated_cumulative:=cumsum(value_totalPatientsTreated), by='health_zone']

# na omit (for health zones that were entirely missing)
data = na.omit(data)

# split before transformations
untransformed = copy(data)

# transform completeness variables using approximation of logit that allows 1's and 0's
# (Smithson et al 2006 Psychological methods "A better lemon squeezer")
smithsonTransform = function(x) { 
	N=length( x[!is.na(x)] )
	prop_lsqueeze = logit(((x*(N-1))+0.5)/N)
}
for(v in complVars) { 
	data[get(v)>1, (v):=1]
	data[, (v):=smithsonTransform(get(v))]
}

# log-transform all variables
logVars = c('ITN_consumed_cumulative','ACTs_SSC_cumulative','RDT_completed_cumulative','SP_cumulative','severeMalariaTreated_cumulative','totalPatientsTreated_cumulative')
for(v in logVars) data[, (v):=log(get(v))]
for(v in logVars) data[!is.finite(get(v)), (v):=quantile(data[is.finite(get(v))][[v]],.01,na.rm=T)]

# rescale variables to have similar variance
# see Kline Principles and Practice of SEM (2011) page 67
scaling_factors = data.table(date=1)
for(v in names(data)) { 
	if (v %in% c('orig_health_zone','health_zone','date')) next
	s=1
	while(var(data[[v]]/s)>1000) s=s*10
	while(var(data[[v]]/s)<100) s=s/10
	scaling_factors[,(v):=s]
}
scaling_factors = scaling_factors[rep(1,nrow(data))]
for(v in names(scaling_factors)) data[, (v):=get(v)/scaling_factors[[v]]]
# data[, lapply(.SD, var)]

# compute lags (after rescaling because it creates more NA's)
lagVars = names(data)[grepl('exp|other_dah|ghe|oop', names(data))]
for(v in lagVars) data[, (paste0('lag_',v)):=data.table::shift(get(v),type='lag',n=2), by='health_zone']
for(v in lagVars) untransformed[, (paste0('lag_',v)):=data.table::shift(get(v),type='lag',n=2), by='health_zone']
data = na.omit(data)
# -----------------------------------------------------------------------


# ---------------------------------------------------------------------------------------
# Run final tests

# test unique identifiers
test = nrow(data)==nrow(unique(data[,c('health_zone','date'), with=F]))
if (test==FALSE) stop(paste('Something is wrong. date does not uniquely identify rows.'))

# test for collinearity

# test for variables with an order of magnitude different variance

# ---------------------------------------------------------------------------------------


# ---------------------------------------------------------
# Save file
save(list=c('data', 'untransformed', 'scaling_factors'), file=outputFile5a)

# save a time-stamped version for reproducibility
archive(outputFile5a)
# ---------------------------------------------------------