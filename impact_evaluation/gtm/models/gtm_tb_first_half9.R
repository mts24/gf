#-----------------------------------------------------------------------------------------------
# AUTHOR: Jen Ross, adapted from drc_malaria1 code by David Phillips. 
# UPDATE DATE: July 12, 2019, by Emily Linebarger 
#
# model: gtm_tb_first_half1 adapted by J Ross from drc_malaria1 code by D Phillips.
# model: gtm_tb_first_half2 modified by Emily Linebarger. All first half variables changed to cumulative
#   sums, and model linkages where data was unavailable were removed. 
# model: gtm_tb_first_half3 modified by Emily Linebarger - dramatically paring down relationships to a simpler 
#   structure, agreed on by Jen Ross 8/13/19
# This is a computationally viable model that adapts the DRC malaria SEM for the GTM TB context
# May 2019
# gtm_tb_first_half5 removes linkages between MDR cases started on Treatment and Cases started on treatment, 
# MDR cases started on treatment and Cases notified, and Total Drugs Distributed and Isoniazid distributed. 
# All of this is set-up to run this as a GLM instead of SEM. 
# gtm_tb_first_half7 - removed 'date' variable as control to see if it can fix high collinearity. EL 8/19/19
# gtm_tb_first_half8 - adding ACF and prison-relevant variables back in now that we've moved to a GLM. EL 8/20/19 
# gtm_tb_first_half9 - adding outcome indicators as well to last 1/3 of model EL 8/23/19 
# 
# In-process regression equations are indicated with the #, which I remove once variable names are formalized
# My current convention is to group funding by module ordered within module by GF, GHE, and DAH
#-----------------------------------------------------------------------------------------------


model = '

  # Linkage 1 = relationships between inputs and activities
  Firstline_Distributed_act_cumulative ~  ghe_tb_cumulative 
  Secondline_Distributed_act_cumulative ~ gf_mdrtb_cumulative 
  Number_of_Cases_Screened_for_MDR_act_cumulative ~ gf_mdrtb_cumulative +  ghe_tb_cumulative + odah_tb_cumulative
  TB_Patients_Tested_for_HIV_act_cumulative ~ gf_tbhiv_cumulative +  ghe_tb_cumulative + odah_tb_cumulative 
  Additional_Cases_Detected_via_ACF_out_cumulative ~ gf_tb_cumulative 

  # Linkage 2 = relationships between activities and outputs or inputs and outputs
  Cases_Notified_out_cumulative  ~ gf_tb_cumulative +  ghe_tb_cumulative + odah_tb_cumulative 
  Cases_Started_on_Treatment_out_cumulative ~ gf_tb_cumulative +  ghe_tb_cumulative + odah_tb_cumulative + Firstline_Distributed_act_cumulative 
  MDR_Cases_Started_Treatment_out_cumulative ~ Number_of_Cases_Screened_for_MDR_act_cumulative + Secondline_Distributed_act_cumulative
  HIV_TB_Cases_Notified_out_cumulative ~ TB_Patients_Tested_for_HIV_act_cumulative 
  Cases_Notified_in_Prisons_out_cumulative ~ gf_tb_cumulative 
  Cases_Notified_in_Prisons_out_cumulative ~ Number_of_Cases_Screened_for_MDR_act_cumulative
  Cases_Notified_out_cumulative ~ Additional_Cases_Detected_via_ACF_out_cumulative
  Children_less5_referred_out_cumulative ~ Additional_Cases_Detected_via_ACF_out_cumulative

  #Linkage 3 = relationships between outputs and outcomes 
  Case_Notification_Rate_imp ~ Cases_Notified_out_cumulative + date
  Proportion_of_HIV_TB_Cases_Treated_out ~ HIV_TB_Cases_Notified_out_cumulative + date
  Treatment_Success_Rate_imp ~ Cases_Started_on_Treatment_out_cumulative + date
  HIV_TB_Treatment_Success_Rate_imp ~ HIV_TB_Cases_Notified_out_cumulative + date
  Proportion_of_MDR_Cases_Treated_out ~ Number_of_Cases_Screened_for_MDR_act_cumulative + date
  MDR_Probably_Cured_rate_imp ~ MDR_Cases_Started_Treatment_out_cumulative + date
  Proportion_of_Cases_in_Prisons_Treated_out ~ Cases_Started_on_Treatment_in_Prisons_out + date
  Proportion_of_Patients_Receiving_DST_out ~ Number_of_Cases_Screened_for_MDR_act_cumulative + date
    

	# latent variables
	
	# fixed variances - zero out the relationships between outputs variables, except where it makes theoretical sense. 

  
'
