# -----------------------------------
# David Phillips
# 
# 2/4/2019
# This visualizes results of the SEM
# -----------------------------------


# -----------------------------------------------
# Load/prep data and functions

source('./impact_evaluation/drc/set_up_r.r')

# load home-made sem graphing function
source('./impact_evaluation/_common/graphLavaan.r')

# load model results
# load(outputFile5a)
load("J:/Project/Evaluation/GF/impact_evaluation/cod/prepped_data/model_runs/first_half_model_results_pc_2019_07_30_11_01_04.rdata") # this is the confirmed "best model"
data1=copy(data)
means1 = copy(means)
summaries1 = copy(summaries)
urFits1 = copy(urFits)
load(outputFile5b)
data2=copy(data)
means2 = copy(means)
summaries2 = copy(summaries)
urFits2 = copy(urFits)

# load nodeTable for graphing
nodeTable1 = fread(nodeTableFile1)
nodeTable2 = fread(nodeTableFile2)

# ensure there are no extra variables introducted from nodeTable
nodeTable1 = nodeTable1[variable %in% names(data1)]
nodeTable2 = nodeTable2[variable %in% names(data2)]

# compute averages (approximation of standard error, would be better as Monte Carlo simulation)
paramVars = c('est.std','est','se_ratio.std', 'se_ratio', 'se.std', 'se')
urFits1[, se_ratio.std:=se.std/est.std]
urFits1[, se_ratio:=se/est]
urFit1 = urFits1[, lapply(.SD, mean), .SDcols=paramVars, by=c('lhs','op','rhs')]
urFit1[se.std>abs(se_ratio.std*est.std), se.std:=abs(se_ratio.std*est.std)]
urFit1[se>abs(se_ratio*est), se:=abs(se_ratio*est)]
urFits2[, se_ratio.std:=se.std/est.std]
urFits2[, se_ratio:=se/est]
urFit2 = urFits2[, lapply(.SD, mean), .SDcols=paramVars, by=c('lhs','op','rhs')]
urFit2[se.std>abs(se_ratio.std*est.std), se.std:=abs(se_ratio.std*est.std)]
urFit2[se>abs(se_ratio*est), se:=abs(se_ratio*est)]
# -----------------------------------------------


# ----------------------------------------------
# Display results

# my sem graph function for first half model
p1 = semGraph(parTable=means1, nodeTable=nodeTable1, 
	scaling_factors=NA, standardized=TRUE, edgeLabels=FALSE,
	lineWidth=1.5, curved=0, tapered=FALSE)

# my sem graph function for second half model
p2 = semGraph(parTable=means2, nodeTable=nodeTable2, 
	scaling_factors=NA, standardized=TRUE, edgeLabels=FALSE,
	lineWidth=1.5, curved=0, tapered=FALSE, variances=FALSE, 
	boxWidth=2, boxHeight=.5, buffer=c(.2, .25, .25, .25))

# my sem graph function for first half model with coefficients
p3 = semGraph(parTable=means1, nodeTable=nodeTable1, 
	scaling_factors=NA, standardized=TRUE, 
	lineWidth=1.5, curved=0, tapered=FALSE)

# my sem graph function for second half model with coefficients
p4 = semGraph(parTable=means2, nodeTable=nodeTable2, 
	scaling_factors=NA, standardized=TRUE, 
	lineWidth=1.5, curved=0, tapered=FALSE, 
	boxWidth=2, boxHeight=.5, buffer=c(.2, .25, .25, .25))

# my sem graph function for first half "unrelated regressions" model
p5 = semGraph(parTable=urFit1, nodeTable=nodeTable1, 
	scaling_factors=NA, standardized=FALSE, 
	lineWidth=1.5, curved=0, tapered=FALSE)

# my sem graph function for second half "unrelated regressions" model
p6 = semGraph(parTable=urFit2, nodeTable=nodeTable2, 
	scaling_factors=NA, standardized=FALSE, 
	lineWidth=1.5, curved=0, tapered=FALSE, 
	boxWidth=2, boxHeight=.5, buffer=c(.2, .25, .25, .25))
# ----------------------------------------------


# -----------------------------------
# Save output
print(paste('Saving:', outputFile6a)) 
pdf(outputFile6a, height=6, width=9)
print(p1)
print(p2)
print(p3)
print(p4)
dev.off()

# save a time-stamped version for reproducibility
archive(outputFile6a)
# -----------------------------------
