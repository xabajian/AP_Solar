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




use "$processed/estimating_sample.dta", clear
codebook county_byte


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 0: prepare data
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/



/*
encode all the geographic dummies
*/
encode state_from_TTS, gen(state_code)

/*
!@#$!@#$!@#$!@#$!@#$
/*
drop any observations that have insufficient information at this point or that have negative solar prices at this point
*/
!@#$!@#$!@#$!@#$!@#$
*/

drop if p_grid==.
drop if p_solar==.
drop if p_solar<=0
sum p_solar
drop if c_grid==.
drop if c_grid<0
drop if c_solar==.
drop if mean_hh_income==.

total household_count if year==2018

/*
$@#$%@$@#$%@$@#$%@$@#$%@
Price index macros
$@#$%@$@#$%@$@#$%@$@#$%@
*/

global P_E "((1- {gamma})^( {rho})*p_solar^(1- {rho}) + {gamma}^( {rho})*p_grid^(1- {rho}))^(1/(1- {rho}))"
global P_C "((1- {delta})^ {kappa} + {delta}^ {kappa} *($P_E)^ (1- {kappa}))^(1/(1- {kappa}))"
display "$P_E $P_C"

/*
$@#$%@$@#$%@$@#$%@$@#$%@
//generate electric expenditures and shares
$@#$%@$@#$%@$@#$%@$@#$%@
*/

gen elect_expend= p_solar*c_solar + p_grid*c_grid
gen c_outside = mean_hh_income - elect_expend

sum elect_expend mean_hh_income
gen elec_share = elect_expend/mean_hh_income
sum elec_share c_outside mean_hh_income p_solar c_solar p_grid c_grid
xtset county_byte year

/*
!@#$!@#$!@#$!@#$!@#$
Create state-dummies and identifiers for constructing instruments
!@#$!@#$!@#$!@#$!@#$
*/


//need a list for each state of all the counties in that state - ie make list of sets of dummies
gen state_fips = floor(county_byte/1000)
sort state_from_TTS
tab state_from_TTS
//(0 observations deleted)
tab state_fips

//list of state codes we care about for coding dummies
global state_code_list "4	5	6	9	10	12	25	27	33	34	36	41	42	48	50	55"
tab state_from_TTS

/*save out
*/

save "$temp/gmm_input.dta", replace
use "$temp/gmm_input.dta", clear

/*
generate peak kw and cumulative kw instrument from EIA data here: https://www.eia.gov/renewable/monthly/solar_photo/pdf/renewable.pdf


National electricity price series: https://www.eia.gov/electricity/data/browser/#/topic/7?agg=0,1&geo=g&endsec=vg&linechart=ELEC.PRICE.US-ALL.A~~~&columnchart=ELEC.PRICE.US-ALL.A~ELEC.PRICE.US-RES.A~ELEC.PRICE.US-COM.A~ELEC.PRICE.US-IND.A&map=ELEC.PRICE.US-ALL.A&freq=A&ctype=linechart&ltype=pin&rtype=s&maptype=0&rse=0&pin=


Henry Hub Price Series: https://fred.stlouisfed.org/series/DHHNGSP#0



*/

//henry hub instrument
gen h_hub =.
replace h_hub=6.73124497991968 if year == 2006
replace h_hub=6.96718253968254 if year == 2007
replace h_hub=8.86252964426877 if year == 2008
replace h_hub=3.94265873015873 if year == 2009
replace h_hub=4.36972222222222 if year == 2010
replace h_hub=3.99630952380952 if year == 2011
replace h_hub=2.75448412698413 if year == 2012
replace h_hub=3.73126984126984 if year == 2013
replace h_hub=4.37269841269841 if year == 2014
replace h_hub=2.623984375 if year == 2015
replace h_hub=2.51597701149425 if year == 2016
replace h_hub=2.98803088803089 if year == 2017
replace h_hub=3.15266129032258 if year == 2018
replace h_hub=2.56092 if year == 2019
replace h_hub=2.02650980392157 if year == 2020
replace h_hub=3.89430278884462 if year == 2021
replace h_hub=6.4468 if year == 2022

reg p_grid h_hub , r




//merge HDD CDD instrument
gen STATE=state_from_TTS
drop state_from_TTS
merge m:1 year STATE using "$temp/NOAA_cdd_annual.dta", gen(merge_CDD)
keep if merge_CDD!=2
drop merge_CDD
/*
gen ln_CDDs = ln(CDDs)
*/
xtset county_byte year
reg p_grid d.CDDs CDDs , r
reg p_grid L.CDDs i.county_byte, r


