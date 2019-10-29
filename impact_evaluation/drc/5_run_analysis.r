# ------------------------------------------------
# David Phillips
# 
# 1/18/2019
# This runs the SEM dose-response model (spanning both "halves")
# This should make 4a and 4b irrelevant once confirmed that the model works
# qsub -l archive=TRUE -cwd -N ie_script_5 -l fthread=12 -l m_mem_free=12G -q all.q -P proj_pce -e /ihme/scratch/users/davidp6/impact_evaluation/errors_output/ -o /ihme/scratch/users/davidp6/impact_evaluation/errors_output/ ./core/r_shell_blavaan.sh ./impact_evaluation/drc/5_run_analysis.r
# ------------------------------------------------

source('./impact_evaluation/drc/set_up_r.r')

# ---------------------------
# Settings

# check operating system
if(Sys.info()[1]=='Windows') stop('This script is currently only functional on IHME\'s cluster')

# whether to rerun everything or only jobs that don't already have output
rerunAll = TRUE

# model version to use
modelVersion = 'drc_malaria7'
# ---------------------------


# ---------------------------
# Load data
set.seed(1)
load(outputFile4)
# ---------------------------


# ----------------------------------------------
# Define model object
source(paste0('./impact_evaluation/drc/models/', modelVersion, '.r'))

# reduce the data down to only necessary variables
parsedModel = lavParseModelString(model)
modelVars = unique(c(parsedModel$lhs, parsedModel$rhs))
modelVars = c('health_zone','date',modelVars)
data = data[, unique(modelVars), with=FALSE]
# ----------------------------------------------


# --------------------------------------------------------------
# Run model (each health zone in parallel)

# save copy of input file for jobs
if (rerunAll==TRUE) file.copy(outputFile4, outputFile4_scratch, overwrite=TRUE)

# store T (length of array)
hzs = unique(data$health_zone)
T = length(hzs)

# store cluster command to submit array of jobs
qsubCommand = paste0('qsub -cwd -N ie1_job_array -t 1:', T, 
		' -l fthread=1 -l m_mem_free=2G -q all.q -P proj_pce -e ', 
		clustertmpDireo, ' -o ', clustertmpDireo, 
		' ./core/r_shell_blavaan.sh ./impact_evaluation/drc/5c_run_single_model.r ', 
		modelVersion, ' 0 FALSE')

# submit array job if we're re-running everything
if (rerunAll==TRUE) system(qsubCommand)

# submit specific jobs that don't have output files if not re-running everything
if (rerunAll==FALSE) { 
	for(i in seq(T)) {
		tmpFile = paste0(clustertmpDir2, 'summary_', i, '.rds')
		if (file.exists(tmpFile)) next
		system(gsub(paste0('1:',T), i, qsubCommand))
	}
}

# wait for jobs to finish (2 files per job)
while(length(list.files(clustertmpDir2, pattern='summary_'))<(T)) { 
	Sys.sleep(5)
	print(paste(length(list.files(clustertmpDir2, pattern='summary_')), 'of', T, 'files found...'))
}

# collect output (summary and urFit)
print('Collecting output...')
for(i in seq(T)) { 
	summary = readRDS(paste0(clustertmpDir2, 'summary_', i, '.rds'))
	urFit = readRDS(paste0(clustertmpDir2, 'urFit_', i, '.rds'))
	if (i==1) summaries = copy(summary)
	if (i>1) summaries = rbind(summaries, summary)
	if (i==1) urFits = copy(urFit)
	if (i>1) urFits = rbind(urFits, urFit)
}

# compute averages (approximation of standard error, would be better as Monte Carlo simulation)
paramVars = c('est.std','est','se_ratio.std', 'se_ratio', 'se.std', 'se')
summaries[, se_ratio.std:=se.std/est.std]
summaries[, se_ratio:=se/est]
means = summaries[, lapply(.SD, mean), .SDcols=paramVars, by=c('lhs','op','rhs')]
means[se.std>abs(se_ratio.std*est.std), se.std:=abs(se_ratio.std*est.std)]
means[se>abs(se_ratio*est), se:=abs(se_ratio*est)]
# --------------------------------------------------------------


# ------------------------------------------------------------------
# Save model output and clean up

# save all sem fits just in case they're needed
print(paste('Saving', outputFile5))
save(list=c('data','model','summaries','means','urFits','modelVersion'), file=outputFile5)

# save full output for archiving
outputFile5_big = gsub('.rdata','_all_semFits.rdata',outputFile5)
print(paste('Saving', outputFile5_big))
semFits = lapply(seq(T), function(i) {
	suppressWarnings(readRDS(paste0(clustertmpDir2, 'semFit_', i, '.rds')))
})
save(list=c('data','model','semFits','summaries','means','urFits','modelVersion'), file=outputFile5_big)

# save a time-stamped version for reproducibility
print('Archiving files...')
archive(outputFile5, 'model_runs')
archive(outputFile5_big, 'model_runs')

# clean up in case jags saved some output
if(dir.exists('./lavExport/')) unlink('./lavExport', recursive=TRUE)

# clean up qsub files
print(paste('Cleaning up cluster temp files...'))
system(paste0('rm ', clustertmpDireo, '/ie1_job_array*'))
system(paste0('rm ', clustertmpDir1	, '/*'))
system(paste0('rm ', clustertmpDir2	, '/*'))
# ------------------------------------------------------------------
