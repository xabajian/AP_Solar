/*
!!@#$!@#$!@#$
!!@#$!@#$!@#$
!!@#$!@#$!@#$
ACA
11/24/2021


Do file to calculate county-level LCOEs



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
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$!@#$!@#$!@$!@$!#@$
!*/

keep if county_byte!=.

gen fips5 = county_byte
merge m:1 fips5 using "$processed/DeepSolar_CountyData_2023.dta", gen(merge_flux)
drop if merge_flux!=3 

/*
!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$

First, we calculate the total level of annual solar generation for each system in the counties we have successful mappings for 


Ok, of the data we have mapped, the annual generation is :
		generation is panel area * efficiency * power

		system size (kW) * 1 (kW/m^2) *(1/efficiency) * daily_flux (kWh/m2) *365.25 days per year * efficiency  (~17.11%)
		
 PV of 30 years' generation discounted at 3% with 1% degredation is 17.90277093 times initial flow value taken from https://pubs.rsc.org/en/content/articlepdf/2011/ee/c0ee00698j with defensible assumptions as some other LCOE estimates
		
			https://reader.elsevier.com/reader/sd/pii/S0301421516301860?token=D6FB016ECFC59E057099B61DB6335AC320AE5CE3A70C62B51D6854D3B4EB1F0106E79F2839A6DE360A8768F734F2B26C

!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$
!@#$!@#$!@$!@$!#@$

*/

gen flag_missing_efficiency = (moduleefficiency1==-9999)
replace moduleefficiency1=. if moduleefficiency1==-9999
drop if moduleefficiency1<0
//these observations must be coded wrong and are discared.



/*
For entries with missing panel efficiency information, I'm going to use the median efficiency for panels installed in that county in that year.
*/


bysort year: egen year_median_efficiency = median(moduleefficiency1)
bysort year state: egen year_county_median_efficiency = median(moduleefficiency1)
replace moduleefficiency1 = year_county_median_efficiency if moduleefficiency1==.
//replace missing entries
replace moduleefficiency1 = year_median_efficiency if moduleefficiency1==.

/*
Calculate annual generation for each system using formulas outlined above
*/
	
gen annual_generation = systemsize  / moduleefficiency1  * daily_solar_flux_fixed *365.25 * moduleefficiency1
	//see above for details

/*
Now, we can calculate prices (using the  LCOE measure) at the county level.

We will have to ignore entries that display a system size but are missing prices, 
but ultimately use average prices at the county level
*/

gen flag_missing_prices = (totalinstalledprice==-9999  | rebateorgrant==-9999 | salestaxcost==-9999 | feedintariffannualpayment==-9999 |performancebasedincentiveannualp==-9999)


	replace totalinstalledprice = . if totalinstalledprice==-9999
	replace rebateorgrant = . if rebateorgrant==-9999
	replace salestaxcost = . if salestaxcost==-9999
	replace performancebasedincentiveannualp = . if performancebasedincentiveannualp==-9999
	replace feedintariffannualpayment = . if feedintariffannualpayment==-9999
  
tab flag_missing_prices
tab flag_missing_prices, sum(systemsize)


/*

A lot of capacity is missing prices, just as module efficiency was missing before.

I will perform an analagous exerciseto calculate the share of capacity missing installation prices.

*/


generate size_x_flag = systemsize if  flag_missing_prices==0
	replace size_x_flag=0 if size_x_flag==.

bysort state: egen total_state_cap=total(systemsize)
bysort state: egen state_nomissing_prices_total=total(size_x_flag) 
gen state_missing_prices_share = 1- state_nomissing_prices_total/total_state_cap
drop if state_missing_prices_share==1

/*

Now, we calculate LCOEs.

The formulas are in the paper, section 4


We are given the year-1 flow values of the feed-in tariff and PBI payments as well as the duration. Treating these as annuities we have that for a finite geo series,

	\sum_0 ^n-1 (ar^k) = a (1-r^n) / (1-r)
		
		https://en.wikipedia.org/wiki/Geometric_series


r_depreciation =(1-DR) x 1/(1+r) = 0.99/1.03 = 0.961165049


r_maintenance = x (1/1+r) = 0.0097087378640776699029126213592233009708737864077669902912621359
The long numbers in the numerator and denominator are the NPV values for unit genegeneration and fixed costs respectively.

*/

gen NPV_PBI = performancebasedincentiveannualp * (1 - 0.961165049^(performancebasedincentivesdurati+1))/(1 - 0.961165049)
gen NPV_FIT = feedintariffannualpayment* (1 - 0.961165049^(feedintariffduration+1))/(1 - 0.961165049)


gen LCOE_gross_cost = ((1+ 0.20188)* totalinstalledprice + salestaxcost) / (annual_generation*17.90277093 )

gen LCOE_all_subs = ((1+ 0.20188)* totalinstalledprice + salestaxcost -rebateorgrant - NPV_PBI - NPV_FIT)  / (annual_generation*17.90277093 )

gen post_2005_dummy = (year>2005)
gen pre_2005_dummy = (post_2005_dummy==0)
gen LCOE_all_subs_ITC = ((0.7*post_2005_dummy+ pre_2005_dummy + 0.20188)* totalinstalledprice + salestaxcost -rebateorgrant - NPV_PBI - NPV_FIT)  / (annual_generation*17.90277093 )




/*

The following command drops some outliers that have exceptionally large leverage
and  that almost certainly stem from coding errors:

It's almost impossible that a system was installed at a negative price before
subsidies -- it's equaully unlikely that the price of installation was over 1000
times the average price that year.

Also droppng systems larger than 100kW or smaller than 0.5kw as discuesed in text
*/
drop if LCOE_gross_cost>20 | LCOE_gross_cost<0
drop if systemsize>100 | systemsize<0.5

collapse  LCOE_all_subs LCOE_gross_cost LCOE_all_subs_ITC [aw = systemsize], by(county_byte)
