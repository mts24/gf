# ----------------------------------------------
# Caitlin O'Brien-Carelli
#
# 4/10/2019
# Rbind the UVL data sets together
# Run dist_facilities_uvl.R to download facility and district names
# ----------------------------------------------

# --------------------
# Set up R
rm(list=ls())
library(data.table)
library(jsonlite)
library(httr)
library(ggplot2)
library(stringr) 
library(plyr)
library(RColorBrewer)
library(raster)
library(maptools)
library(gplots)
library(corrplot)
library(raster)
library(maptools)
library(ggrepel)
# --------------------

# -----------------------------------------------
# detect if operating on windows or on the cluster 

j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')

inDir = paste0(j, '/Project/Evaluation/GF/outcome_measurement/uga/vl_dashboard/prepped/')

dt = readRDS(paste0(inDir, 'uvl_prepped_2014_2018_.rds'))

dt[ ,sum(samples_received), by=year]

outDir = paste0(j, '/Project/Evaluation/GF/outcome_measurement/uga/vl_dashboard/age_analyses/')

#--------------------------
# factor age 

dt$age = factor(dt$age, levels = c("0 - 4", "5 - 9", "10 - 14", "15 - 19",
                                   "20 - 24", "25 - 29", "30 - 34", "35 - 39", 
                                   "40 - 44", "45 - 49"),
                labels = c("0 - 4", "5 - 9", "10 - 14", "15 - 19",
                           "20 - 24", "25 - 29", "30 - 34", "35 - 39", 
                           "40 - 44", "45 - 49"))

# check the levels 
levels(dt$age)
#--------------------------
# color palettes for maps and plots

# store colors
ratio_colors = brewer.pal(8, 'Spectral')
results_colors = brewer.pal(6, 'Blues')
sup_colors = brewer.pal(6, 'Reds')
ladies = brewer.pal(11, 'RdYlBu')
gents = brewer.pal(9, 'Purples')

# red colors for bar graph
bar_colors = c('Not Suppressed'='#de2d26', 'Suppressed'='#fc9272')

graph_colors = c('#bd0026', '#fecc5c', '#74c476','#3182bd', '#8856a7')
tri_sex = c('#bd0026', '#74c476', '#3182bd')
wrap_colors = c('#3182bd', '#fecc5c', '#bd0026', '#74c476', '#8856a7', '#f768a1')
sex_colors = c('#bd0026', '#3182bd', '#74c476', '#8856a7') # colors by sex plus one for facilities
single_red = '#bd0026'
#--------------------------------------
# merge in regions

# import the regions 
regions = fread(paste0(j, '/Project/Evaluation/GF/mapping/uga/uga_geographies_map.csv'))
regions = regions[ ,.(dist112_name, region10_alt)]
setnames(regions, c('district', 'region'))
regions = regions[!duplicated(regions)]

# merge the regions into the data 
dt = merge(dt, regions, by='district', all.x=T)

#--------------------------------------
# create maps

graph_region(dt)

# 15 - 24 vl suppression by region

reg = dt[(age=='15 - 19' | age=='20 - 24') & (year=='2017' | year=='2018')]
reg = reg[ , lapply(.SD, sum), .SDcols=11:18, by=.(region, sex, year)]
reg[ ,ratio:=round(100*(suppressed/valid_results), 1)]

write.csv(reg[sex=='Male' & year=='2018'], paste0(outDir, 'table.csv'))

#--------------------------------------



# chi2 test 


# make contingency table
dt_chi = dt[ ,.(value=round(100*(sum(suppressed)/sum(valid_results)), 1)), by=.(sex, Age=age) ]

dt_chi = dcast(dt_chi, Age~sex)
dt_chi[ ,Age:=as.character(Age)]
dt_chi = as.matrix(dt_chi)
write.table(dt_chi, paste0(outDir, 'contingency.txt'), row.names=F)

dt_chi = read.table(paste0(outDir, 'contingency.txt'), row.names=1, skip=1)
setnames(dt_chi, c("Female", "Male"))


