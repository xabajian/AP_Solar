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



/*
Read in the 3 monthly EIA datasets
*/

//Fix solar
import excel "$raw/EIA_solar_data_monthly.xlsx", sheet("input_solar") firstrow clear

reshape long state, i(Month) j(dummy)
replace state = state*1000000
rename state solar_generation_kwh
rename dummy state

save "$temp/EIA_solar_gen_monthly.dta",  replace 


//Fix customers
import excel "$raw/EIA_solar_data_monthly.xlsx", sheet("input_customers") firstrow clear

drop B* C*

reshape long state, i(Month) j(dummy)
rename state customers
rename dummy state

save "$temp/EIA_customers_monthly.dta",  replace 


//Fix consumption
import excel "$raw/EIA_solar_data_monthly.xlsx", sheet("input_sales") firstrow clear

reshape long state, i(Month) j(dummy)
replace state = state*1000000
rename state resi_consumption_kwh
rename dummy state

save "$temp/EIA_grid_consumption_monthly.dta",  replace 





/*
!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@
!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@
!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@
!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@
!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@

merge them to form panel

!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@
!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@
!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@
!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@
!@#$!@#$!@#$!@#$!@#$!@#$!#@$!@#$!@

*/

use "$temp/EIA_grid_consumption_monthly.dta",  clear
merge 1:1 Month state using "$temp/EIA_customers_monthly.dta",gen(merge_customers)
merge 1:1 Month state using "$temp/EIA_solar_gen_monthly.dta",gen(merge_solar)

 keep if merge_customers==3
 //label states
 
label define state_labels 1 "Connecticut"	2 "Maine"	3 "Massachusetts"	4 "New Hampshire"	5 "Rhode Island"	6 "Vermont"	7 "New Jersey"	8 "New York"	9 "Pennsylvania"	10 "Illinois"	11 "Indiana"	12 "Michigan"	13 "Ohio"	14 "Wisconsin"	15 "Iowa"	16 "Kansas"	17 "Minnesota"	18 "Missouri"	19 "Nebraska"	20 "North Dakota"	21 "South Dakota"	22 "Delaware"	23 "District of Columbia"	24 "Florida"	25 "Georgia"	26 "Maryland"	27 "North Carolina"	28 "South Carolina"	29 "Virginia"	30 "West Virginia"	31 "Alabama"	32 "Kentucky"	33 "Mississippi"	34 "Tennessee"	35 "Arkansas"	36 "Louisiana"	37 "Oklahoma"	38 "Texas"	39 "Arizona"	40 "Colorado"	41 "Idaho"	42 "Montana"	43 "Nevada"	44 "New Mexico"	45 "Utah"	46 "Wyoming"	47 "California"	48 "Oregon"	49 "Washington"	50 "Alaska"	51 "Hawaii"


label values state state_labels







//generate monthly date
gen month_date = mofd(Month)
format month_date %tm
drop merge*
gen year = yofd(Month)
gen quarter = qofd(Month)
gen month_dummy = month(Month)
drop Month


sum year quarter month_dummy month_date

//heat check
xtset state month_date
/*

Panel variable: state (strongly balanced)
 Time variable: month_date, 2008m1 to 2022m10
         Delta: 1 month

*/

duplicates r month_date state

/*


Duplicates in terms of month_date state

--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |         9078             0
--------------------------------------

. xtset state month_date

Panel variable: state (strongly balanced)
 Time variable: month_date, 2008m1 to 2022m10
         Delta: 1 month

. 
end of do-file



*/




/*
//Merge in data on HDD CDD
*/
merge 1:1 month_date state using "$temp/NOAA_DD_panel.dta",  gen(merge_hdd) 
/*

    Result                      Number of obs
    -----------------------------------------
    Not matched                         3,162
        from master                     3,060  (merge_hdd==1)
        from using                        102  (merge_hdd==2)

    Matched                             6,018  (merge_hdd==3)
    -----------------------------------------

. 


*/

tab month_date if merge_hdd==2
//ok, just climate data update more frequently
drop if merge_hdd==2


tab month_date if merge_hdd==1
//great, years I don'c care about not needed
drop merge_hdd


count if solar_generation_kwh!=. & HDDs==""
count if solar_generation_kwh!=. & CDDs==""
//0 -- great

//destring HDD CDDs

