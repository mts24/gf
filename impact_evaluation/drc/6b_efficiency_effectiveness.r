# -----------------------------------
# David Phillips
# 
# 3/25/2019
# Analyze efficiency
# -----------------------------------


# -----------------------------------------------
# Load/prep data and functions

source('./impact_evaluation/drc/set_up_r.r')

# load model results
load(outputFile5a)

# load nodeTable for graphing
nodeTable = fread(nodeTableFile1)

# ensure there are no extra variables introducted from nodeTable
nodeTable = nodeTable[variable %in% names(data)]
# -----------------------------------------------


# -----------------------------------------------
# Set up first half estimates

# subset to coefficients of interest
means = means[op=='~' & !grepl('completeness|date',rhs)]

# compute uncertainty intervals
means[, lower:=est-(1.96*se)]
means[, lower.std:=est.std-(1.96*se.std)]
means[, upper:=est+(1.96*se)]
means[, upper.std:=est.std+(1.96*se.std)]

# estimate the combination of coefficients and their next downstream coefficient (mediation)
# (uncertainty needs improving)
mediation_means = merge(means, means, by.x='rhs', by.y='lhs')
mediation_means[, est:=est.y*est.std.x]
mediation_means[, se:=se.y*est.std.x]
mediation_means[, lower:=est-(1.96*se)]
mediation_means[, upper:=est+(1.96*se)]

# pull in labels
means = merge(means, nodeTable, by.x='lhs', by.y='variable')
means = merge(means, nodeTable, by.x='rhs', by.y='variable')
setnames(means, c('label.x','label.y'), c('label_lhs','label_rhs'))
mediation_means = merge(mediation_means, nodeTable, by.x='lhs', by.y='variable')
mediation_means = merge(mediation_means, nodeTable, by.x='rhs.y', by.y='variable')
setnames(mediation_means, c('label.x','label.y'), c('label_lhs','label_rhs'))
# -----------------------------------------------


# -----------------------------------------------
# Pools funders together, weighting by investment size

# reshape data long
long = melt(data, id.vars=c('orig_health_zone','health_zone','date'))

# aggregate to total across whole time series (unrescaling not necessary)
long = long[, .(value=sum(value)), by=variable]

# merge to means
pooled_means = merge(means, long, by.x='rhs', by.y='variable', all.x=TRUE)

# take the weighted average across funders
pooled_means[grepl('\\$',label_rhs), label_rhs:='Pooled Investment']
byVars = c('lhs','label_lhs','label_rhs')
pooled_means = pooled_means[, .(est=weighted.mean(est, value), 
	se=weighted.mean(se, value)), by=byVars]
	
# get uncertainty
pooled_means[, lower:=est-(1.96*se)]
pooled_means[, upper:=est+(1.96*se)]
# -----------------------------------------------


# -----------------------------------------------
# Display reciprocal of efficiency statistics

# ITN, ACT and RDT shipment costs
commodity_costs = NULL
for(c in c('ITN','RDT','ACT')) {
	output = paste0(c, '_received_cumulative')
	commodity_cost = pooled_means[lhs==output,c('label_rhs','est','se'), with=F]
	commodity_cost = commodity_cost[, .(est=sum(est), se=mean(se))]
	commodity_cost[, lower:=est+(1.96*se)]
	commodity_cost[, upper:=est-(1.96*se)]
	commodity_cost$se = NULL
	commodity_cost[, est:=1/est]
	commodity_cost[, lower:=1/lower]
	commodity_cost[, upper:=1/upper]
	print(paste0('Overall cost to ship one ', c, ':'))
	print(commodity_cost)
	commodity_cost[, commodity:=c]
	commodity_cost = commodity_cost[,c('commodity','est','lower','upper'), with=FALSE]
	commodity_cost = commodity_cost[, lapply(.SD, round, 2), by='commodity']
	if(any(commodity_cost$upper<0)) {
		commodity_cost[, upper:=as.character(upper)]
		commodity_cost[grepl('-',upper), upper:='Negative']
	}
	commodity_costs = rbind(commodity_costs, commodity_cost)
}
# -----------------------------------------------


# ----------------------------------------------
# Bottlenecks in efficiency and effectiveness

actVars = c('ITN_received_cumulative', 'ACT_received_cumulative', 'RDT_received_cumulative')
outVars1 = c('RDT_completed_cumulative', 'severeMalariaTreated_cumulative', 'totalPatientsTreated_cumulative')
outVars2 = c('ACTs_SSC_cumulative', 'ITN_consumed_cumulative', 'SP_cumulative')
outVarsTx = c('severeMalariaTreated_cumulative', 'totalPatientsTreated_cumulative', 'ACTs_SSC_cumulative')
incVars = c('lead_newCasesMalariaMild_rate', 'lead_newCasesMalariaSevere_rate')
mortVars = c('lead_malariaDeaths_rate', 'lead_case_fatality')

# graph coefficients from inputs to activities
p1 = ggplot(means[lhs %in% actVars & rhs!='date'], 
		aes(y=est, ymin=lower, 
			ymax=upper, x=label_rhs)) + 
	geom_bar(stat='identity') + 
	geom_errorbar(width=.25) + 
	facet_wrap(~label_lhs, scales='free', ncol=1) + 
	labs(title='Efficiency', subtitle='Activities', 
		y='Activities per Additional Dollar Invested',x='Input') + 
	theme_bw() + 
	coord_flip()
	
# graph coefficients from inputs to outputs
p2 = ggplot(mediation_means[lhs %in% outVars1 & !rhs.y %in% actVars], 
		aes(y=est, ymin=lower, 
			ymax=upper, x=label_rhs)) + 
	geom_bar(stat='identity') + 
	geom_errorbar(width=.25) + 
	facet_wrap(~label_lhs, scales='free', ncol=1) + 
	labs(title='Efficiency', subtitle='Outputs', 
		y='Outputs per Additional Dollar Invested',x='Input') + 
	theme_bw() + 
	coord_flip()
	
# graph pooled coefficients from inputs to activities
p3 = ggplot(pooled_means[lhs %in% actVars], 
		aes(y=est, ymin=lower, 
			ymax=upper, x=label_lhs)) + 
	geom_bar(stat='identity') + 
	geom_errorbar(width=.25) + 
	labs(title='Efficiency', subtitle='Activities', 
		y='Activities per Additional Dollar Invested',x='Input') + 
	theme_bw() + 
	coord_flip()
# ----------------------------------------------


# ----------------------------------------------
# Save
print(paste('Saving:', outputFile6b)) 
pdf(outputFile6b, height=5.5, width=9)
grid.table(commodity_costs)
print(p1)
print(p2)
print(p3)
dev.off()

# save a time-stamped version for reproducibility
archive(outputFile6b)
# ----------------------------------------------
