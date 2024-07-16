clear all
/*
Read in ACS county-level mean incomes from 2010-18.
Combine all series into one (balanced) panel

All data series are taken directly from the ACS data browser here:
https://www.census.gov/programs-surveys/acs/data/data-tables.html
*/


//set macros
global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/_Data_postAER/Raw"
global temp "$root/_Data_postAER/Temp"
global processed "$root/_Data_postAER/Processed"


cd "$raw/ACS_Income_Series"
/*
Create .dtas
*/

forvalues i = 2010/2018 {
	
	
	local import_dummy = "ACS_" + "`i'" + ".xlsx"
	import excel `import_dummy', sheet("input") firstrow clear
	
	//generate calendar year variable
	gen year = `i'
	
	//pasturize
	destring mean_hh_income, replace force
	destring year, replace force
	destring household_count, replace force
	
	//save out
	local save_dummy = "ACS_" + "`i'" 
	save `save_dummy'.dta, replace

	
	
	display `i'
}
clear


//append panel
forvalues i = 2010/2018 {
	
	
	local import_dummy = "ACS_" + "`i'" 
	append using `import_dummy'.dta, force

	
}
//save out
destring county_byte, replace force
//drop 50 duplicates that occur - they are inconsequential to the counties we estimate the model on.
duplicates drop county_byte year, force
save "$processed/ACS_income_panel.dta", replace

////create 2018 cross section for counterfactual
use "$processed/ACS_income_panel.dta", clear
keep if year==2018
save "$processed/ACS_2018_mean_income.dta", replace