//CDD
destring HDDs, replace
//HDD
destring CDDs, replace



/*
//Merge in data on mean HH income at annual level
*/
//fill state strings
replace state_string="Connecticut" if state==1
replace state_string="Maine" if state==2
replace state_string="Massachusetts" if state==3
replace state_string="New Hampshire" if state==4
replace state_string="Rhode Island" if state==5
replace state_string="Vermont" if state==6
replace state_string="New Jersey" if state==7
replace state_string="New York" if state==8
replace state_string="Pennsylvania" if state==9
replace state_string="Illinois" if state==10
replace state_string="Indiana" if state==11
replace state_string="Michigan" if state==12
replace state_string="Ohio" if state==13
replace state_string="Wisconsin" if state==14
replace state_string="Iowa" if state==15
replace state_string="Kansas" if state==16
replace state_string="Minnesota" if state==17
replace state_string="Missouri" if state==18
replace state_string="Nebraska" if state==19
replace state_string="North Dakota" if state==20
replace state_string="South Dakota" if state==21
replace state_string="Delaware" if state==22
replace state_string="District Of Columbia" if state==23
replace state_string="Florida" if state==24
replace state_string="Georgia" if state==25
replace state_string="Maryland" if state==26
replace state_string="North Carolina" if state==27
replace state_string="South Carolina" if state==28
replace state_string="Virginia" if state==29
replace state_string="West Virginia" if state==30
replace state_string="Alabama" if state==31
replace state_string="Kentucky" if state==32
replace state_string="Mississippi" if state==33
replace state_string="Tennessee" if state==34
replace state_string="Arkansas" if state==35
replace state_string="Louisiana" if state==36
replace state_string="Oklahoma" if state==37
replace state_string="Texas" if state==38
replace state_string="Arizona" if state==39
replace state_string="Colorado" if state==40
replace state_string="Idaho" if state==41
replace state_string="Montana" if state==42
replace state_string="Nevada" if state==43
replace state_string="New Mexico" if state==44
replace state_string="Utah" if state==45
replace state_string="Wyoming" if state==46
replace state_string="California" if state==47
replace state_string="Oregon" if state==48
replace state_string="Washington" if state==49
replace state_string="Alaska" if state==50
replace state_string="Hawaii" if state==51



tab state_string
codebook state state_string
//great

//merge income
merge m:1 year state_string  using "$processed/ACS_income_panel_states.dta",  gen(merge_income) 
/*
  Result                      Number of obs
    -----------------------------------------
    Not matched                         3,696
        from master                     3,678  (merge_income==1)
        from using                         18  (merge_income==2)

    Matched                             5,400  (merge_income==3)
    -----------------------------------------

. drop merge_income
*/

drop if merge_income==2
drop merge_income


/*
xtset
*/
xtset state month_date


/*
generate per-capita (per customer) values in all states
*/

gen solar_per_hh  =  solar_generation_kwh/customers
gen grid_per_hh=  resi_consumption_kwh/customers
gen ratio = solar_per_hh/grid_per_hh
sum grid_per_hh solar_per_hh  ratio


/*
stationarity or pre trends -- 
*/

matrix stationary_dummies = [.]


forvalues i = 1/51{
	
	preserve
	//capture{
	keep if state==`i'
	
	//dfuller grid_per_hh if solar_per_hh!=. 
	dfuller grid_per_hh 
	
	//scalar sig_dummy = r(p)
	scalar sig_dummy = (r(p) < 0.05 )
	
	
	matrix stationary_dummies = stationary_dummies \ sig_dummy
	//}
	restore
}

svmat stationary_dummies
sum stationary_dummies
total stationary_dummies


/*
all 51 stationary in levels...
*/


matrix stationary_FD = [.]


forvalues i = 1/51{
	
	preserve
	capture{
	keep if state==`i'
	
	dfuller D.grid_per_hh
	
	//scalar sig_dummy = r(p)
	scalar sig_dummy = (r(p) < 0.05 )
	
	
	matrix stationary_FD = stationary_FD \ sig_dummy
	}
	restore
}


svmat stationary_FD
sum stationary_FD
total stationary_FD




xtset state month_date

//baseline
reg  grid_per_hh solar_per_hh , r
reg  grid_per_hh solar_per_hh [aw = customers], r

