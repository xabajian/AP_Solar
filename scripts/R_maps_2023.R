#### Workspace ---------------------------------------------------------------------------
rm(list = ls(all.names = TRUE))


# Load packages
library(tidyverse)
library(sf)
library(ncdf4)
library(exactextractr)
library(haven)
library(purrr)
library(foreign)
library(readr)
library(dplyr)
library(raster)
library(rgdal)
library(ggplot2)
library(usmap)
library(wesanderson)
library(haven)
library(ggthemes)
library(greekLetters)
library(viridis)
library(RColorBrewer)
library(scales)



i="Xander"
#i="Nick"
if(i=="Xander"){
  setwd("/Users/xabajian/Library/CloudStorage/Box-Box/Solar_Panels/_Data_postAER/Processed")
}
if(i=="Nick"){
 # setwd("~/Box Sync/Research_Projects/Solar_Panels/Data_Formal/Processed")
}


#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*
#* Part 1 - Deep Solar data
#*
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$

#read_in_dataset
deepsolar_data <- read_dta("DeepSolar_CountyData_2023.dta")
names(deepsolar_data)[3] <- "fips"

# navigate down to draft directory for plot saving
#setwd("../") # up to Data
#setwd("../Draft") # up to main and down to draft

#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot Insolation
#*#*@#$%@#$%@#$%@#$%@#$%@

# insolation map
pal <- wes_palette("Zissou1", 100, type = "continuous")
map1 = plot_usmap(
  regions = "counties",
  exclude=c("AK","HI"),
  data = deepsolar_data,
  values = "daily_solar_flux_fixed",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.00000000000000001,
  color="grey"
) + #scale_fill_gradientn(colours=pal,name = "kWh per Square Meter",label = scales::comma
scale_fill_continuous(low="white", high="red", name = "kWh per Square Meter", label = scales::comma
) + theme(legend.position = "right",plot.margin=grid::unit(c(0,0,0,0), "mm")
)
ggsave("insolation.pdf",map1,device="pdf",width=9,height=7,units="in",dpi="print")

#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot HH Share
#*#*@#$%@#$%@#$%@#$%@#$%@

##PA_perHH HH_share

map2=plot_usmap(
  regions = "counties",
  exclude=c("AK","HI"),
  data = deepsolar_data,
  values = "PA_perHH",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.00000000000000001,
  color="grey"
) +  #scale_fill_gradientn(colours=pal,name = " Installation Rate",label = scales::comma
scale_fill_continuous(low="white", high="red", name = "Panel Area per Household", label = scales::comma,
                      limits=c(0,0.5),oob=squish
) + theme(legend.position = "right"
)
ggsave("PA_per_HH.pdf",map2,device="pdf",width=9,height=7,units="in",dpi="print")


map2=plot_usmap(
  regions = "counties",
  exclude=c("AK","HI"),
  data = deepsolar_data,
  values = "HH_share",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.00000000000000001,
  color="grey"
) +  #scale_fill_gradientn(colours=pal,name = "Household Installation Rate",label = scales::comma
  scale_fill_continuous(low="white", high="red", name = "Household Installation Rate", label = scales::comma,
                        limits=c(0,0.5),oob=squish
  ) + theme(legend.position = "right"
 )
ggsave("install_rate.pdf",map2,device="pdf",width=9,height=7,units="in",dpi="print")


#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*
#* Part 2 - County-level aggregates
#*
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$



#*read in county-level averages from the .dta files we
#*use for our regression specification
county_data <- read_dta("../Data_Formal/Processed/solar_static_counties.dta")

#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot solar prices
#*#*@#$%@#$%@#$%@#$%@#$%@

county_data = county_data[county_data$p_solar >=0,]
county_data = county_data[!is.na(county_data$p_solar),]
county_data$baseline_diff = county_data$p_solar - county_data$p_grid
map3 = plot_usmap(
  regions = "counties",
  exclude=c("AK","HI"),
  data = county_data,
  values = "baseline_diff",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.00000000000000001,
  color="grey"
) + scale_fill_continuous(low="white", high="red", name = "Solar - Grid ($/kWh)", label = scales::comma,
                          limits=c(-0.1,0.1),oob=squish
) + theme(legend.position = "right"
)
ggsave("price_diff_map.pdf",map3,device="pdf",width=9,height=7,units="in",dpi="print")

# counties with negative differentials
county_data_negative = county_data[county_data$baseline_diff <= 0,]
county_data_negative$negative_diff = 1
map4 = plot_usmap(
  regions = "counties",
  exclude=c("AK","HI"),
  data = county_data_negative,
  values = "negative_diff",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.00000000000000001,
  color="grey"
) + scale_fill_continuous(low="white", high="red", name = "Solar - Grid ($/kWh)", label = scales::comma
) + theme(legend.position = "none"
)
ggsave("price_diff_map_negative.pdf",map4,device="pdf",width=9,height=7,units="in",dpi="print")

