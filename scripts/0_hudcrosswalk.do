clear all

/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
The TTS data are at the zip code level, we need to crosswalk/aggregate this into
data at the county level in order to merge into the HUD county-level shapefile.

The official XWalk from HUD can be found here: https://www.huduser.gov/portal/datasets/usps_crosswalk.html

This block merges in zipcodes and deals with entries lacking location data using the hud xwalk from 2021q3.
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/

//set macros
global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/_Data_postAER/Raw"
global temp "$root/_Data_postAER/Temp"
global processed "$root/_Data_postAER/Processed"



//create dta
import excel "$raw/ZIP_COUNTY_092021.xlsx", sheet("ZIP_COUNTY_092021") firstrow clear
save "$raw/ZIP_COUNTY_092021.dta", replace
use "$raw/ZIP_COUNTY_092021.dta", clear
keep COUNTY ZIP RES_RATIO
duplicates r ZIP


codebook COUNTY
sort ZIP RES_RATIO 
sort ZIP RES_RATIO 

//keep only counties with teh highest share of residences from a given zip code. 
by ZIP: gen county_zip_index = _n
by ZIP: gen zip_number_counties = _N
keep if zip_number_counties == county_zip_index
count
//39,488

keep COUNTY ZIP

rename ZIP zipcode
rename COUNTY county
destring county, gen(county_byte)



save "$temp/zip_county_xwalk.dta", replace
save "$processed/zip_county_xwalk.dta", replace
