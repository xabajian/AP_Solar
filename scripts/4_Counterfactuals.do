clear all


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
ACA
1/17/23

Run GMM regressions on new data
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
Generate closed form solutions for baseline model from the parameters 
$@#$%@$@#$%@$@#$%@$@#$%@
*/

use "$temp/counterfactual_input_2023s.dta", clear



sum c_grid_EIA, d
sum c_grid_EIA [aw=household_count], d

kdensity c_grid_EIA [aw=household_count], xtitle("Average Residential Electricity Purchased in 2018, kWh")
graph export "$processed/electricity_kdensity.png", replace


sum mean_hh_income


//generate baseline modeled values ine ach county_byte
rename p_elec p_grid
gen P_E_bl = ((1-state_gamma)^(state_rho)*p_solar^(1-state_rho) + state_gamma^(state_rho)*p_grid^(1-state_rho))^(1/(1-state_rho))
gen P_bl = ( (1-state_delta)^state_kappa + state_delta^state_kappa *(P_E_bl)^(1-state_kappa))^(1/(1-state_kappa))
gen X_E_bl = (mean_hh_income - p_grid * gbar - p_solar * sbar ) * state_delta^state_kappa * P_E_bl^(1-state_kappa) *P_bl^(state_kappa-1)
gen c_bl = (mean_hh_income - p_grid * gbar - p_solar * sbar ) - X_E_bl
gen g_bl = gbar +  state_gamma ^(state_rho)*p_grid ^(-state_rho)*P_E_bl^(state_rho-1)*X_E_bl
gen s_bl = sbar + (1-state_gamma) ^(state_rho)*p_solar^(-state_rho)*P_E_bl^(state_rho-1)*X_E_bl

//sanity checks on parameters and modeled values
sum c_bl g_bl s_bl

sum c_bl g_bl s_bl, d
sum state_gamma state_delta state_kappa state_rho gbar sbar 


/*
$@#$%@$@#$%@$@#$%@$@#$%@
Check buget constraints
$@#$%@$@#$%@$@#$%@$@#$%@
*/
gen total_expend = c_bl + p_solar * s_bl + p_grid*g_bl
corr total_expend mean_hh_income


//counterfactual scenario in model


gen P_E_cf = ((1-state_gamma)^(state_rho)*p_solar_nosubs^(1-state_rho) + state_gamma^(state_rho)*p_grid^(1-state_rho))^(1/(1-state_rho))
gen P_cf = ((1-state_delta)^(state_kappa) + state_delta^(state_kappa)*(P_E_cf)^(1-state_kappa))^(1/(1-state_kappa))
gen X_E_cf =(mean_hh_income - p_grid * gbar - p_solar_nosubs * sbar ) * state_delta^state_kappa * P_E_cf^(1-state_kappa) *P_cf^(state_kappa-1)
gen c_cf = mean_hh_income-X_E_cf
gen g_cf = gbar + state_gamma^(state_rho)*p_grid^(-state_rho)*P_E_cf^(state_rho-1)*X_E_cf
gen s_cf =  sbar + (1-state_gamma)^(state_rho)*p_solar_nosubs^(-state_rho)*P_E_cf^(state_rho-1)*X_E_cf
 
 sum c_cf g_cf s_cf
 
 
  
/*
$@#$%@$@#$%@$@#$%@$@#$%@
Check share of countes which backfire
$@#$%@$@#$%@$@#$%@$@#$%@
*/
gen dgrid = (g_bl-g_cf)
gen dsolar = (s_bl - s_cf) 
gen dsolar_percent = (s_bl - s_cf) /s_cf
sum dsolar_percent dsolar dgrid, d

count if dgrid>0
//7
gen backfire = (dgrid>0)
corr backfire out_dummy



/*


. corr backfire out_dummy
(obs=3,075)

             | backfire out_du~y
-------------+------------------
    backfire |   1.0000
   out_dummy |   0.0296   1.0000



*/

gen dgrid_pct = 100*dgrid/g_cf
sum dgrid_pct if dgrid_pct>0, d
sum dgrid_pct if dgrid_pct>0 [fw=household_count], d
 
//totwal subsidies spent in backfiring counties
gen subsidy_expenditure = s_bl*(p_solar_nosubs-p_solar)
total subsidy_expenditure [fw=household_count] if backfire==1
scalar backfire_subisides = e(b)[1,1]
display backfire_subisides
total subsidy_expenditure [fw=household_count]
scalar total_subsidies =  e(b)[1,1]

display backfire_subisides/total_subsidies
//1.613e-06



/*
$@#$%@$@#$%@$@#$%@$@#$%@
check the county-level arc elasticities
$@#$%@$@#$%@$@#$%@$@#$%@
*/



