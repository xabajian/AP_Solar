clear all

/*
!!@#$!@#$!@#$

Reduced form regressions in table 1.

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

//prep for regressions
destring gini_index heating_degree_days cooling_degree_days race_white_rate race_black_africa_rate education_less_than_high_school_ average_household_income population_density lat mortgage_with_rate voting_2016_gop_percentage diversity land_area housing_unit_median_value	housing_unit_median_gross_rent	lat	lon	elevation	heating_design_temperature	cooling_design_temperature	earth_temperature_amplitude	frost_days	air_temperature	relative_humidity	daily_solar_radiation	atmospheric_pressure	wind_speed	earth_temperature , replace force
//make county fips5 codes numeric
destring fips5, replace


//put income in log(thousands)
replace average_household_income = average_household_income/1000
gen log_income = ln(average_household_income)
label var average_household_income "average income in 2015, thousands of dollars (ACS 2015)"



//Check on states without net metering in 2018
tab STATE if net_metering==0
tab STATE if net_metering<8



/*
@!#$!@#$
Columnn (1) -- Insolation only
@!#$!@#$
*/
reg area_per_HH daily_solar_flux_fixed [aw=household_count] if log_income!=., vce(cluster state)
outreg using deepsolar_rf, se bdec(3 3) nostars replace tex ctitle("","(1)")  title("Decomposition of Solar Panel Area per Household") 


/*
@!#$!@#$
Columnn (2) -- Income only
@!#$!@#$
*/
reg area_per_HH log_income [aw=household_count] if log_income!=. , vce(cluster state)
outreg using deepsolar_rf, se bdec(3 3) nostars merge  tex  ctitle("", "(2)") 



/*
@!#$!@#$
Columnn (3) -- Income and insolation
@!#$!@#$
*/
reg area_per_HH daily_solar_flux_fixed log_income [aw=household_count] if log_income!=. , vce(cluster state)
outreg using deepsolar_rf, se bdec(3 3) nostars merge  tex  ctitle("", "(3)") 



/*
@!#$!@#$
Columnn (4) -- County fixed-effects
@!#$!@#$
*/
areg area_per_HH  [aw=household_count] if log_income!=. , absorb(fips5) vce(cluster state)
outreg using deepsolar_rf, se bdec(3 3) nostars merge  tex  ctitle("", "(4)") 





/*
@!#$!@#$
Columnn (5) -- FEs, income, and insolation
@!#$!@#$
*/
areg area_per_HH daily_solar_flux_fixed log_income [aw=household_count] if log_income!=. , absorb(fips5) vce(cluster state)
outreg using deepsolar_rf, se bdec(3 3) nostars merge  tex  ctitle("", "(5)") 

//LA COUNTY
areg area_per_HH daily_solar_flux_fixed log_income [aw=household_count] if log_income!=. & county!="Los Angeles County" , absorb(fips5) vce(cluster state)


/*
@!#$!@#$
Columnn (6) -- kitchen sink for footnote
@!#$!@#$
*/
areg area_per_HH  daily_solar_flux_fixed log_income average_household_income gini_index diversity education_less_than_high_school_   population_density mortgage_with_rate heating_degree_days   cooling_degree_days land_area housing_unit_median_value	housing_unit_median_gross_rent	lat	lon	elevation	heating_design_temperature	cooling_design_temperature	earth_temperature_amplitude	frost_days	air_temperature	relative_humidity	atmospheric_pressure	wind_speed	earth_temperature  [aw=household_count], absorb(fips5) vce(cluster state)

