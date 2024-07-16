clear all


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
ACA


1/31/2023

External validation procedure: Take state-level prices as given from LBNL data and solve for generation shares in each county. Compare these shares to the share observed using the deepsolar dataset.


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
$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@
Part 1: Create a county level TTS dataset for prices
$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@
*/

//start with the full TTS dataset
use "$temp/TTS_raw_2023.dta", clear


//generate year variable
gen date = date(installationdate, "MDY") 
format date %td
gen year = yofd(date)



/*
Merge in counties by zipcode crosswalk
using the same fix as done in the main file
*/
gen zip5 = substr(zipcode,1,5)
replace zipcode=zip5 if strlen(zipcode)>5
replace zipcode="0"+ zipcode if strlen(zipcode)<5
gen length_test = strlen(zipcode)
sum length_test


merge m:1 zipcode using "$processed/zip_county_xwalk.dta", gen(merge_zip)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                       119,507
        from master                    91,689  (merge_zip==1)
        from using                     27,818  (merge_zip==2)

    Matched                         1,452,142  (merge_zip==3)
    -----------------------------------------

*/


drop if merge_zip==2
//(39,193 observations deleted)
gen missing_zip= (zipcode == "-9999")

//repeat checks on missing zips
destring zipcode, gen(zip_byte) force
tab missing_zip merge_zip


//keep residential observations
keep if customersegment=="RES"


/*
calculate and merge in county-level LCOE values

This reads in system-size weighted averages LCOEs for all residential systems in each county
*/

preserve
do "$root/_Scripts_postAER/3_LCOE_Calculations.do"
save "$temp/lbnl_avg_LCOE.dta", replace
restore


merge m:1 county_byte using "$temp/lbnl_avg_LCOE.dta", gen(covered_LCOEs)

gen state_byte = floor(county_byte/1000)


collapse covered_LCOE LCOE_all_subs_ITC LCOE_gross_cost, by(state_byte county_byte)

/*
$@#$%@$@#$%@$@#$%@$@#$%@

Kick out county and state averages of prices with and without subsidies. Drop negative values before doing so.

$@#$%@$@#$%@$@#$%@$@#$%@
*/

preserve
drop if county_byte==.
drop if LCOE_all_subs_ITC<0
drop covered_LCOE
save "$temp/LBNL_county_avg_LCOE.dta", replace
restore

preserve
drop if LCOE_gross_cost<0
collapse LCOE_gross_cost, by(state_byte)
rename LCOE_gross_cost LCOE_gross_cost_state
save "$temp/LBNL_state_avg_gross_LCOE.dta",replace
restore

preserve
drop if LCOE_gross_cost<0
collapse LCOE_all_subs_ITC, by(state_byte)
rename LCOE_all_subs_ITC LCOE_all_subs_ITC_state
save "$temp/LBNL_state_avg_LCOE.dta",replace
restore

preserve
drop if LCOE_gross_cost<0
collapse LCOE_gross_cost
rename LCOE_gross_cost LCOE_gross_cost_national
save "$temp/LBNL_nat_avg_gross_LCOE.dta" , replace
restore

preserve
drop if LCOE_gross_cost<0
collapse LCOE_all_subs_ITC
rename LCOE_all_subs_ITC LCOE_all_subs_ITC_national
save "$temp/LBNL_nat_avg_LCOE.dta" , replace
restore


clear

/*
$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@

Step 2: Create a version of the county-level DeepSolar data with relevant covariates

$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@
*/

//port in county-level deep solar data
use "$processed/DeepSolar_CountyData_2023.dta", clear


//clean
keep COUNTYNAME lat lon cooling_degree_days  daily_solar_flux_fixed fips5 heating_degree_days household_count id mortgage_with_rate population_density voting_2016_gop_percentage tract_level_R_gen tract_R_purchases total_panel_area_residential solar_system_count_residential daily_solar_flux_fixed average_household_income gini_index diversity education_less_than_high_school_   population_density mortgage_with_rate heating_degree_days   cooling_degree_days land_area housing_unit_median_value	housing_unit_median_gross_rent	lat	lon	elevation	heating_design_temperature	cooling_design_temperature	earth_temperature_amplitude	frost_days	air_temperature	relative_humidity	atmospheric_pressure	wind_speed	earth_temperature

//prepare to merge in covered counties
rename fips5 county_byte
label var county_byte "fips5 county tag"
destring county_byte, replace
//merge in GMM estimates
merge 1:1 county_byte  using "$temp/gmm_fitted.dta", gen(merge_covered_counties) force


/*


  Result                      Number of obs
    -----------------------------------------
    Not matched                         2,507
        from master                     2,507  (merge_covered_counties==1)
        from using                          0  (merge_covered_counties==2)
    Matched                               601  (merge_covered_counties==3)
    ------------------------------------




*/

