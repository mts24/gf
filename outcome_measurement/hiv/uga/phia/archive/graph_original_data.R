


# import viral load data
vl = readRDS(paste0(j, '/Project/Evaluation/GF/outcome_measurement/uga/phia_2016/prepped/vl_data.rds'))

# import shape file
shapeData = shapefile('uga_dist112_map.shp')

# import phia data 
inFilePHIA = paste0(dir, 'prepped/vl_suppression_by_region.csv')
phia = fread(inFilePHIA)

#------------------------------------------
# aggregate districts into regions
vl = vl[ ,.(suppressed=sum(suppressed), valid_results=sum(valid_results)), by=region]

# calculate the suppression ratio
vl[ , ratio:=round(100*(suppressed/valid_results), 1), by=region]
vl = merge(vl, phia, by='region')
setnames(vl, "VLS prevalence (%)", "phia_vls")

# put the regions in the same order as the shape file
regions = regions[match(shapeData@data$dist112_n, regions$district_name)]
id = regions$region

# create coordinates for the old and new plots
shapeDataNew = unionSpatialPolygons(shapeData, id)

#fortify 
coordinates_new = fortify(shapeDataNew)

# merge the data with the coordinates
setnames(vl, 'region', 'id')
coordinates_new = merge(coordinates_new, vl, by='id')
coordinates_new = data.table(coordinates_new)

# identify centroids and label them
names = data.table(coordinates(shapeDataNew))
setnames(names, c('long', 'lat'))
name = unique(coordinates_new$id)
names = cbind(names, name)

# merge in the ratios to create complete labels
vl_new = vl[ ,.(name=id, ratio)]
names = merge(vl_new, names, by='name')

# fix the names to match the phia graphic
names$name = gsub(names$name, pattern='_', replacement='-')
names[grep('^Central', name), name:=(gsub(name, pattern='-', replacement=' '))]
names[grep('^West', name), name:=(gsub(name, pattern='-', replacement=' '))]

# create complete labels
names[ ,name:=paste0(name, ': ', ratio, '%')]
names[ ,ratio:=NULL]

# ---------------
# graph the same time period as the phia graph in uganda vl 

# store colors
ratio_colors = brewer.pal(6, 'BuGn')

# set legend breaks
breaks = c(80, 83, 86, 89)

# map of regions 
plot1 = ggplot(coordinates_new, aes(x=long, y=lat, group=group, fill=ratio)) + 
  geom_polygon() + 
  scale_fill_gradientn(colors=ratio_colors, breaks=breaks) + 
  theme_void() +
  coord_fixed() +
  labs(fill='VLS') +
  geom_label_repel(data = names, aes(label = name, x = long, y = lat, group = name), inherit.aes=FALSE, size=5)


#---------------------------------------------------------------

#---------------------------------------------------------------
# map 2011 or 2016 aids indicator survey estimates 
# these data are cleaned in the analysis function 

# select the survey or projected estimates and import the data 
ais = readRDS(paste0(root, '/Project/Evaluation/GF/outcome_measurement/uga/phia_2016/prepped/ais_data.rds'))
setnames(ais, 'region', 'id')

# round estimates and format as percentages
ais[ , art_coverage:=round(100*art_coverage, 1)]
ais[ , art_coverage_gbd:=round(100*art_coverage_gbd, 1)]
ais[ , art_coverage_2011:=round(100*art_coverage_2011, 1)]

# create a set of art coverage colors
art_colors = brewer.pal(8, 'Spectral')

#--------------------------
# create regional labels 

# identify centroids and label them
ais_names = data.table(coordinates(shapeDataNew))
setnames(ais_names, c('long', 'lat'))
ais_names[ , id:=unique(coordinates_new$id)]

# merge in the ratios for complete labels
ais_names = merge(ais_names, ais, by='id')

# replace labels with hyphens to match phia graphics
ais_names$id = gsub(ais_names$id, pattern='_', replacement='-')
ais_names[grep('^Central', id), id:=(gsub(id, pattern='-', replacement=' '))]
ais_names[grep('^West', id), id:=(gsub(id, pattern='-', replacement=' '))]

