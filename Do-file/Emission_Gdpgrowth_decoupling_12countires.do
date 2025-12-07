clear all
set more off

local countries "USA CHN GBR IND RUS JPN DEU KOR IDN SAU IRN CAN"

* 1) CO2  
import delimited using "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Raw\IEA_EDGAR_CO2_1970_2024.csv", ///
    varnames(1) clear

gen id = _n
reshape long y_, i(id) j(year)

rename y_ co2_gg
generate double co2_mt = co2_gg/1000

label var co2_gg "CO2 emissions (Gg)"
label var co2_mt "CO2 emissions (MtCO2)"

keep if inlist(country_code_a3, ///
    "USA","CHN","IND","RUS","GBR", ///
    "JPN","DEU","KOR") ///
 | inlist(country_code_a3, ///
    "IDN","SAU","IRN","CAN")


sort country_code_a3 year

generate byte post_paris = year >= 2016
generate year_c = year - 2000

save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\edgar_co2_1970_2024_panel.dta", replace



* 2) CH4

import delimited using "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Raw\EDGAR_CH4_1970_2024.csv", ///
    varnames(1) clear

gen id = _n
reshape long y_, i(id) j(year)

rename y_ ch4_gg
generate double ch4_mt = ch4_gg/1000

label var ch4_gg "CH4 emissions (Gg)"
label var ch4_mt "CH4 emissions (MtCH4)"

keep if inlist(country_code_a3, ///
    "USA","CHN","IND","RUS","GBR", ///
    "JPN","DEU","KOR") ///
 | inlist(country_code_a3, ///
    "IDN","SAU","IRN","CAN")


sort country_code_a3 year

generate byte post_paris = year >= 2016
generate year_c = year - 2000

save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\edgar_ch4_1970_2024_panel.dta", replace


* 3) N2O

import delimited using "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Raw\EDGAR_N2O_1970_2024.csv", ///
    varnames(1) clear
gen id = _n
reshape long y_, i(id) j(year)

rename y_ n2o_gg
generate double n2o_mt = n2o_gg/1000

label var n2o_gg "N2O emissions (Gg)"
label var n2o_mt "N2O emissions (MtN2O)"

keep if inlist(country_code_a3, ///
    "USA","CHN","IND","RUS","GBR", ///
    "JPN","DEU","KOR") ///
 | inlist(country_code_a3, ///
    "IDN","SAU","IRN","CAN")


sort country_code_a3 year

generate byte post_paris = year >= 2016
generate year_c = year - 2000

save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\edgar_n2o_1970_2024_panel.dta", replace


* 5) combine dataset (CO2 + CH4 + N2O)

use "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\edgar_co2_1970_2024_panel.dta", clear

* merge CH4
merge 1:1 country_code_a3 year using "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\edgar_ch4_1970_2024_panel.dta", keep(3) nogen

* merge N2O
merge 1:1 country_code_a3 year using "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\edgar_n2o_1970_2024_panel.dta", keep(3) nogen

* add post-paris agreement
capture confirm variable post_paris
if _rc {
    gen post_paris = year>=2016
}


save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\edgar_multigas.dta", replace

********************************************GDP Anuual Growth
clear all
set more off

import delimited using "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Raw\WB_WDI_NY_GDP_MKTP_KD_ZG.csv", ///
    varnames(1) clear
rename ref_area_label country_name
rename ref_area country_code_a3


ds, has(type numeric)
local yearvars `r(varlist)'

local firstvar  : word 1 of `yearvars'
local firstyear = real(substr("`firstvar'", -4, 4))

local i = 1
foreach v of local yearvars {
    rename `v' gdp_`i'
    local ++i
}

rename gdp_1 year
rename gdp_2 percent_growth_per_year
order country_code_a3 year percent_growth_per_year country_name 
sort  country_code_a3 year

keep if year >= 1970 & year <= 2024
drop if missing(percent_growth_per_year)

label var percent_growth_per_year "GDP annual growth  (%)"


save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\gdp_annual_growth_panel.dta", replace



* Merge EDGAR multi-gas with GDP growth
****************************************************
clear all
set more off

use "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\edgar_multigas.dta", clear

destring year, replace

* merge with GDP annual growth
merge 1:1 country_code_a3 year using "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\gdp_annual_growth_panel.dta", keep(3) nogen

save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\multigas_gdp_12countries.dta", replace

*Coupling Table (CO2+CH4))
clear all
set more off

* 1. Load pre-merged multi-gas + GDP dataset