//bl with controls
reg  grid_per_hh solar_per_hh CDDs HDDs , r
reg  grid_per_hh solar_per_hh  CDDs HDDs [aw = customers], r

//bl with controls and incoem
reg  grid_per_hh solar_per_hh CDDs HDDs mean_hh_income , r
reg  grid_per_hh solar_per_hh  CDDs HDDs mean_hh_income [aw = customers], r

//month dummies
reg  grid_per_hh solar_per_hh  CDDs HDDs i.month_date , r
reg  grid_per_hh solar_per_hh  CDDs HDDs i.month_date [aw = customers], r


//FE 
areg grid_per_hh solar_per_hh  CDDs HDDs, absorb(state) vce(robust)
areg grid_per_hh solar_per_hh  CDDs HDDs [aw = customers], absorb(state) vce(robust)

//TWFE
//clement tests...
//first assumes parallel trends, constant effect over time
//twowayfeweights grid_per_hh state month_date solar_per_hh, type(feS) controls( CDDs HDDs)
/*
Under the common trends, treatment monotonicity, and if groups' treatment effect does not change over time,
beta estimates a weighted sum of 5134 LATEs. 

2377 LATEs receive a positive weight, and 2757 receive a negative weight.
The sum of the positive weights is equal to 3.4452689.
The sum of the negative weights is equal to -2.4452689.

beta is compatible with a DGP where the average of those LATEs is equal to 0,
while their standard deviation is equal to .20436585.

beta is compatible with a DGP where those LATEs all are of a different sign than beta,
while their standard deviation is equal to .25793865.



*/
//second less restrictive
//twowayfeweights grid_per_hh state month_date solar_per_hh, type(feTR) controls( CDDs HDDs)
/*

. twowayfeweights grid_per_hh state month_date solar_per_hh, type(feTR) controls( CDDs HDDs)
Under the common trends assumption, beta estimates a weighted sum of 5194 ATTs. 
2566 ATTs receive a positive weight, and 2628 receive a negative weight.
The sum of the positive weights is equal to 1.634016.
The sum of the negative weights is equal to -.63401604.
beta is compatible with a DGP where the average of those ATTs is equal to 0,
while their standard deviation is equal to .55909566.
beta is compatible with a DGP where those ATTs all are of a different sign than beta,
while their standard deviation is equal to .93512785.

*/


//Various TWFE
areg grid_per_hh solar_per_hh CDDs HDDs i.month_date, absorb(state) vce(robust)
areg grid_per_hh solar_per_hh  CDDs HDDs i.month_date [aw = customers], absorb(state) vce(robust)


areg grid_per_hh solar_per_hh CDDs HDDs mean_hh_income i.month_date, absorb(state) vce(robust)
areg grid_per_hh solar_per_hh  CDDs HDDs mean_hh_income i.month_date [aw = customers], absorb(state) vce(robust)





areg grid_per_hh solar_per_hh CDDs HDDs i.month_dummy, absorb(state) vce(robust)
areg grid_per_hh solar_per_hh CDDs HDDs i.month_dummy [aw = customers], absorb(state) vce(robust)


areg grid_per_hh solar_per_hh CDDs HDDs i.quarter, absorb(state) vce(robust)
areg grid_per_hh solar_per_hh CDDs HDDs i.quarter [aw = customers], absorb(state) vce(robust)

areg grid_per_hh solar_per_hh CDDs HDDs i.year, absorb(state) vce(robust)
areg grid_per_hh solar_per_hh CDDs HDDs i.year [aw = customers], absorb(state) vce(robust)





//twfe trends
reg grid_per_hh solar_per_hh CDDs HDDs i.month_date i.state##c.month_date, vce(robust)
reg grid_per_hh solar_per_hh CDDs HDDs i.month_date  i.state##c.month_date [aw = customers],  vce(robust)

