clear all


/*
!!@#$!@#$!@#$

The tracking the sun (TTS) data are sourced from lawrence berkley national laboratory. 

 The TTTS source: https://emp.lbl.gov/tracking-the-sun
 
 
These data are at the installation level and track capacity, cost, efficiency, and time of installation.
This script reads in these data and creates a list of county-level latitutde-longitude pairs to print out and use in the NREL API call.
The NREL API takes covered zips, takes them into counties,  calculates generation for a 1kW system, then maps this value back into this data set

!!@#$!@#$!@#$
*/
//set macros
global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/_Data_postAER/Raw"
global temp "$root/_Data_postAER/Temp"
global processed "$root/_Data_postAER/Processed"





/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 1: Read in the latest Tracking The Sun (TTS) data (from Glen Barbose at NREL) (covers 2018) and create an appended .dta.
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/


import delimited "$raw/tts_lbnl_public_data_file_10-dec-2019_0/TTS_LBNL_public_file_10-Dec-2019_p1.csv", clear
save "$temp/TTS_1_2023.dta", replace
import delimited "$raw/tts_lbnl_public_data_file_10-dec-2019_0/TTS_LBNL_public_file_10-Dec-2019_p2.csv", clear
save  "$temp/TTS_2_2023.dta", replace
clear

//combine using append
use  "$temp/TTS_1_2023.dta"
append using  "$temp/TTS_2_2023.dta", generate(_from_pt2) force
drop _from_pt2
save "$temp/TTS_raw_2023.dta", replace 
clear



/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 2: The TTS data are at the zip code level, we need to crosswalk/aggregate this into
data at the county level in order to merge into the HUD county-level shapefile.

The official XWalk from HUD can be found here: https://www.huduser.gov/portal/datasets/usps_crosswalk.html

This block merges in zipcodes and deals with entries lacking location data.
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/


use "$temp/TTS_raw_2023.dta", clear 


/*
Translate the excel date into stata time format
*/


generate date = date(installationdate, "MDY")
format date %td
gen year = yofd(date)
format year %ty
tab year
sort date



/*
Check share of residential systems
*/

count
//1,543,831

//restrict to residential systms
count if customersegment=="RES"
//  1,456,225
keep if customersegment=="RES"


/*
Check goegraphic coverages
*/

count if state == "-9999"
//0
tab	state
/*
No missing state entres in our observations! However only 24 + DC are convered.
*/

gen state_from_TTS = state
drop state
/*
Examine share of data that are missing important covariates, namely:



	1) dates for installation  and data provider?
	2) system size
	3) price or cost data--
	
	

*/


/*
Date
*/
count if installationdate == "-9999"
count if installationdate == ""
//0
count if dataprovider==""
count if dataprovider=="-9999"
//0

/*
Size
*/
count if systemsize==-9999
//0


/*
Prices
*/
count if totalinstalledprice==-9999
//335,063 

/*
 How much capacity are we missing prices for?
*/


total systemsize
scalar total_size=e(b)[1,1]

total systemsize if totalinstalledprice==-9999
scalar total_missing_price=e(b)[1,1]

display total_missing_price/total_size
//.24070445


/*
So roughly 24 percent of size-weighted capacity is missing a price of installation. However, from later we know some of these entries will get dropped 
*/




/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 2.1 -- zip code cleaning: After some examination there are a few zipcodes that were submitted with 5-4 format, and some submitted
without the preceding zero. 
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/


//check missing zips
count if zipcode == "-9999"
///82,059
gen missing_zip= (zipcode == "-9999")
//throw out completely unusable options



//Create harmonized byte version of zip codes
gen zipcopy = zipcode
gen zip5 = substr(zipcode,1,5)
replace zipcode=zip5 if strlen(zipcode)>5
//(26,897 real changes made)
replace zipcode="0"+ zipcode if strlen(zipcode)<5
//1 change made 
gen length_test = strlen(zipcode)
sum length_test
//great


/*
Merge in the zipcode to county crosswalk from the latest year.
*/

merge m:1 zipcode using "$processed/zip_county_xwalk.dta", gen(county_crosswalk)
/*
. merge m:1 zipcode using "$processed/zip_county_xwalk.dta", gen(county_crosswalk)

    Result                      Number of obs
    -----------------------------------------
    Not matched                       112,396
        from master                    83,051  (county_crosswalk==1)
        from using                     29,345  (county_crosswalk==2)

    Matched                         1,373,174  (county_crosswalk==3)
    -----------------------------------------

. 
end of do-file


*/
//One part is easy, we can drop all counties that are only present in the crosswalk
drop if county_crosswalk==2
//check cross presence
tab missing_zip county_crosswalk

/*

          | Matching result from
missing_zi |         merge
         p | Master on  Matched ( |     Total
-----------+----------------------+----------
         0 |       992  1,373,174 | 1,374,166 
         1 |    82,059          0 |    82,059 
-----------+----------------------+----------
     Total |    83,051  1,373,174 | 1,456,225 

. 
end of do-file



*/
count if missing_zip==0 & county_crosswalk==1
// 992

/*
OK, so some 992 observations are in zipcodes that aren't in the crosswalk. These are dropped now.


*/

drop if missing_zip==0 & county_crosswalk==1
//(992 observations deleted)


/*
Check for duplicate observations that are clerical errors (or other drivers). I believe it's safe to assume there shouldn't be purposeful duplicates on the same date with the same id from the same provider in the same state with the same list price.
*/


duplicates r dataprovider systemidtrackingthesun systemsize installationdate state totalinstalledprice zipcode rebateorgrant if missing_zip==0 

/*


--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |      1373174             0
--------------------------------------

. 

Great.

*/



save "$temp/TTS_int_2023_step21.dta", replace 





/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 2.2: Take stock of aggregate subsidies we can observe for footnote in section 4.2/4.3 as well as the appendix.
Do this for pre-2010 as well as for the entire sample period.
Note that this is retaining some of the missing zipcode counties still as ultimately for these statistics we just care about prices and time of installation.
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/

use "$temp/TTS_int_2023_step21.dta", clear 
count
//  1,455,233

//drop if I can't observe installed prices
count if totalinstalledprice!=-9999
keep if totalinstalledprice!=-9999

count
//1,120,307


