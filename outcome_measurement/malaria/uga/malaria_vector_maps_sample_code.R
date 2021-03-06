# Create maps of HMIS data 

# 21/8/2018
#-----------------------

rm(list=ls())

library(data.table)
library(rgeos)
library(raster)
library(ggplot2)
library(rgdal)
library(tibble)
library(dplyr)
library(RColorBrewer)
library(maptools)
library(plyr)

# --------------------

# ----------------------------------------------
# upload the shape file

# set the working directory to your local drive
# choose the location where your shape file is saved
setwd("C:/Users/ccarelli/Documents/uga/")

# load the shapefile
# you will need additional files in the folder to support the .shp file
# you should not need to change this
shapeData <- shapefile('uga_dist112_map.shp')

# check that shapeData is a spatialpolygonsdataframe
# this should print out spatialpolygonsdataframe
class(shapeData)

# plot the shape file in the base package
plot(shapeData)

# simplify the shape data (could create little gaps, maybe don't do this)
gSimplify(shapeData, tol=0.5, topologyPreserve=TRUE)
plot(shapeData)


#--------------------------------------------
# determine which districts are included in the shape file

# print a list of all of the districts in the map 
unique(shapeData@data$dist112_na)

# confirm that 112 districts are included in the map
length(unique(shapeData@data$dist112_na))

# create a data table that contains only district names and ids from the shape file
# you can match based on name, but it's better to match on id 
# matching on id ensures you don't miss any districts when your merge data with the shape file
shape_names <- data.table(district_name=shapeData@data$dist112_na, id=shapeData@data$dist112)

# view the list of district names and ids
str(shape_names)

#------------------------------
# here are some color palettes you can use
# to use them, change the 'colors' argument in the map code under scale_fill_gradientn
# for example: scale_fill_gradientn(colors=greens)

greens <- brewer.pal(9, 'Greens')
reds <- brewer.pal(9, 'Reds')
purples <- brewer.pal(9, 'Purples')
blues <- brewer.pal(9, 'Blues')
rainbow <- brewer.pal(9, 'RdYlBu')

#-------------------------------------------
# before making a map, clean and check for outliers in your data
# you should only merge prepped, cleaned data with shape files


# upload your prepped, cleaned data 
dt <- readRDS('C:/Users/Jaffers_prepped_data.rds')

# to make a data table to merge with the graph
# input your data table and variable names
# this 'sums' the variable up by district to get annual totals
dt[year==2018, rdts=sum(rdts_performed), by=district]


# check how many districts are in your data set 
# there are probably more than 112, but you need 112 (the map has 112)
dt[ ,length(unique(district))]


# if there aren't 112, here's some code i wrote that should help:

# don't change this - it makes a function!
# the function changes new districts back into old ones
merge_new_dists <- function(x) {
  x[district=="Bunyangabu", district:="Kabarole"]
  x[district=="Butebo", district:="Pallisa"]
  x[district=="Kagadi", district:="Kibaale"]
  x[district=="Kakumiro", district:="Kibaale"]
  x[district=="Kyotera", district:="Rakai"]
  x[district=="Namisindwa", district:="Manafwa" ]
  x[district=="Omoro", district:="Gulu"]
  x[district=="Pakwach", district:="Nebbi"]
  x[district=="Rubanda", district:= "Kabale"]
  x[district=="Rukiga", district:="Kabale"]
  
}

# now you'll run the function on your data!
merge_new_dists(dt) # change dt to the name of your data table

# check that 112 came out...
dt[ ,length(unique(district))]

#----------------------------------
# merge your data table with 'shapenames'
# you do this so your data includes the district id numbers
# this isn't really necessary, but helps to prevent errors

shape_names <- merge(shape_names, dt, by='district', all.x=TRUE ) # change dt to your variable

#-----------------------------------
# MERGE THE DATA AND THE MAP!
# This attaches your data to the map so it will show it

coordinates <- data.table(fortify(shapeData, region='dist112')) 
coordinates[, id:=as.numeric(id)]
coordinates <- merge(coordinates, shape_names, by="id", all.x=TRUE)

#--------------------------------
# map of rdts consumed by health facilities

# change the variable next to fill= to your variable that you want to map
ggplot(coordinates, aes(x=long, y=lat, group=group, fill=YOUR_VARIABLE)) + 
  geom_polygon() + 
  geom_path(size=0.01, color="#636363") + 
  theme_void() + 
  labs(title="RDTs consumed by health facilities",
       fill="RDTs consumed", caption='Source: HMIS', subtitle='January - June 2018') +
  scale_fill_gradientn(colors=greens) + coord_fixed() +
  theme(plot.title=element_text(size=22), plot.subtitle=element_text(size=16), 
        plot.caption=element_text(size=12)) 

#--------------------------------
# map of rdts performed by health facilities

# change the variable after fill= to your variable that you want to map
ggplot(coordinates, aes(x=long, y=lat, group=group, fill=YOUR_VARIABLE)) + 
  geom_polygon() + 
  geom_path(size=0.01, color="#636363") + 
  theme_void() + 
  labs(title="RDTs performed by health facilities by district, Uganda",
        fill="RDTs performed", caption='Source: HMIS', subtitle='January - June 2018') +
  scale_fill_gradientn(colors=purples) + coord_fixed() +
  theme(plot.title=element_text(size=22), plot.subtitle=element_text(size=16), 
        plot.caption=element_text(size=12, vjust=10)) 


#---------------------------
# Bonus map - if you have time
# ACTs consumed by health facilities
# ACTs consumed

ggplot(coordinates, aes(x=long, y=lat, group=group, fill=ACTS_CONSUMED)) + 
  geom_polygon() + 
  geom_path(size=0.01, color="#636363") + 
  theme_void() + 
  labs(title="ACTs consumed by health facilities",
       fill="ACTs consumed", caption='Source: HMIS', subtitle='January - June 2018') +
  scale_fill_gradientn(colors=blues) + coord_fixed() +
  theme(plot.title=element_text(size=22), plot.subtitle=element_text(size=18), 
        plot.caption=element_text(size=12)) 


#--------------------------

