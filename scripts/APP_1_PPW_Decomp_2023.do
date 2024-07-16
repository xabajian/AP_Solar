clear all

cd "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels/Data_Formal/Processed"


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
ACA

1/1/2023 - rerun the marginal vs fixed costs in how ppw and LCOE responds to size of panel isntallation in emperical setting


!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$


Part 1: run some regressions examining system costs

!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$

*/
clear all

set maxvar 32000

//set macros
global root "/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels"
global raw "$root/_Data_postAER/Raw"
global temp "$root/_Data_postAER/Temp"
global sters "$root/_Data_postAER/Sters"
global processed "$root/_Data_postAER/Processed"


use "$temp/TTS_county_annual_prices.dta", clear
drop ppw*

//generate price per watt
gen ppw  = totalinstalledprice / (systemsize*1000)
gen ppw_all_subs = (totalinstalledprice*0.7 - rebateorgrant +salestaxcost )/(systemsize*1000)

//summarize the twoway
sum ppw ppw_all_subs
sum ppw, d

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         ppw |  1,035,349    4.658589    1.824052   1.97e-07   29.73429
ppw_all_subs |  1,021,031    2.931031    1.170618  -49.90452    20.1179

. sum ppw, d


*/


//truncate to a subset of 99/1 tiles
keep if ppw > 0.2 & ppw < 20
//(8,929 observations deleted)



sum ppw
/*

. sum ppw

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         ppw |  1,026,420    4.692252    1.753675   .2004536     19.999

. 
end of do-file

*/





/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$

Step 2. Try to decompose system prices per Watt among size effects and other costs

!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/

//baseline
reg ppw systemsize,  vce(cluster state_from_TTS)
outreg using ppw_decomp, se bdec(3 3) nostars replace tex ctitle("","(1)")  title("Decomposition of Price Per Watt") 
//outreg using ppw_decomp, se bdec(3 3) nostars replace  tex  ctitle("", "(BL)")  keep(systemsize)


//quadratic
gen size2 = systemsize^2
reg ppw systemsize size2, vce(cluster state_from_TTS)
test (size2=0) (systemsize=0)
// Prob > F =    0.0000
outreg using ppw_decomp, se bdec(3 3) nostars merge  tex  ctitle("", "(Quad)")  keep(systemsize size2)
display 7.56*e(b)[1,1] + (10.56^2 - 3^2) * e(b)[1,2]
//-1.012703


//controls
//what about with all of the equipment level stuff (ie kitchen sink)
encode dataprovider, gen(provider_id)
encode installername, gen(installer_id)
encode invertermodel1, gen(inverter_id)
encode moduletechnology1, gen(module_id)
replace thirdpartyowned = 99 if thirdpartyowned==-9999
replace batterysystem = 99 if batterysystem==-9999
replace groundmounted = 99 if groundmounted==-9999
replace newconstruction = 99 if newconstruction==-9999
replace dcoptimizer = 99 if dcoptimizer==-9999

//controls
reghdfe ppw systemsize size2 , vce(cluster state_from_TTS) absorb(i.module_id i.installer_id i.inverter_id i.thirdpartyowned i.batterysystem i.dcoptimizer i.groundmounted i.newconstruction)
outreg using ppw_decomp, se bdec(3 3) nostars merge  tex  ctitle("", "(3)")  keep(systemsize size2)
display 7.56*e(b)[1,1] + (10.56^2 - 3^2) * e(b)[1,2]
//-.61008561

//TWFE
reghdfe ppw systemsize size2, vce(cluster state_from_TTS)  absorb(i.module_id i.installer_id i.inverter_id i.thirdpartyowned i.batterysystem i.dcoptimizer i.groundmounted i.newconstruction i.county_byte i.year ) 
outreg using ppw_decomp, se bdec(3 3) nostars merge  tex  ctitle("", "(4)")  keep(systemsize size2)
display 7.56*e(b)[1,1] + (10.56^2 - 3^2) * e(b)[1,2]
//-.43476431