total totalinstalledprice
scalar totalcost=e(b)[1,1]


total rebateorgrant if rebateorgrant!=-9999
scalar totalrebates=e(b)[1,1]

//generate pbi/fit transfers
gen pbi_value = performancebasedincentiveannualp * performancebasedincentivesdurati
gen fit_value = feedintariffannualpayment * feedintariffduration


//check total PBIs
total pbi_value if performancebasedincentiveannualp!=-9999 & performancebasedincentivesdurati!=-9999
scalar totalpbi=e(b)[1,1]
display totalpbi
//86869966

//total taxes
total salestaxcost if salestaxcost!=-9999 
scalar totaltaxes=e(b)[1,1]
display totaltaxes
//5.465e+08


total fit_value if fit_value!=-performancebasedincentiveannualp
scalar totalfit=e(b)[1,1]
display totalfit
//0 --- Wow, that's admittedly pretty wild.


scalar total_subsidies = (0.3 * totalcost + totalrebates +totalpbi + totalfit)
display total_subsidies
scalar total_subsidy_ratio = (0.3 * totalcost + totalrebates +totalpbi + totalfit)/(totalcost + salestaxcost)
display total_subsidy_ratio
//.3663105





//repeat for 2018


//check total PBIs
total pbi_value if performancebasedincentiveannualp!=-9999 & performancebasedincentivesdurati!=-9999 &  year==2018
scalar totalpbi=e(b)[1,1]
total salestaxcost if salestaxcost!=-9999 &  year==2018
scalar totaltaxes=e(b)[1,1]
total fit_value if fit_value!=-performancebasedincentiveannualp &  year==2018
scalar totalfit=e(b)[1,1]
total totalinstalledprice if year==2018
scalar totalcost=e(b)[1,1]
total rebateorgrant if rebateorgrant!=-9999 &  year==2018
scalar totalrebates=e(b)[1,1]
scalar total_subsidies_2018 = (0.3 * totalcost + totalrebates +totalpbi + totalfit)
display total_subsidies_2018
//1.654e+09



/*
Subsides over entire sample period comprise ~37% of total costs by my count.

Repeat exercise for pre 2010 period.
*/ 

//pre 2010
use "$temp/TTS_int_2023_step21.dta", clear 
drop if year>2009
count
//  117,831
count if totalinstalledprice!=-9999
keep if totalinstalledprice!=-9999
total totalinstalledprice
scalar totalcost=e(b)[1,1]
total rebateorgrant if rebateorgrant!=-9999
scalar totalrebates=e(b)[1,1]

//generate pbi/fit transfers
gen pbi_value = performancebasedincentiveannualp * performancebasedincentivesdurati
gen fit_value = feedintariffannualpayment * feedintariffduration
total pbi_value if performancebasedincentiveannualp!=-9999 & performancebasedincentivesdurati!=-9999
scalar totalpbi=e(b)[1,1]
total salestaxcost if salestaxcost!=-9999 
scalar totaltaxes=e(b)[1,1]
total fit_value if fit_value!=-performancebasedincentiveannualp
scalar totalfit=e(b)[1,1]

scalar total_subsidies = (0.3 * totalcost + totalrebates +totalpbi + totalfit)
display total_subsidies
//
scalar total_subsidy_ratio = (0.3 * totalcost + totalrebates +totalpbi + totalfit)/(totalcost + salestaxcost)
display total_subsidy_ratio
//.60277006


clear

/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 3: Figure out which entries, due to having no zipcode listed, will be not mapped into a county. Check whether the data with incomplete entries display systemic correlationor account for a large share of residential generation capacity
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/
use "$temp/TTS_int_2023_step21.dta", clear 
count
//1,455,233
count if missing_zip ==0 
//1,373,174
count if missing_zip ==0 & year!=-9999 & systemsize!=-9999
//  1,373,174

/*
Check how much residential generation is currently missing a county assignment
*/

//calculate missing
sum systemsize if county_byte==.
scalar missing_cap = r(mean) * r(N)

//calculate total
sum systemsize 
scalar total_cap = r(mean) * r(N) 
display missing_cap/total_cap
// .05237904

/*
For aggregate residential-scale generation, ~5.2 percent of total capacity cannot be attributed to a county... What about at the state level? 
*/

/*
Calculate shares of missing generation capacity by state
*/
gen flag_missing_county = (missing(county_byte))
generate size_x_flag = systemsize if  flag_missing_county==0
replace size_x_flag=0 if size_x_flag==.
bysort state_from_TTS: egen total_state_cap=total(systemsize)
bysort state_from_TTS: egen non_missing_state_cap=total(size_x_flag)
gen state_missing_county_share = 1 - non_missing_state_cap/total_state_cap
tab state_from_TTS, summarize(state_missing_county_share)



/*

tab state, summarize(state_missing_county_share)

              |             Summary of
state_from_ |     state_missing_county_share
        TTS |        Mean   Std. dev.       Freq.
------------+------------------------------------
         AR |   .00398001           0          91
         AZ |   .00010941           0     134,617
         CA |   .00233546           0     874,420
         CO |           1           0      44,524
         CT |           0           0      15,835
         DC |   .00078484           0       3,730
         DE |           0           0       2,275
         FL |   .00073028           0       2,661
         KS |           0           0         134
         MA |           0           0      85,258
         MD |           1           0      13,531
         MN |   .00032299           0       1,444
         MO |           0           0       4,719
         NH |   .00095777           0       5,153
         NJ |   .00004556           0      98,373
         NM |   .00922397           0      16,357
         NY |           0           0      83,271
         OH |           0           0       1,299
         OR |           0           0       3,925
         PA |   .00941672           0       6,361
         RI |           1           0         894
         TX |    .0002533           0      21,602
         UT |           1           0      20,412
         VT |           0           0      11,169
         WI |   .00016116           0       3,178
------------+------------------------------------
      Total |    .0561077   .22669694   1,455,233

. 

*/
	  
	  
drop size_x_flag total_state_cap  non_missing_state_cap  state_missing_county_share


/*
Noting here that Colorado, Maryland, Utah, and Rhode Island are the problem states. They don't have *any* zipcode listings at all.
*/
tab zipcode if state_from_TTS=="CO" | state_from_TTS=="MD" | state_from_TTS=="UT" | state_from_TTS=="RI" 


