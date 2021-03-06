#------------------------------------------------
# PDF VISUALS 
#----------------------------------------
# reporting completeness graphs

# 1 - count of facilities and art sites reporting
g1 = ggplot(report[ratio==FALSE], aes(x=date, y=value, color=variable, group=variable)) +
  geom_point(size=0.8) +
  geom_line() +
  geom_line() +
  theme_bw() +
  facet_wrap(~indicator) +
  scale_color_manual(values = brewer.pal(4, 'RdYlBu')) +
  labs(x='Date', y='Number of health facilities', 
       title='Number of health facilities and ART sites reporting stock out information', 
       caption = '*For accredited ART sites only; non-ART sites that provide Option B+ also reported on ARV stock (not represented here)',
       subtitle='2014 - September 2019', color="")

# 2 - ratio of facilities reporting
g2 = ggplot(report[ratio==TRUE], aes(x=date, y=value, color=variable, group=variable)) +
  geom_point(size=0.8) +
  geom_line() +
  geom_line() +
  theme_bw() +
  facet_wrap(~variable) +
  labs(x='Date', y='% of facilities', 
       title='Percentage of health facilities and ART sites reporting stock out information',
       subtitle='2014 - September 2019', color='% Reporting')

#-----------------------------------
# arv stockout graphs 

# 3 - arv stockout counts
g3 = ggplot(arv[variable!='Percentage of ART sites stocked out of ARVs'], 
            aes(x=date, y=value, color=variable, group=variable)) +
  geom_line() +
  geom_line() +
  theme_bw() +
  labs(title='Number of ART sites that were stocked out of ARVs in a given week', 
       y='Number of facilities', x='Date', color="")

# 4  - arv stockout counts below a threshold
g4 = ggplot(arv_thresh[variable!='Percentage of ART sites stocked out of ARVs'],
            aes(x=date, y=value, color=variable, group=variable)) +
  geom_point(alpha=0.5, size=0.8) +
  geom_line() +
  geom_line() +
  theme_bw() +
  labs(title='Number of ART sites that were stocked out of ARVs in a given week', 
       subtitle = 'Weeks in which at least 50% of ART sites reported',
       y='Number of facilities', x='Date', color="")

# 5 - percentage of art sites that reported that were stocked out
# label the range of percentages
perc_range = arv[variable=='Percentage of ART sites stocked out of ARVs' ,range(value)]
st_range = paste0("Range: ", perc_range[[1]], '-', perc_range[[2]], '%')

g5 = ggplot(arv[variable=='Percentage of ART sites stocked out of ARVs'], aes(x=date, y=value)) +
  geom_point(size=0.5) +
  geom_line() +
  geom_line() +
  theme_bw() +
  facet_wrap(~variable, scales='free_y') +
  labs(title='Percentage of ART sites that were stocked out of ARVs in a given week', 
       subtitle=st_range, x='Date', y='Percent (%)')

# summary graph 
g5a = ggplot(arv, aes(x=date, y=value, color=factor(variable))) +
  geom_point(size=0.5) +
  geom_line() +
  geom_line() +
  theme_bw() +
  facet_wrap(~variable, scales='free_y') +
  labs(title='Stock outs of ARVs at ART Sites',
       subtitle ='January 2014 - September 2019',
       x='Date', y='', color="")

#-----------------------------------
# arv stockout bar graphs

# 6 - stacked bar of weeks stocked out 
g6 = ggplot(arv_weeks[weeks!=0], aes(x=weeks, y=facilities, fill=factor(year))) + 
  geom_bar(stat='identity', position='dodge') +
  theme_minimal() +
  scale_fill_manual(values=bar_color) +
  labs(title = "Number of ART sites stocked out of ARVs for at least one week by total weeks stocked out",
       x='Number of weeks out of stock*', 
       y="Number of facilities", caption="*Does not include facilities stocked out for 0 weeks", 
       fill='Year (n = total facilities)',
       subtitle='2014 - 2018')

