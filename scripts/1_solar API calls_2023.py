"""



12/15/2021
Alexander Abajian


"""

import numpy as np  # universal package of math operators
import matplotlib.pyplot as plt  # standard Python scientific plotting library
import os  # lets you set your working directory easily
import datetime						# lets you use date-time objects
import requests
import json
import csv
import pandas as pd

# Set your working directory to save files into
os.chdir('/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels/_Data_postAER')

# Pull in the coordinate series
input_coordinates = pd.read_csv('Processed/coordinates_for_NREL.csv');
type(input_coordinates)
print(input_coordinates)

# convert into a DF
data_frame = pd.DataFrame(input_coordinates, columns= ['fips5','LAT','LON']);
print(data_frame)
type(data_frame)

#create series i can call easily
county_list=data_frame['fips5']
latitude_list = data_frame["LAT"]
longitude_list = data_frame["LON"]

##check a few things
print(len(latitude_list))

##list of baseline parameters
array_type = 1
    ###rooftop, no tracking
###mid (15 percent efficiency)
module_type = 1
###high (19 percent efficiency)
module_type = 2
azimuth = 180
system_capacity = 8
#system_capacity = 1
losses = 14.08
tilt = 20
iter = 1



#-----#-----#-----#-----#-----#-----
#-----#-----#-----#-----#-----#-----
#-----#-----#-----#-----#-----#-----
#-----#-----#-----#-----#-----#-----
#-----#-----#-----#-----#-----#-----
#-----#-----#-----#-----#-----#-----

annaul_generation = []
##looop
for i in range(0,820,1):


    #pull in things to loop over
    i_lat = str(latitude_list[i])
    i_lon = str(longitude_list[i])

    # print(i_lat)
    # print(i_lon)

    #generate string parts

    #note this includes xander abajian's API key
    part1 = "https://developer.nrel.gov/api/pvwatts/v6.json?api_key=$$YOUR API KEY HERE$$$$&lat="
    part2 = "&lon="
    #part 3 for mid-efficiency
    part3 = "&system_capacity=1&azimuth=180&tilt=40&array_type=1&module_type=1&losses=14.08"
    #part 3 for high-efficiency
        #part3 = "&system_capacity=1&azimuth=180&tilt=40&array_type=1&module_type=2&losses=14.08"

 
    #create api call to loop over
    dummy_api_call = part1 + i_lat + part2 + i_lon + part3

    #do API call
    response = requests.get(dummy_api_call)
    print(response.status_code)


    pull_response = response.json()
    outputs = pull_response["outputs"]
    # print(outputs)
    annual_ac = outputs["ac_annual"]
    # print(annual_ac)
    annaul_generation.append(annual_ac)



generation_df_out = pd.DataFrame(annaul_generation,columns=['annaul generation'])
#print(generation_df_out)




#remind me of objects
county_list=data_frame['fips5']
latitude_list = data_frame["LAT"]
longitude_list = data_frame["LON"]

#make labeled data for output
d_out = {'fips5_byte': county_list, 'annual_gen': annaul_generation }
#d_out = {'fips5_byte': county_list, 'LAT': latitude_list, 'LON': longitude_list, 'annual_gen': annaul_generation }

#make datafarme
df_out = pd.DataFrame(d_out)
#print(df_out)


#save to .csv
#df_out.to_csv('Processed/NREL_gen_mid_eff_804.csv')
df_out.to_csv('Processed/NREL_gen_mid_eff_820.csv')






