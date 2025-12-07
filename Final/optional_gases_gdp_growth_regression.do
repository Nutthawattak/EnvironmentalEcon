clear all
set more off

cd "C:\Users\Admin\Documents\Github\EnvironmentalEcon"   // your directory
use "multigas_gdp_12countries.dta", clear
****************************************************
* 1) CO2  IEA_EDGAR_CO2_1970_2024.csv
****************************************************
levelsof country_code_a3, local(cties)

foreach c of local cties {

    di "======================================="
    di " Regression for country_code_a3 = `c'"
    di "======================================="

    reg co2_mt c.year_c##i.post_paris ///
        if country_code_a3=="`c'", vce(robust)

    di ""
}

save "edgar_co2_12countries.dta", replace

* 2) CH4
****************************************************
levelsof country_code_a3, local(cties)

foreach c of local cties {

    di "======================================="
    di " Regression for country_code_a3 = `c'"
    di "======================================="

    reg ch4_mt c.year_c##i.post_paris ///
        if country_code_a3=="`c'", vce(robust)

    di ""
}

save "edgar_ch4_12countries.dta", replace

***N2O

levelsof country_code_a3, local(cties)

foreach c of local cties {

    di "======================================="
    di " Regression for country_code_a3 = `c'"
    di "======================================="

    reg n2o_mt c.year_c##i.post_paris ///
        if country_code_a3=="`c'", vce(robust)

    di ""
}

save "edgar_n2o_12countries.dta", replace	

****************************************************
* (Optional) Regressions: gas growth vs GDP growth (12 countries)
****************************************************
use "multigas_gdp_12countries.dta", clear
keep if inrange(year,1970,2024)

* add post_paris agreement
capture confirm variable post_paris
if _rc {
    gen post_paris = year>=2016
}

local countries "USA CHN GBR IND RUS JPN DEU KOR IDN SAU IRN CAN"

* --- 8.1 Simple regressions ---
foreach cc of local countries {

    di "====================================="
    di "Country: `cc'  (simple regression)"
    di "====================================="

    di "CO2 Emission vs GDP growth"
    reg co2_mt percent_growth_per_year if country_code_a3=="`cc'"

    di "CH4 Emission vs GDP growth"
    reg ch4_mt percent_growth_per_year if country_code_a3=="`cc'"

    di "N2O Emission vs GDP growth"
    reg n2o_mt percent_growth_per_year if country_code_a3=="`cc'"
}

* --- With Paris interaction (to see decoupling post-Paris Agreement) ---
foreach cc of local countries {

    di "====================================="
    di "Country: `cc'  (with Paris interaction)"
    di "====================================="

    di "CO2 growth ~ GDP * post_paris"
    reg co2_mt c.percent_growth_per_year##i.post_paris if country_code_a3=="`cc'"

    di "CH4 growth ~ GDP * post_paris"
    reg ch4_mt c.percent_growth_per_year##i.post_paris if country_code_a3=="`cc'"
	
	di "N2O growth ~ GDP * post_paris"
    reg n2o_mt c.percent_growth_per_year##i.post_paris if country_code_a3=="`cc'"


}

	
	