use "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\multigas_gdp_12countries.dta", clear

capture rename country_code_a3 Country_code_A3
capture rename name             Name
capture rename ipcc_annex       IPCC_annex
capture rename c_group_im24_sh  C_group_IM24_sh

keep if inlist(Country_code_A3, ///
    "CHN","USA","IND","RUS","JPN","IRN","DEU") ///
 | inlist(Country_code_A3, ///
    "KOR","IDN","CAN""SAU","GBR")

keep if inrange(year, 1990, 2024)
encode Country_code_A3, gen(country_id)
xtset country_id year

* 2. Build emission & GDP growth variables


* Use Mt variables for emissions (levels)
rename co2_mt co2
rename ch4_mt ch4

* CO2 and CH4 growth rates (% per year, log-difference)
bys country_id (year): gen co2_growth = 100 * (ln(co2) - ln(L.co2))
bys country_id (year): gen ch4_growth = 100 * (ln(ch4) - ln(L.ch4))

* GDP growth (%), from WDI NY_GDP_MKTP_KD_ZG
gen gdp_growth = percent_growth_per_year


* 3. Absolute and relative decoupling indicators


gen abs_decouple_co2 = (gdp_growth > 0 & co2_growth < 0)
gen rel_decouple_co2 = (gdp_growth > 0 & co2_growth > 0 ///
                         & co2_growth < gdp_growth)

gen abs_decouple_ch4 = (gdp_growth > 0 & ch4_growth < 0)
gen rel_decouple_ch4 = (gdp_growth > 0 & ch4_growth > 0 ///
                         & ch4_growth < gdp_growth)

* Save full panel with decoupling flags
save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\co2_ch4_decoupling_panel.dta", replace


* 4. Aggregate over 2016–2024 (Paris Agreement period)
*----------------------------------------------------------

keep if year >= 2016

bys Country_code_A3: egen n_years = count(year)

bys Country_code_A3: egen abs_co2 = total(abs_decouple_co2)
bys Country_code_A3: egen rel_co2 = total(rel_decouple_co2)

bys Country_code_A3: egen abs_ch4 = total(abs_decouple_ch4)
bys Country_code_A3: egen rel_ch4 = total(rel_decouple_ch4)

bys Country_code_A3: keep if _n == 1

gen decouple_total_co2 = abs_co2 + rel_co2
gen share_decouple_co2 = decouple_total_co2 / n_years
gen share_abs_co2      = abs_co2 / decouple_total_co2 if decouple_total_co2 > 0

gen decouple_total_ch4 = abs_ch4 + rel_ch4
gen share_decouple_ch4 = decouple_total_ch4 / n_years
gen share_abs_ch4      = abs_ch4 / decouple_total_ch4 if decouple_total_ch4 > 0

set linesize 255

list Country_code_A3 ///
     abs_co2 rel_co2 decouple_total_co2 share_decouple_co2 share_abs_co2 ///
     abs_ch4 rel_ch4 decouple_total_ch4 share_decouple_ch4 share_abs_ch4, ///
     noobs sep(0) clean

* 5. Prepare wide dataset for graph

preserve

keep Country_code_A3 abs_co2 rel_co2 abs_ch4 rel_ch4

tempfile wide
save `wide'

use `wide', clear
keep Country_code_A3 abs_co2 rel_co2
gen gas = "CO2"
rename abs_co2 abs
rename rel_co2 rel
tempfile co2
save `co2'

use `wide', clear
keep Country_code_A3 abs_ch4 rel_ch4
gen gas = "CH4"
rename abs_ch4 abs
rename rel_ch4 rel