//twfe quad
gen time2 = month_date^2
reghdfe  grid_per_hh solar_per_hh  CDDs HDDs,  vce(robust) absorb(i.state##c.month_date i.month_date )
reghdfe  grid_per_hh solar_per_hh CDDs HDDs  [aw = customers],  vce(robust) absorb(i.state##c.month_date i.month_date )
reghdfe  grid_per_hh solar_per_hh  CDDs HDDs [aw = customers],  vce(robust) absorb(i.state##c.month_date i.state#c.time2 i.month_date )





//First differences
reg  d.grid_per_hh d.solar_per_hh [aw = customers], r
reg  d.grid_per_hh d.solar_per_hh   i.month_date [aw = customers], r
areg  d.grid_per_hh d.solar_per_hh   i.month_date [aw = customers], absorb(state) vce(robust)




/*
generate peak kw and cumulative kw instrument


see here -- https://www.eia.gov/renewable/monthly/solar_photo/pdf/renewable.pdf
*/

gen peakkw=.
replace peakkw=320208 if year==2006
replace peakkw=320208 if year==2007
replace peakkw=494148 if year==2008
replace peakkw=920693 if year==2009
replace peakkw=1188879 if year==2010
replace peakkw=2644498 if year==2011
replace peakkw=3772075 if year==2012
replace peakkw=4655005 if year==2013
replace peakkw=4984881 if year==2014
replace peakkw=6237524 if year==2015
replace peakkw=9942978 if year==2016
replace peakkw=13451187 if year==2017
replace peakkw=7971622 if year==2018
replace peakkw=16372314  if year==2019
replace peakkw=20412296 if year==2020
replace peakkw=26339918 if year==2021
replace peakkw=17327669 if year==2022



reg solar_per_hh peakkw [aw = customers] , r
reg solar_per_hh L.peakkw [aw = customers] , r

gen cumkw=.
replace cumkw=320208 if year ==2006
replace cumkw=814356 if year ==2007
replace cumkw=1735049 if year ==2008
replace cumkw=2923928 if year ==2009
replace cumkw=5568426 if year ==2010
replace cumkw=9340501 if year ==2011
replace cumkw=13995506 if year ==2012
replace cumkw=18980387 if year ==2013
replace cumkw=25217911 if year ==2014
replace cumkw=35160889 if year ==2015
replace cumkw=48612076 if year ==2016
replace cumkw=59476621 if year ==2017
replace cumkw=67448243 if year ==2018
replace cumkw=83820557 if year ==2019
replace cumkw=104232853 if year ==2020
replace cumkw=130572771 if year ==2021
replace cumkw=147900440 if year ==2022


reg solar_per_hh cumkw [aw = customers], r
reg solar_per_hh L.cumkw [aw = customers], r
reg solar_per_hh L.cumkw i.state i.month_dummy [aw = customers], r
reg solar_per_hh L.cumkw HDDs CDDs i.state i.month_dummy [aw = customers], r



gen period_shipments =.
replace period_shipments=1120728 if year ==2006
replace period_shipments=1665279 if year ==2007
replace period_shipments=3213219 if year ==2008
replace period_shipments=3316972 if year ==2009
replace period_shipments=5192670 if year ==2010
replace period_shipments=5990348 if year ==2011
replace period_shipments=5341383 if year ==2012
replace period_shipments=3754813 if year ==2013
replace period_shipments=5425418 if year ==2014
replace period_shipments=7014257 if year ==2015
replace period_shipments=9701365 if year ==2016
replace period_shipments=5238043 if year ==2017
replace period_shipments=3563669 if year ==2018
replace period_shipments=6707456 if year ==2019
replace period_shipments=7647845 if year ==2020
replace period_shipments=8886278 if year ==2021
replace period_shipments=5672338 if year ==2022



reg solar_per_hh period_shipments [aw = customers], r
reg solar_per_hh L.period_shipments [aw = customers], r


gen cum_shipments =.
replace cum_shipments=1120728 if year ==2006
replace cum_shipments=2786007 if year ==2007
replace cum_shipments=5999226 if year ==2008
replace cum_shipments=9316198 if year ==2009
replace cum_shipments=14508868 if year ==2010
replace cum_shipments=20499216 if year ==2011
replace cum_shipments=25840599 if year ==2012
replace cum_shipments=29595412 if year ==2013
replace cum_shipments=35020830 if year ==2014
replace cum_shipments=42035087 if year ==2015
replace cum_shipments=51736452 if year ==2016
replace cum_shipments=56974495 if year ==2017
replace cum_shipments=60538164 if year ==2018
replace cum_shipments=67245620 if year ==2019
replace cum_shipments=74893465 if year ==2020
replace cum_shipments=83779743 if year ==2021
replace cum_shipments=89452081 if year ==2022


reg solar_per_hh cum_shipments [aw = customers], r
reg solar_per_hh L.cum_shipments [aw = customers], r
reg solar_per_hh L.cum_shipments i.state i.month_dummy [aw = customers], r
reg solar_per_hh L.cum_shipments L.cumkw i.state i.month_dummy [aw = customers], r




gen period_priceperwatt = period_shipments/peakkw


reg solar_per_hh period_priceperwatt [aw = customers], r
reg solar_per_hh L.period_priceperwatt [aw = customers], r


/*
merge residential ng consumption naturals
*/

merge m:1 state month_date using "$temp/EIA_gas_per_hh.dta"
keep if _merge!=2
drop _merge

//gas_per_customer

/*
merge lat lon
*/

merge m:1 state_string using "$processed/state_lat_lon_pairs.dta"
keep if _merge!=2
drop _merge


*/lagged c/

 

//IV - use lag of cumulative shipments as instrument --/
xtset state month_date

///OLS
reg grid_per_hh solar_per_hh HDDs CDDs i.state i.month_dummy  [aw = customers], vce(robust) 
reg grid_per_hh solar_per_hh HDDs CDDs i.state i.month_date  [aw = customers], vce(robust) 
ivregress 2sls  grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= L.peakkw)  [aw = customers], vce(robust) 


//$@#%#$@%$#@%$#@%$%@#$%@#$%
//(1)
ivregress gmm grid_per_hh (solar_per_hh= L.cumkw) [aw = customers], vce(robust) 
ivregress 2sls grid_per_hh (solar_per_hh= L.cumkw) [aw = customers], vce(robust)

//ivregress 2sls grid_per_hh (solar_per_hh= lagged_instrument_cumulative) [aw = customers], vce(robust)
display e(b)[1,1]
//-.81520422
test (solar_per_hh  = -1)
outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars replace tex ctitle("","(1)")  title("Grid Consumption vs. Solar Gen ") keep(solar_per_hh)


//$@#%#$@%$#@%$#@%$%@#$%@#$%
//(2)
ivregress 2sls grid_per_hh i.state i.month_dummy (solar_per_hh= L.cumkw)  [aw = customers], vce(robust)
//ivregress 2sls grid_per_hh i.state i.month_dummy (solar_per_hh= lagged_instrument_cumulative)  [aw = customers], vce(robust)
outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(FEs)") keep(solar_per_hh)

display e(b)[1,1]
test (solar_per_hh  = -1)
/*

. display e(b)[1,1]
-.59402518

. test (solar_per_hh  = -1)

 ( 1)  solar_per_hh = -1

           chi2(  1) =    1.10
         Prob > chi2 =    0.2948


*/


//$@#%#$@%$#@%$#@%$%@#$%@#$%
//(3)
ivregress 2sls  grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= L.cumkw)  [aw = customers], vce(robust) 
//ivregress 2sls  grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= L.cumkw)  [aw = customers], vce(cluster state_month) 


outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(FEs ctr)") keep(solar_per_hh HDDs CDDs)

display e(b)[1,1]
test (solar_per_hh  = -1)

/*

. display e(b)[1,1]
-.65810062

. test (solar_per_hh  = -1)

 ( 1)  solar_per_hh = -1

           chi2(  1) =    1.74
         Prob > chi2 =    0.1874


. 


*/


//ivregress 2sls grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= L.cumkw)  [aw = customers], vce(robust) 
ivregress 2sls grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= lag_cum) , vce(bootstrap, reps(500)) 