gen covered_county = (merge_covered_counties==3)
drop merge*

//clean
drop  thirdpartyowned state_code   p_solar p_grid  c_grid c_solar c_solar c_elec  
gen state_byte = floor(county_byte/1000)


//save this file
save "$temp/DeepSolar_for_Validation_2023.dta", replace




/*
$@#$%@$@#$%@$@#$%@$@#$%@

4.3 merge solar prices into deep solar data

$@#$%@$@#$%@$@#$%@$@#$%@
*/


use "$temp/DeepSolar_for_Validation_2023.dta", clear

merge 1:1 county_byte using "$temp/LBNL_county_avg_LCOE.dta", gen(merge_county_prices)
drop if merge_county_prices==2
merge m:1 state_byte using "$temp/LBNL_state_avg_LCOE.dta", gen(merge_state_prices)
drop if merge_state_prices==2

preserve
use "$temp/LBNL_nat_avg_LCOE.dta", clear
scalar national_price = LCOE_all_subs_ITC_national[1]
restore

gen lcoe_national = national_price





/*
$@#$%@$@#$%@$@#$%@$@#$%@

replace negative LCOEs with state averages

Then replace all missing values with state/national average where applicable
$@#$%@$@#$%@$@#$%@$@#$%@
*/

gen p_solar = LCOE_all_subs_ITC
replace p_solar = LCOE_all_subs_ITC_state if LCOE_all_subs_ITC<0
replace p_solar = LCOE_all_subs_ITC_state if LCOE_all_subs_ITC==.
//(1,516 real changes made)
replace p_solar = lcoe_national if p_solar==.
//(1,325 real changes made)


/*
$@#$%@$@#$%@$@#$%@$@#$%@

Step 3: merge in electricity prices and quantities along with mean HH incomes in 2018

$@#$%@$@#$%@$@#$%@$@#$%@
*/

drop electricity_consume_residential electricity_price_residential
merge 1:1 county_byte using "$processed/2018_EIA_prices.dta", gen(merge_electricity)
 
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                            57
        from master                        33  (merge_electricity==1)
        from using                         24  (merge_electricity==2)

    Matched                             3,075  (merge_electricity==3)
    -----------------------------------------

.  


*/

drop if merge_electricity!=3

//re-merge income
drop mean_hh_income
merge 1:1 county_byte using "$processed/ACS_2018_mean_income.dta", gen(merge_income) force
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                           145
        from master                         0  (merge_income==1)
        from using                        145  (merge_income==2)

    Matched                             3,075  (merge_income==3)
    -----------------------------------------


. 
end of do-file
*/
keep if merge_income==3
drop merge* 



/*
$@#$%@$@#$%@$@#$%@$@#$%@

4.5 generate variables I care about

$@#$%@$@#$%@$@#$%@$@#$%@
*/


/*
$@#$%@$@#$%@$@#$%@$@#$%@
Measured solar to grid consumption ratios
$@#$%@$@#$%@$@#$%@$@#$%@
*/
//Note solar generation was monthly
gen c_solar = 12*tract_level_R_gen/household_count
gen c_grid = electricity_consume_residential
gen p_elec = electricity_price_residential


drop state_delta state_gamma state_kappa state_rho gbar sbar

save "$temp/fitting_data_2023.dta", replace




/*
$@#$%@$@#$%@$@#$%@$@#$%@

4.6 Repeat above external validation exercise with alternative specification for the model with state amenity parameters

$@#$%@$@#$%@$@#$%@$@#$%@
*/

use "$temp/fitting_data_2023.dta", clear
/*
$@#$%@$@#$%@$@#$%@$@#$%@
Pull in my existing estimates for state-level parameters
$@#$%@$@#$%@$@#$%@$@#$%@
*/


//state-level parameters
gen state_gamma=.
gen state_delta=.
gen state_kappa=.
gen state_rho=.

//count level parameters
gen sbar = .
gen gbar = .

//grab .ster file

estimates use "$sters/main_est_6_25.ster"
//estimates use "$sters/main_est.ster"
replace sbar = /sbar 
replace gbar = /gbar
replace state_kappa = /kappa  
replace state_rho = /rho  	



//list of state codes I need
global state_code_list "4	5	6	9	10	12	25	27	33	34	36	41	42	48	50	55"
drop state_fips
gen state_fips = floor(county_byte/1000)

//loop over states to assign state-level weights
foreach i of numlist $state_code_list  {
	local delta_dummy = "[xd]state_delta_" + "`i'"
	local gamma_dummy = "[xg]state_gamma_" + "`i'"
	replace state_delta = `delta_dummy'  if state_fips==`i'
	replace state_gamma = `gamma_dummy'  if state_fips==`i'
}