# create labels with region names and art coverage ratios
ais_names[ ,art_coverage_2011:=paste0(id, ': ', art_coverage_2011, '%' )]
ais_names[ ,art_coverage_gbd:=paste0(id, ': ', art_coverage_gbd, '%' )]
ais_names[ ,art_coverage:=paste0(id, ': ', art_coverage, '%' )]

# shape long
ais_names = melt(ais_names, id.vars=c('id', 'long', 'lat'))

#----------------------------
# repeat to facet wrap
coordinates_ais = merge(coordinates_new, ais, by='id')
coordinates_ais[ ,c('suppressed', 'valid_results', 'ratio'):=NULL]
coordinates_ais = melt(coordinates_ais, id.vars=c('id', 'long', 'lat', 'order', 'hole', 'piece', 'group'))

# print out a comparative map of original and projected estimates
pdf(paste0(root, '/Project/Evaluation/GF/outcome_measurement/uga/phia_2016/output/art_coverage_comparison_maps.pdf'), height=6, width=12)

# map of regions 

ggplot(coordinates_ais, aes(x=long, y=lat, group=group, fill=value)) + 
  geom_polygon() + 
  scale_fill_gradientn(colors=art_colors) + 
  theme_void() +
  coord_fixed() +
  facet_wrap(~variable) +
  labs(fill='ART Coverage(%)') +
  geom_label_repel(data = ais_names, aes(label = value, x = long, y = lat, group = value), inherit.aes=FALSE, size=4)

dev.off()

#---------------------------------------------------------------
# phia and vl dashboard before regression

pv = readRDS('J:/Project/Evaluation/GF/outcome_measurement/uga/phia_2016/prepped/phia_vl_adj.rds')
setnames(pv, 'region', 'id')

# round estimates and format as percentages
pv[ , vld_suppression_adj:=round(vld_suppression_adj, 1)]

# create a set of art coverage colors
lavender = brewer.pal(8, 'BuPu')

#--------------------------
# create regional labels 

# identify centroids and label them
pv_names = data.table(coordinates(shapeDataNew))
setnames(pv_names, c('long', 'lat'))
pv_names[ , id:=unique(coordinates_new$id)]

# merge in the ratios for complete labels
pv_names = merge(pv_names, pv, by='id')

# replace labels with hyphens to match phia graphics
pv_names$id = gsub(pv_names$id, pattern='_', replacement='-')
pv_names[grep('^Central', id), id:=(gsub(id, pattern='-', replacement=' '))]
pv_names[grep('^West', id), id:=(gsub(id, pattern='-', replacement=' '))]

# create labels with region names and art coverage ratios
pv_names[ , phia:=paste0(id, ': ', phia_vls, '%' )]
pv_names[ , vl:=paste0(id, ': ', vld_suppression_adj, '%' )]

vl_names = pv_names[ ,.(id, long, lat, variable='vld_suppression_adj', value=vl)]
phia_names = pv_names[ ,.(id, long, lat, variable='phia_vls', value=phia)]
labels = rbind(vl_names, phia_names)

#--------------------------------------------
# merge coordinates and make maps
pv = melt(pv, id.vars='id')

pv1 = pv[variable=='phia_vls']
pv2 =  pv[variable=='vld_suppression_adj']

coordinates_new[ ,c('suppressed', 'valid_results', 'ratio'):=NULL]
map1 = merge(coordinates_new, pv1, by='id')
map2 = merge(coordinates_new, pv2, by='id')

coord_pv = rbind(map1, map2)

# map of regions 
ggplot(coord_pv, aes(x=long, y=lat, group=group, fill=value)) + 
  geom_polygon() + 
  scale_fill_gradientn(colors=lavender) + 
  theme_void() +
  coord_fixed() +
  facet_wrap(~variable) +
  labs(fill='VLS (%)') +
  geom_label_repel(data = labels, aes(label = value, x = long, y = lat, group = value), inherit.aes=FALSE, size=5)

#-------------------------------------------