*===============================================================
* fig_2_1_trends_overall.do
* Section 2.1: Trends in credentials, overall
*   - Figure 1A: Count by credential by year (all certs together)
*   - Figure 1B: Credential share by year
*   - Figure 1C: Certificate count by year (broken out by type
*                and by undergrad vs grad)
*===============================================================

clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"

*---------------------------------------------------------------
* Load the panel
*---------------------------------------------------------------
use "data/clean/completions_panel_2000_2024.dta", clear
keep if inrange(year, 2000, 2024)

*===============================================================
* FIGURE 1A: Count by credential by year (5 categories, all certs
* grouped together).
*===============================================================

preserve
    gen category = .
    replace category = 1 if inlist(awlevel, 1, 2, 4, 6, 8, 20, 21)   // certificates
    replace category = 2 if awlevel == 3                              // associate's
    replace category = 3 if awlevel == 5                              // bachelor's
    replace category = 4 if awlevel == 7                              // master's
    replace category = 5 if inlist(awlevel, 9, 10, 17, 18, 19)        // doctorate
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

    twoway (line certs year, lwidth(medthick)) ///
           (line assoc year, lwidth(medthick)) ///
           (line bach  year, lwidth(medthick)) ///
           (line mast  year, lwidth(medthick)) ///
           (line doct  year, lwidth(medthick)), ///
           title("Credentials awarded nationally by category, 2000-2024", ///
                 size(medsmall)) ///
           ytitle("Awards conferred") ///
           xtitle("Year") ///
           xlabel(2000(4)2024) ///
           ylabel(, format(%9.0fc) angle(horizontal)) ///
           legend(order(1 "Certificates" 2 "Associate's" 3 "Bachelor's" ///
                        4 "Master's" 5 "Doctorate") ///
                  rows(1) position(6) size(small)) ///
           graphregion(color(white)) plotregion(color(white))

    graph export "output/figures/fig_1A_count_by_credential_by_year.png", ///
        replace width(1600)
restore

*===============================================================
* FIGURE 1B: Credential share by year.
*===============================================================

preserve
    gen category = .
    replace category = 1 if inlist(awlevel, 1, 2, 4, 6, 8, 20, 21)
    replace category = 2 if awlevel == 3
    replace category = 3 if awlevel == 5
    replace category = 4 if awlevel == 7
    replace category = 5 if inlist(awlevel, 9, 10, 17, 18, 19)
    drop if missing(category)

    label define cat 1 "Certificates" 2 "Associate's" 3 "Bachelor's" ///
                     4 "Master's" 5 "Doctorate"
    label values category cat

    collapse (sum) ctotalt, by(year category)

    bysort year: egen year_total = total(ctotalt)
    gen share = 100 * ctotalt / year_total

    reshape wide ctotalt share year_total, i(year) j(category)
    rename share1 s_certs
    rename share2 s_assoc
    rename share3 s_bach
    rename share4 s_mast
    rename share5 s_doct

    twoway (line s_certs year, lwidth(medthick)) ///
           (line s_assoc year, lwidth(medthick)) ///
           (line s_bach  year, lwidth(medthick)) ///
           (line s_mast  year, lwidth(medthick)) ///
           (line s_doct  year, lwidth(medthick)), ///
           title("Share of all credentials awarded by category, 2000-2024", ///
                 size(medsmall)) ///
           ytitle("Share of all awards (%)") ///
           xtitle("Year") ///
           xlabel(2000(4)2024) ///
           ylabel(0(10)50, angle(horizontal)) ///
           legend(order(1 "Certificates" 2 "Associate's" 3 "Bachelor's" ///
                        4 "Master's" 5 "Doctorate") ///
                  rows(1) position(6) size(small)) ///
           graphregion(color(white)) plotregion(color(white))

    graph export "output/figures/fig_1B_credential_share_by_year.png", ///
        replace width(1600)
restore

*===============================================================
* FIGURE 1C: Certificate counts by type and undergrad vs grad.
*===============================================================

preserve
    gen cert_type = .
    replace cert_type = 1 if inlist(awlevel, 1, 20, 21)
    replace cert_type = 2 if awlevel == 2
    replace cert_type = 3 if awlevel == 4
    replace cert_type = 4 if awlevel == 6
    replace cert_type = 5 if awlevel == 8
    drop if missing(cert_type)

    label define ctype 1 "Undergrad: under 1 yr" ///
                      2 "Undergrad: 1 to 2 yr" ///
                      3 "Undergrad: 2 to 4 yr" ///
                      4 "Postbaccalaureate" ///
                      5 "Post-master's"
    label values cert_type ctype

    collapse (sum) ctotalt, by(year cert_type)
    reshape wide ctotalt, i(year) j(cert_type)
    rename ctotalt1 ug_under1
    rename ctotalt2 ug_1to2
    rename ctotalt3 ug_2to4
    rename ctotalt4 postbacc
    rename ctotalt5 postmast

    twoway (line ug_under1 year, lwidth(medthick)) ///
           (line ug_1to2   year, lwidth(medthick)) ///
           (line ug_2to4   year, lwidth(medthick)) ///
           (line postbacc  year, lwidth(medthick)) ///
           (line postmast  year, lwidth(medthick)), ///
           title("Certificates awarded by type, undergraduate and graduate, 2000-2024", ///
                 size(medsmall)) ///
           ytitle("Certificates conferred") ///
           xtitle("Year") ///
           xlabel(2000(4)2024) ///
           ylabel(, format(%9.0fc) angle(horizontal)) ///
           legend(order(1 "Undergrad: under 1 yr" ///
                        2 "Undergrad: 1 to 2 yr" ///
                        3 "Undergrad: 2 to 4 yr" ///
                        4 "Postbaccalaureate" ///
                        5 "Post-master's") ///
                  rows(2) position(6) size(small)) ///
           graphregion(color(white)) plotregion(color(white))

    graph export "output/figures/fig_1C_certificate_count_by_type.png", ///
        replace width(1600)
restore

display _newline "=== Section 2.1 figures done ==="



