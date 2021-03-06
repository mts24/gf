# ----------------------------------------------
# AUTHOR: Francisco Rios Casas, Emily Linebarger, based on code written by Irena Chen
# PURPOSE: Prep commonly-formatted coverage indicator sheet from 
#   PU/DRs across countries. Modified to prep the qualitative data in the comments
# DATE: Last updated June 2019. 


prep_coverage_1B_comments =  function(dir, inFile, sheet_name, language) {
  
  #TROUBLESHOOTING HELP
  # #Uncomment variables below and run line-by-line.
  # country = 'gtm' # set manually
  # file_list = master_file_list[loc_name==country & file_iteration=="approved_gm" & !is.na(sheet_coverage_1b)]
  # master_file_dir = paste0(box, toupper(country), "/raw_data/")
  # folder = "budgets"
  # folder = ifelse (file_list$data_source[i] == "pudr", "pudrs", folder)
  # if (file_list$file_iteration[i]=="initial"){
  #   version = "iterations"
  # } else if (file_list$file_iteration[i]=="revision"){
  #   version= "revisions"
  # } else {
  #   version = ""
  # }
  # grant_period = file_list$grant_period[i]
  # 
  # dir = paste0(master_file_dir, file_list$grant_status[i], "/", file_list$grant[i], "/", grant_period, "/", folder, "/")
  # if (version != ""){
  #   dir = paste0(dir, version, "/")
  # }
  # inFile = file_list$file_name[i]
  # sheet_name = file_list$sheet_coverage_1b[i]
  # language = file_list$language_1b[i]

  STOP_COL = 6 #What column starts to have sub-names? (After you've dropped out first 2 columns)
  
  # Sanity check: Is this sheet name one you've checked before? 
  verified_sheet_names <- c('Coverage Indicators_1B', 'Indicateurs Couverture_1B')
  if (!sheet_name%in%verified_sheet_names){
    print(sheet_name)
    stop("This sheet name has not been run with this function before - Are you sure you want this function? Add sheet name to verified list within function to proceed.")
  }
  
  # Load/prep data
  gf_data <-data.table(read.xlsx(paste0(dir,inFile), sheet=sheet_name, detectDates=TRUE))
  
  #------------------------------------------------------
  # 1. Select columns, and fix names 
  #------------------------------------------------------
  module_col = grep("Module|Módulo", gf_data)
  extra_module_col = grep("HIVAIDS_Module", gf_data)
  if (length(extra_module_col)>0){
    if (verbose){
      print("Extra name rows are being dropped.")
      print(gf_data[[extra_module_col]])
    }
    gf_data[[extra_module_col]]<-NULL
    module_col = module_col[module_col!=extra_module_col]
  }
  stopifnot(length(module_col)==1)
  name_row = grep("Module|Módulo", gf_data[[module_col]])
  extra_name_row = grep("Module Name", gf_data[[module_col]])
  if (length(extra_name_row)>0){
    if (verbose){
      print("Extra name rows are being dropped.")
      print(gf_data[extra_name_row])
    }
    gf_data = gf_data[-extra_name_row, ]
    name_row = name_row[name_row!=extra_name_row]
  }
  stopifnot(length(name_row)==1)
  
  names = gf_data[name_row, ]
  names = tolower(names)
  names = gsub("\\.", "_", names)
  
  #Drop the record ID column. 
  # If the module column is #3, drop the first two rows. 
  comment_col = grep("comment|causas de la variación programática", names) 
  record_id_col = grep("record id", tolower(gf_data))
  stopifnot(length(record_id_col)==1 | is.na(record_id_col)) #Just don't drop more than one column here. 
  gf_data = gf_data[, !c(record_id_col), with=FALSE] 
  if (module_col==3){
    gf_data = gf_data[, 3:ncol(gf_data)] #Drop the first two columns in this case, they're unnecessary. 
  }
  
  #------------------------------------------------------
  # 2. Reset names after subset above. 
  #------------------------------------------------------
  
  module_col = grep("Module|Módulo", gf_data)
  stopifnot(length(module_col)==1)
  name_row = grep("Module|Módulo", gf_data[[module_col]])
  stopifnot(length(name_row)==1)
  
  names = gf_data[name_row, ]
  names = tolower(names)
  names = gsub("\\.", "_", names)
  
  names(gf_data) = names
  
  #Sometimes, there is a row right before the names row that says where the LFA and Global Fund verified sections begin, respectively. 
  pre_name_row = name_row-1
  # lfa_start_col = grep()
 
   #Drop everything before the name row, because it isn't needed 
  gf_data = gf_data[(name_row+1):nrow(gf_data)] #Go ahead and drop out the name row here too because you've already captured it
  sub_names = as.character(gf_data[1, ])
  
  #------------------------------------------------------
  # 3. Rename columns 
  #------------------------------------------------------
  
  #Remove diacritical marks from names to make grepping easier
  names = fix_diacritics(names)
  names = gsub("\\n", "", names)
  
  if (language == "fr"){
    reference_col = grep("reference", names)
    target_col = grep("cible", names)
    result_col = grep("resultats", names)
    lfa_result_col = grep("verified result", names)
    gf_result_col = grep("global fund validated result", names) 
    gf_result_col = grep("global fund validated result|validated result", names)
    pr_comments_col = grep("motifs de l'ecart programmatique|comments:reasons for programmatic deviation", names)
    lfa_comments_col = grep("lfa analysis on progress to date", names)
    gf_comments_col = grep("country team comments on validated results", names)
  } else if (language == "eng"){
    reference_col = grep("baseline", names) 
    target_col = grep("target", names)
    result_col = grep("result", names) 
    lfa_result_col = grep("verified result", names)
    gf_result_col = grep("global fund validated result|validated result", names)
    pr_comments_col = grep("reasons for programmatic deviation", names)
    lfa_comments_col = grep("lfa analysis on progress to date", names)
    gf_comments_col = grep("country team comments on validated results", names)
  } else if (language=="esp"){
    reference_col = grep("linea de base", names) 
    target_col = grep("meta", names)
    result_col = grep("resultados", names) 
    lfa_result_col = grep("verified result", names)
    gf_result_col = grep("global fund validated result", names)
    pr_comments_col = grep("reasons for programmatic deviation|causas de la variacion programatica", names)
    lfa_comments_col = grep("lfa analysis on progress to date", names)
    gf_comments_col = grep("country team comments on validated results", names)
  }
  reference_col = reference_col[reference_col>=STOP_COL]
  target_col = target_col[target_col>STOP_COL]
  result_col = result_col[result_col>STOP_COL]
  lfa_result_col = lfa_result_col[lfa_result_col>STOP_COL]
  gf_result_col = gf_result_col[gf_result_col>STOP_COL]
  pr_comments_col = pr_comments_col[pr_comments_col>STOP_COL]
  lfa_comments_col = lfa_comments_col[lfa_comments_col>STOP_COL]
  gf_comments_col = gf_comments_col[gf_comments_col>STOP_COL]
  
  # now that we are keeping in comments on validated results it's accidentally pulling both values in the result column
  if (length(gf_result_col!=1)){
    gf_result_col <- gf_result_col[1]
  }
  
  if (length(result_col)>1){ #The word 'result' appears several times for English files, and you just want the first column here. 
    result_col = result_col[1]
  }
  if (length(target_col)>1) { #There is an extra "meta" mentioned in column 20 for some Guatemala files 
    target_col = target_col[1]
  }
  
  #Validate that you grabbed exactly 8 columns (5 original plus three comments)
  flagged_col_list = c(reference_col, target_col, result_col, lfa_result_col, gf_result_col, pr_comments_col, lfa_comments_col, gf_comments_col)
  stopifnot(length(flagged_col_list)==8)
  
  #------------------------------------------------------------
  # DYNAMICALLY RE-ASSIGN NAMES (DUE TO MULTIPLE FILE FORMATS)
  #------------------------------------------------------------
  #1. Tag the names that you currently have. 
  #2. Match them from a list of previously tagged names. 
  #3. Build up a list of correctly named vectors in the order in which it appears. 
  # 4. Reset names 
  
  #---------------------------------------------
  # MAIN NAMES 
  #---------------------------------------------
  
  #Acceptable raw column names - will be matched to corrected names below. 
  module_names = c('module', 'modulo')
  standard_ind_names = c('standard coverage indicator', 'indicateurs', 'coverage indicator', 'indicador ')
  custom_ind_names = c('custom coverage indicator')
  geography_names = c('geographic area', 'geographie', 'geografia')
  cumulative_target_names = c('targets cumulative?', "cibles cumulatives ?", "targets cumulative?_x000d_", "¿metas acumulativas?", "targets cumulative?\n")
  reverse_ind_names = c("reverse indicator?")
  
  baseline_names = c('baseline (if applicable)', "reference", 'linea de base')
  target_names = c('target', 'cible', 'meta')
  result_names = c('result', 'resultats', 'resultados')
  lfa_result_names = c('verified result')
  gf_result_names = c('validated result', "global fund validated result")
  
  pr_comments_names = c("comments:reasons for programmatic deviation from intended target and deviations from the related workplan activities",
                        "commentaires:motifs de l'ecart programmatique par rapport s la cible visee et des ecarts par rapport aux activites connexes du plan de travail",
                        "causas de la variacion programatica con respecto a la meta fijada y de las varianzas en relacion con las actividades del plan de trabajo")
  lfa_comments_names = c('comments:lfa analysis on progress to date and any variance between targets and results, and any other comments(this should not be a “copy and paste” of the reasons provided by the pr)')
  gf_comments_names = c('country team comments on validated results')
  
  #Correct these matched names. 
  names[which(names%in%module_names)] = "module"
  names[which(names%in%standard_ind_names)] = "indicator"
  names[which(names%in%custom_ind_names)] = "custom_coverage_indicator"
  names[which(names%in%geography_names)] = "geography"
  names[which(names%in%cumulative_target_names)] = "cumulative_target"
  names[which(names%in%reverse_ind_names)] = "reverse_indicator"
  
  names[which(names%in%baseline_names)] = "baseline"
  names[which(names%in%target_names)] = "target"
  names[which(names%in%result_names)] = "pr_result"
  names[which(names%in%lfa_result_names)] = "lfa_result"
  names[which(names%in%gf_result_names)] = "gf_result"
  
  names[which(names%in%pr_comments_names)] = "pr_comments"
  names[which(names%in%lfa_comments_names)] = "lfa_comments"
  names[which(names%in%gf_comments_names)] = "gf_comments"
  
  
  #Where 'achievement ratio' exists in the names vector, move to the sub-names vector 
  achievement_ratio_names = c('achievement ratio', "taux d'accomplissement", "achivement ratio(final one is calculated by gos)", "achivement ratio", "relacion de logro", "achivement ratio\n(final one is calculated by gos)")
  ach_ratio_indices = which(names%in%achievement_ratio_names)
  stopifnot(is.na(unique(sub_names[ach_ratio_indices])))
  sub_names[ach_ratio_indices] = "achievement_ratio"
  names[ach_ratio_indices] = NA
  
  #Where 'verification method' exists in the names vector, move to the sub-names vector 
  verification_method_names = c('verification method', "data validation checks on pr data", "data validation checks on lfa data", "data validation checks on gf data")
  ver_method_indices = which(names%in%verification_method_names)
  stopifnot(is.na(unique(sub_names[ver_method_indices])))
  sub_names[ver_method_indices] = "verification_method"
  names[ver_method_indices] = NA
  
  #Where 'source' exists in the names vector, move to the sub-names vector 
  data_source_names = c('source', 'fuente')
  source_indices = which(names%in%data_source_names)
  stopifnot(is.na(unique(sub_names[source_indices])))
  sub_names[source_indices] = "source"
  names[source_indices] = NA
  
  #Make sure you've tagged all names correctly so far. 
  if (verbose){
    print("These are the variable names that haven't been correctly tagged.")
    print(names[!names%in%c("module", "indicator", "custom_coverage_indicator", "geography", 
                              "cumulative_target", "reverse_indicator", "baseline", "target", "pr_result", "lfa_result", "gf_result",
                            "pr_comments", "lfa_comments", "gf_comments", NA)])
  }
  stopifnot(names%in%c("module", "indicator", "custom_coverage_indicator", "geography", 
                       "cumulative_target", "reverse_indicator", "baseline", "target", "pr_result", "lfa_result", "gf_result", "pr_comments", "lfa_comments", "gf_comments") | is.na(names))
  
  #----------------------------------
  # SUB-NAMES 
  #----------------------------------
  num_names = c("N#")
  denom_names = c("D#")
  proportion_names = c("%")
  year_names = c("Year", "Année", "Año")
  verification_source_names = c("Source", "source", "Fuente")
  
  sub_names[which(sub_names%in%num_names)] = "n"
  sub_names[which(sub_names%in%denom_names)] = "d"
  sub_names[which(sub_names%in%proportion_names)] = "%"
  sub_names[which(sub_names%in%year_names)] = "year"
  sub_names[which(sub_names%in%verification_source_names)] = "source"
  
  #Certain column names are okay to change to NA here. 
  na_names = c("If sub-national, please specify under the \"Comments\" Column", 
               "Si infranationale, veuillez préciser dans la colonne des commentaires", 
               "Si es subnacional, especifíquelo en el columna de comentarios")
  sub_names[which(sub_names%in%na_names)] = NA
  
  if (verbose){
    print("These are the sub-names that haven't been correctly tagged.")
    print(sub_names[!sub_names%in%c('n', 'd', '%', 'year', 'source', 'achievement_ratio', 'verification_method', NA)])
  }
  stopifnot(sub_names%in%c('n', 'd', '%', 'year', 'source', 'achievement_ratio', 'verification_method') | is.na(sub_names))
  
  #------------------------------------------
  # REASSIGN NAMES USING CORRECTED VECTORS
  
  #First, extend each of the 'flag' column names to cover the whole span. 
  names[reference_col:(target_col-1)] = "baseline"
  names[target_col:(result_col-1)] = "target"
  names[result_col:(lfa_result_col-1)] = "pr_result"
  names[lfa_result_col:(gf_result_col-1)] = "lfa_result"
  names[gf_result_col:length(names)] = "gf_result"
  stopifnot(!is.na(names))
  
  # add in new names
  names[pr_comments_col] = "pr_comments"
  names[lfa_comments_col] = "lfa_comments"
  names[gf_comments_col] = "gf_comments"
  
  #Second, append names and subnames. 
  stopifnot(length(names)==length(sub_names))
  final_names = names
  for (i in 1:length(sub_names)){
    if (!is.na(sub_names[i])){
      final_names[i] = paste0(names[i], "_", sub_names[i])
    }
  }
  
  #Make sure your name vector still matches the length of the data! 
  stopifnot(length(final_names)==ncol(gf_data))
  names(gf_data) = final_names
  #------------------------------------------------------
  # 2. Drop out empty rows 
  #------------------------------------------------------
  
  #Drop out rows that have NAs, and drop the sub names column. 
  gf_data = gf_data[-c(1)]
  gf_data = gf_data[!(is.na(module) & is.na(indicator)), ] 
  
  return(gf_data)
}