//log change in prices
gen log_dp_solar = log(p_solar/p_solar_nosubs)


//log changes in quantities 
gen log_dq_solar = log(s_bl/s_cf)

//elasticities
gen solar_PED = log_dq_solar/log_dp_solar


sum solar_PED, d 
sum solar_PED [aw=household_count], d 
 
 /*

                          solar_PED
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -4.328959       -4.34367
 5%    -4.273322      -4.342828
10%    -4.222862      -4.341502       Obs               3,074
25%    -4.010707      -4.341382       Sum of wgt.       3,074

50%    -3.454662                      Mean           -2.92644
                        Largest       Std. dev.      1.300287
75%    -1.779836      -.0227954
90%    -.8587348      -.0191291       Variance       1.690745
95%     -.543314      -.0167855       Skewness       .7713439
99%    -.1541526      -.0160117       Kurtosis       2.154896

. sum solar_PED [aw=household_count], d 

                          solar_PED
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -4.333995       -4.34367
 5%    -4.318345      -4.342828
10%    -4.273322      -4.341502       Obs               3,074
25%    -4.169015      -4.341382       Sum of wgt.   113915564

50%    -3.767653                      Mean          -3.202196
                        Largest       Std. dev.      1.248185
75%    -2.437128      -.0227954
90%    -.9810421      -.0191291       Variance       1.557966
95%     -.674143      -.0167855       Skewness       1.078912
99%    -.2014309      -.0160117       Kurtosis       2.687883


. 


*/
 
 
//counterfactual -- median gammas 

egen median_gamma =median(state_gamma)


gen P_E_med_gamma = ((1-median_gamma)^(state_rho)*p_solar^(1-state_rho) + median_gamma^(state_rho)*p_grid^(1-state_rho))^(1/(1-state_rho))
gen P_med_gamma  = ((1-state_delta)^(state_kappa) + state_delta^(state_kappa)*(P_E_med_gamma)^(1-state_kappa))^(1/(1-state_kappa))
gen X_med_gamma  = state_delta^(state_kappa) * P_E_med_gamma^(1-state_kappa) *P_med_gamma^(state_kappa-1)*(mean_hh_income - p_grid * gbar - p_solar * sbar )
gen c_med_gamma  = (mean_hh_income - p_grid * gbar - p_solar * sbar )-X_med_gamma
gen g_med_gamma  = gbar +  median_gamma^(state_rho)*p_grid^(-state_rho)*P_E_med_gamma^(state_rho-1)*X_med_gamma
gen s_med_gamma  =  sbar + (1-median_gamma)^(state_rho)*p_solar^(-state_rho)*P_E_med_gamma^(state_rho-1)*X_med_gamma
 

//counterfactual -- median solar price

egen p_s_median =median(p_solar)

gen P_E_med_solar = ((1-state_gamma)^(state_rho)*p_s_median^(1-state_rho) + state_gamma^(state_rho)*p_grid^(1-state_rho))^(1/(1-state_rho))
gen P_med_solar = ((1-state_delta)^(state_kappa) + state_delta^(state_kappa)*(P_E_med_solar)^(1-state_kappa))^(1/(1-state_kappa))
gen X_E_med_solar = state_delta * P_E_med_solar^(1-state_kappa) *P_med_solar^(state_kappa-1)*(mean_hh_income - p_grid * gbar - p_s_median * sbar )
gen c_med_solar = (mean_hh_income - p_grid * gbar - p_s_median * sbar )-X_E_med_solar
gen g_med_solar =  gbar + state_gamma^(state_rho)*p_grid^(-state_rho)*P_E_med_solar^(state_rho-1)*X_E_med_solar
gen s_med_solar = sbar + (1-state_gamma)^(state_rho)*p_s_median^(-state_rho)*P_E_med_solar^(state_rho-1)*X_E_med_solar
 

 //counterfactual -- median grid price


 egen p_e_median =median(p_grid)
 
 
gen P_E_med_grid = ((1-state_gamma)^(state_rho)*p_solar^(1-state_rho) + state_gamma^(state_rho)*p_e_median^(1-state_rho))^(1/(1-state_rho))
gen P_med_grid = ((1-state_delta)^(state_kappa) + state_delta^(state_kappa)*(P_E_med_grid)^(1-state_kappa))^(1/(1-state_kappa))
gen X_E_med_grid = state_delta^(state_kappa) * P_E_med_grid^(1-state_kappa) *P_med_grid^(state_kappa-1)*(mean_hh_income - p_e_median * gbar - p_solar * sbar )
gen c_med_grid = (mean_hh_income - p_grid * gbar - p_e_median * sbar )-X_E_med_grid
gen g_med_grid = gbar + state_gamma^(state_rho)*p_e_median^(-state_rho)*P_E_med_grid^(state_rho-1)*X_E_med_grid
gen s_med_grid = sbar + (1-state_gamma)^(state_rho)*p_solar^(-state_rho)*P_E_med_grid^(state_rho-1)*X_E_med_grid
 