//repeating the above exercise:
//calculate missing
sum systemsize if county_byte==. & state!="CO" & state!="MD" & state!="UT" & state!="RI" 
scalar missing_cap = r(mean) * r(N)

//calculate total
sum systemsize if state!="CO" & state!="MD" & state!="UT" & state!="RI" 
scalar total_cap = r(mean) * r(N) 
display missing_cap/total_cap
// .00236854 -- Great!


/*
At this point, drop all installations where they cannot be mapped into a county.
*/
drop if county_byte==.
//(82,059 observations deleted)
save "$temp/TTS_int_2023_step3.dta", replace 

/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 4: Append the solar flux data from the deep solar data set at the county level. Drop excess covariates
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/



use "$temp/TTS_int_2023_step3.dta", clear 
count
//  1,373,174

//Check a few things for parameterizing the later API calls
sum tilt1  if tilt1!=-9999, d
sum azimuth1 if azimuth1!=-9999, d

/*
Tilt 20 and azumuth 180 seems reasonable.
*/


tab batterysystem
tab tracking
/*
Essentially no tracking or batteries 
*/


count
//1,373,174


//Merge in deepsolary county-level aggregates
destring county, gen(fips5)
merge m:1 fips5 using "$processed/DeepSolar_CountyData_2023.dta", gen(merge_flux)
/*

. merge m:1 fips5 using "$processed/DeepSolar_CountyData_2023.dta", gen(merge_flux)
(variable county was str5, now str27 to accommodate using data's values)

    Result                      Number of obs
    -----------------------------------------
    Not matched                         2,313
        from master                        48  (merge_flux==1)
        from using                      2,265  (merge_flux==2)

    Matched                         1,373,126  (merge_flux==3)
    -----------------------------------------

. 
end of do-file



*/
tab fips5 if merge_flux==1


/*
Note that FIPS prefix 15 is Hawaii. All of these 48 counties (those in my data but not in deep solar) are in Hawaii.
Entries are dropped accordingly
*/
drop if merge_flux!=3 
drop merge* 




//do a little housekeeping -- these could theoretically be controls later, but for now are not too helpful
drop customersegment county_crosswalk additionalmodulemodel azimuth2  azimuth3 bipvmodule2 bipvmodule3 invertermanufacturer2 invertermanufacturer3 invertermodel2 invertermodel3 microinverter2 microinverter3 moduleefficiency2 moduleefficiency3 modulemanufacturer2 modulemanufacturer3 modulemodel2 modulemodel3 moduletechnology2 moduletechnology3 tilt2 tilt3


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 4.1:


 Note finally there are counties which are coded wrong it terms of which state their zip code lies in.
 when comparing the zip codes and their true state (IE, those matched with the deep solar data) to the states listed in the TTS dataset there are inconsistencies.
 I drop these entries now.
 
 
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/


tab STATE if STATE!= state_from_TTS

/*

    STATE |      Freq.     Percent        Cum.
------------+-----------------------------------
         AL |          1        1.61        1.61
         AZ |          2        3.23        4.84
         CA |          7       11.29       16.13
         CO |          1        1.61       17.74
         CT |          1        1.61       19.35
         DE |          1        1.61       20.97
         FL |          1        1.61       22.58
         GA |          1        1.61       24.19
         ID |          1        1.61       25.81
         IL |          2        3.23       29.03
         IN |          1        1.61       30.65
         MA |          1        1.61       32.26
         MD |          2        3.23       35.48
         ME |          3        4.84       40.32
         MI |          1        1.61       41.94
         MO |          1        1.61       43.55
         NC |          1        1.61       45.16
         NJ |          2        3.23       48.39
         NM |          2        3.23       51.61
         NV |          7       11.29       62.90
         NY |          4        6.45       69.35
         OR |          3        4.84       74.19
         PA |          2        3.23       77.42
         TX |          5        8.06       85.48
         UT |          3        4.84       90.32
         VA |          2        3.23       93.55
         WA |          2        3.23       96.77
         WI |          2        3.23      100.00
------------+-----------------------------------
      Total |         62      100.00




*/
drop if  STATE!= state_from_TTS
//(62 observations deleted)


tab STATE
tab state_from_TTS

//Note deep solar gives static values of electricity consumption from 2015. These are superceded by the EIA data and should be droppedchaffe
drop  electricity_consume_residential electricity_price_residential  state STATE


/*
take stock of a few aggregates
*/
bysort county_byte: gen incounty_count = _n
count if incounty_count==1
//The set of unique zip codes maps into 804 unique counties

gen fips5_byte = fips5
save "$temp/TTS_int_2023_step4.dta", replace 






/*
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
Part 5: Use the NREL PV watts API to 

	(1) kick out set of counties where i need representative annual generations
	
	(2) Map them back in 

!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$

*/

use "$temp/TTS_int_2023_step4.dta", clear

//count covered states
 codebook state_from_TTS
//Kick out the covered counties
preserve
rename lat LAT
rename lon LON
collapse LAT LON, by(fips5)
count
//820
export delimited using "$processed/coordinates_for_NREL.csv", replace
restore


/*
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$

1/5/2021 - Merge in alternative generation that stems from the NREL API estimates

!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
*/

//straightforward 
merge m:1 fips5_byte using "$processed/NREL_gen_mid_eff_820.dta", gen(merge_NREL)
rename annual_gen annual_gen_mid_eff
tab  fips5_byte  if merge_NREL==1
keep if merge_NREL==3
drop merge_NREL
save "$temp/TTS_int_2023_part5.dta", replace 





/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$

Part 6: Generate Generation from my heuristic and the NREL api

!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/







use "$temp/TTS_int_2023_part5.dta", clear 



/*
First, we calculate the total level of annual solar generation for each system in the counties we have successful mappings for. Annual generation is :

		generation = panel area * efficiency * power

		= system size (kW) * 1 (kW/m^2) *(1/efficiency) * daily_flux (kWh/m2) *365.25 days per year * efficiency  

PV of 30 years' generation discounted at 3% with 1% degredation is 17.90277093 times initial flow value
	
		taken from https://pubs.rsc.org/en/content/articlepdf/2011/ee/c0ee00698j with defensible assumptions as
		some other LCOE estimates
		

*/


