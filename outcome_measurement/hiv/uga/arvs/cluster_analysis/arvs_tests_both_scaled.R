# K-means cluster analysis
# Final model for use in analysis
# Plots to determine number of clusters and variables to use

# Caitlin O'Brien-Carelli
# 10/18/2019

# ----------------------
# Set up R
rm(list=ls())
library(ggplot2)
library(rgdal)
library(dplyr)
library(RColorBrewer)
library(plyr)
library(data.table)
library(dendextend)
library(purrr)
library(cluster)
library(gridExtra)
library(plotly)

# turn off scientific notation
options(scipen=999)
# ----------------------
# home drive 
j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')

# data directory
dir = paste0(j,  '/Project/Evaluation/GF/outcome_measurement/uga/arv_stockouts/')

# import the data 
dt = readRDS(paste0(dir, 'prepped_data/arv_stockouts_2013_2019.rds'))

# set the working directory to the code repo to source functions
setwd('C:/Users/ccarelli/local/gf/outcome_measurement/hiv/uga/arvs/cluster_analysis/')

# drop 2013 - reporting is very low and short time series 
dt = dt[year!=2013]

# ----------------------
# source the functions for elbow plots and silhouette widths

source('cluster_functions.R')

#----------------------------
# create a data frame on which to run linear regressions

# create a new data table
df = copy(dt)

# calculate if the facility reported on test kit or arv stock outs
df[!is.na(test_kits), reported_tests:=TRUE]
df[is.na(reported_tests), reported_tests:=FALSE]
df[!is.na(arvs), reported_arvs:=TRUE]
df[is.na(reported_arvs), reported_arvs:=FALSE]

#-----------
# sum to the annual level - weeks out and stock outs 
df = df[ ,.(test_kits=sum(test_kits, na.rm=T),
            arvs=sum(arvs, na.rm=T), reported_tests=sum(reported_tests),
            reported_arvs=sum(reported_arvs)),
         by=.(facility, level,region, year)]

# calculate percent of time out of both commodities
df[ , percent_tests:=round(100*(test_kits/reported_tests), 1)]
df[ , percent_arvs:=round(100*(arvs/reported_arvs), 1)]

# if they were never out of stock, set percent of time out to 0
df[is.na(percent_tests), percent_tests:=0]
df[is.na(percent_arvs), percent_arvs:=0]

#------------------------
# sum the main data table to a single value 

# calculate if the facility reported
dt[!is.na(test_kits), reported_tests:=TRUE]
dt[is.na(reported_tests), reported_tests:=FALSE]
dt[!is.na(arvs), reported_arvs:=TRUE]
dt[is.na(reported_arvs), reported_arvs:=FALSE]

# total test kits and total arvs
dt = dt[ ,.(test_kits=sum(test_kits, na.rm=T),
            arvs=sum(arvs, na.rm=T), reported_tests=sum(reported_tests),
            reported_arvs=sum(reported_arvs)),
         by=.(facility, level,region)] # do not include year

# calculate percent of time out of both commodities
# no NANs in data set - otherwise replace with 0s
dt[ , percent_tests:=round(100*(test_kits/reported_tests), 1)]
dt[ , percent_arvs:=round(100*(arvs/reported_arvs), 1)]

#------------------------
# calculate the slopes per facility
# calculate using the annual data, but append to the full time series data 

# slope of change in percent tests
for (f in unique(df$facility)) {
  model = lm(percent_tests~year, data=df[facility==f])
  dt[facility==f, test_slope:=coef(model)[[2]]]
}

# slope of change in percent arvs 
for (f in unique(df$facility)) {
  model = lm(percent_arvs~year, data=df[facility==f])
  dt[facility==f, arv_slope:=coef(model)[[2]]]
}
#------------------------
# scale both

dt[ , test_slope_scale:=((test_slope - mean(test_slope))/sd(test_slope))]
dt[ , arv_slope_scale:=((arv_slope - mean(arv_slope))/sd(arv_slope))]

dt[ , arvs_scale:=((percent_tests - mean(percent_tests))/sd(percent_tests))]
dt[ , tests_scale:=((percent_arvs - mean(percent_arvs))/sd(percent_arvs))]

#----------------------------------------
# create a matrix for cluster analysis

dt_k = dt[ ,.(test_slope_scale, arv_slope_scale, tests_scale, arvs_scale)]

#----------------------------------------
# calculate elbow plots and silhouette widths and plot

# calculate using sourced functions
elbow = elbow_fun(dt_k, 2, 10)
sil = sil_fun(dt_k, 2, 10)



# ----------------------
# plot the elbow plot

elbow_df = ggplot(elbow, aes(x=k, y=tot_withinss))+
  geom_point()+
  geom_line()+
  theme_bw()+
  labs(y = "Total within-cluster sum of squares", x = "K Clusters",
       title='Elbow plot to empirically determine k clusters',
       subtitle='Variables: % of reporting weeks out of ARVs,
       % of reporting weeks out of tests, slopes* (2014 - 2019)',
       caption = '*Slope of the annual change in time out of stock')+
  theme(text=element_text(size=18))

# ----------------------
# plot the silhouette plot