# price diff net of subsidies
county_data$diff_no_subs = county_data$LCOE_gross_cost - county_data$p_grid
map5 = plot_usmap(
  regions = "counties",
  exclude=c("AK","HI"),
  data = county_data,
  values = "diff_no_subs",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.00000000000000001,
  color="grey"
) + scale_fill_continuous(low="white", high="red", name = "Solar - Grid ($/kWh)", limits=c(-0.06,1),oob=squish,label = scales::comma
) + theme(legend.position = "right"
)
ggsave("price_diff_map_no_subs.pdf",map5,device="pdf",width=9,height=7,units="in",dpi="print")



#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*
#* Part 3 - Counterfactuals
#*
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$
#*#*@#$%@#$%@#$%@#$%@#$%@#$

#*read in county-level averages from the .dta files we
##updates

county_data <- read_dta("new_cfx_2023.dta")


#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot implied price aggregate map and compute electricity price aggregates for hypothesis tests
#*@#$%@#$%@#$%@#$%@#$%@#$



# implied electricity price index
county_data$p_e_INDEX = (county_data$state_gamma^county_data$state_rho * 
                           county_data$p_grid^(1-county_data$state_rho) + 
                           (1-county_data$state_gamma)^county_data$state_rho * 
                           county_data$p_solar^(1-county_data$state_rho))^(1/(1-county_data$state_rho))
county_data$p_tilde_INDEX = (county_data$state_delta^county_data$state_kappa * 
                               county_data$p_e_INDEX^(1-county_data$state_kappa) + 
                               (1-county_data$state_delta)^county_data$state_kappa)^(1/(1-county_data$state_kappa))
county_data$elast_ptilde_pe = county_data$state_delta^county_data$state_kappa * 
  (county_data$p_e_INDEX / county_data$p_tilde_INDEX)^(1-county_data$state_kappa)
county_data$one_elast_ptilde_pe = 1-county_data$elast_ptilde_pe
county_data$rho_kappa_ratio = (county_data$state_rho - 1) / (county_data$state_kappa - 1)
county_data$condition_4_holds = ifelse(county_data$rho_kappa_ratio > county_data$one_elast_ptilde_pe,1,0)

#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plots
#*@#$%@#$%@#$%@#$%@#$%@#$
map_price_elast = plot_usmap(
  regions = "counties",
  exclude=c("AK","HI"),
  data = county_data,
  values = "one_elast_ptilde_pe",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.00000000000000001,
  color="grey"
) + scale_fill_continuous(low="white", high="red", name = expression(paste("1 - ",epsilon,sep="")), label = scales::comma
) + theme(legend.position = "right"
)
#ggsave("price_diff_map_no_subs.pdf",map5,device="pdf",width=9,height=7,units="in",dpi="print")


#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot maps of increase/decreases in grid consumption levels
#*#*@#$%@#$%@#$%@#$%@#$%@

map_log_increase=plot_usmap(
  regions = "counties",
  data = county_data,
  exclude=c("AK","HI"),
  values = "dgrid_pct",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.1,
  color="grey"
) +  scale_fill_continuous(
  low = "blue", high = "white", name = "Percent Change in Grid \n Electricity Consumption", label = scales::comma,
  limits=c(-.5,0.0),oob=squish
)  + theme(legend.position = "right")



ggsave("cfx_grid.pdf",map_log_increase,device="pdf",width=9,height=7,units="in",dpi="print")



#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot maps of increase/decreases in solar consumption levels
#*#*@#$%@#$%@#$%@#$%@#$%@
#

map_solar_increase=plot_usmap(
  regions = "counties",
  data = county_data,
  exclude=c("AK","HI"),
  values = "solar_pct",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.1,
  color="grey"
) +  scale_fill_continuous(
  low = "white", high = "red", name = "Percent Change in Residential \n Solar Electricity Consumption", 
  limits=c(0,300),oob=squish,
  label = scales::comma
)  + theme(legend.position = "right")


ggsave("cfx_solar.pdf",map_solar_increase,device="pdf",width=9,height=7,units="in",dpi="print")




#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot maps of induced demand
#*#*@#$%@#$%@#$%@#$%@#$%@
#


solar_demand_induced=plot_usmap(
  regions = "counties",
  data = county_data,
  exclude=c("AK","HI"),
  values = "p_induced_demand",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.1,
  color="grey"
) +  scale_fill_continuous(
  low = "white", high = "red",
  limits=c(0,0.5),oob=squish,
  label = scales::comma,
  name = "Subsidy Expenditure per \n Induced Solar Demand ($/kWh)",
)  + theme(legend.position = "right")
ggsave("cfx_demand.pdf",solar_demand_induced,device="pdf",width=9,height=7,units="in",dpi="print")