/*
Calculate annual generation for each system using formulas outlined above
*/
	
gen annual_generation = systemsize  * daily_solar_flux_fixed *365.25 
	//see above for details

	
	
/*
Calculate alternative annual generation for each system using NREL data--

Scale NREL estimates for a representative panel in each county by system sizes
*/
	
gen alt_gen_mid = annual_gen_mid_eff * systemsize
sum alt_gen_mid  annual_generation


/*
check system efficiencies to compare w/ my parameters used in the NREL API
*/
//replace missing entries
replace moduleefficiency1=. if  moduleefficiency1==-9999
sum moduleefficiency1, d

//replace negative efficiencies with median value of efficiency by year by state_missing_county_share
gen negative_efficiency_flag = (moduleefficiency1<0)
replace moduleefficiency1=. if moduleefficiency1<0
//(53 real changes made, 53 to missing)
bysort year state: egen state_year_median = median(moduleefficiency1)
bysort year: egen year_median_efficiency = median(moduleefficiency1)
replace moduleefficiency1=state_year_median if moduleefficiency1==1
//great


gen flag_missing_efficiency = (moduleefficiency1==.)
tab flag_missing_efficiency
//so we still have ~350,000 at some level missing efficiencies

//repeat above interpolation process for state then year levels
replace moduleefficiency1 = state_year_median if moduleefficiency1==.
replace moduleefficiency1 = year_median_efficiency if moduleefficiency1==.




/*
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$

 Part 5.1: compare the two estimates (our own heuristic above vs. the API) as referenced in part B of the appendix

!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
*/


//check appropriate efficiency to use
gen floor = floor(systemsize)
sum moduleefficiency1 , d
sum moduleefficiency1 [fweight = floor], d
//closer to the mid-efficiency


twoway (kdensity alt_gen_mid  if alt_gen_mid <= 40000) ( kdensity annual_generation  if alt_gen_mid <= 40000) , ///
xtitle("Annual Generation, kWh") legend(order(1 "NREL API" 2 "Heuristic")) title("Kernel Density of Estimates for System-" "level Annual Generation")
graph export "$processed/NREL_v_heuristic_kdensity.png", replace

codebook 

//correlation in appendix
reg annual_generation alt_gen_mid, r
corr annual_generation alt_gen_mid
	
save "$temp/TTS_int_2023_part6.dta", replace


/*
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$

Part 6.2:  Generate quantity generated panel for county-year level

!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
*/



use "$temp/TTS_int_2023_part6.dta", clear
count
//   1,373,064
tab thirdpartyowned


//drop the states that I ultimately have zero coverage of due to pricing
drop if state_from_TTS=="DC" |  state_from_TTS=="KS" |  state_from_TTS=="MO" |   state_from_TTS=="NM" |  state_from_TTS=="OH" 
//(26,077 observations deleted)


count if systemsize>100
drop if systemsize>100
//(400 observations deleted)

//too small
count if systemsize < 0.5
drop if systemsize < 0.5
//(567 observations deleted)

codebook state_from_TTS county_byte
count 
//   1,346,020



gen system_mean_for_quantities = systemsize
gen system_total_for_quantities= systemsize


/*
//OK, generate the county-year aggregates weighting prices each year by system-size
*/



//make aggregates
collapse (mean) system_mean_for_quantities (sum) system_total_for_quantities alt_gen_mid, by(year county_byte state_from_TTS)


//fill gaps and drop if generation is zero
xtset county_byte year
tsfill, full
replace alt_gen_mid =0 if alt_gen_mid==.

//generate annual and cumulative generation in each county 
rename alt_gen_mid new_cap_annual_generation
label var new_cap_annual_generation "Annual generation by panel installed in c-t, kWh"

label var system_mean_for_quantities "mean system wattage used to calculate quantities in given county-year, kW"
label var system_total_for_quantities "total system wattage used to calculate quantities in given year, kW"




//cumulative
sort county_byte year
bysort county_byte: gen cumulative_annual_gen = sum(new_cap_annual_generation)
label var cumulative_annual_gen "Annual generation by all installations in c-t, kWh"
drop if cumulative_annual_gen==0

codebook state_from_TTS county_byte
//630 unique counties

sum year, d


save "$processed/TTS_county_annual_gen.dta", replace
use "$processed/TTS_county_annual_gen.dta",clear 
/*
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$

Part 7:  Calculate LCOE Data :  Now, we can calculate prices (using the  LCOE measure) at the county level. We will have to ignore entries that display a system size but are missing prices, but ultimately use average prices at the county level


!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
*/
	
use "$temp/TTS_int_2023_part6.dta", clear


/*
Flag entries missing prices
*/

gen flag_missing_prices = (totalinstalledprice==-9999  | rebateorgrant==-9999 | salestaxcost==-9999 | feedintariffannualpayment==-9999 |performancebasedincentiveannualp==-9999)


	replace totalinstalledprice = . if totalinstalledprice==-9999
	replace rebateorgrant = . if rebateorgrant==-9999
	replace salestaxcost = . if salestaxcost==-9999
	replace performancebasedincentiveannualp = . if performancebasedincentiveannualp==-9999
	replace feedintariffannualpayment = . if feedintariffannualpayment==-9999

	
count if flag_missing_prices==1
//  351,701
tab flag_missing_prices, sum(systemsize)


/*
A lot of capacity is missing prices, just as module efficiency was missing before. I will perform an analagous exerciseto calculate the share of capacity missing installation prices.
*/


capture {
drop size_x_flag
}
generate size_x_flag = systemsize if  flag_missing_prices==0
//(351,701 missing values generated)

replace size_x_flag=0 if size_x_flag==.
//(351,717 missing values generated)
bysort state_from_TTS: egen total_state_cap=total(systemsize)
bysort state_from_TTS: egen state_nomissing_prices_total=total(size_x_flag) 
gen state_missing_prices_share = 1- state_nomissing_prices_total/total_state_cap
tab state_from_TTS, sum(state_missing_prices_share)
drop  size_x_flag
//


/*
Noting that these shares of data that lack prices can be very high in some states. Ohio, New Mexico, Montana, Kansas and DC have 100% missing price shares. As such, these observations are dropped. 

Note NJ and Vermont are also very bad
*/
drop if state_missing_prices_share==1
tab state_from_TTS