display e(b)[1,1]
//outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(FEs gas)") keep(solar_per_hh HDDs CDDs)

display e(b)[1,1]
test (solar_per_hh  = -1)

/*

. display e(b)[1,1]
-.8789177

. test (solar_per_hh  = -1)

 ( 1)  solar_per_hh = -1

           chi2(  1) =    0.15
         Prob > chi2 =    0.6973


		 
*/

//Groups year-by-state
 egen state_by_year = group(state year), label

//Alternative IV - use lag of cumulative value of shipments as instrument --


//$@#%#$@%$#@%$#@%$%@#$%@#$%
//(4')
// //alterantive instrument
// ivregress 2sls grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= L.cum_shipments)  [aw = customers], vce(robust)
// display e(b)[1,1]
// test (solar_per_hh  = -1)
// outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(cum $s)") keep(solar_per_hh HDDs CDDs)
//
// /*
//
//
// . display e(b)[1,1]
// -.89859885
//
// . test (solar_per_hh  = -1)
//
//  ( 1)  solar_per_hh = -1
//
//            chi2(  1) =    0.14
//          Prob > chi2 =    0.7066
//
// . 
// end of do-file
//
// . 
//
// */


 //$@#%#$@%$#@%$#@%$%@#$%@#$%
//(4)
//state specific time trends
 ivregress 2sls grid_per_hh HDDs CDDs i.state##c.month_date  (solar_per_hh= L.cumkw) , vce(robust) 
