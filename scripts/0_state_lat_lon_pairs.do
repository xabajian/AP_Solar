clear all

/*
!!@#$!@#$!@#$

make lat lon pairs
!!@#$!@#$!@#$
*/


//set macros
global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/_Data_postAER/Raw"
global temp "$root/_Data_postAER/Temp"
global processed "$root/_Data_postAER/Processed"

cd "$processed"

/*
Read deepsolar data with corrected solar flux values at the census tract level
*/
use "$temp/DeepSolar_Dec2018_int.dta", clear

collapse LAT LON [aweight = household_count], by(STATE state)


replace state="Alabama" if STATE=="AL"
replace state="Alaska" if STATE=="AK"
replace state="Arizona" if STATE=="AZ"
replace state="Arkansas" if STATE=="AR"
replace state="California" if STATE=="CA"
replace state="Colorado" if STATE=="CO"
replace state="Connecticut" if STATE=="CT"
replace state="Delaware" if STATE=="DE"
replace state="District Of Columbia" if STATE=="DC"
replace state="Florida" if STATE=="FL"
replace state="Georgia" if STATE=="GA"
replace state="Hawaii" if STATE=="HI"
replace state="Idaho" if STATE=="ID"
replace state="Illinois" if STATE=="IL"
replace state="Indiana" if STATE=="IN"
replace state="Iowa" if STATE=="IA"
replace state="Kansas" if STATE=="KS"
replace state="Kentucky" if STATE=="KY"
replace state="Louisiana" if STATE=="LA"
replace state="Maine" if STATE=="ME"
replace state="Maryland" if STATE=="MD"
replace state="Massachusetts" if STATE=="MA"
replace state="Michigan" if STATE=="MI"
replace state="Minnesota" if STATE=="MN"
replace state="Mississippi" if STATE=="MS"
replace state="Missouri" if STATE=="MO"
replace state="Montana" if STATE=="MT"
replace state="Nebraska" if STATE=="NE"
replace state="Nevada" if STATE=="NV"
replace state="New Hampshire" if STATE=="NH"
replace state="New Jersey" if STATE=="NJ"
replace state="New Mexico" if STATE=="NM"
replace state="New York" if STATE=="NY"
replace state="North Carolina" if STATE=="NC"
replace state="North Dakota" if STATE=="ND"
replace state="Ohio" if STATE=="OH"
replace state="Oklahoma" if STATE=="OK"
replace state="Oregon" if STATE=="OR"
replace state="Pennsylvania" if STATE=="PA"
replace state="Puerto Rico" if STATE=="PR"
replace state="Rhode Island" if STATE=="RI"
replace state="South Carolina" if STATE=="SC"
replace state="South Dakota" if STATE=="SD"
replace state="Tennessee" if STATE=="TN"
replace state="Texas" if STATE=="TX"
replace state="Utah" if STATE=="UT"
replace state="Vermont" if STATE=="VT"
replace state="Virginia" if STATE=="VA"
replace state="Virgin Islands" if STATE=="VI"
replace state="Washington" if STATE=="WA"
replace state="West Virginia" if STATE=="WV"
replace state="Wisconsin" if STATE=="WI"
replace state="Wyoming" if STATE=="WY"

rename state state_string
drop STATE
save "$processed/state_lat_lon_pairs.dta", replace