/*

        TTS |      Freq.     Percent        Cum.
------------+-----------------------------------
         AR |         90        0.01        0.01
         AZ |    134,585        9.99       10.00
         CA |    871,865       64.73       74.73
         CT |     15,834        1.18       75.90
         DE |      2,274        0.17       76.07
         FL |      2,645        0.20       76.27
         MA |     85,258        6.33       82.60
         MN |      1,443        0.11       82.70
         NH |      5,139        0.38       83.08
         NJ |     98,359        7.30       90.39
         NY |     83,271        6.18       96.57
         OR |      3,925        0.29       96.86
         PA |      6,358        0.47       97.33
         TX |     21,595        1.60       98.93
         VT |     11,169        0.83       99.76
         WI |      3,177        0.24      100.00
------------+-----------------------------------
      Total |  1,346,987      100.00



*/


/*

Now, we calculate LCOEs. The formulas are in the appendix, formula B.1. We are given the year-1 flow values of the feed-in tariff and PBI payments as well as the duration. Treating these as annuities we have that for a finite geo series,

	\sum_0 ^n-1 (ar^k) = a (1-r^n) / (1-r)
		
r_depreciation =(1-DR) x 1/(1+r) = 0.99/1.03 = 0.961165049

alternative rate -- 

r_maintenance = x (1/1+r) = 0.0097087378640776699029126213592233009708737864077669902912621359
The long numbers in the numerator and denominator are the NPV values for unit genegeneration and fixed costs respectively.


*/
gen NPV_PBI = performancebasedincentiveannualp * (1 - 0.961165049^(performancebasedincentivesdurati+1))/(1 - 0.961165049)
gen NPV_FIT = feedintariffannualpayment* (1 - 0.961165049^(feedintariffduration+1))/(1 - 0.961165049)
gen lifecycle_FIT = NPV_FIT/(annual_generation*17.90277093 )
gen lifecycl_PBI = NPV_PBI/(annual_generation*17.90277093 )

//gen LCOE for all local subsidies, no ITC
gen LCOE_all_subs = ((1+ 0.20188)* totalinstalledprice + salestaxcost -rebateorgrant - NPV_PBI - NPV_FIT)  / (annual_generation*17.90277093 )


//gen LCOE for all local subsidies and assume full ITC uptake
gen post_2005_dummy = (year>2005)
gen pre_2005_dummy = (post_2005_dummy==0)
gen LCOE_all_subs_ITC = ((0.7*post_2005_dummy+ pre_2005_dummy + 0.20188)* totalinstalledprice + salestaxcost -rebateorgrant - NPV_PBI - NPV_FIT)  / (annual_generation*17.90277093 )

//gen gross cost with no subsidies
gen LCOE_gross_cost = ((1+ 0.20188)* totalinstalledprice + salestaxcost) / (annual_generation*17.90277093 )



sum LCOE_gross_cost LCOE_all_subs_ITC LCOE_all_subs, d
sum LCOE_gross_cost LCOE_all_subs_ITC LCOE_all_subs


 
/*
 The following command drops some outliers that have exceptionally large leverage and  that (almost) certainly stem from clerical errors.  First, drop all systems larger than 100. This is well above the 99th percentile and more than 2 stdevs beyond the mean on the RHS. Next, I drop some systems that are unreasonable small -- there are 700 systems under 1/2 a Watt.  These are unlikely to be true residential SPV systems in the sense of providing a meaningful amount of power
*/

//too large
sum systemsize, d
count if systemsize>100
drop if systemsize>100
//(400 observations deleted)

//too small
count if systemsize < 0.5
drop if systemsize < 0.5
//(567 observations deleted)

count
//   1,346,020


/*
Second, we drop all systems with negative system prices pre-rebates. It's almost impossible that a system was installed at a negative price before
subsidies. Thanksfully this amount is zero.
*/

count if LCOE_gross_cost<0
drop if LCOE_gross_cost<0

/*
Third, we need to trip some of the unreasonably expensive systems. The largest have prices of $25,000 which is insanely high
*/
sum LCOE_gross_cost, d
sum LCOE_gross_cost if LCOE_gross_cost<100, d
count if LCOE_gross_cost>20 & LCOE_gross_cost!=.
count if LCOE_gross_cost>10 & LCOE_gross_cost!=.
count if LCOE_gross_cost>1 & LCOE_gross_cost!=.
count if LCOE_gross_cost!=.

/*
Well over 99% of systems have LCOEs under $1. As such, executive decision to trim LCOE's to have a ceiling of $1 gross. Per below, this drops 595 (<<<<1% of observations)
*/

count if LCOE_gross_cost>1 & LCOE_gross_cost!=.
//547
drop if  LCOE_gross_cost>1 & LCOE_gross_cost!=.
//(547 observations deleted)



/*
Now, drop all missing entres in the sense of those with insufficient pricing data
*/

drop if LCOE_gross_cost==.
//(310,125 observations deleted)


drop incounty_count
bysort county_byte: gen incounty_count = _n
count if incounty_count==1
//  629 counties left.
drop incounty_count 
gen ppw = (totalinstalledprice*0.7 - rebateorgrant +salestaxcost )/systemsize
gen ppw_nosubs = (totalinstalledprice +salestaxcost )/systemsize


tab year [aw = systemsize], sum(ppw)
tab year [aw = systemsize], sum(ppw_nosubs)



save "$temp/TTS_county_annual_prices.dta", replace







/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$

Part 6: Merge in electricity data.
This allows for the figures of the time series of price gaps over time
as well as the distribution of the dispersion in markups

!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/




use  "$temp/TTS_county_annual_prices.dta", clear 


//many to one merge of annual electricity prices in each county
merge m:1 year county_byte using "$processed/EIA_power_county_panel.dta", gen(merge_electricity_prices)
/*

    Result                      Number of obs
    -----------------------------------------
    Not matched                        54,253
        from master                       149  (merge_electricity_prices==1)
        from using                     54,104  (merge_electricity_prices==2)

    Matched                         1,035,199  (merge_electricity_prices==3)
    -----------------------------------------

. 
end of do-file

*/
//pretty good.
keep if merge_electricity_prices==3




