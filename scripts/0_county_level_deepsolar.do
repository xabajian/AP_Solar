clear all


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
ACA
11/24/2021


The DeepSolar Data provide census tract-level insolation (radiative forcing) and panel area, along with the estiamted decomposition of installations between residential and commercial generation. This allows us to calculate panel area per HH at the county level. The raw source of the data may be found here:

http://web.stanford.edu/group/deepsolar/deepsolar_tract.csv



!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/


//set macros
global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/_Data_postAER/Raw"
global temp "$root/_Data_postAER/Temp"
global processed "$root/_Data_postAER/Processed"





//Import the "Stanford University's DeepSolar Project (Yu et al.) dataset for 2018 solar installations
import delimited "$raw/solar_data_2018.csv"

//save as a .dta file
save "$processed/DeepSolar_Data_Dec2018.dta", replace
clear




/*

!@#$!@#$!@#$@#
!@#$!@#$!@#$@#
!@#$!@#$!@#$@#

Part Zero - 

Check if total Wattage (generating capacity) that's present in the  "Deep Solar" data set for both residential-scale and commercial-scale comports (roughly) with EIA estimate for small-scall wattage installed in 2018.
	
	
	EIA source for small-scale generation:
		https://www.eia.gov/electricity/annual/html/epa_04_03.html
	
	EIA reports there was about 19,547.1 MW of CSPV capacity installed
		on a "small-scale" in 2018
	I will assume this is composed of only of commercial and residential solar systems
		
		
The assumptions for converting between panel surface area and Wattage are as follows:
		Wattage: 175W/m^2

If panel wattage is ~175W/m^2, this means there should	be about 19,547 * 175^-1 ~= 111 .69 MM m^2 panels at the residential and commercial scales combined to match EIA's capacity measure. This block checks if want to check if the DeepSolar data believe there is a similar amount of panel area to what EIA reports (after converting wattage to panel area).

!@#$!@#$!@#$@#
!@#$!@#$!@#$@#
!@#$!@#$!@#$@#

*/
use "$processed/DeepSolar_Data_Dec2018.dta", clear



preserve
collapse (sum) total_panel_area total_panel_area_nonresidential total_panel_area_residential 
scalar NRes = total_panel_area_nonresidential
scalar Res = total_panel_area_residential
scalar total = total_panel_area
restore
display total
//96731548


/*
We have EIA reporting there was ~111MM meters^2 of installed panels by the end of 2018, vs. ~96MM in the deep solar data set.
Translating this total area into MW of capacity, this is 16,928 Megawatts. Given the DeepSolar snapshot was taken in early December 2018 this is a fairly good crossover. 
This suggests the deep solar set is probably a pretty accurate measure.
*/

clear


/*
!@#$!@#$!@#$@#
Part 1- Generate Area per household at the tract level
!@#$!@#$!@#$@#
*/

use "$processed/DeepSolar_Data_Dec2018.dta", clear

//First, a quick check to ensure the data comport with basic facts about the number of U.S. households
sum household_count, detail

/*

quick check of whether these data reconcile with total households

72M x 1,600HH is about 115 MM households, checks out with the magnitude of what it should be

*/


//Calculate meters^2 of panels per household for each census tract
gen area_per_HH = total_panel_area_residential / household_count
	replace area_per_HH = 0 if area_per_HH==.
sum area_per_HH, detail
//I would note there are some huge outliers here.


/*
!@#$!@#$!@#$@#
Part 2- Generate Area per household at the tract level
!@#$!@#$!@#$@#


Now we must calculate monthly electricity generation per panel area. Monthly average household electricity generation at the census level follows the following formula:

Day per month TIMES avgerage solar insolation/day (kWh*m^2 /day) TIMES 
Panel efficiency (pure number) TIMES 
Average panel area per HH (M^2)		

*** assuming there's no 'over capacity' (IE, insolation is never over 1000W/m^2)

		Technical assumptions:
		~30.4375 days per month 
		~20% CSPV panel efficiency (this is probably high) 
		~Panels never receive >1000Watts per meter of solar insolation and therefore 
			the generation constraint is never binding


The first step is to clean entries for daily average insolation 
*/


sum daily_solar_radiation

//Needs cleaning at the tract level - how many observations are missing?

count if daily_solar_radiation=="NA"
//5,802
/*
OK, that's a decent amount of the ~72K census tract-level observations.
For now, let's mark the missing entries. 
*/

destring daily_solar_radiation, generate(daily_solar_flux) force

generate missing_solar_flux = (missing(daily_solar_flux))
tab missing_solar_flux 
	


/*
Interpolate missing insolation values assuming that solar insolation for missing census tracts is equal to the average insolation in the counties missing tracts lie in. This is going to allow me to fill in the (large) amount of missing entries
*/
//gen county level means
bysort county state: egen mean_county_flux = mean(daily_solar_flux)

//in sample-errors
gen flux_error = daily_solar_flux - mean_county_flux
sum flux_error
	
/*
The in sample-errors are very low. As one might expect, solar insolation differs little within counties as that's how geography works. 
*/
	
