clear all

cd "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
ACA
4/4/2022

Borenstein Bushnell Damage mapping
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/

//set macros
//set global root directory
global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/Data_Formal/Raw"
global temp "$root/Data_Formal/Temp"
global processed "$root/Data_Formal/Processed"

//use bnb data
use "$raw/BNB_21_Output.dta", clear

//rename for merege
rename eia_id_e UtilityNumber

//run merge mapping utilities into counties
merge m:m UtilityNumber using "$raw/EIA Electricity Prices/eia_816_territories.dta", gen(merge_fips)

/*

    Result                      Number of obs
    -----------------------------------------
    Not matched                         3,995
        from master                     1,041  (merge_fips==1)
        from using                      2,954  (merge_fips==2)

    Matched                            10,438  (merge_fips==3)
    -----------------------------------------

. 
end of do-file
*/

drop if merge_fips==2

bysort merge_fips: egen total_elec = total(res_sales)

tab total_elec merge_fips

//collapse for sales-weighted SMCs by county
collapse damagesCO2 emc [fw= res_sales], by(FIPS State)

rename FIPS fips

keep if fips!=.

save "$processed/county_level_external_damages.dta", replace


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
ACA
4/4/2022

Borenstein Bushnell Damage mapping
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/