sil_df = ggplot(sil, aes(x=k, y=sil_width))+
  geom_point()+
  geom_line()+
  theme_bw() +
  labs(x='K Clusters', y='Average silhouette width',
       title='Silhouette Width to determine k clusters')+
  theme(text=element_text(size=18))

# ----------------------

#----------------------------------------
# plot the clusters

list_of_plots = NULL
list_of_plots_slope = NULL
i = 1

# function to run the calculations for every cluster
for (x in c(2:10)) {
  # run a test cluster
  k_clust = kmeans(dt_k, centers = x)
  dt[ , kcluster:=k_clust$cluster]
  
  # mark the slope centroids for labeling
  dt[ ,centroid_x_slope:=mean(test_slope_scale, na.rm=T), by=kcluster]
  dt[ ,centroid_y_slope:=mean(arv_slope_scale, na.rm=T), by=kcluster]
  dt[ ,slope_label:=paste0(round(centroid_x_slope, 1), ", ", round(centroid_y_slope, 1)), by=kcluster]
  
  # mark the centroids for labeling
  dt[ ,centroid_x:=mean(tests_scale, na.rm=T), by=kcluster]
  dt[ ,centroid_y:=mean(arvs_scale, na.rm=T), by=kcluster]
  dt[ ,label:=paste0(round(centroid_x), ", ", round(centroid_y)), by=kcluster]
  
  # rbind the data 
  interim_data = copy(dt)
  interim_data[ , total_clusters:=x]
  if (i ==1) full_data = interim_data
  if (1 < i) full_data = rbind(full_data, interim_data)

  # create the plots of the percent of time out
  list_of_plots[[i]] = ggplot(full_data[total_clusters==x],
                              aes(x=tests_scale, y=arvs_scale, color=factor(kcluster)))+
    geom_jitter(alpha=0.6)+
    theme_bw()+
    annotate("text", x=full_data[total_clusters==x]$centroid_x,
             y=full_data[total_clusters==x]$centroid_y,
             label=full_data[total_clusters==x]$label)+
    labs(x = "Percent of weeks out of test kits, scaled",
         y = "Percent of weeks out of ARVs, scaled", color='Clusters',
         title="Percent of reporting weeks out of test kits and ARVs, 2014 - 2019",
         caption = "Percentage is equal to total weeks out/total weeks reported per facility",
         subtitle=paste0('Number of clusters = ', x))+
    theme(text=element_text(size=18))
  
  
  # create plots of the slope
  list_of_plots_slope[[i]] = ggplot(full_data[total_clusters==x],
                                    aes(x=test_slope, y=arv_slope, color=factor(kcluster)))+
    geom_jitter(alpha=0.6)+
    theme_bw()+
    annotate("text", x=full_data[total_clusters==x]$centroid_x_slope,
             y=full_data[total_clusters==x]$centroid_y_slope,
             label=full_data[total_clusters==x]$slope_label)+
    labs(x = "Slope of change in test kit stock outs",
         y = "Slope of change in ARV stock outs", color='Clusters',
         title="Change in stock out percent of time stocked out, 2014 - 2019",
         subtitle=paste0('Number of clusters = ', x))+
    theme(text=element_text(size=18))
  
  i = i+1 }






ah = full_data[total_clusters==5]
ah = ah[kcluster==2 | kcluster==5]


ggplot(ah[kcluster==2 | kcluster==5], 
       aes(x=test_slope_scale, y=arv_slope_scale, color=factor(kcluster)))+
  geom_jitter(alpha=0.2)+
  theme_bw()+
  labs(x = "Slope of change in test kit stock outs",
       y = "Slope of change in ARV stock outs", color='Clusters',
       title="Change in stock out percent of time stocked out, 2014 - 2019",
       subtitle=paste0('Number of clusters = ', 5))+
  theme(text=element_text(size=18))


ah_k = ah[ ,.(test_slope_scale, arv_slope_scale, tests_scale, arvs_scale)]

pamah = pam(ah_k, k=5)

pamah$silinfo

sil = sil_fun(ah_k, 5, 5)

silhouette(ah_k, )

#----------------------------
# print a pdt of plots

pdf(paste0(dir, 'k_means_outputs/all_scaled_2014_2019.pdf'),height=9, width=18)

grid.arrange(elbow_df, sil_df, nrow=1)
for(i in seq(length(list_of_plots_slope))) {
  p = list_of_plots[[i]]
  p_slope = list_of_plots_slope[[i]]
  grid.arrange(p, p_slope, sil_df, nrow=1)
}

dev.off()

#----------------------------
# create a 3d graph for visualization 

plot_ly(full_data[total_clusters==4],
        x = ~percent_tests, y = ~percent_arvs, z = ~test_slope, color = ~factor(kcluster),
        colors = brewer.pal(9, 'RdYlBu')) %>%
  add_markers() %>%
  layout(scene = list(xaxis = list(title = '% Test kits'),
                      yaxis = list(title = '% ARVs'),
                      zaxis = list(title = 'Slope of tests')))

#----------------------------
# export a data set for analysis, including cluster assignmwnra

dt_export = full_data[total_clusters==4, .(facility, percent_tests, 
                                           percent_arvs, test_slope, arv_slope)]

saveRDS(dt_export, paste0(dir, 'prepped_data/cluster_assignments.RDS'))