tab state_gamma
//generate a lower and upper bound for fitted values of gamma I'll be estimating
egen min_estimated_gamma = min(state_gamma)
egen max_estimated_gamma = max(state_gamma)

//repeat for deltas
egen min_estimated_delta = min(state_delta)
egen max_estimated_delta = max(state_delta)



/*
$@#$%@$@#$%@$@#$%@$@#$%@
generate county-level fitted values for amenity parameters delta and gamma
from extrapolation done in estimation.
$@#$%@$@#$%@$@#$%@$@#$%@
*/

//grab fitting values for gamma
estimates use "$sters/gammas.ster"

predict fitted_gammas
sum fitted_gammas
gen out_dummy = (state_gamma==.)
 tab state_fips if out_dummy == 1
/*
OOS states


.  tab state_fips if out_dummy == 1

 state_fips |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |         66        2.97        2.97
          8 |         63        2.84        5.81
         13 |        158        7.11       12.92
         16 |         44        1.98       14.90
         17 |         98        4.41       19.31
         18 |         89        4.01       23.31
         19 |         98        4.41       27.72
         20 |        105        4.73       32.45
         21 |        120        5.40       37.85
         22 |         62        2.79       40.64
         23 |         16        0.72       41.36
         24 |         24        1.08       42.44
         26 |         83        3.74       46.17
         28 |         81        3.65       49.82
         29 |        113        5.09       54.91
         30 |         56        2.52       57.43
         31 |         93        4.19       61.61
         32 |         16        0.72       62.33
         35 |         33        1.49       63.82
         37 |        100        4.50       68.32
         38 |         52        2.34       70.66
         39 |         88        3.96       74.62
         40 |         77        3.47       78.08
         44 |          5        0.23       78.31
         45 |         46        2.07       80.38
         46 |         65        2.93       83.30
         47 |         94        4.23       87.53
         49 |         29        1.31       88.84
         51 |        132        5.94       94.78
         53 |         39        1.76       96.53
         54 |         55        2.48       99.01
         56 |         22        0.99      100.00
------------+-----------------------------------
      Total |      2,222      100.00

. 
Thirty-two states! great.

*/








//grab fitting values for delta
estimates use "$sters/deltas.ster"
		
predict fitted_deltas
sum fitted_deltas
 

/*
$@#$%@$@#$%@$@#$%@$@#$%@
Replace missing entries with fitted values
$@#$%@$@#$%@$@#$%@$@#$%@
*/


replace state_gamma = fitted_gammas if state_gamma==.
replace state_gamma = min_estimated_gamma if state_gamma<=0
replace state_gamma = max_estimated_gamma if state_gamma>=1
//(32 real changes made)

replace state_delta = fitted_deltas if state_delta==.
replace state_delta = min_estimated_delta if state_delta<=0
replace state_delta = max_estimated_delta if state_delta>=1
//(12 real changes made)

sum state_gamma state_delta

//generate predicted interior ratio by model (that would targe the quantities less their reference levels)
gen interior_ratio = ( (1-state_gamma) * p_elec )/(state_gamma *p_solar)
gen fitted_solar_ratio =( interior_ratio )^ (state_rho)

//take realized ones and subtract bar values
gen target_solar_ratio = (c_solar - sbar) / (c_grid- gbar)
sum target_solar_ratio, d


//summarize
sum fitted_solar_ratio target_solar_ratio, d
xtile fitted_pctile= fitted_solar_ratio , n(99)
xtile target_pctile= target_solar_ratio , n(99)

 count if          fitted_pctile < 99 
  count if          fitted_pctile < 99 &target_solar_ratio>0

//unweighted
cor target_solar_ratio fitted_solar_ratio 
cor target_solar_ratio fitted_solar_ratio if fitted_solar_ratio<0.1 & target_solar_ratio<0.1



/*
regression tables
*/

reg  target_solar_ratio fitted_solar_ratio , vce(cluster state_byte)
//reg out all, no winsor
outreg using "$processed/counterfactual.tex", se bdec(3 3)  replace tex ctitle("","(1)") title("Grid-Solar Moment Matching for In- and Out-of-Sample Counties")

//reg out all, with winsor
reg  target_solar_ratio fitted_solar_ratio if  fitted_pctile < 99 , vce(cluster state_byte)
outreg using "$processed/counterfactual.tex", se bdec(3 3)  replace tex ctitle("","(1)") title("Grid-Solar Moment Matching for In- and Out-of-Sample Counties")



//reg out in
reg  target_solar_ratio fitted_solar_ratio if  out_dummy==0 &   fitted_pctile < 99 , vce(cluster state_byte)
outreg using "$processed/counterfactual.tex", se bdec(3 3)   merge  tex  ctitle("", "(2)")