dt2 = as.table(as.matrix(dt_chi))

balloonplot(t(dt2), main ="dt_chi", xlab ="", ylab="",
            label = FALSE, show.margins = FALSE)

chisq = chisq.test(dt_chi)
chisq


round(chisq$expected, 1)

corrplot(chisq$residuals, is.cor = FALSE)







library(betareg)
fit = betareg(I(suppressed/valid_results) ~ factor(age)*factor(sex), dt)


frame = unique(dt[,c('age','sex')])
frame[, est:=predict(fit)]
frame[, upper:=predict(fit, )]

#---------------------

# make contingency table
dt_chi = dt[ ,.(value=sum(suppressed), 1), by=.(sex, Age=age) ]

dt_chi = dcast(dt_chi, Age~sex)
dt_chi[ ,Age:=as.character(Age)]

balloonplot(dt_chi)
dt_chi = as.matrix(dt_chi)
write.table(dt_chi, paste0(outDir, 'contingency.txt'), row.names=F)

dt_chi = read.table(paste0(outDir, 'contingency.txt'), row.names=1, skip=1)
setnames(dt_chi, c("Female", "Male"))



dt2 = as.table(as.matrix(dt_chi))

balloonplot(t(dt2), main ="Number virally suppressed", xlab ="", ylab="",
            label = FALSE, show.margins = FALSE)

chisq = chisq.test(dt_chi)
chisq


round(chisq$expected, 1)

corrplot(chisq$residuals, is.cor = FALSE)

corrplot(chisq$residuals, type = "upper", order = "hclust", 
         tl.col = "black", tl.srt = 45, is.cor=F)



corrplot(chisq$residuals, type="full", 
         tl.col = "black", is.cor=F)



dcast(dt_chi, Age~Female+Male)

#-------------
# correlation matrix

cor_plot = cor(dt2)

library(corrplot)





#--------------------------
# facilities reporting

pdf(paste0(outDir, 'age_figures.pdf'), width=12, height=9)

# create a table of the number of facilities reporting annualy by district         
report = dt[, .(facilities_report=length(unique(facility_id)),
                    patients=sum(patients_received)), by=date]
report[ , ratio:=patients/facilities_report]
report_long = melt(report, id.vars='date')
  
report_long$variable = factor(report_long$variable, labels = c('Facilities Reporting', 'Patients Submitting Samples',
                                                               'Mean Patients Submitting per Facility'))
n = dt[ ,length(unique(facility_id))]
n_year = report[ ,min(year(date))]

# reporting plot
  ggplot(report_long, aes(x=date, y=value, color=variable)) + 
  geom_point() +
  geom_line(alpha=0.6) +
  theme_bw() +
  facet_wrap(~variable, scales='free_y') +
  scale_color_manual(values = c('#bd0026', '#2c7fb8', '#fdae61')) +
  labs(title="Viral Load Testing: Reporting Over Time", x="Date", y="Count",
       subtitle=paste("6,404 health facilities in Uganda as of 2017;" , n , "facilities have reported since", n_year),
                       caption="Source: Uganda Viral Load Dashboard") +
    theme(legend.position='none', text = element_text(size=18) )

#--------------------------
# patients by sex
  
pts = dt[, .(patients=sum(patients_received)), by=.(sex, date)]

month_mean_f = round(pts[sex=='Female' ,sum(patients)/length(unique(date))],0)
month_mean_m = round(pts[sex=='Male' ,sum(patients)/length(unique(date))],0)

# reporting plot
ggplot(pts, aes(x=date, y=patients, color=sex)) + 
    geom_point() +
    geom_line(alpha=0.6) +
    theme_bw() +
    scale_color_manual(values = c('#bd0026', '#2c7fb8')) +
    labs(title="Patients submitting samples by sex", x="Date", y="Number of patients",
         subtitle=paste0('Mean female patients per month: ', month_mean_f, '; mean male patients per month: ', month_mean_m)) +
    theme(legend.position='none', text = element_text(size=18))

