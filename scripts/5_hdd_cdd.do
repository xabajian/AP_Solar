
/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
ACA



!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$

1/4/2023


!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$


*/


//set macros
global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/_Data_postAER/Raw"
global temp "$root/_Data_postAER/Temp"
global sters "$root/_Data_postAER/Sters"
global processed "$root/_Data_postAER/Processed"






/*

reading in CDD/HDD data

CDD

https://ftp.cpc.ncep.noaa.gov/htdocs/products/analysis_monitoring/cdus/degree_days/archives/Cooling%20Degree%20Days/monthly%20cooling%20degree%20days%20state/1998/dec%201998.txt

https://ftp.cpc.ncep.noaa.gov/htdocs/products/analysis_monitoring/cdus/degree_days/archives/Cooling%20Degree%20Days/monthly%20cooling%20degree%20days%20state/2010/Aug%202010.txt
HDD
https://ftp.cpc.ncep.noaa.gov/htdocs/products/analysis_monitoring/cdus/degree_days/archives/Heating%20degree%20Days/monthly%20states/2008/Apr%202008.txt



test
import delimited "https://ftp.cpc.ncep.noaa.gov/htdocs/products/analysis_monitoring/cdus/degree_days/archives/Cooling%20Degree%20Days/monthly%20cooling%20degree%20days%20state/1998/dec%201998.txt", rowrange(16:67) clear 

local heat_cool "hdd cdd"



*/



local monthlist "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
local yearlist "2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022"


foreach i of local yearlist {
	foreach j of local monthlist {
	
	local import_dummy = "https://ftp.cpc.ncep.noaa.gov/htdocs/products/analysis_monitoring/cdus/degree_days/archives/Cooling%20Degree%20Days/monthly%20cooling%20degree%20days%20state/" + "`i'" + "/" + "`j'" +"%20" + "`i'" + ".txt"
	import delimited "`import_dummy'", rowrange(16:67) clear 

		
		
	gen correc_spacing = subinstr(v1," ","",2)
	split correc_spacing
	keep correc_spacing1 correc_spacing2
	rename correc_spacing1 state
	rename correc_spacing2 CDDs
	
	
	gen year = `i'
	gen month = "`j'"
	//display "`import_dummy'"

	local save_dummy = "$raw/DegreeDays_data_NOAA/cdd_" + "`i'" + "_" + "`j'" 
	save "`save_dummy'.dta",replace
	
}
}


/*
Append


*/


clear

local monthlist "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
local yearlist "2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022"

foreach i of local yearlist {
	foreach j of local monthlist {
	
	local append_dummy = "$raw/DegreeDays_data_NOAA/cdd_" + "`i'" + "_" + "`j'" 

	append using  "`append_dummy'.dta"

}
}

drop if state=="REGION"
drop if year==.

save "$raw/DegreeDays_data_NOAA/full_cdd_panel.dta", replace



/*
repeat for HDDs
*/

local monthlist "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
local yearlist "2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022"



foreach i of local yearlist {
	foreach j of local monthlist {
	
	local import_dummy = "https://ftp.cpc.ncep.noaa.gov/htdocs/products/analysis_monitoring/cdus/degree_days/archives/Heating%20degree%20Days/monthly%20states/" + "`i'" + "/" + "`j'" +"%20" + "`i'" + ".txt"
	import delimited "`import_dummy'", rowrange(16:67) clear 

		
		
	gen correc_spacing = subinstr(v1," ","",2)
	split correc_spacing
	keep correc_spacing1 correc_spacing2
	rename correc_spacing1 state
	rename correc_spacing2 HDDs
	
	
	gen year = `i'
	gen month = "`j'"
	//display "`import_dummy'"

	local save_dummy = "$raw/DegreeDays_data_NOAA/hdd_" + "`i'" + "_" + "`j'" 
	save "`save_dummy'.dta",replace
	
}
}



/*
Append


*/


clear

local monthlist "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
local yearlist "2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022"

foreach i of local yearlist {
	foreach j of local monthlist {
	
	local append_dummy = "$raw/DegreeDays_data_NOAA/hdd_" + "`i'" + "_" + "`j'" 

	append using  "`append_dummy'.dta"


}
}

drop if state=="REGION"
drop if year==.

save "$raw/DegreeDays_data_NOAA/full_hdd_panel.dta", replace


clear



/*
merge
*/

use "$raw/DegreeDays_data_NOAA/full_hdd_panel.dta", clear
merge 1:1 year month state using "$raw/DegreeDays_data_NOAA/full_cdd_panel.dta"
drop _merge