//Sum stuff of interest
sum electricity_price_residential LCOE_all_subs LCOE_all_subs_ITC LCOE_gross_cost
gen price_gap_itc = LCOE_all_subs_ITC - electricity_price_residential
count 
scalar count = r(N)
count if price_gap_itc>0
scalar count_positive = r(N)
display count_positive/count
//.17293293




gen price_gap_noitc =  LCOE_all_subs - electricity_price_residential
gen price_gap_raw = LCOE_gross_cost - electricity_price_residential

gen gap_itc_10 = price_gap_itc
gen gap_itc_90 = price_gap_itc

gen gap_itc_50 = price_gap_itc
gen gap_nosubs_50 = price_gap_raw

gen gap_nosubs_10 = price_gap_raw
gen gap_nosubs_90 = price_gap_raw



//nice figure of time kdensities

twoway kdensity price_gap_itc if price_gap_raw<= 0.3 & price_gap_itc>= -0.3, lcolor(blue) lwidth(thick) legend(label(1 "Full Subsidy Uptake")) || ///
kdensity price_gap_noitc if price_gap_raw<= 0.3 & price_gap_itc>= -0.3, color(orange) lwidth(thick) legend(label(2 "No ITC Uptake") region(lcolor(none))) ||  ///
kdensity price_gap_raw if price_gap_raw<= 0.3 & price_gap_itc>= -0.3, color(red) lwidth(thick) legend(label(3 "No Subsidy Uptake") region(lcolor(none)))  ///
xtitle("Solar vs. Grid Price Differential ($/kWh)") ///
ytitle("kernel density") note("Note: Each density denotes the price difference at the system level between the LCOE we estimate and the" "per kilowatt hour grid electricity price in that county. The dashed grey line indicates the breakeven point.") title("Density of County Level Rooftop Solar" "and Grid Electricity Price Differentials") ///
xline(0, lpattern(dash) lcolor(gray))
graph export "$processed/marukps_kdensity.png", as(png)   replace


preserve

/*
//collapse over years to get time series with quantile intervals, all systems
*/
collapse (p10) gap_itc_10 gap_nosubs_10  (p90) gap_itc_90 gap_nosubs_90 (p50) gap_itc_50 gap_nosubs_50 (mean) price_gap_itc price_gap_raw, by(year)



//nice Figure of time series
twoway  (rarea gap_itc_10 gap_itc_90 year, fcolor(blue%15) color(white%0)  ) (rarea gap_nosubs_10 gap_nosubs_90 year, fcolor(red%15) lcolor(white%0)   ) ///
(line gap_itc_50 year, lcolor(blue) lwidth(    medthick ) ) (line gap_nosubs_50 year, lcolor(red) lwidth(    medthick ) ), ///
ytitle("Solar vs. Grid Price Differential ($/kWh)") xtitle("Year") xlabel( 2000(4)2020  ) ///
 note("Note: Solid lines denote the annual median difference at the system level between the LCOE we estimate" "and the grid electricity price ($/kwh) in that county. The dashed grey line indicates the breakeven" "point where the prices are equal. Shaded regions denote the 10% and 90% percentiles in each year.") ///
legend(order(3 "Full Subsidy Uptake" 4 "No Subsidy Uptake") region(lcolor(none)) ) ///
title("Median Annual County-Level Rooftop Solar" "and Grid Electricity Price Differentials") ///
yline(0, lpattern(dash) lcolor(gray%50))
graph export "$processed/marukps_TS.png", as(png)   replace


restore

/*
repeat firgue 3 exercise for TPO systems only
*/

tab thirdpartyowned

/*

Third-Party |
      Owned |      Freq.     Percent        Cum.
------------+-----------------------------------
      -9999 |     58,539        5.65        5.65
          0 |    549,716       53.10       58.76
          1 |    426,944       41.24      100.00
------------+-----------------------------------
      Total |  1,035,199      100.00
*/

 keep if thirdpartyowned==1
 
 collapse (p10) gap_itc_10 gap_nosubs_10  (p90) gap_itc_90 gap_nosubs_90 (p50) gap_itc_50 gap_nosubs_50 (mean) price_gap_itc price_gap_raw, by(year)

 twoway  (rarea gap_itc_10 gap_itc_90 year, fcolor(blue%15) color(white%0)  ) (rarea gap_nosubs_10 gap_nosubs_90 year, fcolor(red%15) lcolor(white%0)   ) ///
(line gap_itc_50 year, lcolor(blue) lwidth(    medthick ) ) (line gap_nosubs_50 year, lcolor(red) lwidth(    medthick ) ), ///
ytitle("Solar vs. Grid Price Differential ($/kWh)") xtitle("Year") xlabel( 2000(4)2020  ) ///
 note("Note: Solid lines denote the annual median difference at the system level between the LCOE we estimate for each" "third-party owned system and the grid electricity price ($/kwh) in that county. The dashed grey line indicates the" " breakeven point where the prices are equal. Shaded regions denote the 10th and 90th percentiles in each year.") ///
legend(pos(2) ring(0) order(3 "Full Subsidy Uptake" 4 "No Subsidy Uptake") region(lcolor(none)) ) ///
title("Median County-Level Third-Party Owned Solar PV " "and Grid Electricity Price Differentials, 2000-2018") ///
yline(0, lpattern(dash) lcolor(gray%50))
graph export "$processed/marukps_TS_TPOonly.png", as(png)   replace
 
 
 
/*
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$


Part 8:

			1- generate a panel of average price paid per generation of solar electricity in a given county each year
			
			2 -  Merge in income and electricity data for estimation.

!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$!!@#$!@#$!@#$
*/


use  "$temp/TTS_county_annual_prices.dta", clear

//unique entry counts
codebook year county_byte
codebook year county_byte if LCOE_all_subs!=.
//         Unique values: 615


