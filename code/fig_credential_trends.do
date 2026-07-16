*===============================================================
* fig_credential_trends.do
* Simple 5-line chart: credential counts by category, 2000-2024
*===============================================================

clear all
set more off

cd "C:\Users\mohammadif\Documents\certificate_trends"

use "data/clean/completions_panel_2000_2024.dta", clear

keep if inrange(year, 2000, 2024)

* Build 5 categories from AWLEVEL
gen category = .
replace category = 1 if inlist(awlevel, 1, 2, 4, 6, 8, 20, 21)   // all certificates
replace category = 2 if awlevel == 3                              // associate's
replace category = 3 if awlevel == 5                              // bachelor's
replace category = 4 if awlevel == 7                              // master's
replace category = 5 if inlist(awlevel, 17, 18, 19)               // doctorate
replace category = 5 if inlist(awlevel, 9, 10, 17, 18, 19)   // doctorate

drop if missing(category)

label define cat 1 "Certificates" 2 "Associate's" 3 "Bachelor's" ///
                 4 "Master's" 5 "Doctorate"
label values category cat

collapse (sum) ctotalt, by(year category)

reshape wide ctotalt, i(year) j(category)

rename ctotalt1 certs
rename ctotalt2 assoc
rename ctotalt3 bach
rename ctotalt4 mast
rename ctotalt5 doct

* Quick sanity check
list year certs assoc bach mast doct if inlist(year, 2000, 2010, 2024)

twoway (line certs year, lwidth(medthick)) ///
       (line assoc year, lwidth(medthick)) ///
       (line bach  year, lwidth(medthick)) ///
       (line mast  year, lwidth(medthick)) ///
       (line doct  year, lwidth(medthick)), ///
       ytitle("Awards conferred") ///
       xtitle("Year") ///
       xlabel(2000(4)2024) ///
       ylabel(, format(%9.0fc) angle(horizontal)) ///
       legend(order(1 "Certificates" 2 "Associate's" 3 "Bachelor's" ///
                    4 "Master's" 5 "Doctorate") ///
              rows(1) position(6) size(small)) ///
       graphregion(color(white)) ///
       plotregion(color(white))

graph export "output/figures/credential_trends_2000_2024.png", replace width(1600)