/*
$@#$%@$@#$%@$@#$%@$@#$%@
OK, they're very close

Now check on the aggreagtes
$@#$%@$@#$%@$@#$%@$@#$%@
*/



//measured aggregates
gen measured_county_solar = c_solar *household_count
gen measured_county_grid = c_grid_EIA *household_count
egen total_measured_solar = total(measured_county_solar)
egen total_measured_grid = total(measured_county_grid)

//baseline model outputs
gen baseline_county_solar = s_bl *household_count
gen baseline_county_grid = g_bl *household_count
egen total_bl_solar = total(baseline_county_solar)
egen total_bl_grid = total(baseline_county_grid)

//counterfactual model outputs (no subisidies)
gen cfx_county_solar = s_cf *household_count
gen cfx_county_grid = g_cf *household_count
egen total_cfx_solar = total(cfx_county_solar)
egen total_cfx_grid = total(cfx_county_grid)

//counterfactual model outputs (median gammas)
gen med_gamma_county_solar = s_med_gamma* household_count
gen med_gamma_county_grid = g_med_gamma* household_count
egen total_gamma_solar = total(med_gamma_county_solar)
egen total_gamma_grid = total(med_gamma_county_grid)


sum total_measured_grid total_bl_grid total_cfx_grid
sum total_measured_solar total_bl_solar total_cfx_solar

gen grid_error = (total_bl_grid- total_measured_grid)/total_measured_grid
gen solar_error = (total_bl_solar- total_measured_solar)/total_measured_solar

sum grid_error solar_error

///print out values for table
// display total_measured_solar[1]
// display total_measured_grid[1]
display total_bl_solar[1]
display total_bl_grid[1]
display total_cfx_solar[1]
display total_cfx_grid[1]
display total_gamma_solar[1]
display total_gamma_grid[1]



/*
$@#$%@$@#$%@$@#$%@$@#$%@
Check ratios
$@#$%@$@#$%@$@#$%@$@#$%@
*/


// display total_measured_solar[1]/total_measured_grid[1]
display total_bl_solar[1]/total_bl_grid[1]
display total_cfx_solar[1]/total_cfx_grid[1]
display total_gamma_solar[1]/total_gamma_grid[1]
// display total_medsolar_solar[1]/total_medsolar_grid[1]
// display total_medgrid_solar[1]/total_medpgrid_grid[1]





/*
$@#$%@$@#$%@$@#$%@$@#$%@
Aggregate increase$
$@#$%@$@#$%@$@#$%@$@#$%@
*/

display total_bl_solar +  total_bl_grid - total_cfx_solar - total_cfx_grid
//9.736e+09

display (total_bl_solar - total_cfx_solar)/total_cfx_solar
// //2.5499755
. 

//aggregate pass through trate
display (total_bl_grid-total_cfx_grid) /(total_bl_solar - total_cfx_solar) 
//-.5014417

//show by type
display total_bl_solar -  total_cfx_solar
//1.953e+10


display total_bl_grid -  total_cfx_grid
//-9.793e+09

//rebound
display (total_bl_solar +  total_bl_grid - total_cfx_solar - total_cfx_grid) /(total_bl_solar -  total_cfx_solar) 
//.37889503

/*
$@#$%@$@#$%@$@#$%@$@#$%@
Check increase in grid and solar consumption
$@#$%@$@#$%@$@#$%@$@#$%@
*/


//percent changes 
gen grid_pct_change = (baseline_county_grid-cfx_county_grid)/cfx_county_grid
gen solar_pct_change = (baseline_county_solar-cfx_county_solar)/cfx_county_solar
gen grid_agg_pct_change = (total_bl_grid-total_cfx_grid)/total_cfx_grid
gen solar_agg_pct_change = (total_bl_solar-total_cfx_solar)/total_cfx_solar


//sumarize % changes in grid
sum grid_pct_change, d
sum grid_pct_change if backfire==1, d

//summarize % chagnes in solar consumption
sum solar_pct_change, d
sum solar_pct_change [aw=household_count], d