//clean house
keep systemsize COUNTYNAME HH_share LCOE_all_subs LCOE_all_subs_ITC LCOE_gross_cost state_from_TTS county_byte air_temperature atmospheric_pressure cooling_degree_days cooling_design_temperature daily_solar_flux_fixed earth_temperature elevation earth_temperature_amplitude frost_days heating_degree_days heating_design_temperature land_area lat lon newconstruction relative_humidity selfinstalled wind_speed voting_2016_gop_percentage  fips5_byte  housing_unit_median_gross_rent housing_unit_median_value  mortgage_with_rate population_density thirdpartyowned utilityserviceterritory voting_2016_gop_percentage  year  gini_index heating_degree_days cooling_degree_days race_white_rate race_black_africa_rate education_less_than_high_school_ average_household_income population_density lat mortgage_with_rate voting_2016_gop_percentage diversity land_area housing_unit_median_value	housing_unit_median_gross_rent	lat	lon	elevation	heating_design_temperature	cooling_design_temperature	earth_temperature_amplitude	frost_days	air_temperature	relative_humidity	atmospheric_pressure	wind_speed	earth_temperature



/*
//OK, generate the county-year aggregates weighting prices each year by system-size
*/

gen system_mean_for_prices= systemsize
gen system_total_for_prices= systemsize


/*
//OK, generate the county-year aggregates weighting prices each year by system-size
*/

collapse (rawsum) system_total_for_prices (mean)   system_mean_for_prices HH_share LCOE_all_subs LCOE_all_subs_ITC LCOE_gross_cost  air_temperature atmospheric_pressure cooling_degree_days  daily_solar_flux_fixed earth_temperature elevation earth_temperature_amplitude frost_days heating_degree_days heating_design_temperature cooling_design_temperature land_area newconstruction relative_humidity selfinstalled wind_speed voting_2016_gop_percentage   housing_unit_median_gross_rent housing_unit_median_value  mortgage_with_rate population_density thirdpartyowned gini_index  race_white_rate race_black_africa_rate education_less_than_high_school_ average_household_income        diversity	lat	lon [aw = systemsize], by(state_from_TTS  COUNTYNAME county_byte year)

label var system_mean_for_prices "mean system wattage used to calculate prices in given county-year, kW"
label var system_total_for_prices "total system wattage used to calculate prices in given year, kW"



duplicates r year county_byte
//good


 
/*
Fill in panel with covariates
*/


xtset county_byte year
tsfill, full

/*
Replace things that are time-invariant
*/

sort county_byte year

 //do a bunch of times
 forvalues i = 1/100{
 	
	
	//STATE
 	 by county_byte (year), sort: replace state_from_TTS = state_from_TTS[_n-1] if state_from_TTS==""
	 by county_byte (year), sort: replace state_from_TTS = state_from_TTS[_n+1] if state_from_TTS==""
 	
	//COUNTYNAME names of counties
 	 by county_byte (year), sort: replace COUNTYNAME = COUNTYNAME[_n-1] if COUNTYNAME==""
	 by county_byte (year), sort: replace COUNTYNAME = COUNTYNAME[_n+1] if COUNTYNAME==""
 	
	//lat
	replace lat = L.lat if lat==. & `i'>20
	replace lat = F.lat if lat==.
	
	//lon
	replace lon = L.lon if lon==. & `i'>20
	replace lon = F.lon if lon==.
	 
	  
	  
	 	//air_temperature
	replace air_temperature = L.air_temperature if air_temperature==. & `i'>20
	replace air_temperature = F.air_temperature if air_temperature==.
	 
	 
	 	//land_area
	replace land_area = L.land_area if land_area==. & `i'>20
	replace land_area = F.land_area if land_area==.
	 
	 
	 	//earth_temperature
	replace earth_temperature = L.earth_temperature if earth_temperature==. & `i'>20
	replace earth_temperature = F.earth_temperature if earth_temperature==.
	 
	 	 
	  
	 
	 	//daily_solar_flux_fixed
	replace daily_solar_flux_fixed = L.daily_solar_flux_fixed if daily_solar_flux_fixed==. & `i'>20
	replace daily_solar_flux_fixed = F.daily_solar_flux_fixed if daily_solar_flux_fixed==.
	 
	 	 
		 
		// cooling_degree_days
	replace cooling_degree_days = L.cooling_degree_days if cooling_degree_days==. & `i'>20
	replace cooling_degree_days = F.cooling_degree_days if cooling_degree_days==.
	 
	 	 
		 //cooling_design_temperature
	replace cooling_design_temperature = L.cooling_design_temperature if cooling_design_temperature==. & `i'>20
	replace cooling_design_temperature = F.cooling_design_temperature if cooling_design_temperature==.
	 
	 	 
		  // elevation 
	replace elevation = L.elevation if elevation==. & `i'>20
	replace elevation = F.elevation if elevation==.
	 
	 	// earth_temperature_amplitude 
	replace earth_temperature_amplitude = L.earth_temperature_amplitude if earth_temperature_amplitude==. & `i'>20
	replace earth_temperature_amplitude = F.earth_temperature_amplitude if earth_temperature_amplitude==.

		   
	// atmospheric_pressure 
	replace atmospheric_pressure = L.atmospheric_pressure if atmospheric_pressure==. & `i'>20
	replace atmospheric_pressure = F.atmospheric_pressure if atmospheric_pressure==.

		   
		  // frost_days 
	replace frost_days = L.frost_days if frost_days==.
	replace frost_days = F.frost_days if frost_days==.
	
		  // heating_degree_days 
	replace heating_degree_days = L.heating_degree_days if heating_degree_days==. & `i'>20
	replace heating_degree_days = F.heating_degree_days if heating_degree_days==.

		  // heating_design_temperature 
	replace heating_design_temperature = L.heating_design_temperature if heating_design_temperature==. & `i'>20
	replace heating_design_temperature = F.heating_design_temperature if heating_design_temperature==.

		
		
	// relative_humidity 
		replace relative_humidity = L.relative_humidity if relative_humidity==. & `i'>20
		replace relative_humidity = F.relative_humidity if relative_humidity==.
		
	// wind_speed 
		replace wind_speed = L.wind_speed if wind_speed==. & `i'>20
		replace wind_speed = F.wind_speed if wind_speed==.
	 	   
		   
		   		
	// voting_2016_gop_percentage 
		replace voting_2016_gop_percentage = L.voting_2016_gop_percentage if voting_2016_gop_percentage==. & `i'>20
		replace voting_2016_gop_percentage = F.voting_2016_gop_percentage if voting_2016_gop_percentage==.
	 	   
		   
		   		
	// housing_unit_median_gross_rent 
		replace housing_unit_median_gross_rent = L.housing_unit_median_gross_rent if housing_unit_median_gross_rent==. & `i'>20
		replace housing_unit_median_gross_rent = F.housing_unit_median_gross_rent if housing_unit_median_gross_rent==.
	 	   
		   
		   		   		
	// housing_unit_median_value 
		replace housing_unit_median_value = L.housing_unit_median_value if housing_unit_median_value==. & `i'>20
		replace housing_unit_median_value = F.housing_unit_median_value if housing_unit_median_value==.
	 	   
		   
		   		   		
	// mortgage_with_rate 
		replace mortgage_with_rate = L.mortgage_with_rate if mortgage_with_rate==. & `i'>20
		replace mortgage_with_rate = F.mortgage_with_rate if mortgage_with_rate==.
	 	   
		   
		   		   		
	// population_density 
		replace population_density = L.population_density if population_density==. & `i'>20
		replace population_density = F.population_density if population_density==.
	 	   
		   
	// diversity 
		replace diversity = L.diversity if diversity==. & `i'>20
		replace diversity = F.diversity if diversity==.
	 	   
	// average_household_income 
		replace average_household_income = L.average_household_income if average_household_income==. & `i'>20
		replace average_household_income = F.average_household_income if average_household_income==.
	 	   
		   
	// education_less_than_high_school_ 
		replace education_less_than_high_school_ = L.education_less_than_high_school_ if education_less_than_high_school_==. & `i'>20
		replace education_less_than_high_school_ = F.education_less_than_high_school_ if education_less_than_high_school_==.

		
			   
	// gini_index 
		replace gini_index = L.gini_index if gini_index==. & `i'>20
		replace gini_index = F.gini_index if gini_index==.
	 	   
		  	   
				               										

	// race_white_rate  
		replace race_white_rate = L.race_white_rate if race_white_rate==. & `i'>20
		replace race_white_rate = F.race_white_rate if race_white_rate==.
	 	   
		  	   
	// race_black_africa_rate 
		replace race_black_africa_rate = L.race_black_africa_rate if race_black_africa_rate==. & `i'>20
		replace race_black_africa_rate = F.race_black_africa_rate if race_black_africa_rate==.
	 	   
		  	   
				               										   
		   
		                
 
 
 }
 
 
 
