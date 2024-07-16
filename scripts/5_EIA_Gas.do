clear all

cd "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"


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

Does EIA data suggest 1:1 offsetting for rooftop solar and grid sales?

*/
//set macros

global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/_Data_postAER/Raw"
global temp "$root/_Data_postAER/Temp"
global sters "$root/_Data_postAER/Sters"
global processed "$root/_Data_postAER/Processed"


//grab Qs
import excel "$raw/EIA Gas/eia_gas_input.xlsx", sheet("input_sales") firstrow clear



reshape long state, i(date year) j(dummy)



rename state gas_consumption_mmcf 
label var gas_consumption_mmcf "Natural Gas Residential Consumption (MMcf)"
rename dummy state

//Natural Gas Residential Consumption (MMcf)


save "$temp/EIA_gas_consumption_monthly.dta",  replace 


//grab customers
import excel "$raw/EIA Gas/eia_gas_input.xlsx", sheet("input_customers") firstrow clear



reshape long state, i(year) j(dummy)



rename state number_customers 
label var number_customers "number of resi customers in state"
rename dummy state

//Natural Gas Residential Consumption (MMcf)


save "$temp/EIA_resi_gas_consumers.dta",  replace 


//join
use "$temp/EIA_gas_consumption_monthly.dta", clear
merge m:1 state year using "$temp/EIA_resi_gas_consumers.dta"
keep if _merge==3
drop _merge

gen gas_per_customer = gas_consumption_mmcf/number_customers





//generate monthly date
gen month_date = mofd(date)
gen month=month(date)
format month_date %tm
xtset state month_date

preserve
keep month month_date state gas_per_customer
save "$temp/EIA_gas_per_hh.dta",  replace 
restore


//check for stationarity

matrix stationary_dummies = [.]





forvalues i = 1/51{
	
	preserve
	//capture{
	keep if state==`i'
	
	//dfuller gas_per_customer if gas_per_customer!=. 
	dfuller gas_per_customer if gas_per_customer!=. & year>2010
	//dfuller gas_per_customer if gas_per_customer!=. , drift
	//dfuller gas_per_customer if gas_per_customer!=. , trend
	
	//scalar sig_dummy = r(p)
	scalar sig_dummy = (r(p) < 0.05 )
	
	
	matrix stationary_dummies = stationary_dummies \ sig_dummy
	//}
	restore
}

svmat stationary_dummies
sum stationary_dummies
total stationary_dummies