//reg out out
reg  target_solar_ratio fitted_solar_ratio if   out_dummy==1  &   fitted_pctile < 99 , vce(cluster state_byte)
outreg using "$processed/counterfactual.tex", se bdec(3 3)   merge  tex  ctitle("", "(3)")

/*
reg  target_solar_ratio fitted_solar_ratio if    fitted_pctile < 99 &target_solar_ratio>0 , r
outreg using "$processed/counterfactual.tex", se bdec(3 3)   merge  tex  ctitle("", "(4)")


// model vs. sample solar consumption
preserve
keep if   fitted_pctile < 99 
gen errors_2 = (target_solar_ratio - fitted_solar_ratio)^2
egen mean = mean(target_solar_ratio)
gen resid_2 = (target_solar_ratio - mean)^2
egen tss = sum(resid_2 )
egen sse = sum(errors_2)
gen R_squared= 1 - sse/tss
drop errors_2 mean resid_2 tss sse  
sum R_squared
restore
*/

label var fitted_solar_ratio "Fitted Ratio of Solar to Grid Consumption from Model "
label var target_solar_ratio "Measured Ratio of Solar to Grid Consumption from DeepSolar"


count if fitted_solar_ratio>0.2 | target_solar_ratio>0.2
//65
count if fitted_solar_ratio>0.1 | target_solar_ratio>0.1
//  82

twoway (scatter fitted_solar_ratio target_solar_ratio  if fitted_solar_ratio<0.1 & target_solar_ratio<0.1, color("black") ) ///
(lfit target_solar_ratio target_solar_ratio if fitted_solar_ratio<0.1 & target_solar_ratio<0.1, lpattern("dash") ),  ///
ytitle("Fitted Ratio, Hat SG") ///
xtitle("Observed Ratio, Tilde SG") ///
legend(order(1 "Fitted Values" 2 "45{superscript:{&loz}} line")) ///
title("Fitted vs. Observed County-Level Solar-Grid Ratios, 2018") ///
note("Note: Plotted data are limited to counties with fitted and observed solar-grid ratios of less than 0.1" "to ease visibility. This omits 82 of 3,075 observations.")

graph export "$processed/fitted_vs_observed_sg.png", replace


/*
$@#$%@$@#$%@$@#$%@$@#$%@
Merge alternative pricing schemes to have HH pay gross costs 
$@#$%@$@#$%@$@#$%@$@#$%@
*/

merge m:1 state_byte using "$temp/LBNL_state_avg_gross_LCOE.dta", gen(merge_state_prices)
drop if merge_state_prices==2

preserve
use "$temp/LBNL_nat_avg_gross_LCOE.dta" , clear
scalar national_price = LCOE_gross_cost_national[1]
restore

gen lcoe_national_gross = national_price


gen p_solar_nosubs = LCOE_gross_cost
replace p_solar_nosubs = LCOE_gross_cost_state if v<0
replace p_solar_nosubs = LCOE_gross_cost_state if LCOE_all_subs_ITC==.

 tab state_fips if p_solar_nosubs == .
/*

 tate_fips |      Freq.     Percent        Cum.
------------+-----------------------------------
          8 |         63        4.79        4.79
         19 |         98        7.46       12.25
         20 |        105        7.99       20.24
         21 |        120        9.13       29.38
         22 |         62        4.72       34.09
         28 |         81        6.16       40.26
         30 |         56        4.26       44.52
         31 |         93        7.08       51.60
         38 |         52        3.96       55.56
         39 |         88        6.70       62.25
         40 |         77        5.86       68.11
         44 |          5        0.38       68.49
         45 |         46        3.50       71.99
         46 |         65        4.95       76.94
         47 |         94        7.15       84.09
         51 |        132       10.05       94.14
         54 |         55        4.19       98.33
         56 |         22        1.67      100.00
------------+-----------------------------------
      Total |      1,314      100.00


Colorado, Iowa, Kansas, Kentucky, Lousiana, Mississippi, Montana, Nebraska, North Dakota, Ohio, Oklahoma, Rhode Island, South Carolina, South Dakota, Tennessee, Virginia, West Virginia, Wyoming 

*/


replace p_solar_nosubs = lcoe_national_gross if p_solar_nosubs==.


/*
$@#$%@$@#$%@$@#$%@$@#$%@

4.7 Output data for policy experiment

$@#$%@$@#$%@$@#$%@$@#$%@
*/
//downsize data for what i need.
rename c_grid c_grid_EIA
keep p_solar_nosubs p_solar p_elec c_solar c_grid_EIA county_byte COUNTYNAME id  state_byte state_fips household_count state_gamma state_rho state_kappa state_delta sbar gbar  mean_hh_income out_dummy 


//save out
count
//  3,075
save "$temp/counterfactual_input_2023s.dta", replace
export delimited "$temp/counterfactual_input_2023s.csv", replace