# 7 - stacked bar of weeks stocked out 
g7 = ggplot(arv_weeks2, aes(x=weeks, y=facilities, fill='red')) + 
  geom_bar(stat='identity', position='stack') +
  geom_text(data=lab_facilities, aes(label=lab_facilities$facilities), vjust=-0.5)+
  theme_minimal() +
  scale_fill_manual(values=bar_color) +
  labs(title = "Number of ART sites by total time out of ARVs", 
       subtitle = "January 1 - September 1, 2019",
       x='Number of weeks out of stock', 
       y="Number of facilities")+
  guides(fill=FALSE)

# 7a - stacked bar of weeks out of stock by facility level
g7a = ggplot(arv_weeks2, aes(x=weeks, y=facilities, fill=factor(arv_weeks2$level))) + 
  geom_bar(stat='identity', position='stack') +
  theme_minimal() +
  scale_fill_manual(values=brewer.pal(9, 'Purples')) +
  labs(title = "ART sites by facility level and total time out of ARVs", 
       subtitle = 'January 1 - September 1, 2019',
       x='Number of weeks out of stock', 
       y="Number of facilities", fill='Health facility level')


g6a = ggplot(arv_weeks3, aes(x=weeks, y=facilities, fill=factor(year))) + 
  geom_bar(stat='identity', position='dodge') +
  theme_minimal() +
  scale_fill_manual(values=bar_color) +
  labs(title = "Number of ART sites stocked out of ARVs",
       x='Number of weeks out of stock*', 
       y="Number of facilities", 
       fill='Year (n = total facilities)',
       subtitle='January 1 - September 1')

#-----------------------
# ARV stockout maps - 8:15