sum grid_pct_change solar_pct_change grid_agg_pct_change solar_agg_pct_change

 
 
 
 /*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$


EFFICIENCY OF SUBSIDY

!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/

//aggregate subsidies

total subsidy_expenditure [fw=household_count]
//  1.44e+09 

//aggregate cost of induced demand
display  e(b)[1,1] /(total_bl_solar - total_cfx_solar) 
//.07373376



//county-level costs of induced demand
scalar test  = (p_solar*(total_bl_solar - total_cfx_solar) )/(p_solar)
gen d_solar_q = s_bl - s_cf

 
 //generate demand induced per dollar
 gen dQ_dExp = d_solar_q/subsidy_expenditure
 sum dQ_dExp, d
 
 //generate price of induced demand
 gen p_induced_demand = 1/dQ_dExp
 sum p_induced_demand, d 
 
 
 count if p_induced_demand>p_solar_nosubs
 
 
 /*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$


Emissions damages and implied average abatement costs

!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/
gen fips=county_byte
merge 1:1 fips using "$processed/county_level_external_damages.dta", gen(merge_damages)
 
 /*

    Result                      Number of obs
    -----------------------------------------
    Not matched                            15
        from master                        13  (merge_damages==1)
        from using                          2  (merge_damages==2)

    Matched                             3,062  (merge_damages==3)
    -----------------------------------------

.  


*/

keep if merge_damages!=2
drop merge_damages

//generate RA's change in grid consiumption in each county
gen d_gridq_county =  cfx_county_grid-baseline_county_grid

//generate total and co2 external costs and put in dollars
gen co2_county_ext_costs = d_gridq_county*damagesCO2/100
sum damagesCO2, d
scalar median_damage = r(p50)
scalar median_factor = median_damage/5000
display median_factor
gen co2_county_ext_costs_median = d_gridq_county*median_damage/100
gen all_county_ext_costs = d_gridq_county*emc/100

//convert co2 to emissions abateds
gen co2_county_abatement = co2_county_ext_costs/(50)
label var co2_county_abatement "total co2 emissions abated annualy in each county, Metric tons CO2"
gen co2_county_abatement_median = co2_county_ext_costs_median/(50)

//generate total estimated abatement
sum co2_county_abatement
sum co2_county_abatement_median

gen abatement_positive = co2_county_abatement * (co2_county_abatement>0)
egen total_abatement = total(co2_county_abatement)
display total_abatement[1]
//4326244.5

egen total_abatement_median = total(co2_county_abatement_median)
display total_abatement_median[1]
//5540408.5

egen net_abatement = total(abatement_positive)
 sum net_abatement total_abatement
 
 
//Aggregate to create average abatement costs

//solve for subsidies
total subsidy_expenditure [fw=household_count]
// 8.05e+08
scalar total_subsidy = e(b)[1,1]
display total_subsidy/total_abatement
//332.83974

//solve for subsidies in non backfiring counties
total subsidy_expenditure [fw=household_count] if backfire==0
scalar total_subsidy_nobf = e(b)[1,1]
display total_subsidy_nobf/net_abatement
//332.83974
 
 
 //divide by costs to get abatement costs
gen avg_MAC_county = (subsidy_expenditure*household_count)/co2_county_abatement
 sum avg_MAC_county, d
  sum avg_MAC_county [fw=household_count]  , d
gen mac_for_map = avg_MAC_county
replace mac_for_map = . if avg_MAC_county<0

sum mac_for_map, d
 
 /*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$


Total social benefits/costs:

//variables of interest
co2_county_abatement
co2_county_ext_costs

!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/
gen d_solar_value = d_solar_q*p_solar
sum d_solar_value subsidy_expenditure

gen test_ratio = ( d_solar_q*p_solar*household_count  - subsidy_expenditure*household_count)/( subsidy_expenditure*household_count )
sum test_ratio
//drop county_NSB total_private total_external  total_subs private_ben 
//gen county_NSB= (co2_county_ext_costs + d_solar_q*p_solar*household_count)/( subsidy_expenditure*household_count )
// gen county_NSB= (co2_county_ext_costs + d_solar_q* p_solar_nosubs*household_count  - subsidy_expenditure*household_count)/( subsidy_expenditure*household_count )
 gen county_NSB= (co2_county_ext_costs + d_solar_q*p_solar*household_count  - subsidy_expenditure*household_count)/( subsidy_expenditure*household_count )

sum county_NSB, d
sum county_NSB [fw=household_count] 


egen total_external = total(co2_county_ext_costs)
egen total_subs = total(subsidy_expenditure*household_count)

gen private_ben = d_solar_q*p_solar
egen total_private = total(private_ben*household_count)

sum total_private total_external total_subs
gen solar_pct = solar_pct_change*100

/*
save these values out for maps
*/

preserve

//keep fips nosubs_subs_grid_ratio nosubs_subs_solar_ratio  dQ_dExp in_dummy color_val state_gamma MAC_county one_less_gamma in_gamma out_gamma
//old
save "$processed/new_cfx_2023.dta", replace
export delimited "$processed/new_cfx_2023.csv", replace


restore











