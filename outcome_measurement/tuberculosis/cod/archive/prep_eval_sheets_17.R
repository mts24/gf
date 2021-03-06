# Audrey Batzel
# 9/17/18
# function to clean eval sheets in 2017 data

# TO DO : expand this to cover other years as well

clean_eval_sheets <- function(dir, year, file){

i <- 1

for (s in sheets_eval[1:length(sheets_eval)]){
  
  dt <- data.table(read_excel(paste0(dir, year, "/", file), sheet= s))
  
  # remove rows at the top up until the header row
  setnames(dt, colnames(dt)[1], "col1")
  index <- grep("CPLT", dt$col1 )
  
  dt <- dt[-c(1:(index-1))]
  
  # remove columns of percentages
  cols <- !is.na( dt[1,] )
  cols <- colnames(dt)[cols]
  
  dt <- dt[, cols, with=FALSE]
  
  # remove rows that are entirely NA
  rows_to_remove <- apply(dt, 1, function(x) all(is.na(x)))
  dt <- dt[!rows_to_remove, ]
  # remove rows where col1 is na
  dt <- dt[!is.na(col1)]
  
  # remove total rows (sometime has "RDC")
  dt <- dt[!grepl("TOTAL", col1)]
  dt <- dt[!grepl("RDC", col1)]
  
  # set column names to be header row:
  colnames(dt) <- as.character(dt[1,])
  
  # remove header row in row 1
  dt <- dt[-1, ]
  
  ##----------------------------------
  # clean column names:
  colnames(dt) <- tolower(colnames(dt))
  
  setnames(dt, grep('cplt', colnames(dt)), 'dps')
  setnames(dt, grep('enreg', colnames(dt)), 'tot_cas_reg')
  
  for(n in c('guer')) if(any(grepl(n, names(dt)))) setnames(dt, grep(n, names(dt)), 'healed')
  if(!'healed' %in% names(dt)) print(paste0('In sheet, ', s, ', healed is not a column'))
  
  setnames(dt, grep('traitement termine', colnames(dt)), 'trt_complete')
  
  for(n in c('dece','dcd')) if(any(grepl(n, names(dt)))) setnames(dt, grep(n, names(dt)), 'died')
  if(!'died' %in% names(dt)) stop(paste0('In sheet, ', s, ', died is not a column'))
  
  for(n in c('echecs')) if(any(grepl(n, names(dt)))) setnames(dt, grep(n, names(dt)), 'trt_failed')
  if(!'trt_failed' %in% names(dt)) print(paste0('In sheet, ', s, ', trt_failed is not a column'))
  
  for(n in c('perdu','abandon', 'interruptions')) if(any(grepl(n, names(dt)))) setnames(dt, grep(n, names(dt)), 'lost_to_followup')
  if(!'lost_to_followup' %in% names(dt)) stop(paste0('In sheet, ', s, ', lost_to_followup is not a column'))
  
  setnames(dt, grep('transfer', colnames(dt)), 'transferred')
  
  for(n in c('total  evalue','total evalue', 'total cas evalues')) if(any(grepl(n, names(dt)))) setnames(dt, grep(n, names(dt)), 'cas_eval')
  if(!'cas_eval' %in% names(dt)) stop(paste0('In sheet, ', s, ', cas_eval is not a column'))
  
  for(n in c('non evalue')) if(any(grepl(n, names(dt)))) setnames(dt, grep(n, names(dt)), 'cas_not_eval')
  if(!'cas_not_eval' %in% names(dt)) stop(paste0('In sheet, ', s, ', cas_not_eval is not a column'))
  
  # clean DPS names
  dt$dps <- gsub(" ", "-", dt$dps)
  dt$dps <- gsub("--", "-", dt$dps)
  
  dt$dps <- chartr(paste(names(unwanted_array), collapse=''),
                   paste(unwanted_array, collapse=''),
                   dt$dps)
  
  # one case where this is different:
  
  dt <- dt[dps !="EQUATEUR"]
  dt <- dt[dps !="KASAI-ORIENTAL"]
  
  dt$dps <- tolower(dt$dps)
  
  dt[ dps == 'kasai-centre', dps:= 'kasai-central']
  
  dt <- dt[dps %in% dps_names]
  
  # add columns for quarter, year, and TB type
  dt[, sheet:= s]
  dt[, quarter:= dt_sheets_eval[sheet_name==s, quarter]]
  dt[, TB_type := dt_sheets_eval[sheet_name==s, TB_type]]
  dt[, data_year := dt_sheets_eval[sheet_name==s, year]]
  dt[, file_year := year]
  
  if (i==1){
    # if it's the first sheet, initialize the new dt
    outcomes <- dt
    # for subsequent sheets, rbind to that dt
  } else {
    outcomes <- rbindlist(list(outcomes, dt), use.names=TRUE, fill= TRUE)
  }
  # print(s)
  i <- i + 1
}

return(outcomes)

}
