*===============================================================================
* Project 2: Postsecondary Certificate Trends
* File: 03_descriptives.do
* Purpose: Descriptive tables and figures from the 2000-2024 panel
* Author:  Feda Mohammadi
*===============================================================================

clear all
set more off

*-------------------------------------------------------------------------------
* Setup
*-------------------------------------------------------------------------------
global root    "C:\Users\mohammadif\Documents\certificate_trends"
global clean   "$root\data\clean"
global tables  "$root\output\tables"
global figs    "$root\output\figures"

capture mkdir "$tables"
capture mkdir "$figs"

use "$clean\completions_panel_2000_2024.dta", clear

*===============================================================================
* Table 1: National totals by award category and year
*===============================================================================
preserve
collapse (sum) ctotalt, by(year award_category)
reshape wide ctotalt, i(year) j(award_category) string
order year ctotaltcert_under_1yr ctotaltcert_1_to_2yr ctotaltcert_2_to_4yr ///
      ctotaltcert_postbacc ctotaltcert_postmasters ///
      ctotaltassociate ctotaltbachelor ctotaltmaster ctotaltdoctorate

rename ctotalt* *
export delimited using "$tables\t1_totals_by_year_category.csv", replace
restore

*===============================================================================
* Figure 1: Certificate totals over time (5 lines, one per certificate category)
*===============================================================================
preserve
keep if is_certificate == 1
collapse (sum) ctotalt, by(year award_category)

reshape wide ctotalt, i(year) j(award_category) string

twoway ///
    (line ctotaltcert_under_1yr year, lcolor(navy) lwidth(medthick)) ///
    (line ctotaltcert_1_to_2yr year, lcolor(maroon) lwidth(medthick)) ///
    (line ctotaltcert_2_to_4yr year, lcolor(forest_green) lwidth(medthick)) ///
    (line ctotaltcert_postbacc year, lcolor(dkorange) lwidth(medthick)) ///
    (line ctotaltcert_postmasters year, lcolor(purple) lwidth(medthick)), ///
    ytitle("Certificates awarded") ///
    xtitle("Year") ///
    xlabel(2000(4)2024) ///
    ylabel(, format(%9.0fc)) ///
    title("Certificate awards by type, 2000-2024") ///
    legend(order(1 "Under 1 year" 2 "1 to 2 years" 3 "2 to 4 years" ///
                 4 "Postbaccalaureate" 5 "Post-master's") ///
           position(6) rows(2)) ///
    graphregion(color(white))

graph export "$figs\f1_certs_by_type.png", replace width(1600)
restore

*===============================================================================
* Figure 2: Certificates vs degrees, indexed to 2000 = 100
*===============================================================================
preserve
collapse (sum) ctotalt, by(year is_certificate)

* Get 2000 baseline for each series
sort is_certificate year
by is_certificate: gen base = ctotalt[1]
gen index = (ctotalt / base) * 100

reshape wide ctotalt base index, i(year) j(is_certificate)

twoway ///
    (line index1 year, lcolor(navy) lwidth(medthick)) ///
    (line index0 year, lcolor(maroon) lwidth(medthick)), ///
    yline(100, lcolor(gs10) lpattern(dash)) ///
    ytitle("Index (2000 = 100)") ///
    xtitle("Year") ///
    xlabel(2000(4)2024) ///
    title("Certificate vs degree growth, 2000-2024") ///
    legend(order(1 "All certificates" 2 "All degrees") position(6) rows(1)) ///
    graphregion(color(white))

graph export "$figs\f2_cert_vs_degree_index.png", replace width(1600)
restore

*===============================================================================
* Figure 3: Certificate share of total awards over time
*===============================================================================
preserve
collapse (sum) ctotalt, by(year is_certificate)
reshape wide ctotalt, i(year) j(is_certificate)
gen cert_share = ctotalt1 / (ctotalt0 + ctotalt1) * 100

twoway ///
    (line cert_share year, lcolor(navy) lwidth(medthick)), ///
    ytitle("Certificates as % of all awards") ///
    xtitle("Year") ///
    xlabel(2000(4)2024) ///
    ylabel(0(5)30, format(%9.0f)) ///
    title("Certificate share of total awards, 2000-2024") ///
    graphregion(color(white)) ///
    legend(off)

graph export "$figs\f3_cert_share.png", replace width(1600)
restore

*===============================================================================
* Table 2: Certificates by institution type (CONTROL x ICLEVEL), selected years
*===============================================================================
preserve
keep if is_certificate == 1
keep if inlist(year, 2000, 2010, 2019, 2024)
keep if inlist(control, 1, 2, 3)   // drop -3 "not applicable"
keep if inlist(iclevel, 1, 2, 3)   // drop -3 "not applicable"

collapse (sum) ctotalt, by(year control iclevel)
export delimited using "$tables\t2_certs_by_institution_type.csv", replace
restore

*===============================================================================
* Figure 4: Certificate totals by institution CONTROL over time
*===============================================================================
preserve
keep if is_certificate == 1
keep if inlist(control, 1, 2, 3)

collapse (sum) ctotalt, by(year control)
reshape wide ctotalt, i(year) j(control)

twoway ///
    (line ctotalt1 year, lcolor(navy) lwidth(medthick)) ///
    (line ctotalt2 year, lcolor(forest_green) lwidth(medthick)) ///
    (line ctotalt3 year, lcolor(maroon) lwidth(medthick)), ///
    ytitle("Certificates awarded") ///
    xtitle("Year") ///
    xlabel(2000(4)2024) ///
    ylabel(, format(%9.0fc)) ///
    title("Certificate awards by institution control, 2000-2024") ///
    legend(order(1 "Public" 2 "Private nonprofit" 3 "Private for-profit") ///
           position(6) rows(1)) ///
    graphregion(color(white))

graph export "$figs\f4_certs_by_control.png", replace width(1600)
restore

*===============================================================================
* Table 3: Top 10 CIP fields for certificates, 2000 vs 2024
*===============================================================================
preserve
keep if is_certificate == 1
keep if inlist(year, 2000, 2024)

collapse (sum) ctotalt, by(year cip2)

* Rank within each year
bysort year (ctotalt): gen rank = _N - _n + 1
keep if rank <= 10

sort year rank
export delimited using "$tables\t3_top_cip_certs.csv", replace
restore

*===============================================================================
* Summary numbers for the memo
*===============================================================================
display _newline "########## Headline numbers ##########"

* Total certificates in first and last year
sum ctotalt if year == 2000 & is_certificate == 1
sum ctotalt if year == 2024 & is_certificate == 1

* Bachelor's growth
sum ctotalt if year == 2000 & award_category == "bachelor"
sum ctotalt if year == 2024 & award_category == "bachelor"

* Certificate share of awards
tabstat ctotalt if year == 2000, by(is_certificate) statistics(sum)
tabstat ctotalt if year == 2024, by(is_certificate) statistics(sum)

display _newline "########## Descriptives complete ##########"