append using `co2'

graph bar abs rel, ///
    over(gas, label(labsize(vsmall))) ///
    over(Country_code_A3, label(labsize(vsmall))) ///
    stack ///
    legend(order(1 "Absolute" 2 "Relative") size(vsmall)) ///
    ytitle("Number of years (2016–2024)", size(vsmall)) ///
    title("CO2 and CH4 decoupling years after the Paris Agreement")
	
graph export "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Final\Graph\co2_ch4_decoupling_combined_2016_2024.png", replace
graph save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Final\Graph\co2_ch4_decoupling_combined_2016_2024.gph", replace
restore


* Graphs - gas growth + GDP growth + Paris line

**** CO2 + GDP growth (dual axis)

use "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\multigas_gdp_12countries.dta", clear
keep if inrange(year,1970,2024)

* range (can change)
local xmin = 1970  
local xmax = 2024

local countries "USA CHN GBR IND RUS JPN DEU KOR IDN SAU IRN CAN"

foreach cc of local countries {

    twoway ///
        (line co2_mt year if country_code_a3=="`cc'", yaxis(1) lpattern(solid)) ///
        (line percent_growth_per_year year if country_code_a3=="`cc'", yaxis(2) lpattern(solid)), ///
        ///
        yscale(range(`co2min' `co2max') axis(1)) ///
        yscale(range(`gdpmin' `gdpmax') axis(2)) ///
		 xlabel(1970(6)2024) ///
        xscale(range(1970 2024)) ///
        ///
        ytitle("CO2 emissions (Mt)", axis(1)) ///
        ytitle("GDP growth (%)", axis(2)) ///
        xtitle("Year") ///
        legend(order(1 "CO2 (Mt)" 2 "GDP growth (%)")) ///
        xline(2016, lpattern(dash)) ///
        title("`cc': CO2 emissions and GDP growth") ///
        name(co2_gdp_`cc', replace)


    graph export "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Final\Graph\co2_gdp_`cc'_ts.png", replace
    graph save   "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\Graph\co2_gdp_`cc'.gph", replace
}


* CO2+GDP 12 countries (panel)
graph combine ///
    co2_gdp_USA co2_gdp_CHN co2_gdp_GBR ///
    co2_gdp_IND co2_gdp_RUS co2_gdp_JPN ///
    co2_gdp_DEU co2_gdp_KOR co2_gdp_IDN ///
    co2_gdp_SAU co2_gdp_IRN co2_gdp_CAN, ///
    cols(3) xcommon ///
    title("CO2 emissions (Mt) & GDP growth (%) – 12 countries")

graph export "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Final\Graph\co2_gdp_12countries_panel.png", replace
 graph save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Final\Graph\co2_gdp_12countries_panel.gph", replace 


* 4) CH4 + N2O + GDP growth (dual axis)

use "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\multigas_gdp_12countries.dta", clear

* range (can change)
local xmin = 1970  
local xmax = 2024

local countries "USA CHN GBR IND RUS JPN DEU KOR IDN SAU IRN CAN"

foreach cc of local countries {

    twoway ///
        (line ch4_mt year if country_code_a3=="`cc'", ///
            yaxis(1) lpattern(solid)) ///
        (line n2o_mt year if country_code_a3=="`cc'", ///
            yaxis(1) lpattern(solid)) ///
        (line percent_growth_per_year year if country_code_a3=="`cc'", ///
            yaxis(2) lpattern(solid)), ///
        ///
        yscale(range(`gasmin' `gasmax') axis(1)) ///
        yscale(range(`gdpmin' `gdpmax') axis(2)) ///
        xscale(range(`xmin' `xmax')) ///
        xlabel(1970(6)2024) ///
        ///
        ytitle("CH4 & N2O emissions (Mt)", axis(1)) ///
        ytitle("GDP growth (%)", axis(2)) ///
        xtitle("Year") ///
legend(order(1 "CH4 (Mt)" 2 "N2O (Mt)" 3 "GDP growth (%)")) ///
        xline(2016, lpattern(dash)) ///
        title("`cc': CH4 & N2O (Mt) and GDP growth") ///
        name(ch4n2o_gdp_`cc', replace)

    graph export "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Final\Graph\ch4n2o_gdp_`cc'_ts.png", replace
    graph save   "C:\Users\Admin\Documents\Github\EnvironmentalEcon\process\Graph\ch4n2o_gdp_`cc'.gph", replace
}


* CH4+N2O+GDP of 12 Countries
graph combine ///
    ch4n2o_gdp_USA ch4n2o_gdp_CHN ch4n2o_gdp_GBR ///
    ch4n2o_gdp_IND ch4n2o_gdp_RUS ch4n2o_gdp_JPN ///
    ch4n2o_gdp_DEU ch4n2o_gdp_KOR ch4n2o_gdp_IDN ///
    ch4n2o_gdp_SAU ch4n2o_gdp_IRN ch4n2o_gdp_CAN, ///
    cols(3) xcommon ///
    title("CH4 & N2O emissions (Mt) & GDP growth – 12 countries")

graph export "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Final\Graph\ch4n2o_gdp_12countries_panel.png", replace
graph save "C:\Users\Admin\Documents\Github\EnvironmentalEcon\Final\Graph\ch4n2o_gdp_12countries_panel.gph", replace 