#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot maps of cost of demand in terms of private cost
#*#*@#$%@#$%@#$%@#$%@#$%@
#


plot_usmap(
  regions = "counties",
  data = county_data,
  exclude=c("AK","HI"),
  values = "private_subs_ratio",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.1,
  color="grey"
) +  scale_fill_continuous(
  low = "white", high = "blue",
  name = "Cost of Induced Demand \n Relative to Private Cost of Solar Generation",
)  + theme(legend.position = "right")





#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot maps of covered state gammas
#*#*@#$%@#$%@#$%@#$%@#$%@
#


amenity1=plot_usmap(
  regions = "counties",
  data = county_data,
  values = "in_gamma",
  exclude=c("AK","HI"),
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  color="grey",
  size=0.1,
) + theme(legend.position = "right"
) + scale_fill_continuous(
  #limits=c(0,0.02),oob=squish,
  low = "white", high = "red", name = "Structural State-Level \n Solar Amenity Weights", label = scales::comma
) 
ggsave("state_solar_weights.pdf",amenity1,device="pdf",width=9,height=7,units="in",dpi="print")


#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot map of out-of-sample state gammas
#*#*@#$%@#$%@#$%@#$%@#$%@
#


amenity2=plot_usmap(
  regions = "counties",
  data = county_data,
  values = "out_gamma",
  exclude=c("AK","HI"),
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  color="grey",
  size=0.1,
) + theme(legend.position = "right"
) + scale_fill_continuous(
  low = "white", high = "red", name = "Fitted County-Level \n Solar Amenity Weights", label = scales::comma
) 
ggsave("fitted_solar_weights.pdf",amenity2,device="pdf",width=9,height=7,units="in",dpi="print")


#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot Average MACs
#*#*@#$%@#$%@#$%@#$%@#$%@


MACS=plot_usmap(
  regions = "counties",
  data = county_data,
  exclude=c("AK","HI"),
  values = "mac_for_map",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.1,
  color="grey"
) + scale_fill_continuous(
  low = "white", high = "red",
  limits=c(0,1000),oob=squish,
  label = scales::comma,
  name = "Average Cost of CO2 Abatement \n in each county, $/MT ",
)   + theme(legend.position = "right")
ggsave("cfx_MACs.pdf",MACS,device="pdf",width=9,height=7,units="in",dpi="print")


#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot Backfiring 
#*#*@#$%@#$%@#$%@#$%@#$%@
#


colourPalette = c( "#4575B4", "#91BFDB" ,"#E0F3F8" ,"#FEE090", "#FC8D59", "#D73027"  )

backfire=plot_usmap(
  regions = "counties",
  data = county_data,
  exclude=c("AK","HI"),
  values = "backfire",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.1,
  color="grey"
) + scale_fill_continuous(
  low = "white", high = "red",
  limits=c(0,1), #oob=squish,
  label = scales::comma,
  name = "Map of Backfiring Counties",
)   + theme(legend.position = "none")
ggsave("cfx_backfire.pdf",backfire,device="pdf",width=9,height=7,units="in",dpi="print")




#*@#$%@#$%@#$%@#$%@#$%@#$
#* Plot NSB Ratios
#*#*@#$%@#$%@#$%@#$%@#$%@
#


colourPalette = c( "#4575B4", "#91BFDB" ,"#E0F3F8" ,"#FEE090", "#FC8D59", "#D73027"  )

net_benefit_ratios=plot_usmap(
  regions = "counties",
  data = county_data,
  exclude=c("AK","HI"),
  values = "county_NSB",
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  size=0.1,
  color="grey"
) +  scale_fill_continuous(
  low = "white", high = "red",
  limits=c(-1,1),oob=squish,
  label = scales::comma,
  name = "Net Social Benefit Ratios",
)  + theme(legend.position = "right")
ggsave("cfx_nsb.pdf",net_benefit_ratios,device="pdf",width=9,height=7,units="in",dpi="print")



map_abatement=plot_usmap(
  regions = "counties",
  data = county_data,
  values = "county_NSB",
  exclude=c("AK","HI"),
  show.legend = TRUE,
  labels = FALSE,
  label_color = "black",
  color="grey",
  size=0.1,
) + theme(legend.position = "right"
) + scale_fill_gradient(
  low = "white", high = "red",name = "Net Social Benefit Ratios ", label = scales::comma, limits=c(-1,0),oob=squish)
  #scale_fill_binned(
#breaks = c(-0.75, -0.5,-0.25, 0), low = "purple",high = "white",  name = "Net Social Benefit Ratios ", label = scales::comma
   #n.breaks=4, nice.breaks = TRUE ,low = "white",high = "red",  name = "Net Social Benefit Ratrios ", label = scales::comma\
#) 
ggsave("cfx_abatement.pdf",map_abatement,device="pdf",width=9,height=7,units="in",dpi="print")