gen daily_solar_flux_fixed = daily_solar_flux
replace daily_solar_flux_fixed = mean_county_flux if daily_solar_flux_fixed==.
count if daily_solar_flux_fixed==.
//11

//repeat exercise at the state level
bysort state: egen mean_state_flux = mean(daily_solar_flux)
replace daily_solar_flux_fixed = mean_state_flux if daily_solar_flux_fixed==.


drop mean_state_flux mean_county_flux
/*
OK, now that we have insolation measures for all census tracts, we can generate average monthly HH residential solar generation according to the above formula
*/
gen monthly_HH_R_gen = 30.4375 * 0.2 * daily_solar_flux_fixed * area_per_HH
save "$temp/DeepSolar_Dec2018_int.dta", replace




/*
Match census tracts to counties
*/
/*
Create variable to merge over in our data set
*/
use "$temp/DeepSolar_Dec2018_int.dta", clear

//generate fips5 codes
gen floor_tests = floor(fips/1000000)
sum floor_tests
tostring floor_tests, generate(fips5) force
replace fips5="0" + fips5 if strlen(fips5)==4


gen check =strlen(fips5)
sum check
//make sure everything is kosher
merge m:1 fips5 using "$processed/us_counties_cleaned.dta"
tab STATE if _merge!=3

//Great, we have AK AS GU HI PR and VI (alaska, american samoa, guam, hawaii, puerto rico, and virgin islands) not accounted for, as expected. we can drop these unmatched values.

drop if _merge!=3


/*


Aside, calculate ratios of self-generated to purchased energy at the tract level
	to replicate some of Nick's figures
 
*/

			 
gen self_generated_purchased_ratio = monthly_HH_R_gen/electricity_consume_residential 
sum self_generated_purchased_ratio, detail
	
gen ratio_over1=(self_generated_purchased_ratio>=1)
tab ratio_over1
tab state if ratio_over1 == 1
/*

OK, so by these calculations there are 11 census tracts out of the ~72,000 which produce more residential solar energy than they consume during an average month. (assuming purchases of electricity off the grid are homogeneous across tracts within counties).How about at the county level on a monthly basis? Here we need to aggregate up capacity (square meters) to tract level, then sum (collapse) over counties

So *total* tract-level (residential) generation = resi_area * daily_solar_flux * 0.2 (efficiency) * 30.4375 (kWh)
	 
*/
 
	
gen tract_level_R_gen = 0.2  * 30.4375 * total_panel_area_residential * daily_solar_flux_fixed
		
		
//Create aggregate residential purchases at tract level (kWh)
gen tract_R_purchases = electricity_consume_residential * household_count
sum tract_R_purchases
	
//noting it's a little strange some tracts have zero households
sum  household_count, d
save "$temp/DeepSolar_Dec2018_int.dta", replace

clear
/*
!#@$!@#$!@#$
!#@$!@#$!@#$
!#@$!@#$!@#$
	
Part 3 : Generate county-level deepsolar dataset 
 !#@$!@#$!@#$
!#@$!@#$!@#$
!#@$!@#$!@#$

 */	
 use "$temp/DeepSolar_Dec2018_int.dta", clear


//Collapse at the county level. It will sum generation and purchases over census tracts, by counties

//destring
destring electricity_price_residential electricity_consume_residential daily_solar_flux_fixed average_household_income housing_unit_median_value housing_unit_median_gross_rent  voting_2016_gop_percentage population_density heating_degree_days cooling_degree_days mortgage_with_rate incentive_residential_state_leve  land_area housing_unit_median_value	housing_unit_median_gross_rent	lat	lon	elevation	heating_design_temperature	cooling_design_temperature	earth_temperature_amplitude	frost_days	air_temperature	relative_humidity	daily_solar_radiation	atmospheric_pressure	race_white_rate race_black_africa_rate wind_speed	earth_temperature gini_index diversity education_less_than_high_school_  , replace force


//collapse
collapse (rawsum) total_panel_area_residential tract_level_R_gen tract_R_purchases  solar_system_count_residential household_count (mean) average_household_income gini_index diversity education_less_than_high_school_  electricity_price_residential electricity_consume_residential daily_solar_flux_fixed voting_2016_gop_percentage population_density heating_degree_days cooling_degree_days mortgage_with_rate incentive_residential_state_leve id  land_area housing_unit_median_value	housing_unit_median_gross_rent	lat	lon	elevation	heating_design_temperature	cooling_design_temperature	earth_temperature_amplitude	frost_days	air_temperature	relative_humidity	daily_solar_radiation	atmospheric_pressure	wind_speed	earth_temperature race_white_rate race_black_africa_rate  [aw =household_count] , by(county state STATE  COUNTYNAME  fips5) 

//generate a few other variables
gen  county_level_res_gen = tract_level_R_gen
gen county_level_res_purchases= tract_R_purchases 
gen county_res_ratio = county_level_res_gen/county_level_res_purchases
gen HH_share = solar_system_count_residential/household_count
destring fips5, replace


//save out
save  "$processed/DeepSolar_CountyData_2023.dta", replace
clear all