#--------------------------
# viral suppression by sex
vl = dt[ ,.(suppressed=sum(suppressed), 
         valid_results=sum(valid_results)), by=.(sex, date)] 

vl[ , ratio:=round(100*(suppressed/valid_results), 1) ]
  
vl = melt(vl, id.vars=c('sex', 'date'))

vl$variable = factor(vl$variable, labels = c('Virally suppressed', 'Valid test results',
                                             'Viral suppression ratio'))

# reporting plot
ggplot(vl[variable!='Viral suppression ratio'], aes(x=date, y=value, color=variable)) + 
  geom_point() +
  geom_line(alpha=0.6) +
  theme_bw() +
  scale_color_manual(values = c('#fdb863', '#542788')) +
  facet_wrap(~sex) +
  labs(x="Date", y="Count", color='', title='Viral suppression and valid test results by sex') +
  theme(text = element_text(size=18))

# viral suppression ratio by sex
ggplot(vl[variable=='Viral suppression ratio'], aes(x=date, y=value, color=sex)) + 
  geom_point() +
  geom_line(alpha=0.6) +
  theme_bw() +
  scale_color_manual(values = c('#bd0026', '#2c7fb8')) +
  labs(x="Date", y="Percent suppressed (%)", color='Sex', title = "Percent virally suppressed by sex") +
  theme(text = element_text(size=18))


vl_bar = dt[ ,.(suppressed=sum(suppressed), 
            valid_results=sum(valid_results)), by=.(sex, year=year(date))] 

vl_bar[ , ratio:=round(100*(suppressed/valid_results), 1) ]

# samples received by sex, age, year - all years
ggplot(vl_bar, aes(x=year, y=ratio, fill=sex)) +
  geom_bar(stat="identity", position=position_dodge()) +
  theme_bw() +
  labs(y='Viral suppression ratio', x='Age category', fill='Sex') 



#--------------------------
# viral suppression by sex
vl_age = dt[ ,.(suppressed=sum(suppressed), 
            valid_results=sum(valid_results)), by=.(age, sex, date)] 

vl_age[ , ratio:=round(100*(suppressed/valid_results), 1) ]

vl_age = melt(vl_age, id.vars=c('age', 'sex', 'date'))

vl_age$variable = factor(vl_age$variable, labels = c('Virally suppressed', 'Valid test results',
                                             'Viral suppression ratio'))

# viral suppression ratio by sex
ggplot(vl_age[variable=='Viral suppression ratio'], aes(x=date, y=value, color=age)) + 
  geom_point() +
  geom_line(alpha=0.6) +
  theme_bw() +
  facet_wrap(~sex) +
  scale_color_manual(values = brewer.pal(11, 'PuOr')) +
  labs(x="Date", y="Percent suppressed (%)", color='Age category', title = "Percent virally suppressed by sex") +
  theme(text = element_text(size=18))

  

#--------------------

bar = dt[ ,lapply(.SD, sum), by=.(age, sex, year=year(date)), .SDcols=11:18 ]
bar_long = melt(bar, id.vars=c('age', 'sex', 'year'))

# samples received by sex, age, year - all years
ggplot(bar_long[variable=='samples_received'], aes(x=age, y=value, fill=sex)) +
  geom_bar(stat="identity", position=position_dodge()) +
  facet_wrap(~year) +
  theme_bw() +
  labs(y='Number of samples received', x='Age category', fill='Sex')


# patients received by sex, age, year - 2016 - present
ggplot(bar_long[variable=='patients_received'& 2016 < year], aes(x=age, y=value, fill=sex)) +
  geom_bar(stat="identity", position=position_dodge()) +
  facet_wrap(~year) +
  theme_bw() + labs(y='Number of patients submitting VL samples', x='Age category', fill='Sex') +
  theme(text = element_text(size=18), axis.text.x=element_text(size=12, angle=90))



#--------------------


vl_bar2 = dt[ ,.(suppressed=sum(suppressed), 
                valid_results=sum(valid_results)), by=.(sex, year=year(date), age)] 

