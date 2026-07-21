*===============================================================
* fig_2_2_length.do
* Section 2.2: Length
*   - Figure 2: Count by type of under-1-year certificate by year
*===============================================================

clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"

use "data/clean/completions_panel_2000_2024.dta", clear

keep if inlist(awlevel, 20, 21)
keep if inrange(year, 2020, 2024)

gen length_type = .
replace length_type = 1 if awlevel == 20
replace length_type = 2 if awlevel == 21

label define length_lbl 1 "Under 12 weeks" ///
                       2 "12 weeks to under 1 year"
label values length_type length_lbl

collapse (sum) ctotalt, by(year length_type)

reshape wide ctotalt, i(year) j(length_type)
rename ctotalt1 under12wk
rename ctotalt2 wk12_to_1yr

* Create label variables that show the value only in the last year (2024)
gen lbl_under12wk = string(under12wk, "%9.0fc") if year == 2024
gen lbl_wk12     = string(wk12_to_1yr, "%9.0fc") if year == 2024

twoway (line under12wk   year, lwidth(medthick)) ///
       (line wk12_to_1yr year, lwidth(medthick)) ///
       (scatter under12wk   year, msymbol(none) ///
            mlabel(lbl_under12wk) mlabposition(3) mlabsize(small)) ///
       (scatter wk12_to_1yr year, msymbol(none) ///
            mlabel(lbl_wk12) mlabposition(3) mlabsize(small)), ///
       title("Under-1-year certificates by length, 2020-2024", ///
             size(medsmall)) ///
       ytitle("Certificates conferred") ///
       xtitle("Year") ///
       xlabel(2020(1)2024) ///
       xscale(range(2020 2024.6)) ///
       ylabel(, format(%9.0fc) angle(horizontal)) ///
       legend(order(1 "Under 12 weeks" ///
                    2 "12 weeks to under 1 year") ///
              rows(1) position(6) size(small)) ///
       graphregion(color(white)) plotregion(color(white))

graph export "output/figures/fig_2_under_1yr_by_length.png", ///
    replace width(1600)

display _newline "=== Section 2.2 figure done ==="