//Fix months
rename month month_string
gen month = .
replace month=1 if month_string=="Jan"
replace month=2 if month_string=="Feb"
replace month=3 if month_string=="Mar"
replace month=4 if month_string=="Apr"
replace month=5 if month_string=="May"
replace month=6 if month_string=="Jun"
replace month=7 if month_string=="Jul"
replace month=8 if month_string=="Aug"
replace month=9 if month_string=="Sep"
replace month=10 if month_string=="Oct"
replace month=11 if month_string=="Nov"
replace month=12 if month_string=="Dec"


gen date_dummy = mdy(month, 1, year)
gen month_date = mofd(date_dummy)
format month_date %tm

//Fix state names
replace state="Alabama" if state =="ALABAMA"
replace state="Alaska" if state =="ALASKA"
replace state="Arizona" if state =="ARIZONA"
replace state="Arkansas" if state =="ARKANSAS"
replace state="California" if state =="CALIFORNIA"
replace state="Colorado" if state =="COLORADO"
replace state="Connecticut" if state =="CONNECTICUT"
replace state="Delaware" if state =="DELAWARE"
replace state="District of Columbia" if state =="DISTRCTCOLUMBIA"
replace state="Florida" if state =="FLORIDA"
replace state="Georgia" if state =="GEORGIA"
replace state="Hawaii" if state =="HAWAII"
replace state="Idaho" if state =="IDAHO"
replace state="Illinois" if state =="ILLINOIS"
replace state="Indiana" if state =="INDIANA"
replace state="Iowa" if state =="IOWA"
replace state="Kansas" if state =="KANSAS"
replace state="Kentucky" if state =="KENTUCKY"
replace state="Louisiana" if state =="LOUISIANA"
replace state="Maine" if state =="MAINE"
replace state="Maryland" if state =="MARYLAND"
replace state="Massachusetts" if state =="MASSACHUSETTS"
replace state="Michigan" if state =="MICHIGAN"
replace state="Minnesota" if state =="MINNESOTA"
replace state="Mississippi" if state =="MISSISSIPPI"
replace state="Missouri" if state =="MISSOURI"
replace state="Montana" if state =="MONTANA"
replace state="Nebraska" if state =="NEBRASKA"
replace state="Nevada" if state =="NEVADA"
replace state="New Hampshire" if state =="NEWHAMPSHIRE"
replace state="New Jersey" if state =="NEWJERSEY"
replace state="New Mexico" if state =="NEWMEXICO"
replace state="New York" if state =="NEWYORK"
replace state="North Carolina" if state =="NORTHCAROLINA"
replace state="North Dakota" if state =="NORTHDAKOTA"
replace state="Ohio" if state =="OHIO"
replace state="Oklahoma" if state =="OKLAHOMA"
replace state="Oregon" if state =="OREGON"
replace state="Pennsylvania" if state =="PENNSYLVANIA"
replace state="Rhode Island" if state =="RHODEISLAND"
replace state="South Carolina" if state =="SOUTHCAROLINA"
replace state="South Dakota" if state =="SOUTHDAKOTA"
replace state="Tennessee" if state =="TENNESSEE"
replace state="Texas" if state =="TEXAS"
replace state="Utah" if state =="UTAH"
replace state="Vermont" if state =="VERMONT"
replace state="Virginia" if state =="VIRGINIA"
replace state="Washington" if state =="WASHINGTON"
replace state="West Virginia" if state =="WESTVIRGINIA"
replace state="Wisconsin" if state =="WISCONSIN"
replace state="Wyoming" if state =="WYOMING"

drop year month_string month date_dummy