vl_bar2[ , ratio:=round(100*(suppressed/valid_results), 1) ]

# samples received by sex, age, year - all years
ggplot(vl_bar2, aes(x=age, y=ratio, fill=sex)) +
  geom_bar(stat="identity", position=position_dodge()) +
  theme_bw() +
  facet_wrap(~year) +
  labs(y='Viral suppression ratio', x='Age category', fill='Sex') 


# samples received by sex, age, year - all years
ggplot(vl_bar2[2017 <= year], aes(x=age, y=ratio, fill=sex)) +
  geom_bar(stat="identity", position=position_dodge()) +
  theme_bw() +
  facet_wrap(~year) +
  labs(title='Percent virally suppressed by sex, 2017 - 2018', subtitle='Range: 55.1% - 92.9%',
       y='Viral suppression ratio', x='Age category', fill='Sex') +
  coord_cartesian(ylim=c(50, 100)) +
  theme(text = element_text(size=18), axis.text.x=element_text(size=12, angle=90))




vl_bar3 = dt[ ,.(suppressed=sum(suppressed), 
                 valid_results=sum(valid_results)), by=.(sex, age)] 

vl_bar3[ , ratio:=round(100*(suppressed/valid_results), 1) ]

# samples received by sex, age, year - all years
ggplot(vl_bar3, aes(x=age, y=ratio, fill=sex)) +
  geom_bar(stat="identity", position=position_dodge()) +
  theme_bw() +
  labs(y='Viral suppression ratio', x='Age category', fill='Sex') 



# age

age_line = dt[ ,.(ratio=round(100*(sum(suppressed)/sum(valid_results)), 1)),
               by=.(age, sex, date)]


ggplot(age_line, aes(x=date, y=ratio, color=sex)) +
  geom_point() +
  geom_line() +
  facet_wrap(~age, scales='free_y') +
  theme_bw()


ggplot(age_line[year(date)==2017 | year(date)==2018], aes(x=date, y=ratio, color=sex)) +
  geom_point() +
  geom_line() +
  facet_wrap(~age, scales='free_y') +
  theme_bw()


ggplot(age_line[year(date)==2017 | year(date)==2018], aes(x=date, y=ratio, color=sex)) +
  geom_point() +
  geom_line() +
  facet_wrap(~age) +
  theme_bw()


dev.off()







# map

  
# call map code
# create maps of viral suppression by region for age groups by sex





# tables 




men = dt[(year==2017 | year==2018) & sex=='Male',.(valid_results=sum(valid_results), sup=round(100*(sum(suppressed)/sum(valid_results)), 1)), by=age][order(age)]
women = dt[(year==2017 | year==2018) & sex=='Female',.(valid_results=sum(valid_results), sup=round(100*(sum(suppressed)/sum(valid_results)), 1)), by=age][order(age)]
write.csv(men, paste0(outDir, 'age_totals_male.csv'))
write.csv(women, paste0(outDir, 'age_totals_female.csv'))

# chi2
men = dt[(year==2017 | year==2018) & sex=='Male',.(valid_results=sum(valid_results), sup=round(100*(sum(suppressed)/sum(valid_results)), 1)), by=age][order(age)]





sup = dt[ ,.(patients=sum(patients_received), vl_ratio=round(100*(sum(suppressed)/sum(valid_results)), 1)),
          by=.(sex, year(date))][order(year, sex)]
write.csv(sup, paste0(outDir, 'ratio.csv'))




# regression analysis

# chi2




#--------------------------------------



ratio = dt[ ,.(value = sum(patients_received)), by=.(sex, Year=year(date))][order(sex, Year)]

ratio = dcast(ratio, Year~sex)

ratio[ , submit:=round(Female/Male, 1)]

dt[age=='15 - 19' | age=='15 - 24',.(samples=sum(patients_received)), by=sex]

dt[age=='25 - 29' | age=='30 - 34',.(samples=sum(patients_received)), by=sex]
















  