/*
Merge in cumulative generation and capacity each year
note this 
*/


merge 1:1 year county_byte using "$processed/TTS_county_annual_gen.dta", gen(merge_quantities) 
keep if merge_quantities==3
drop merge_quantities


/*
Generate weighted-average prices each year

 (1) calculate in-sample cumulative capacity 
 (2) use this as weights for prices each year

*/


//cumulative capacity
gen c_capacity_prices = system_total_for_prices
replace c_capacity_prices=0 if c_capacity_prices==.
by county_byte (year), sort: replace c_capacity_prices = sum(c_capacity_prices)
//sanity
count if c_capacity_prices < c_capacity_prices[_n-1] & county_byte==county_byte[_n-1]
//great
lab var c_capacity_prices "cumulative installed capacity used for price weights"


//annual moments
gen weighted_price_numerator = LCOE_all_subs_ITC*system_total_for_prices
label var weighted_price_numerator "product of all installation prices and their relative size each year each county" 

//divide the sum of weighted price terms by cumulative capacity
gen p_solar =  0
by county_byte (year), sort: replace p_solar = sum(weighted_price_numerator)/c_capacity
sum p_solar LCOE_all_subs_ITC, d



/*
//many to one merge of annual electricity Ps and Qs in each county
*/
merge m:1 year county_byte using "$processed/EIA_power_county_panel.dta", gen(merge_electricity_prices)
keep if merge_electricity_prices==3

/*
. merge m:1 year county_byte using "$processed/EIA_power_county_panel.dta", gen(merge_electricity_prices)

    Result                      Number of obs
    -----------------------------------------
    Not matched                        51,343
        from master                        37  (merge_electricity_prices==1)
        from using                     51,306  (merge_electricity_prices==2)

    Matched                             7,610  (merge_electricity_prices==3)
    -----------------------------------------

. 


*/


//codebook
 codebook year county_byte
//Unique values: 626
count
//  7,610
/*
//Income and household counts
*/


merge m:1 year county_byte using "$processed/ACS_income_panel.dta", gen(merge_income) 
keep if merge_income==3

/*

. merge m:1 year county_byte using "$processed/ACS_income_panel.dta", gen(merge_income) 

    Result                      Number of obs
    -----------------------------------------
    Not matched                        25,875
        from master                     2,257  (merge_income==1)
        from using                     23,618  (merge_income==2)

    Matched                             5,353  (merge_income==3)
    -----------------------------------------

. keep if merge_income==3
(25,875 observations deleted)


*/

keep if merge_electricity_prices==3 & merge_income==3



//average generation among all customers is total generation over customers
gen c_solar = cumulative_annual_gen
replace c_solar = c_solar/household_count
label var c_solar "Average HH solar consumption in county-year, kwh"

//generate select new variables with more convenient names
gen p_grid = electricity_price_residential
gen c_grid = electricity_consume_residential
gen c_elec = electricity_consume_residential + c_solar
gen solar_elec_ratio =    c_solar /c_elec
gen solar_grid_ratio = c_solar/c_grid

//label
label var c_solar "Average HH solar consumption in county-year, kwh"
label var c_grid "Average HH grid consumption in county-year, kwh"
label var p_solar "Average residential solar price, $/kwh"
label var p_grid "Average residential grid price, $/kwh"

sum c_solar c_grid p_solar p_grid solar_elec_ratio solar_grid_ratio 
/*
. sum c_solar c_grid p_solar p_grid solar_elec_ratio solar_grid_ratio 

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
     c_solar |      5,353    63.82255    171.4397   .0589737   1827.028
      c_grid |      5,353    10263.63    3024.234   4488.054   19632.39
     p_solar |      5,340    .1386829    .0758334  -.4600879   .8088884
      p_grid |      5,353    .1318989    .0310735   .0774494     .28849
solar_elec~o |      5,353    .0082663    .0229328   4.20e-06   .2387007
-------------+---------------------------------------------------------
solar_grid~o |      5,353    .0089446    .0264169   4.20e-06   .3135438

. 
end of do-file

*/






//check a few aggregates
total household_count if year==2018

drop merge*
save "$processed/estimating_sample.dta", replace
clear



