*===============================================================
* fig_2_3_sector.do
* Section 2.3: Sector
*   - Figure 3A: Count of <=1 year certs by sector -- undergrad
*   - Figure 3B: Sector share of <=1 year certs -- undergrad
*   - Figure 3C: Count of graduate certificates by sector
*   - Figure 3D: Sector share of graduate certificates
*
* Sector categories (based on CONTROL x PREDDEG):
*   1. Public 4-year (public, predom. bachelor's or grad)
*   2. Public community college (public, predom. associate's)
*   3. Public cert-focused (public, predom. certificate)
*   4. Private nonprofit (all PREDDEG combined)
*   5. For-profit (all PREDDEG combined)
*===============================================================

clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"

use "data/clean/completions_panel_with_preddeg.dta", clear
keep if inrange(year, 2000, 2024)

*---------------------------------------------------------------
* Build the 5 sector categories
* CONTROL: 1 = public, 2 = private nonprofit, 3 = for-profit
* PREDDEG: 1 = cert, 2 = assoc, 3 = bach, 4 = grad
*---------------------------------------------------------------

gen sector = .
replace sector = 1 if control == 1 & inlist(preddeg, 3, 4)   // Public 4-year
replace sector = 2 if control == 1 & preddeg == 2             // Public community coll
replace sector = 3 if control == 1 & preddeg == 1             // Public cert-focused
replace sector = 4 if control == 2                            // Private nonprofit
replace sector = 5 if control == 3                            // For-profit

label define sec 1 "Public 4-year" ///
                 2 "Public community college" ///
                 3 "Public cert-focused" ///
                 4 "Private nonprofit" ///
                 5 "For-profit"
label values sector sec

drop if missing(sector)

* Save a working copy
tempfile working
save `working'

*===============================================================
* FIGURE 3A: Count of under-1-year undergrad certs by sector
*===============================================================

use `working', clear
keep if inlist(awlevel, 1, 20, 21)   // under-1-year undergrad certs

collapse (sum) ctotalt, by(year sector)
reshape wide ctotalt, i(year) j(sector)
rename ctotalt1 pub4yr
rename ctotalt2 pubcc
rename ctotalt3 pubcert
rename ctotalt4 pnp
rename ctotalt5 fp

gen lbl_pub4yr  = string(pub4yr,  "%9.0fc") if year == 2024
gen lbl_pubcc   = string(pubcc,   "%9.0fc") if year == 2024
gen lbl_pubcert = string(pubcert, "%9.0fc") if year == 2024
gen lbl_pnp     = string(pnp,     "%9.0fc") if year == 2024
gen lbl_fp      = string(fp,      "%9.0fc") if year == 2024

twoway (line pub4yr  year, lwidth(medthick)) ///
       (line pubcc   year, lwidth(medthick)) ///
       (line pubcert year, lwidth(medthick)) ///
       (line pnp     year, lwidth(medthick)) ///
       (line fp      year, lwidth(medthick)) ///
       (scatter pub4yr  year, msymbol(none) mlabel(lbl_pub4yr)  mlabposition(3) mlabsize(vsmall)) ///
       (scatter pubcc   year, msymbol(none) mlabel(lbl_pubcc)   mlabposition(3) mlabsize(vsmall)) ///
       (scatter pubcert year, msymbol(none) mlabel(lbl_pubcert) mlabposition(3) mlabsize(vsmall)) ///
       (scatter pnp     year, msymbol(none) mlabel(lbl_pnp)     mlabposition(3) mlabsize(vsmall)) ///
       (scatter fp      year, msymbol(none) mlabel(lbl_fp)      mlabposition(3) mlabsize(vsmall)), ///
       title("Under-1-year undergraduate certificates by sector, 2000-2024", ///
             size(medsmall)) ///
       ytitle("Certificates conferred") ///
       xtitle("Year") ///
       xlabel(2000(4)2024) ///
       xscale(range(2000 2026)) ///
       ylabel(, format(%9.0fc) angle(horizontal)) ///
       legend(order(1 "Public 4-year" 2 "Public community college" ///
                    3 "Public cert-focused" 4 "Private nonprofit" ///
                    5 "For-profit") ///
              rows(2) position(6) size(small)) ///
       graphregion(color(white)) plotregion(color(white))

graph export "output/figures/fig_3A_under1yr_certs_by_sector_undergrad.png", ///
    replace width(1600)

*===============================================================
* FIGURE 3B: Sector share of under-1-year undergrad certs
*===============================================================

use `working', clear
keep if inlist(awlevel, 1, 20, 21)

collapse (sum) ctotalt, by(year sector)
bysort year: egen year_total = total(ctotalt)
gen share = 100 * ctotalt / year_total

keep year sector share
reshape wide share, i(year) j(sector)
rename share1 s_pub4yr
rename share2 s_pubcc
rename share3 s_pubcert
rename share4 s_pnp
rename share5 s_fp

gen lbl_pub4yr  = string(s_pub4yr,  "%4.1f") + "%" if year == 2024
gen lbl_pubcc   = string(s_pubcc,   "%4.1f") + "%" if year == 2024
gen lbl_pubcert = string(s_pubcert, "%4.1f") + "%" if year == 2024
gen lbl_pnp     = string(s_pnp,     "%4.1f") + "%" if year == 2024
gen lbl_fp      = string(s_fp,      "%4.1f") + "%" if year == 2024

twoway (line s_pub4yr  year, lwidth(medthick)) ///
       (line s_pubcc   year, lwidth(medthick)) ///
       (line s_pubcert year, lwidth(medthick)) ///
       (line s_pnp     year, lwidth(medthick)) ///
       (line s_fp      year, lwidth(medthick)) ///
       (scatter s_pub4yr  year, msymbol(none) mlabel(lbl_pub4yr)  mlabposition(3) mlabsize(vsmall)) ///
       (scatter s_pubcc   year, msymbol(none) mlabel(lbl_pubcc)   mlabposition(3) mlabsize(vsmall)) ///
       (scatter s_pubcert year, msymbol(none) mlabel(lbl_pubcert) mlabposition(3) mlabsize(vsmall)) ///
       (scatter s_pnp     year, msymbol(none) mlabel(lbl_pnp)     mlabposition(3) mlabsize(vsmall)) ///
       (scatter s_fp      year, msymbol(none) mlabel(lbl_fp)      mlabposition(3) mlabsize(vsmall)), ///
       title("Sector share of under-1-year undergraduate certificates, 2000-2024", ///
             size(medsmall)) ///
       ytitle("Share of under-1-year undergrad certs (%)") ///
       xtitle("Year") ///
       xlabel(2000(4)2024) ///
       xscale(range(2000 2026)) ///
       ylabel(0(10)60, angle(horizontal)) ///
       legend(order(1 "Public 4-year" 2 "Public community college" ///
                    3 "Public cert-focused" 4 "Private nonprofit" ///
                    5 "For-profit") ///
              rows(2) position(6) size(small)) ///
       graphregion(color(white)) plotregion(color(white))

graph export "output/figures/fig_3B_sector_share_under1yr_certs_undergrad.png", ///
    replace width(1600)

*===============================================================
* FIGURE 3C: Count of graduate certificates by sector
* (codes 6 = postbacc, 8 = post-master's, combined)
*===============================================================

use `working', clear
keep if inlist(awlevel, 6, 8)

collapse (sum) ctotalt, by(year sector)
reshape wide ctotalt, i(year) j(sector)
rename ctotalt1 pub4yr
rename ctotalt2 pubcc
rename ctotalt3 pubcert
rename ctotalt4 pnp
rename ctotalt5 fp

gen lbl_pub4yr  = string(pub4yr,  "%9.0fc") if year == 2024
gen lbl_pubcc   = string(pubcc,   "%9.0fc") if year == 2024
gen lbl_pubcert = string(pubcert, "%9.0fc") if year == 2024
gen lbl_pnp     = string(pnp,     "%9.0fc") if year == 2024
gen lbl_fp      = string(fp,      "%9.0fc") if year == 2024

twoway (line pub4yr  year, lwidth(medthick)) ///
       (line pubcc   year, lwidth(medthick)) ///
       (line pubcert year, lwidth(medthick)) ///
       (line pnp     year, lwidth(medthick)) ///
       (line fp      year, lwidth(medthick)) ///
       (scatter pub4yr  year, msymbol(none) mlabel(lbl_pub4yr)  mlabposition(3) mlabsize(vsmall)) ///
       (scatter pubcc   year, msymbol(none) mlabel(lbl_pubcc)   mlabposition(3) mlabsize(vsmall)) ///
       (scatter pubcert year, msymbol(none) mlabel(lbl_pubcert) mlabposition(3) mlabsize(vsmall)) ///
       (scatter pnp     year, msymbol(none) mlabel(lbl_pnp)     mlabposition(3) mlabsize(vsmall)) ///
       (scatter fp      year, msymbol(none) mlabel(lbl_fp)      mlabposition(3) mlabsize(vsmall)), ///
       title("Graduate certificates by sector, 2000-2024", ///
             size(medsmall)) ///
       ytitle("Graduate certificates conferred") ///
       xtitle("Year") ///
       xlabel(2000(4)2024) ///
       xscale(range(2000 2026)) ///
       ylabel(, format(%9.0fc) angle(horizontal)) ///
       legend(order(1 "Public 4-year" 2 "Public community college" ///
                    3 "Public cert-focused" 4 "Private nonprofit" ///
                    5 "For-profit") ///
              rows(2) position(6) size(small)) ///
       graphregion(color(white)) plotregion(color(white))

graph export "output/figures/fig_3C_grad_certs_by_sector.png", ///
    replace width(1600)

*===============================================================
* FIGURE 3D: Sector share of graduate certificates
*===============================================================

use `working', clear
keep if inlist(awlevel, 6, 8)

collapse (sum) ctotalt, by(year sector)
bysort year: egen year_total = total(ctotalt)
gen share = 100 * ctotalt / year_total

keep year sector share
reshape wide share, i(year) j(sector)
rename share1 s_pub4yr
rename share2 s_pubcc
rename share3 s_pubcert
rename share4 s_pnp
rename share5 s_fp

gen lbl_pub4yr  = string(s_pub4yr,  "%4.1f") + "%" if year == 2024
gen lbl_pubcc   = string(s_pubcc,   "%4.1f") + "%" if year == 2024
gen lbl_pubcert = string(s_pubcert, "%4.1f") + "%" if year == 2024
gen lbl_pnp     = string(s_pnp,     "%4.1f") + "%" if year == 2024
gen lbl_fp      = string(s_fp,      "%4.1f") + "%" if year == 2024

twoway (line s_pub4yr  year, lwidth(medthick)) ///
       (line s_pubcc   year, lwidth(medthick)) ///
       (line s_pubcert year, lwidth(medthick)) ///
       (line s_pnp     year, lwidth(medthick)) ///
       (line s_fp      year, lwidth(medthick)) ///
       (scatter s_pub4yr  year, msymbol(none) mlabel(lbl_pub4yr)  mlabposition(3) mlabsize(vsmall)) ///
       (scatter s_pubcc   year, msymbol(none) mlabel(lbl_pubcc)   mlabposition(3) mlabsize(vsmall)) ///
       (scatter s_pubcert year, msymbol(none) mlabel(lbl_pubcert) mlabposition(3) mlabsize(vsmall)) ///
       (scatter s_pnp     year, msymbol(none) mlabel(lbl_pnp)     mlabposition(3) mlabsize(vsmall)) ///
       (scatter s_fp      year, msymbol(none) mlabel(lbl_fp)      mlabposition(3) mlabsize(vsmall)), ///
       title("Sector share of graduate certificates, 2000-2024", ///
             size(medsmall)) ///
       ytitle("Share of graduate certs (%)") ///
       xtitle("Year") ///
       xlabel(2000(4)2024) ///
       xscale(range(2000 2026)) ///
       ylabel(0(10)80, angle(horizontal)) ///
       legend(order(1 "Public 4-year" 2 "Public community college" ///
                    3 "Public cert-focused" 4 "Private nonprofit" ///
                    5 "For-profit") ///
              rows(2) position(6) size(small)) ///
       graphregion(color(white)) plotregion(color(white))

graph export "output/figures/fig_3D_sector_share_grad_certs.png", ///
    replace width(1600)

display _newline "=== Section 2.3 figures done ==="


