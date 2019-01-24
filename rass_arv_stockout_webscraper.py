## Emily Linebarger- adapted from code by Emily Dansereau and Hannah Kravitz
## Code to automatically download data from RASS ARV stockouts dashboards
## January 2019

## Works with Python Anaconda package
## Need to have Selenium Python package AND Chrome Driver installed. 
## https://pypi.python.org/pypi/selenium
## https://sites.google.com/a/chromium.org/chromedriver/home

#Pseudo code: 
# 1. Navigate to the table you want. There are two you can pull, let's just do the first one as an example. 
# 2. Download the CSV of the drug data. 
# 3. Import this .csv back into Python, and drop all of the rows with 0's. 
# 4. Reshape the data long, so the number of rows of the data represents the number of clicks you should make to get the facility level data. 
# 5. Navigate to these places on the embedded table, and click to expose the .csv of facilities. 
# 6. Download this .csv of facilities, and import it into Python 
# 7. Reshape the second .csv wide, and append it to the first .csv so each row has the facility names with stock outs. 
# 8. Add on week, district, region, and facility name variables. 
# 9. Remove 2 csvs from downloads so links don't break. 

#---------------------------------------------------------------
# Import packages
#---------------------------------------------------------------
import time
from selenium import webdriver
import pandas as pd
import os

#---------------------------------------------------------------
# Set up main variables for the website.
#---------------------------------------------------------------
main_url = "http://rass.mets.or.ug/"
save_loc = "J:/Project/Evaluation/GF/outcome_measurement/uga/rass_arv_dashboards/raw/"
admin_level = "District" 
current_week="2019w3" #Change to match the current week, but it won't break the code either way. 

#---------------------------------------------------------------
# Start your chrome driver!
#---------------------------------------------------------------
driver = webdriver.Chrome('C:\chromedriver.exe')

#---------------------------------------------------------------
#Set the names of the districts and weeks you want to pull here. 
#---------------------------------------------------------------
districts = {
        "Buliisa District":"CQTmrrriwOq", 
#        "Hoima District":"PJFtfCyp6Rb",
#        "Kagadi District":"LtyM5HnzFui",
#        "Kakumiro District":"HRakdY52JPf",
#        "Kibaale District":"AtnLKczpkvP",
#        "Kikuube District":"fXT6ayIyYeH",
#        "Kiryandongo District":"B0G9cqixld8",
#        "Masindi District":"xr8EMirOASp"
        }

weeks = [""]
for year in {2016, 2017}:
    for week in range(1):
        week_string = str(year) + "W" + str(week+1)
        print(week_string)
        weeks += week_string

#---------------------------------------------------------------
# For the districts and weeks specified above, pull the list of facilities
#   that have information on ARV stocks. 
#---------------------------------------------------------------
for district in districts:
    for week in weeks:
        print(week)
        
        final_dir = save_loc + district + "/"
        file = final_dir + str(week) + ".csv"
        print(file)
        #Check to make sure you haven't downloaded this data before! 
        if os.path.isfile(file):
            print("This data has already been downloaded. Skipping this district/week: " + str(district) + " " + str(week))
        else:    
            print("Downloading " + str(district) + " " + str(week))
            
            #Create a URL to access the given week for the given district (accessing API back end)
            url = main_url + "?o=" + districts[district] + "&w=" + week + "&wn=1" + "&on=" + district + "&ol=" + admin_level + "&cw=" + current_week; 
            driver.get(url); 
            time.sleep(2); #Give it a second to load. 
        
            # Download the first table, the stock status for HIV communities, to get which rows and columns have valid data (not 0).
            driver.find_element_by_xpath('//*[@id="stock_wrapper"]/div[1]/button[2]/span').click()
            time.sleep(3)
            
            # Reimport into Python, and only keep the rows that have working links, and valid facility data (value is not 0). 
            commodities = pd.read_csv("C:/Users/elineb/Downloads/MoH Uganda - Realtime ARV Stock Status Monitoring Dashboard.csv") 
            commodities.insert(0, 'row_number', range(1, 1+len(commodities))) #Add a number to match the row number in the embedded table in the website to make an xpath later.
            
            # Reshape the data long, so the number of rows of the data represents the number of clicks you should make to get the facility level data. 
            commodities = pd.melt(commodities, id_vars=['Commodity', 'Category', 'row_number'], value_vars = ['#Under', '#Adequate', '#Over', '#StockOuts'])
            commodities = commodities.dropna(axis=0) #This is the dataset that should guide you for step 5
            commodities = commodities[commodities.value!=0]
            
            #Only attempt to grab data if you have some valid rows. 
            if (len(commodities)!=0):
                #Use this dictionary to build up an x-path (corresponds to embedded table in website)
                col_number = {
                    '#Under': '3',
                    '#Adequate': '4',
                    '#Over': '5',
                    'StockOuts': '6'
                }
                
                #Assign a new column to the data frame giving the column number of the embedded table in the website. 
                #Making this slightly less code using the dictionary above. 
                for number in col_number:
                    commodities.loc[commodities['variable'] == number, 'col_number'] = col_number[number]
                    
                #Format a list of xpaths you need to click given the data frame above, which tells you where you have valid facilities. 
                #Build a string for the xpath of a list of facilities under each of the four types listed in the 'col_number' dictionary above. 
                commodities["xpath"] = '//*[@id="stock"]/tbody/tr[' + commodities["row_number"].map(str) + ']/td[' + commodities["col_number"].map(str) + ']/a'
                
                #Navigate to this xpath, which represents a list of facilities, and click. Download this .csv to the J:drive. 
                for index, row in commodities.iterrows():
                    driver.find_element_by_xpath(row['xpath']).click()
                    driver.find_element_by_xpath('//*[@id="hf-list_wrapper"]/div[1]/button[2]/span').click()
                    time.sleep(3)
                    
                    #Save this file on the J:drive in the raw data folder 
                    if not os.path.exists(final_dir): #Add a test to make sure you haven't downloaded this data before. Actually add this at the top! 
                        os.makedirs(final_dir)
                    os.rename("C:/Users/elineb/Downloads/MoH Uganda - Realtime ARV Stock Status Monitoring Dashboard.csv", file)
                    
                    #Navigate back to the URL you were working on so you can keep going!
                    driver.get(url)
        
        
