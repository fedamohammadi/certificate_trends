*===============================================================
* fig_2_2_length.do
* Section 2.2: Length
*   - Figure 2: Count by type of under-1-year certificate by year
*===============================================================
clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"
capture mkdir "output/editable_figs"
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
twoway (line under12wk   year, lwidth(medthick) lcolor("31 119 180")) ///
       (line wk12_to_1yr year, lwidth(medthick) lcolor("214 39 40")) ///
       (scatter under12wk   year, msymbol(none) ///
            mlabel(lbl_under12wk) mlabposition(3) mlabsize(vsmall) mlabcolor("31 119 180")) ///
       (scatter wk12_to_1yr year, msymbol(none) ///
            mlabel(lbl_wk12) mlabposition(3) mlabsize(vsmall) mlabcolor("214 39 40")), ///
       ytitle("Certificates conferred", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2020(1)2024, labsize(small)) ///
       xscale(range(2020 2024.9)) ///
       ylabel(, format(%9.0fc) angle(horizontal) labsize(small)) ///
       legend(order(1 "Under 12 weeks" ///
                    2 "12 weeks to under 1 year") ///
              rows(1) position(6) size(small) region(lstyle(none))) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)
graph export "output/figures/fig_2_under_1yr_by_length.png", ///
    replace width(2100)
graph export "output/editable_figs/fig_2_under_1yr_by_length.emf", replace
graph export "output/editable_figs/fig_2_under_1yr_by_length.pdf", replace
display _newline "=== Section 2.2 figure done ==="