reg p_grid CDDs i.state_code, r
reg p_grid HDDs , r




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

gen period_priceperwatt = period_shipments/peakkw

reg p_solar period_priceperwatt, r

/*
//Servicable first stage

. reg p_solar period_priceperwatt, r

Linear regression                               Number of obs     =      5,110
                                                F(1, 5108)        =     179.62
                                                Prob > F          =     0.0000
                                                R-squared         =     0.0487
                                                Root MSE          =     .06607

-------------------------------------------------------------------------------------
                    |               Robust
            p_solar | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
--------------------+----------------------------------------------------------------
period_priceperwatt |   .0134382   .0010027    13.40   0.000     .0114725    .0154039
              _cons |     .12763   .0014229    89.70   0.000     .1248405    .1304195
-------------------------------------------------------------------------------------

. 
end of do-file



*/


//country-level electric prices 
gen p_elec_us =.
replace p_elec_us = 8.9 if year==2006		
replace p_elec_us = 9.13 if year==2007		
replace p_elec_us = 9.74 if year==2008		
replace p_elec_us = 9.82 if year==2009		
replace p_elec_us = 9.83 if year==2010		
replace p_elec_us = 9.9 if year==2011		
replace p_elec_us = 9.84 if year==2012		
replace p_elec_us = 10.07 if year==2013		
replace p_elec_us = 10.44 if year==2014		
replace p_elec_us = 10.41 if year==2015		
replace p_elec_us = 10.27 if year==2016		
replace p_elec_us = 10.48 if year==2017		
replace p_elec_us = 10.53 if year==2018		
replace p_elec_us = 10.54 if year==2019		
replace p_elec_us = 10.59 if year==2020		
replace p_elec_us = 11.1 if year==2021		

reg p_grid p_elec_us , r
/*

 
. reg p_grid p_elec_us , r

Linear regression                               Number of obs     =      5,110
                                                F(1, 5108)        =     144.53
                                                Prob > F          =     0.0000
                                                R-squared         =     0.0269
                                                Root MSE          =     .03052

------------------------------------------------------------------------------
             |               Robust
      p_grid | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
   p_elec_us |   .0187979   .0015636    12.02   0.000     .0157325    .0218632
       _cons |  -.0585143   .0158878    -3.68   0.000    -.0896612   -.0273674
------------------------------------------------------------------------------

. 
end of do-file

. 

end of do-file
*/


/*
$@#$%@$@#$%@$@#$%@$@#$%@
Check panel
$@#$%@$@#$%@$@#$%@$@#$%@
*/

bysort  county_byte : gen total_obs = _N

preserve
collapse total_obs, by(county_byte)
tab total_obs
restore

/*

     (mean) |
  total_obs |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |          5        0.83        0.83
          2 |          4        0.67        1.50
          3 |          7        1.16        2.66
          4 |          8        1.33        3.99
          5 |         10        1.66        5.66
          6 |          7        1.16        6.82
          7 |         23        3.83       10.65
          8 |         42        6.99       17.64
          9 |        495       82.36      100.00
------------+-----------------------------------
      Total |        601      100.00

. restore

. 


*/

/*
$@#$%@$@#$%@$@#$%@$@#$%@
Section 1. Estimations
$@#$%@$@#$%@$@#$%@$@#$%@
*/


/*
$@#$%@$@#$%@$@#$%@$@#$%@
Force idiosyncratic weights at state level
$@#$%@$@#$%@$@#$%@$@#$%@
*/

global P_state_E "((1- {xg:})^( {rho})*p_solar^(1- {rho}) + {xg:}^( {rho})*p_grid^(1- {rho}))^(1/(1- {rho}))"
global P_state_C "((1- {xd:})^ {kappa} + {xd: }^ {kappa} *($P_state_E)^ (1- {kappa}))^(1/(1- {kappa}))"

display "$P_state_E $P_state_C"

//generate gamma and delta dummies as well as state-level instruments
foreach i of numlist $state_code_list  {
    
    gen state_gamma_`i' = (state_fips==`i')
    gen state_delta_`i' = (state_fips==`i')
    gen state_kappa_`i' = (state_fips==`i')
    gen state_rho_`i' = (state_fips==`i')
    gen state_z_`i' = (state_fips==`i')*period_priceperwatt
    gen state_lon_z_`i' = (state_fips==`i')*period_priceperwatt*lon
    gen p_elec_us_`i' = (state_fips==`i')*p_elec_us
	//gen state_cdd_`i' = (state_fips==`i')*log(CDDs)
	gen state_cdd_`i' = (state_fips==`i')*log(L.CDDs)
    gen h_hub_`i' = (state_fips==`i')*h_hub
}