//state_bytes
gen state_byte=.
replace state_byte=1 if state=="Connecticut"
replace state_byte=2 if state=="Maine"
replace state_byte=3 if state=="Massachusetts"
replace state_byte=4 if state=="New Hampshire"
replace state_byte=5 if state=="Rhode Island"
replace state_byte=6 if state=="Vermont"
replace state_byte=7 if state=="New Jersey"
replace state_byte=8 if state=="New York"
replace state_byte=9 if state=="Pennsylvania"
replace state_byte=10 if state=="Illinois"
replace state_byte=11 if state=="Indiana"
replace state_byte=12 if state=="Michigan"
replace state_byte=13 if state=="Ohio"
replace state_byte=14 if state=="Wisconsin"
replace state_byte=15 if state=="Iowa"
replace state_byte=16 if state=="Kansas"
replace state_byte=17 if state=="Minnesota"
replace state_byte=18 if state=="Missouri"
replace state_byte=19 if state=="Nebraska"
replace state_byte=20 if state=="North Dakota"
replace state_byte=21 if state=="South Dakota"
replace state_byte=22 if state=="Delaware"
replace state_byte=23 if state=="District of Columbia"
replace state_byte=24 if state=="Florida"
replace state_byte=25 if state=="Georgia"
replace state_byte=26 if state=="Maryland"
replace state_byte=27 if state=="North Carolina"
replace state_byte=28 if state=="South Carolina"
replace state_byte=29 if state=="Virginia"
replace state_byte=30 if state=="West Virginia"
replace state_byte=31 if state=="Alabama"
replace state_byte=32 if state=="Kentucky"
replace state_byte=33 if state=="Mississippi"
replace state_byte=34 if state=="Tennessee"
replace state_byte=35 if state=="Arkansas"
replace state_byte=36 if state=="Louisiana"
replace state_byte=37 if state=="Oklahoma"
replace state_byte=38 if state=="Texas"
replace state_byte=39 if state=="Arizona"
replace state_byte=40 if state=="Colorado"
replace state_byte=41 if state=="Idaho"
replace state_byte=42 if state=="Montana"
replace state_byte=43 if state=="Nevada"
replace state_byte=44 if state=="New Mexico"
replace state_byte=45 if state=="Utah"
replace state_byte=46 if state=="Wyoming"
replace state_byte=47 if state=="California"
replace state_byte=48 if state=="Oregon"
replace state_byte=49 if state=="Washington"
replace state_byte=50 if state=="Alaska"
replace state_byte=51 if state=="Hawaii"

rename state state_string
rename state_byte state

//label
label define state_labels 1 "Connecticut"	2 "Maine"	3 "Massachusetts"	4 "New Hampshire"	5 "Rhode Island"	6 "Vermont"	7 "New Jersey"	8 "New York"	9 "Pennsylvania"	10 "Illinois"	11 "Indiana"	12 "Michigan"	13 "Ohio"	14 "Wisconsin"	15 "Iowa"	16 "Kansas"	17 "Minnesota"	18 "Missouri"	19 "Nebraska"	20 "North Dakota"	21 "South Dakota"	22 "Delaware"	23 "District of Columbia"	24 "Florida"	25 "Georgia"	26 "Maryland"	27 "North Carolina"	28 "South Carolina"	29 "Virginia"	30 "West Virginia"	31 "Alabama"	32 "Kentucky"	33 "Mississippi"	34 "Tennessee"	35 "Arkansas"	36 "Louisiana"	37 "Oklahoma"	38 "Texas"	39 "Arizona"	40 "Colorado"	41 "Idaho"	42 "Montana"	43 "Nevada"	44 "New Mexico"	45 "Utah"	46 "Wyoming"	47 "California"	48 "Oregon"	49 "Washington"	50 "Alaska"	51 "Hawaii"


label values state state_labels


save "$temp/NOAA_DD_panel.dta",  replace 
//$!@$#@!$#!@#$!#@$!@#$!@#$@
use "$temp/NOAA_DD_panel.dta",  clear

destring HDDs CDDs, force replace
generate year = 1960 + floor(month_date/12)
collapse (sum) HDDs CDDs, by(year state_string state)

gen STATE = ""
replace STATE = "AL" if state_string=="Alabama"
replace STATE = "AR" if state_string=="Arkansas"
replace STATE = "AZ" if state_string=="Arizona"
replace STATE = "CA" if state_string=="California"
replace STATE = "CT" if state_string=="Connecticut"
replace STATE = "DE" if state_string=="Delaware"
replace STATE = "FL" if state_string=="Florida"
replace STATE = "IL" if state_string=="Illinois"
replace STATE = "IN" if state_string=="Indiana"
replace STATE = "MA" if state_string=="Massachusetts"
replace STATE = "ME" if state_string=="Maine"
replace STATE = "MI" if state_string=="Michigan"
replace STATE = "MN" if state_string=="Minnesota"
replace STATE = "MO" if state_string=="Missouri"
replace STATE = "NH" if state_string=="New Hampshire"
replace STATE = "NJ" if state_string=="New Jersey"
replace STATE = "NV" if state_string=="Nevada"
replace STATE = "NY" if state_string=="New York"
replace STATE = "OR" if state_string=="Oregon"
replace STATE = "PA" if state_string=="Pennsylvania"
replace STATE = "TX" if state_string=="Texas"
replace STATE = "VT" if state_string=="Vermont"
replace STATE = "WA" if state_string=="Washington"
replace STATE = "WI" if state_string=="Wisconsin"

drop state state_string
keep if STATE!=""
save "$temp/NOAA_cdd_annual.dta",  replace 