# map of facility-weeks of stock outs - 8
g8 = ggplot(arv_map, aes(x=long, y=lat, group=group, fill=value)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Reds'))) + 
  theme_void() +
  labs(title="Total facility-weeks of ARV stockouts by district, Uganda", 
       caption="*A facility-week is defined as each week a facility reports", 
        fill="Facility-weeks*") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

# mean weeks stocked out per facility - 9
g9 = ggplot(arv_map_norm, aes(x=long, y=lat, group=group, fill=mean_weeks)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Blues'))) + 
  theme_void() +
  labs(title="Mean number of weeks stocked out of ARVs per ART site by district", caption="Source: HMIS", 
  fill="Mean weeks per facility") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

# rate of change in annual facility-weeks stocked out - 10
g10 = ggplot(roc_map, aes(x=long, y=lat, group=group, fill=change)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  scale_fill_gradientn(colors=rev(brewer.pal(9, 'RdYlBu'))) + 
  theme_void() +
  labs(title="Rate of change: facility-weeks of ARV stockouts in 2018 minus 2017", 
       caption="* Positive difference = more weeks stocked out in 2018 than 2017", 
       fill="Difference in weeks (2018 - 2017)*") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

# facilities with more stockouts - 11
g11 = ggplot(roc_map_alt, aes(x=long, y=lat, group=group, fill=change)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  scale_fill_gradientn(colors=brewer.pal(9, 'Reds')) + 
  theme_void() +
  labs(title="Districts with more facility-weeks of ARV stockouts in 2018 than 2017 ",
       caption="The number of ART sites remained the same from 2017 to 2018", 
        fill="Difference in weeks (2018 - 2017)") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

#-----------------
# categorical ROC graph

g11a = ggplot(roc_map, aes(x=long, y=lat, group=group, fill=roc_cat)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  theme_void() +
  labs(title="District-level change in stock outs: facility-weeks of ARV stockouts in 2018 minus 2017", 
       fill="Difference in weeks (2018 - 2017)") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

#-----------------
# percentage of weeks stocked out - 12
g12 = ggplot(stock, aes(x=long, y=lat, group=group, fill=percent_out)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path() + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Reds'))) + 
  theme_void() +
  labs(title="Percentage of facility-weeks stocked out of ARVs", 
       subtitle="Weeks ART sites were stocked out/Total weeks in which ART sites reported", 
       caption='Source: HMIS', fill="% of weeks stocked out") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

# percentage of weeks stocked out, just 2017/18 - 13
g13 = ggplot(stock[year==2017 | year==2018], aes(x=long, y=lat, group=group, fill=percent_out)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Reds'))) + 
  theme_void() +
  labs(title="Percentage of facility-weeks stocked out of ARVs", 
       subtitle="Weeks ART sites were stocked out/Total weeks in which ART sites reported", 
       caption='Source: HMIS', fill="% of weeks stocked out") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

# percentage of weeks stocked out, just 2017/18 - 13
g14 = ggplot(stock[year==2017 | year==2018], aes(x=long, y=lat, group=group, fill=percent_out)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Reds'))) + 
  theme_void() +
  labs(title="Weeks ART sites were stocked out/Total weeks in which ART sites reported", 
       caption='Source: HMIS', fill="% of weeks stocked out") +
  theme(plot.title =element_text(size=16), strip.text.x = element_text(size=18), legend.text=element_text(size=14),  
        legend.title=element_text(size=14)) 

#---------------------------------------------------
# TEST KIT GRAPHS BEGIN 

# number of weeks of stockout divided by facilities reporting, 2017/18 only - 15
g15 = ggplot(tk_map_norm[year==2017 | year==2018], aes(x=long, y=lat, group=group, fill=mean_weeks)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Blues'))) + 
  theme_void() +
  labs(fill="Mean weeks per facility") +
  theme(plot.title = element_text(size=16), strip.text.x = element_text(size=18), legend.text=element_text(size=14),
        legend.title=element_text(size=14)) 

# comparison of stock outs - arvs and test kits - 16
g16 = ggplot(compare, aes(x=date, y=value, color=variable)) +
  geom_point(size=0.6) +
  geom_line() +
  geom_line() +
  theme_bw() +
  scale_color_manual(values=two) +
  labs(x='Date', y='Percent (%)', color="") +
  theme(plot.title = element_text(size=16), strip.text.x = element_text(size=18), legend.text=element_text(size=14)) 

#----------------------------
# same slide, but titled to use as the opening slide

g_opener = ggplot(compare, aes(x=date, y=value, color=variable)) +
  geom_point(size=0.6) +
  geom_line() +
  geom_line() +
  theme_bw() +
  scale_color_manual(values=two) +
  labs(x='Date', y='Percent (%)', color="",
       title='Percentage of health facilitities with inventory stock outs, weekly',
       subtitle='January 1, 2014 - September 1, 2019')+
  theme(plot.title = element_text(size=16), strip.text.x = element_text(size=18), legend.text=element_text(size=14)) 

#------------------------------
# TEST KIT GRAPHS

# test kits - 16:18

# test kit stockout counts - 16
g17 = ggplot(test[variable!='Percentage of facilities stocked out of test kits'],
      aes(x=date, y=value, color=variable, group=variable)) +
  geom_point(size=0.5, alpha=0.5) +
  geom_line() +
  geom_line() +
  theme_bw() +
  labs(title='Number of facilities that were stocked out of HIV test kits in a given week', 
       y='Number of facilities', x='Date', color="")

# percentage of facilities that reported that were stocked out of test kits - 17
g18 = ggplot(test[variable=='Percentage of facilities stocked out of test kits'], aes(x=date, y=value)) +
  geom_point(size = 0.5) +
  geom_line() +
  geom_line() +
  theme_bw() +
  facet_wrap(~variable, scales='free_y') +
  labs(title='Percentage of facilities that were stocked out of HIV test kits in a given week', 
       x='Date', y='Percent (%)')


#------------------------------
# stacked bar graphs - 19:20 

# stacked bar of weeks stocked out 
g19 = ggplot(tk_weeks, aes(x=weeks, y=facilities, fill=factor(year))) + 
  geom_bar(stat='identity', position='dodge') +
  theme_minimal() +
  scale_fill_manual(values=brewer.pal(5, 'Blues')) +
  labs(title = "Facilities stocked out of HIV test kits for at least one week by total weeks stocked out", x='Number of weeks out of stock*', 
       y="Number of facilities", caption="*Does not include facilities stocked out for 0 weeks", fill='Year')

g20 = ggplot(tk2019, aes(x=weeks, y=facilities, fill=factor(year))) + 
  geom_bar(stat='identity', position='dodge') +
  geom_text(data=tk2019, aes(label=facilities), vjust=-0.5)+
  theme_minimal() +
  scale_fill_manual(values=rev(brewer.pal(5, 'Reds'))) +
  labs(title = "Number of facilities out of test kits by total weeks out, 2019", 
       x='Number of weeks out of stock', 
       y="Number of facilities", fill="")

# stock out scatter by year
g21 = ggplot(scat, aes(x=year, y=test_kits, color=level))+
  geom_jitter(alpha=0.8)+
  theme_bw()+
  labs(x='Year', y='Weeks out of test kits',
       title='Number of weeks out of test kits per facility in a given year',
       color='Facility level')

#------------------------------------
# test kit maps - 21:26

# map of facility-weeks of stock outs 
g22 = ggplot(tk_map, aes(x=long, y=lat, group=group, fill=value)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Reds'))) + 
  theme_void() +
  labs(title="Total facility-weeks of test kit stockouts by district, Uganda", caption="Source: HMIS", 
   fill="Facility-weeks stocked out of tests") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

# number of weeks of stockout divided by facilities reporting 
g23 = ggplot(tk_map_norm, aes(x=long, y=lat, group=group, fill=mean_weeks)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Blues'))) + 
  theme_void() +
  labs(title="Mean number of weeks stocked out of HIV test kits per facility by district", caption="Source: HMIS", 
       fill="Mean weeks per facility") 

# number of weeks of stockout divided by facilities reporting, 2017/18 only
g24 = ggplot(tk_map_norm[year==2017 | year==2018], aes(x=long, y=lat, group=group, fill=mean_weeks)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Blues'))) + 
  theme_void() +
  labs(title="Mean number of weeks stocked out of HIV test kits per facility", 
       fill="Mean weeks per facility") +
  theme(plot.title=element_text(size=22), plot.caption=element_text(size=18)) 

# rate of change 
g25 = ggplot(tk_roc_map, aes(x=long, y=lat, group=group, fill=change)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  scale_fill_gradientn(colors=brewer.pal(9, 'RdYlBu')) + 
  theme_void() +
  labs(title="Rate of change: facility-weeks of test kit stockout in 2018 minus 2017", caption="Source: HMIS", 
       subtitle='Same time period: January - November',fill="Difference in weeks (2018 - 2017)") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

# districts with more facility-weeks of stockouts
g26 = ggplot(tk_roc_map_alt, aes(x=long, y=lat, group=group, fill=change)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  scale_fill_gradientn(colors=brewer.pal(9, 'BuGn')) + 
  theme_void() +
  labs(title="Districts with more facility-weeks of test kit stockouts in 2018 than 2017 ", 
       subtitle='Same time period: January - September',
       fill="Difference in weeks (2018 - 2017)") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 


#---------------
# categorical facility-weeks 

g26a = ggplot(tk_roc_map, aes(x=long, y=lat, group=group, fill=roc_cat)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  theme_void() +
  labs(title="District-level change in stock outs: facility-weeks of test kit stockouts in 2018 minus 2017", 
       fill="Difference in weeks (2018 - 2017)") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

#---------------
# percentage of weeks stocked out
g27 = ggplot(tk_stock, aes(x=long, y=lat, group=group, fill=percent_out)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~year) +
  scale_fill_gradientn(colors=(brewer.pal(9, 'Blues'))) + 
  theme_void() +
  labs(title="Percentage of facility-weeks stocked out", 
       subtitle="Weeks stocked out at ART sites/Total weeks reported on by ART sites", 
       caption='Source: HMIS', fill="% of weeks stocked out") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

#--------------------------------
# facility level scatter plots - 27:29

# arv stockouts by level
g28 = ggplot(scatter[art_site==TRUE & !is.na(level2)], aes(x=level2, y=arvs)) +
  geom_jitter(width=0.25, alpha=0.2) +
  theme_bw() + 
  labs(title='Weeks stocked out of ARVs by facility level (ART sites)',
       subtitle='2017 - 2018', x='Facility level',
       y='Weeks stocked out of ARVs')

# arv stockouts by level, year       
g29 = ggplot(scatter2[art_site==TRUE], aes(x=level2, y=arvs)) +
  geom_jitter(width=0.25, alpha=0.2) + 
  facet_wrap(~year) +
  labs(title='Weeks stocked out of ARVs by facility level (ART sites)', x='Facility level', 
       y='Weeks stocked out of ARVs', caption = 'Note: 2019 includes only 35 weeks of data') +
  theme_bw()

# test kit stockouts by level, year       
g30 = ggplot(scatter, aes(x=level2, y=test_kits)) +
  geom_jitter(width=0.25, alpha=0.5) + 
  labs(title='Weeks stocked out of HIV test kits by facility level', 
       subtitle='2017 - 2018',
       x='Facility level', 
       y='Weeks stocked out of HIV test kits') +
  theme_bw()

# test kit stockouts by level, year       
g31 = ggplot(scatter2, aes(x=level2, y=test_kits)) +
  geom_jitter(width=0.25, alpha=0.5) + 
  facet_wrap(~year) +
  labs(title='Weeks stocked out of HIV test kits by facility level', x='Facility level', 
       y='Weeks stocked out of HIV test kits', subtitle='Same time period: January - September') +
  theme_bw()

#--------------------------------
# finale maps - categorical arv stock outs - 30:33

# Number of weeks stocked out, categorical
g32 = ggplot(final[year==2018], aes(x=long, y=lat, group=group, fill=value)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~variable) +
  scale_fill_gradientn(colors=brewer.pal(9, 'YlGnBu')) + 
  theme_void() +
  labs(title="Number of facilities stocked out of ARVs by total time stocked out, 2018", 
       subtitle="Cumulative: one month is equal to four weeks stocked out of ARVs", 
       caption='Source: HMIS', fill="Number of facilities") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

#------------------
# alternate map with 0s in grey 
  
g32a = ggplot(final[year==2018], aes(x=long, y=lat, group=group, fill=alter)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~variable) +
  scale_fill_gradientn(colors=brewer.pal(9, 'Reds')) + 
  theme_void() +
  labs(title="Number of facilities stocked out of ARVs by total time stocked out, 2018", 
       subtitle="Grey = 0 facilities", 
       caption='Source: HMIS', fill="Number of facilities") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

#------------------
# at least one stockout
g33 = ggplot(final[year==2017 & variable!='No stock outs reported'], aes(x=long, y=lat, group=group, fill=value)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~variable) +
  scale_fill_gradientn(colors=brewer.pal(9, 'YlGnBu')) + 
  theme_void() +
  labs(title="Number of facilities stocked out of ARVs by time stocked out, 2017", 
       subtitle="Includes only ART sites with at least one week out", 
       caption='Source: HMIS', fill="Number of facilities") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

# Number of weeks stocked out, categorical
g34 = ggplot(final[year==2018], aes(x=long, y=lat, group=group, fill=value)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~variable) +
  scale_fill_gradientn(colors=brewer.pal(9, 'YlOrBr')) + 
  theme_void() +
  labs(title="Number of facilities stocked out of ARVs by time stocked out, 2018", 
       subtitle="Cumulative: one month is equal to four weeks stocked out of ARVs", 
       caption='Source: HMIS', fill="Number of facilities") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

# at least one stockout
g35 = ggplot(final[year==2018 & variable!='No stock outs reported'], aes(x=long, y=lat, group=group, fill=value)) + 
  coord_fixed() +
  geom_polygon() + 
  geom_path(size=0.01) + 
  facet_wrap(~variable) +
  scale_fill_gradientn(colors=brewer.pal(9, 'YlOrBr')) + 
  theme_void() +
  labs(title="Number of facilities stocked out of ARVs by time stocked out, 2018", 
       subtitle="Minimum one week of stockout", 
       caption='Source: HMIS', fill="Number of facilities") +
  theme(plot.title=element_text(vjust=-1), plot.caption=element_text(vjust=6)) 

#------------------------------


