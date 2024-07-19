# Abajian and Pretnar 2024

Read me file accompanying the scripts required to replicate findings in the main text and appendix “Subsidies for Close Substitutes: Aggregate Demand for Residential Solar Electricity”

Questions concerning running the code here or with replicating analysis performed in the peer review process should be directed to xander.abajian@gmail.com.

## Setup

Scripts in this repository are written in a combination of Stata, R, and Python. Throughout this document, it is assumed that the replicator operates from a working directory containing all the necessary files and folders detailed in the structure below. Most importantly, a replicator must download the associated data repository from Zenodo at [https://doi.org/10.5281/zenodo.12749922](https://doi.org/10.5281/zenodo.12749922). To run the Stata scripts, this folder should be set as the root directory and the global macro $root should correspond to the folder containing all files in "_Data_postAER". (IE,  global root "{~/_Data_postAER}" needs to be run).

## Requirements


All programs run in the following versions of these applications:

* Stata: Stata/SE 18.0 for Mac (Apple Silicon)
* R: RStudio 2022.12.0+353 
* Python: Python 3.11.1 64bit for Mac


To run the Stata scripts, one must set their root directory to be the folder containing _Data_postAER. All other macros should then be internally consistent.

To run the python and R scripts, more directory manipulation may be needed depending on how a replicator has configured their environment.



# File Tree 

```bash
└── scripts
  ├── 0_county_level_deepsolar.do
  ├── 0_deep_solar_regressions.do
  ├── 0_hudcrosswalk.do
  ├── 0_read_861_electricity.do
  ├── 0_read_ACS_income.do
  ├── 0_read_BB_2022_damages.do
  ├── 0_state_lat_lon_pairs.do
  ├── 1_Read_TTS.do
  ├── 1_solar API calls_2023.py
  ├── 2_GMM_estimation.do
  ├── 3_LCOE_Calculations.do
  ├── 3_external_validation_2023.do
  ├── 4_Counterfactuals.do
  ├── 5_EIA_Gas.do
  ├── 5_EIA_residentialsolar_monthly.do
  ├── 5_hdd_cdd.do
  ├── APP_1_PPW_Decomp_2023.do
  └── R_maps_2023.R


```


# Description of Scripts to Replicate our Analysis


The numerical prefixes to each script denote the order in which they should be executed to replicate findings in our paper. The order within sections should be executed as written below.


## Section 0 

Files in this section essentially read in all raw data we use in various portions of the paper. These data are almost always drawn directly from the “_Data_postAER/raw” directory.


`0_county_level_deepsolar.do`: This folder reads in the _DeepSolar_ dataset from Yu et al. (2018) and aggregates the census-tract level data up to the county level resolution we use in later analysis and saves them into our data directory.

`0_deep_solar_regressions.do`: Performs regressions as-specified in section 2.2 of the draft. This reads in the deepsolar dataset and runs these regressions with no extra analysis — we take the dataset as given.

`0_read_861_electricity`: Reads in utility-by-county specific average residential electricity prices and consumption at the annual level. These data are drawn directly from the EIA’s form 861 files available from the EIA website. It reads each individual excel file, maps each year into county-level data using the crosswalk EIA provides for 2018, and then saves them into a panel.

`0_hudcrosswalk.do`: Creates our crosswalk between zip codes and counties. This is needed to map system-level installations into counties (our unit of analysis) in the main text. The procedure to deal with zip codes that overlay multiple counties is described in detail in the script.

`0_read_ACS_income.do`: Reads in county-level average household income levels for the years 2010-2018 from underlying data tables from the ACS.

`0_read_BB_2022_damages.do`: Reads in Borenstein and Bushnell (2022) estimates for the marginal external costs and marginal carbon emissions that result from marginal electricity demand changes at the county level

`0_state_lat_lon_pairs.do`: Creates population-weighted state-level latitude-longitude centroids from census-tract level data.

## Section 1  

`1_Read_TTS.do`: This script processes the raw tracking the sun dataset taken from the national renewable energy laboratory’s tracking the sun project (Barbose 2019). Included in this script is all data cleaning procedures described in more detail in the main text and appendix. This script produces the panel dataset of solar prices and quantities at the county level we use for estimation as well as tracking prices over time in figure 3. This includes calculating the levelized cost of energy for the counties in each time period we observe. It then combines these data with our panel of electricity prices and saves them into our data directory for estimating in section 2.

`1_solar API calls_2023.py`: This script calls LBNL’s PVWatts API to estimate average system level PV generation in each of the approximately 820 counties for which we observe solar generation (note this is not the same as counties we use for estimation in which we construct both quantities and prices). This script will not run without an API key for the PVWatts API — one should be able to request a new one from LBNL as it is a public interface.


## Section 2 

`2_GMM_estimation.do`: Performs the estimation procedure described in section 4 of the main text. This includes constructing the relevant time series for both instruments (solar module import prices and Henry hub natural gas contracts) as well as interacting them with county-level longitudes. The script then estimates the model using Stata’s GMM routine and then repeats this for bootstrapping the standard errors. It takes about 10 minutes to run the estimator with asymptotic standard errors and overnight to run the bootstrapped version on a 2021 macbook pro.

## Section 3 

`3_LCOE_Calculations.do`: Assigns estimated LCOEs over time in counties not included in our estimating sample. This produces the full cross-section of solar prices for the some 3000 counties in the lower-48 states we use in our simulation exercises and saves them into our data directory.

`3_external_validation_2023.do`: This script performs the external validation procedure we describe in appendix B.3.3. 

## Section 4 

`4_Counterfactuals.do`: This script performs all of the counterfactual analysis that underpins section 5 of our paper. It reads in our estimated structural parameters as well as the extrapolated values and solves for the equilibrium demand functions for each form of electricity under the pricing schemes we consider. It also takes in electricity prices and income levels for 2018 taken from files generated in section 0 of the scripts.


## Section 5 


`5_EIA_Gas.do`: reads in monthly residential natural gas consumption per customer. Used in alternative specifications for the reduced-form regression in equation (15) in section 5.2 of the paper

`5_hdd_cdd.do`: reads in monthly population weighted state-level heating and cooling degree days data from NOAA. This script reads the data directly from NOAA’s web directories.

`5_EIA_residentialsolar_monthly.do` : Reads in monthly residential electricity consumption as well as small-scale solar PV generation from EIA data files located in our data folder. Combines these panel data with CDD/HDD data generated by 5_hdd_cdd.do. Performs variations of the regression in equation (15) on these data.

## Misc

`R_maps_2023.R`: Creates all maps in the paper. Takes arguments of .csv outputs from the “_Data_postAER” folder.



## Section APP 

`APP_1_PPW_Decomp_2023.do`: This script carries out the price variance decomposition exercises we perform in Appendix C.


# Data Description for the Data Repo

There are four folders: raw, processed,.sters, and temp. Contents are pretty much self explanatory and 

## Raw

Contains all raw data files used in our analysis. This includes the LBNL _Tracking the Sun_ data on individual solar PV systems (Barbose et al. 2019), the _DeepSolar_ dataset (Yu et al. 2018), EIA data on residential electricity prices and consumption from Form EIA - 861, ACS data on county-level average incomes, NOAA data on state-level heating and cooling degree days, EIA data on monthly natural gas consumption, and zip-code to county crosswalks from the U.S. Department of Housing and Urban Development.

## Processed

Processed files. This includes the main estimating sample as well as covariates for the 3,074 counties used in our simulations and counterfactuals for 2018.

## Temp

Temporary directory containing intermediate data files used to construct our sample.

## .sters

Regression outputs.