/*
$@#$%@$@#$%@$@#$%@$@#$%@
Prefered specification: State level weights plus non-homothetic terms plus other instruments
$@#$%@$@#$%@$@#$%@$@#$%@
*/

//Note instrument of state_lon_z_ is valid here -- prices increase in longitude going east.
reg p_solar lon 
reg p_solar lon lat
reg p_solar lon lat daily_solar_flux_fixed


/*
$@#$%@$@#$%@$@#$%@$@#$%@
//baseline estimate: 

	(1) two price instruments interacted with residuals from structural demand eqations when evaluated at those parameter values along with 
	(2)  this estimator sets the expectation of structural demand errors in each state to zero along with those errors interacted with instruments
$@#$%@$@#$%@$@#$%@$@#$%@
*/

 set maxiter 300
 
 



/*
twostep step estimator ---- robust standard errors
*/
gmm (eq1: log(c_grid)  - log( {gbar=1000} + ( {xg:	state_gamma_* }/p_grid)^ {rho=4} *$P_state_E^ ( {rho}-1) *(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq2: log(c_solar) - log( {sbar} + ((1- {xg: })/p_solar)^ {rho}*$P_state_E^ ( {rho}-1)*(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq3: log(c_outside) - log( (1- {xd: state_delta_* })^( {kappa=0.5})*$P_state_C^ ( {kappa}-1) * (mean_hh_income - {sbar} * p_solar - {gbar}*p_grid ) ) ), ///
    twostep winitial(identity)  vce(robust) ///
    instruments(eq1: state_lon_z_* h_hub_* state_gamma_*, noconstant) ///
    instruments(eq2:  state_lon_z_* h_hub_* state_gamma_*, noconstant) ///
    instruments(eq3: state_lon_z_* h_hub_*  state_gamma_*, noconstant) ///
    from(	state_gamma_4 0.9 	state_gamma_5 0.9 	state_gamma_6 0.9 	state_gamma_9 0.9 	state_gamma_10 0.9 	state_gamma_12 0.9 		  	state_gamma_25 0.9 	 	state_gamma_27 0.9  	state_gamma_33 0.9 	state_gamma_34 0.9 	state_gamma_36 0.9 	state_gamma_41 0.9 	state_gamma_42 0.9 	state_gamma_48 0.9 	state_gamma_50 0.9  state_gamma_55 0.9 	state_delta_4 0.1 	state_delta_5 0.1 	state_delta_6 0.1 	state_delta_9 0.1 	state_delta_10 0.1 	state_delta_12 0.1 	 	state_delta_25 0.1 	state_delta_27 0.1 state_delta_33 0.1 	state_delta_34 0.1 	state_delta_36 0.1 	state_delta_41 0.1 	state_delta_42 0.1 	state_delta_48 0.1 	state_delta_50 0.1 	 state_delta_55 0.1)
    
	
	

//save out these estimates
//estimates save "$sters/main_est_6_25.ster", replace
estimates use "$sters/main_est_6_25.ster"
estimates replay
estat overid


/*
//twostep step estimator ----  bootstrapped standard errors
*/
gmm (eq1: log(c_grid)  - log( {gbar=1000} + ( {xg:	state_gamma_* }/p_grid)^ {rho=4} *$P_state_E^ ( {rho}-1) *(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq2: log(c_solar) - log( {sbar} + ((1- {xg: })/p_solar)^ {rho}*$P_state_E^ ( {rho}-1)*(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq3: log(c_outside) - log( (1- {xd: state_delta_* })^( {kappa=0.5})*$P_state_C^ ( {kappa}-1) * (mean_hh_income - {sbar} * p_solar - {gbar}*p_grid ) ) ), ///
    twostep winitial(identity)  vce(bootstrap, reps(50)) ///
    instruments(eq1: state_lon_z_* h_hub_* state_gamma_*, noconstant) ///
    instruments(eq2:  state_lon_z_* h_hub_* state_gamma_*, noconstant) ///
    instruments(eq3: state_lon_z_* h_hub_*  state_gamma_*, noconstant) ///
    from(	state_gamma_4 0.9 	state_gamma_5 0.9 	state_gamma_6 0.9 	state_gamma_9 0.9 	state_gamma_10 0.9 	state_gamma_12 0.9 		  	state_gamma_25 0.9 	 	state_gamma_27 0.9  	state_gamma_33 0.9 	state_gamma_34 0.9 	state_gamma_36 0.9 	state_gamma_41 0.9 	state_gamma_42 0.9 	state_gamma_48 0.9 	state_gamma_50 0.9  state_gamma_55 0.9 	state_delta_4 0.1 	state_delta_5 0.1 	state_delta_6 0.1 	state_delta_9 0.1 	state_delta_10 0.1 	state_delta_12 0.1 	 	state_delta_25 0.1 	state_delta_27 0.1 state_delta_33 0.1 	state_delta_34 0.1 	state_delta_36 0.1 	state_delta_41 0.1 	state_delta_42 0.1 	state_delta_48 0.1 	state_delta_50 0.1 	 state_delta_55 0.1)
    
//save out 2, bootsrapped
//estimates save "$sters/main_est_6_25_BS.ster", replace
estimates use "$sters/main_est_6_25_BS.ster"
estimates replay
estat overid


/*
//twostep step estimator ----  markups
*/

preserve
replace p_solar = 1.05 * p_solar


gmm (eq1: log(c_grid)  - log( {gbar=1000} + ( {xg:	state_gamma_* }/p_grid)^ {rho=4} *$P_state_E^ ( {rho}-1) *(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq2: log(c_solar) - log( {sbar} + ((1- {xg: })/p_solar)^ {rho}*$P_state_E^ ( {rho}-1)*(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq3: log(c_outside) - log( (1- {xd: state_delta_* })^( {kappa=0.5})*$P_state_C^ ( {kappa}-1) * (mean_hh_income - {sbar} * p_solar - {gbar}*p_grid ) ) ), ///
    twostep winitial(identity)  vce(robust) ///
    instruments(eq1: state_lon_z_* h_hub_* state_gamma_*, noconstant) ///
    instruments(eq2:  state_lon_z_* h_hub_* state_gamma_*, noconstant) ///
    instruments(eq3: state_lon_z_* h_hub_*  state_gamma_*, noconstant) ///
    from(	state_gamma_4 0.9 	state_gamma_5 0.9 	state_gamma_6 0.9 	state_gamma_9 0.9 	state_gamma_10 0.9 	state_gamma_12 0.9 		  	state_gamma_25 0.9 	 	state_gamma_27 0.9  	state_gamma_33 0.9 	state_gamma_34 0.9 	state_gamma_36 0.9 	state_gamma_41 0.9 	state_gamma_42 0.9 	state_gamma_48 0.9 	state_gamma_50 0.9  state_gamma_55 0.9 	state_delta_4 0.1 	state_delta_5 0.1 	state_delta_6 0.1 	state_delta_9 0.1 	state_delta_10 0.1 	state_delta_12 0.1 	 	state_delta_25 0.1 	state_delta_27 0.1 state_delta_33 0.1 	state_delta_34 0.1 	state_delta_36 0.1 	state_delta_41 0.1 	state_delta_42 0.1 	state_delta_48 0.1 	state_delta_50 0.1 	 state_delta_55 0.1)
    
	
	


//save out these estimates
estimates save "$sters/markup_est_6_25.ster", replace
estimates replay
estat overid

restore




//monte carlo 
matrix kappa = [.]
matrix rho = [.]
matrix gamma_california = [.]
matrix delta_california = [.]
matrix sbar = [.]
matrix gbar = [.]
matrix markup = [.]

//loop over markups
qui{
	//select number of leads as two years
		forvalues i = 0.1(0.1)1 {
			preserve

				//markups
				replace p_solar = (1 + `i') * p_solar
				
				//run estimation 
				gmm (eq1: log(c_grid)  - log( {gbar=1000} + ( {xg:	state_gamma_* }/p_grid)^ {rho=4} *$P_state_E^ ( {rho}-1) *(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq2: log(c_solar) - log( {sbar} + ((1- {xg: })/p_solar)^ {rho}*$P_state_E^ ( {rho}-1)*(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq3: log(c_outside) - log( (1- {xd: state_delta_* })^( {kappa=0.5})*$P_state_C^ ( {kappa}-1) * (mean_hh_income - {sbar} * p_solar - {gbar}*p_grid ) ) ), ///
    twostep winitial(identity)  vce(robust) ///
    instruments(eq1: state_lon_z_* h_hub_* state_gamma_*, noconstant) ///
    instruments(eq2:  state_lon_z_* h_hub_* state_gamma_*, noconstant) ///
    instruments(eq3: state_lon_z_* h_hub_*  state_gamma_*, noconstant) ///
    from(	state_gamma_4 0.9 	state_gamma_5 0.9 	state_gamma_6 0.9 	state_gamma_9 0.9 	state_gamma_10 0.9 	state_gamma_12 0.9 		  	state_gamma_25 0.9 	 	state_gamma_27 0.9  	state_gamma_33 0.9 	state_gamma_34 0.9 	state_gamma_36 0.9 	state_gamma_41 0.9 	state_gamma_42 0.9 	state_gamma_48 0.9 	state_gamma_50 0.9  state_gamma_55 0.9 	state_delta_4 0.1 	state_delta_5 0.1 	state_delta_6 0.1 	state_delta_9 0.1 	state_delta_10 0.1 	state_delta_12 0.1 	 	state_delta_25 0.1 	state_delta_27 0.1 state_delta_33 0.1 	state_delta_34 0.1 	state_delta_36 0.1 	state_delta_41 0.1 	state_delta_42 0.1 	state_delta_48 0.1 	state_delta_50 0.1 	 state_delta_55 0.1)
    
	
				
				
				//kick out parameters 
				matrix kappa = kappa \ /kappa
				matrix rho = rho \ /rho
				matrix gamma_california = gamma_california \ [xg]state_gamma_6
				matrix delta_california = delta_california \ [xd]state_delta_6
				matrix sbar = sbar \ /sbar
				matrix gbar = gbar \ /gbar
				matrix markup = markup \ `i'
				

		
			
			restore
	}
	
}

 //Lagged terms pre-treatment



svmat kappa
svmat rho
svmat sbar
svmat gamma_california
svmat delta_california
svmat gbar
svmat markup


/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
Part 1.3: Unused (alternative) model specifications
!!@#$!@#$!@#$
!!@#$!@#$!@#$
*/



	


/*
$@#$%@$@#$%@$@#$%@$@#$%@
//homothetic version at country level for reference parameter values
$@#$%@$@#$%@$@#$%@$@#$%@
*/

gmm (eq1: log(c_grid)  - log( ( {gamma=0.9}/p_grid) ^ {rho=2} * $P_E^ ( {rho}-1) *(elect_expend))) ///
            (eq2: log(c_solar) - log(((1- {gamma})/p_solar) ^ {rho} * $P_E^ ( {rho}-1) *(elect_expend))) ///
            (eq3: log(c_outside) - log( (1- {delta=0.02})^( {kappa=0.5})*$P_C^ ( {kappa}-1) * (mean_hh_income) ) ), ///
            twostep winitial(identity) vce(robust)  ///
            instruments(eq1: period_priceperwatt p_elec_us) ///
            instruments(eq2: period_priceperwatt p_elec_us) ///
            instruments(eq3: period_priceperwatt p_elec_us) 
			
			
gmm (eq1: log(c_grid)  - log( ( {gamma=0.9}/p_grid) ^ {rho=4} * $P_E^ ( {rho}-1) *(elect_expend))) ///
            (eq2: log(c_solar) - log(((1- {gamma})/p_solar) ^ {rho} * $P_E^ ( {rho}-1) *(elect_expend))) ///
            (eq3: log(c_outside) - log( (1- {delta=0.02})^( {kappa=0.1})*$P_C^ ( {kappa}-1) * (mean_hh_income) ) ), ///
            twostep winitial(identity) vce(robust)  ///
            instruments(eq1: period_priceperwatt h_hub) ///
            instruments(eq2: period_priceperwatt h_hub) ///
            instruments(eq3: period_priceperwatt h_hub) 

//save out
estimates save "$sters/nat_level_homothetic.ster", replace	
estimates use "$sters/nat_level_homothetic.ster"	
estimates replay
estat overid


			



/*
$@#$%@$@#$%@$@#$%@$@#$%@
one step estimator ---- national price instrument
$@#$%@$@#$%@$@#$%@$@#$%@
*/



/*
*/

gmm (eq1: log(c_grid)  - log( {gbar=1000} + ( {xg:	state_gamma_* }/p_grid)^ {rho=2} *$P_state_E^ ( {rho}-1) *(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq2: log(c_solar) - log( {sbar} + ((1- {xg: })/p_solar)^ {rho}*$P_state_E^ ( {rho}-1)*(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq3: log(c_outside) - log( (1- {xd: state_delta_* })^( {kappa=1.5})*$P_state_C^ ( {kappa}-1) * (mean_hh_income - {sbar} * p_solar - {gbar}*p_grid ) ) ), ///
    onestep winitial(identity) vce(robust)  ///
    instruments(eq1: state_z_* p_elec_us_* state_gamma_*, noconstant) ///
    instruments(eq2:  state_z_* p_elec_us_* state_gamma_*, noconstant) ///
    instruments(eq3: state_z_* p_elec_us_*  state_gamma_*, noconstant) ///
    from(	state_gamma_4 0.9 	state_gamma_5 0.9 	state_gamma_6 0.9 	state_gamma_9 0.9 	state_gamma_10 0.9 	state_gamma_12 0.9 		  	state_gamma_25 0.9 	 	state_gamma_27 0.9  	state_gamma_33 0.9 	state_gamma_34 0.9 	state_gamma_36 0.9 	state_gamma_41 0.9 	state_gamma_42 0.9 	state_gamma_48 0.9 	state_gamma_50 0.9  state_gamma_55 0.9 	state_delta_4 0.1 	state_delta_5 0.1 	state_delta_6 0.1 	state_delta_9 0.1 	state_delta_10 0.1 	state_delta_12 0.1 	 	state_delta_25 0.1 	state_delta_27 0.1 state_delta_33 0.1 	state_delta_34 0.1 	state_delta_36 0.1 	state_delta_41 0.1 	state_delta_42 0.1 	state_delta_48 0.1 	state_delta_50 0.1 	 state_delta_55 0.1)
	
	

/*	
//twostep step estimator ----  CDDs as instrument
*/
gmm (eq1: log(c_grid)  - log( {gbar=1000} + ( {xg:	state_gamma_* }/p_grid)^ {rho=4} *$P_state_E^ ( {rho}-1) *(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq2: log(c_solar) - log( {sbar} + ((1- {xg: })/p_solar)^ {rho}*$P_state_E^ ( {rho}-1)*(elect_expend - {sbar} * p_solar - {gbar}*p_grid ))) ///
    (eq3: log(c_outside) - log( (1- {xd: state_delta_* })^( {kappa=0.5})*$P_state_C^ ( {kappa}-1) * (mean_hh_income - {sbar} * p_solar - {gbar}*p_grid ) ) ), ///
    twostep winitial(identity)  vce(robust) technique(bfgs) ///
    instruments(eq1: state_lon_z_* state_cdd_* state_gamma_*, noconstant) ///
    instruments(eq2:  state_lon_z_* state_cdd_* state_gamma_*, noconstant) ///
    instruments(eq3: state_lon_z_* state_cdd_*  state_gamma_*, noconstant) ///
    from(	state_gamma_4 0.9 	state_gamma_5 0.9 	state_gamma_6 0.9 	state_gamma_9 0.9 	state_gamma_10 0.9 	state_gamma_12 0.9 		  	state_gamma_25 0.9 	 	state_gamma_27 0.9  	state_gamma_33 0.9 	state_gamma_34 0.9 	state_gamma_36 0.9 	state_gamma_41 0.9 	state_gamma_42 0.9 	state_gamma_48 0.9 	state_gamma_50 0.9  state_gamma_55 0.9 	state_delta_4 0.1 	state_delta_5 0.1 	state_delta_6 0.1 	state_delta_9 0.1 	state_delta_10 0.1 	state_delta_12 0.1 	 	state_delta_25 0.1 	state_delta_27 0.1 state_delta_33 0.1 	state_delta_34 0.1 	state_delta_36 0.1 	state_delta_41 0.1 	state_delta_42 0.1 	state_delta_48 0.1 	state_delta_50 0.1 	 state_delta_55 0.1)
  





	
	

/*
$@#$%@$@#$%@$
$@#$%@$@#$%@$@#$%@$@#$%@
Part 2: Generate closed form solutions for baseline model from the parameters 
$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$
*/


use "$temp/gmm_input.dta", clear


//CES parameters
gen state_gamma=.
gen state_delta=.
gen state_kappa=.
gen state_rho=.

//reference parameters
gen sbar = .
gen gbar = .

/* state codes to loop over*/


global state_code_list "4	5	6	9	10	12	25	27	33	34	36	41	42	48	50	55"

/*
$@#$%@$@#$%@$@#$%@$@#$%@
Loop to set parameters from state-level estimates
$@#$%@$@#$%@$@#$%@$@#$%@
*/

estimates use "$sters/main_est_6_25.ster"

//replace common parameter values
replace sbar = /sbar 
replace gbar = /gbar
replace state_kappa = /kappa  
replace state_rho = /rho  	

//loop over states
foreach i of numlist $state_code_list  {

    local delta_dummy = "[xd]state_delta_" + "`i'"
    local gamma_dummy = "[xg]state_gamma_" + "`i'"
    replace state_delta = `delta_dummy'  if state_fips==`i'
    replace state_gamma = `gamma_dummy'  if state_fips==`i'
}
sum state_gamma state_delta, d
/*
$@#$%@$@#$%@$@#$%@$@#$%@
Solve for fitted values from  model$
$@#$%@$@#$%@$@#$%@$@#$%@
*/

//
//baseline model values
//

gen P_E_bl = ((1-state_gamma)^(state_rho)*p_solar^(1-state_rho) + state_gamma^(state_rho)*p_grid^(1-state_rho))^(1/(1-state_rho))
gen P_bl = ( (1-state_delta)^state_kappa + state_delta^state_kappa *(P_E_bl)^(1-state_kappa))^(1/(1-state_kappa))
gen X_E_bl = (mean_hh_income - p_grid * gbar - p_solar * sbar ) * state_delta^state_kappa * P_E_bl^(1-state_kappa) *P_bl^(state_kappa-1)
gen c_bl = (mean_hh_income - p_grid * gbar - p_solar * sbar ) - X_E_bl
gen g_bl = gbar +  state_gamma ^(state_rho)*p_grid ^(-state_rho)*P_E_bl^(state_rho-1)*X_E_bl
gen s_bl = sbar + (1-state_gamma) ^(state_rho)*p_solar^(-state_rho)*P_E_bl^(state_rho-1)*X_E_bl


//homothetic case
// P_E_bl = ((1-state_gamma)^(state_rho)*p_solar^(1-state_rho) + state_gamma^(state_rho)*p_grid^(1-state_rho))^(1/(1-state_rho))
// gen P_bl = ( (1-state_delta)^state_kappa + state_delta^state_kappa *(P_E_bl)^(1-state_kappa))^(1/(1-state_kappa))
// gen X_E_bl = (mean_hh_income) * state_delta^state_kappa * P_E_bl^(1-state_kappa) *P_bl^(state_kappa-1)
// gen c_bl = (mean_hh_income) - X_E_bl
// gen g_bl =  state_gamma ^(state_rho)*p_grid ^(-state_rho)*P_E_bl^(state_rho-1)*X_E_bl
// gen s_bl = (1-state_gamma) ^(state_rho)*p_solar^(-state_rho)*P_E_bl^(state_rho-1)*X_E_bl
//



gen elec_share_bl = 1 - (c_bl/mean_hh_income)
sum elec_share_bl

//sanity checks on parameter outcomes
sum state_gamma state_delta state_kappa state_rho gbar sbar 
sum state_gamma state_delta state_kappa state_rho gbar sbar, d

//check expenditure zeros
gen total_expend = c_bl + p_solar * s_bl + p_grid*g_bl
corr total_expend mean_hh_income

/*
Winzorize at 0.5% level
*/

preserve
 xtile solar_pctiles = s_bl, nquantiles(200)
 keep if solar_pctiles<200
//(25 observations deleted)

//1%
//  xtile solar_pctiles = s_bl, nquantiles(100)
//  keep if solar_pctiles<100

//2%
//  xtile solar_pctiles = s_bl, nquantiles(50)
//  keep if solar_pctiles<50

/*
Non-targeted moments
*/
gen  model_sg_ratio = s_bl/g_bl 
rename elec_share_bl model_elec_share

corr c_solar s_bl c_grid g_bl 

/*

. 
             |  c_solar     s_bl   c_grid     g_bl
-------------+------------------------------------
     c_solar |   1.0000
        s_bl |   0.7188   1.0000
      c_grid |  -0.3342  -0.3389   1.0000
        g_bl |  -0.3164  -0.3305   0.8612   1.0000




*/
/*
Un-Targeted Sample Moments

elec_share -- electricity expenditure shares
*/

gen sample_sg_ratio = c_solar/c_grid
rename elec_share sample_elec_share
 
/*
Test measured vs. model-predicted values in sample
*/

 //*Compare
sum model_sg_ratio sample_sg_ratio model_elec_share sample_elec_share  
sum model_sg_ratio sample_sg_ratio model_elec_share sample_elec_share  ,d 
/*

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
model_sg_r~o |      5,085    .0077163    .0239282   .0000309   .2935091
sample_sg_~o |      5,085    .0093345     .026743   4.20e-06   .3135438
model_elec~e |      5,085    .0197372    .0044247    .010273   .0338758
sample_ele~e |      5,085    .0197954    .0058304     .00779   .0483687

*/


sum c_solar s_bl c_grid g_bl
sum c_solar s_bl c_grid g_bl , d


/*

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
     c_solar |      5,085    66.55395    173.8762   .0589737   1827.028
        s_bl |      5,085    52.74298    146.6797   .6024617   1593.255
      c_grid |      5,085    10153.59    3038.239   4488.054   19632.39
        g_bl |      5,085    10368.77      3366.7   5100.336   23685.09



. 
*/
sum c_solar s_bl, d
sum c_grid g_bl, d 
sum model_sg_ratio sample_sg_ratio model_elec_share sample_elec_share  [fw=household_count]
sum c_solar s_bl c_grid g_bl  [fw=household_count]


//Model Fit


//R^2s


// model vs. sample solar grid ratio 
gen errors_2 = (sample_sg_ratio - model_sg_ratio)^2
egen mean = mean(sample_sg_ratio)
gen resid_2 = (sample_sg_ratio - mean)^2
egen tss = sum(resid_2)
egen sse = sum(errors_2)
gen R_squared_sg = 1 - sse/tss
drop errors_2 mean resid_2 tss sse 


// model vs. sample model_elec_share
gen errors_2 = (sample_elec_share - model_elec_share)^2
egen mean = mean(sample_elec_share)
gen resid_2 = (sample_elec_share - mean)^2
egen tss = sum(resid_2)
egen sse = sum(errors_2)
gen R_squared_elecshare = 1 - sse/tss
drop errors_2 mean resid_2 tss sse 

// model vs. sample solar consumption
gen errors_2 = (c_solar - s_bl)^2
egen mean = mean(c_solar)
gen resid_2 = (c_solar - mean)^2
egen tss = sum(resid_2)
egen sse = sum(errors_2)
gen R_squared_solar= 1 - sse/tss
drop errors_2 mean resid_2 tss sse 

// model vs. sample electricity_consume_residential
gen errors_2 = (c_grid - g_bl)^2
egen mean = mean(c_grid)
gen resid_2 = (c_grid - mean)^2
egen tss = sum(resid_2)
egen sse = sum(errors_2)
gen R_squared_grid = 1 - sse/tss
drop errors_2 mean resid_2 tss sse 


sum R_squared*

/*

0.5%


. sum R_squared*

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
R_squared_sg |      5,085     .567072           0    .567072    .567072
R_squared_~e |      5,085    .7490633           0   .7490633   .7490633
R_squared_~r |      5,085    .4947659           0   .4947659   .4947659
R_squared_~d |      5,085    .6756899           0   .6756899   .6756899


*/

//ttests for equal mmeans
ttest model_elec_share == sample_elec_share, unpaired unequal welch
//can't reject   at 5%
ttest model_sg_ratio == sample_sg_ratio, unpaired unequal welch
//reject at 5%
ttest c_solar == s_bl, unpaired unequal welch
//reject at 5%
ttest c_grid == g_bl, unpaired unequal welch
//reject 5%

restore


/*
$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@

Part 2: Decompose estimated preference parameters from et of static observations from latest year for extrapolation

$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@
$@#$%@$@#$%@$@#$%@$@#$%@
*/

//keep latest year in each county-dummies
keep if count_obs==count_index
count 
//  601





reg state_gamma daily_solar_flux_fixed average_household_income gini_index diversity education_less_than_high_school_   population_density mortgage_with_rate heating_degree_days   cooling_degree_days land_area housing_unit_median_value	housing_unit_median_gross_rent	lat	lon	elevation	heating_design_temperature	cooling_design_temperature	earth_temperature_amplitude	frost_days	air_temperature	relative_humidity	atmospheric_pressure	wind_speed	earth_temperature  , vce(cluster state_fips)

estimates save "$sters/gammas.ster", replace
            

            
            
            
reg state_delta daily_solar_flux_fixed average_household_income gini_index diversity education_less_than_high_school_   population_density mortgage_with_rate heating_degree_days   cooling_degree_days land_area housing_unit_median_value	housing_unit_median_gross_rent	lat	lon	elevation	heating_design_temperature	cooling_design_temperature	earth_temperature_amplitude	frost_days	air_temperature	relative_humidity	atmospheric_pressure	wind_speed	earth_temperature  , vce(cluster state_fips)

estimates save "$sters/deltas.ster", replace
            
            
save "$temp/gmm_fitted.dta", replace

