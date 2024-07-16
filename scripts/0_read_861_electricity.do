clear all



/*
Read in EIA 861 panel from 2000-2018.
This gives aggregate statistics of kwh consumed per customer (and its price) on an annual basis per utility-by-state-by-year.
Combine all series into one (roughly balanced) panel

EIA raw data files are here: https://www.eia.gov/electricity/data/eia861/

*/

//set macros
global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/_Data_postAER/Raw"
global temp "$root/_Data_postAER/Temp"
global processed "$root/_Data_postAER/Processed"


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 1: Create .dtas for electricity annual forms
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/
//set working directory
cd "$raw/EIA 861/processed_EIA_xlsx"



//loop to read in excel files from EIA
forvalues i = 2000/2018 {
	
	//qui{
	//generate sttring dummy to loop over
	local import_dummy = "sales_" + "`i'" + ".xlsx"
	import excel `import_dummy', sheet("input") firstrow clear
	//generate calendar year variable
	gen year = `i'
	//clean unidentified utilites
	drop if UtilityNumber==99999
	//Clean data pre-collapse
	capture{
	drop DataTypeOObservedIImput DataYear
	}
	//keep customers, sales quantities, and total revenue
	destring customer_count, replace
	destring revenues_kdollars, replace
	destring sales_mwh, replace
	//drop utilities that report no customers or have no customers
	drop if customer_count==.
	drop if customer_count==0
	/*keep Part A only - 
	This restricts sample to utilities reporting of electricity revenues/customers/quantitites
	for which the price of power and delivery (distribution/transmission service) is bundled
	  see read me for EIA form 861*/
	keep if Part=="A"
	//drop duplicate observations for utility by state by year combination given 
	duplicates drop State UtilityNumber, force
	//save out
	local save_dummy = "sales_" + "`i'"
	save `save_dummy'.dta, replace
	display `i'
}

clear





//append into one panel
forvalues i = 2000/2018 {
	local import_dummy = "sales_" + "`i'" 
	append using `import_dummy'.dta, force
}
duplicates r State  UtilityNumber year
count
//51,313
save "$temp/EIA_power_panel.dta", replace


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 2: Map to counties

This will use the crosswalk from EIA form 861 in 2018 between utilities and counties.
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/

//part 2.1 --  create crosswalk
import excel "$raw/EIA 861/EIA_2018_county_utility_xwalk", firstrow sheet("EIA_County_Utility_Coverage") clear
rename DataYear crosswalk_year
drop if FIPS == .
duplicates r  FIPS UtilityNumber State
drop UtilityName
save "$temp/eia_816_territories.dta", replace 


/*
Note there are more Counties than the some 3,100 in the U.S. 

Multiple entries stem from the fact that many counties are serviced by multiple electric utilities.
At this point, we keep all observations of utility $j$ county $i$ pairs as
the county-year level values will be weighted values across all the utilities that
served a given county that year
*/



/*part 2.2 -- true pairwise matching */
use "$temp/EIA_power_panel.dta", clear



/*
Merge in utility-county code xwalk
Note the join is pairwise and potentially generates "many to many".
Each county-year pair may be associated with multiple utilities, and many utilities
serve multiple counties within a year.
*/

joinby State UtilityNumber using "$temp/eia_816_territories.dta", unmatched(master)
tab _merge
keep if _merge==3

//keep only observations of use.

//Check duplicates
duplicates r FIPS year
duplicates tag FIPS year, gen(county_year_dup_count)
duplicates r FIPS State year UtilityNumber
//great, safe to keep county names
/*
Note to reader. At this point I have an annual panel of utilties-by-count observations.

Each observation for county $i$ utility $j$ in year $t$ catalogues the *total* customers, 
revenue, and quanitity of electricity supplied by a given utility $j$ to all counties $i$ it served that year.


The collapse below will for each county-$i$ year-$t$ pair calculate the total
revenue, quantitity of electricicity, and customers across all utilities which serviced that county.

county-year prices ($/kWh) are then total revenue over total quantity (revenues_kdollars/sales_mwh)
county-year consumption (kWh)  per household is (1000*sales_mwh/customer_count)

*/

/*
!@#$!@#$@!#$!@$
%%%Part 3
Collapse by FIPS codes by year to generate aggregates at the county level
!@#$!@#$@!#$!@$
*/

collapse (sum) customer_count revenues_kdollars sales_mwh, by(FIPS County State year)



//Rename variables for ease of merge
gen electricity_price_residential=revenues_kdollars/sales_mwh
gen electricity_consume_residential = 1000*sales_mwh/customer_count
drop if electricity_consume_residential==. | electricity_price_residential==.
label var electricity_price_residential "average residential electric price/kwh"
label var electricity_consume_residential "average residential hh energy consmption, kwh"
drop County State

//rename for merge into the solar price and quantity data later
rename FIPS county_byte
label var county_byte "county-level FIPS codes"
sum electricity_price_residential, d
sum electricity_consume_residential, d

//drop missing values for counties
drop if county_byte==.

//take stock
tab year
bysort county_byte: gen nobs = _N
tab nobs
//histogram nobs, bin(19)
drop nobs
/*
We retain about 3,100 counties. coverage is very good
*/



save "$processed/EIA_power_county_panel.dta", replace
count
//58,916



//create 2018 cross section
use "$processed/EIA_power_county_panel.dta", clear
keep if year==2018
save "$processed/2018_EIA_prices.dta", replace