//kitchen sink
reghdfe ppw systemsize size2  , vce(cluster state_from_TTS) absorb(i.year i.county_byte##c.year i.module_id i.installer_id i.inverter_id i.thirdpartyowned i.batterysystem i.dcoptimizer i.groundmounted i.newconstruction)
outreg using ppw_decomp, se bdec(3 3) nostars merge  tex  ctitle("", "(5)")  keep(systemsize size2)
display 7.56*e(b)[1,1] + (10.56^2 - 3^2) * e(b)[1,2]
//-.42979093






//nonlinear
areg ppw systemsize size2 i.year, vce(cluster state_from_TTS) absorb(county_byte)
test (size2=0) (systemsize=0)
//Ok so just with fixed effects we are ruling out quite a bit....

//tpo
areg ppw systemsize size2 i.year i.thirdpartyowned, vce(cluster state_from_TTS) absorb(county_byte)


reghdfe ppw systemsize size2  , vce(cluster state_from_TTS) absorb(i.year i.module_id i.installer_id i.inverter_id i.thirdpartyowned i.batterysystem i.dcoptimizer i.groundmounted i.county_byte i.newconstruction)

display e(b)[1,1] e(b)[1,2]
gen size_effect = systemsize * e(b)[1,1] + size2 *e(b)[1,2]
sum size_effect, d

//compare effect of size to total cost per Watt 

gen size_effect_abs = sqrt(size_effect^2)

gen normed = size_effect/ppw
gen normed_abs = size_effect_abs/ppw
sum normed_abs normed, d

/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$

Re do step 2 for LCOE_all_subs_ITC

!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/


//baseline
reg LCOE_all_subs_ITC systemsize,  vce(cluster state_from_TTS)
outreg using lcoe_decomp, se bdec(3 3) nostars replace  tex  ctitle("", "(BL)")  keep(systemsize)
display 7.56*e(b)[1,1]
//-.01387498

//quadratic
reg LCOE_all_subs_ITC systemsize size2, vce(cluster state_from_TTS)
test (size2=0) (systemsize=0)
// Prob > F =    0.0000
outreg using lcoe_decomp, se bdec(3 3) nostars merge  tex  ctitle("", "(Quad)")  keep(systemsize size2)
display 7.56*e(b)[1,1] + (10.56^2 - 3^2) * e(b)[1,2]
//-.01777557

//controls
reghdfe LCOE_all_subs_ITC systemsize size2 , vce(cluster state_from_TTS) absorb(i.module_id i.installer_id i.inverter_id i.thirdpartyowned i.batterysystem i.dcoptimizer i.groundmounted i.newconstruction)
outreg using lcoe_decomp, se bdec(3 3) nostars merge  tex  ctitle("", "(3)")  keep(systemsize size2)
display 7.56*e(b)[1,1] + (10.56^2 - 3^2) * e(b)[1,2]
//-.0159562

//TWFE
reghdfe LCOE_all_subs_ITC systemsize size2, vce(cluster state_from_TTS)  absorb(i.module_id i.installer_id i.inverter_id i.thirdpartyowned i.batterysystem i.dcoptimizer i.groundmounted i.newconstruction i.county_byte i.year ) 
outreg using lcoe_decomp, se bdec(3 3) nostars merge  tex  ctitle("", "(4)")  keep(systemsize size2)
display 7.56*e(b)[1,1] + (10.56^2 - 3^2) * e(b)[1,2]
//-.01124629

//kitchen sink
reghdfe LCOE_all_subs_ITC systemsize size2  , vce(cluster state_from_TTS) absorb(i.year i.county_byte##c.year i.module_id i.installer_id i.inverter_id i.thirdpartyowned i.batterysystem i.dcoptimizer i.groundmounted i.newconstruction)
outreg using lcoe_decomp, se bdec(3 3) nostars merge  tex  ctitle("", "(5)")  keep(systemsize size2)
display 7.56*e(b)[1,1] + (10.56^2 - 3^2) * e(b)[1,2]
//-.01135156






/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$!!@#$!@#$!@#$

Variance decomp exercise for PPW

!!@#$!@#$!@#$!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/


/*
run regression
*/

reghdfe ppw systemsize size2  , residuals vce(cluster state_from_TTS) absorb( i.county_byte##i.year i.module_id i.installer_id i.inverter_id i.thirdpartyowned i.batterysystem i.dcoptimizer i.groundmounted i.newconstruction)
display 7.56*e(b)[1,1] + (10.56^2 - 3^2) * e(b)[1,2]
//-.42847249

//solve for the fitted values less year-by-county fixed effects 
//note this fits the full model
predict fitted_values, xbd

//note this is *just* the absorbed fixed effects
predict fitted_FEs, d



sum ppw fitted_FEs fitted_values
cor ppw fitted_FEs fitted_values


/*
create value of the intercept term so I can subtract this value from the fitted values leaivng me with the slope coefficients times system size for each installation
*/
gen intercept = _b[_cons]


//solve for just the marginal effect terms - ie the contribution of systemsize_(county-year) * beta(count-year)
gen marginal_effects = fitted_values-intercept-fitted_FEs

//check what we've got
sum marginal_effects,d

sum marginal_effects size_effect
//generate ratios of fitted marginal effects to both fitted and observed values

gen marginal_fitted_ratio = marginal_effects/fitted_values
gen marginal_observed_ratio = marginal_effects/LCOE_all_subs_ITC

//look at shares
sum marginal_observed_ratio marginal_fitted_ratio,d

//kdensity
//kdensity marginal_fitted_ratio if marginal_fitted_ratio>-0.5 & marginal_fitted_ratio<0.02

//use a decomposition of squared portions
gen magnitude_decomp_fitted = sqrt(marginal_effects^2/(intercept^2 + fitted_FEs^2 + marginal_effects^2))

label var magnitude_decomp_fitted "Share of Gross Price Variation Explained by Size"


kdensity magnitude_decomp_fitted, ///
title("Share of Gross Price Variation Explained" "by System Size") ///
note("Note: Plotted data are limited to the 1,021,812 observations for which we can construct the decomposition metric.")

graph export "$processed/decomp_density.png", replace 



sum magnitude_decomp_fitted, d

lowess ppw systemsize 


preserve
gen collapse_weight = floor(systemsize)
collapse household_count systemsize ppw [fw=collapse_weight], by(fips5_byte year)

lowess ppw systemsize 
restore