display e(b)[1,1]
test (solar_per_hh  = -1)
outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(cum $s)") keep(solar_per_hh HDDs CDDs)

 

//$@#%#$@%$#@%$#@%$%@#$%@#$%
//(5)
//overidentified
ivregress gmm grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= L.cumkw L.cum_shipments)  [aw = customers], vce(robust) wmatrix(robust)
outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(overid)") keep(solar_per_hh HDDs CDDs)

display e(b)[1,1]
test (solar_per_hh  = -1)
estat overid, forceweights



/*

. 
-.52898096

. test (solar_per_hh  = -1)

 ( 1)  solar_per_hh = -1

           chi2(  1) =    3.36
         Prob > chi2 =    0.0667

. estat overid, forceweights

  Test of overidentifying restriction:

  Hansen's J chi2(1) = 29.6285 (p = 0.0000)

. 




*/

//OTHER SPECIFICATIONS 


//overid no CA
ivregress 2sls grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= L.cumkw L.cum_shipments)  [aw = customers] if state!=47, vce(robust)
display e(b)[1,1]
//-.90087305


//no california
ivregress 2sls grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= L.cumkw)  [aw = customers] if state !=47 , vce(robust) 
display e(b)[1,1]
//-.96024272

//no weights
ivregress 2sls grid_per_hh HDDs CDDs i.state i.month_dummy  (solar_per_hh= L.cumkw)  , vce(robust) 
display e(b)[1,1]
//-.62328254



//UPDATE 6/27/223 -- with gas
//$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%
//$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%
//$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%


gen lagged_instrument_cumulative = L.cumkw * LON
//(1)
ivregress 2sls grid_per_hh gas_per_customer (solar_per_hh= lagged_instrument_cumulative) [aw = customers] if state_string!="Hawaii" & state_string!="Alaska", vce(robust)
display e(b)[1,1]
//-1.3795585

outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars replace tex ctitle("","(1)")  title("Decomposition of Solar Panel Area per Household") keep(solar_per_hh gas_per_customer HDDs CDDs)

//(2)
ivregress 2sls grid_per_hh gas_per_customer HDDs CDDs (solar_per_hh= lagged_instrument_cumulative) [aw = customers] if state_string!="Hawaii" & state_string!="Alaska", vce(robust)
display e(b)[1,1]
//-.67878354
outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(State FEs)") keep(solar_per_hh gas_per_customer HDDs CDDs)


//(3 - TWFE, preferred)
ivregress 2sls grid_per_hh gas_per_customer HDDs CDDs i.state i.month_dummy (solar_per_hh= lagged_instrument_cumulative)  [aw = customers] if state_string!="Hawaii" & state_string!="Alaska" , vce(robust)
display e(b)[1,1]
//-.45630222
outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(TWFEs)") keep(solar_per_hh gas_per_customer HDDs CDDs)





//alt instrument
ivregress 2sls grid_per_hh gas_per_customer  HDDs CDDs i.state i.month_dummy  (solar_per_hh= lagged_instrument_peak )  [aw = customers] if state_string!="Hawaii" & state_string!="Alaska"  , vce(robust) 
outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(alt inst)") keep(solar_per_hh gas_per_customer HDDs CDDs)


//overid
ivregress gmm grid_per_hh gas_per_customer  HDDs CDDs i.state i.month_dummy  (solar_per_hh= lagged_instrument_cumulative lagged_instrument_peak )  [aw = customers] if state_string!="Hawaii" & state_string!="Alaska"  , vce(robust) 
outreg using "$processed/passthrough_IV.tex", se bdec(3 3) nostars merge  tex  ctitle("", "(overid)") keep(solar_per_hh gas_per_customer HDDs CDDs)




//$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%
//$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%
//$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@%$%#$@



