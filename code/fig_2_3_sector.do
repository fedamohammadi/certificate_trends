*===============================================================
* fig_2_3_sector.do
* Section 2.3: Sector
*   - Figure 3A: Count of <=1 year certs by sector -- undergrad
*   - Figure 3B: Sector share of <=1 year certs -- undergrad
*   - Figure 3C: Count of graduate certificates by sector
*   - Figure 3D: Sector share of graduate certificates
*
* Sector categories (based on CONTROL x PREDDEG):
*   1. Public 4-year    (public, predom. bachelor's or grad)
*   2. Public 2-year    (public, predom. associate's or certificate)
*   3. For-profit       (all PREDDEG combined)
*   4. Private nonprofit (all PREDDEG combined)
*===============================================================

clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"

use "data/clean/completions_panel_with_preddeg.dta", clear
keep if inrange(year, 2000, 2024)

*---------------------------------------------------------------
* Build the 4 sector categories
* CONTROL: 1 = public, 2 = private nonprofit, 3 = for-profit
* PREDDEG: 1 = cert, 2 = assoc, 3 = bach, 4 = grad
*---------------------------------------------------------------

gen sector = .
replace sector = 1 if control == 1 & inlist(preddeg, 3, 4)   // Public 4-year
replace sector = 2 if control == 1 & inlist(preddeg, 1, 2)   // Public 2-year
replace sector = 3 if control == 3                            // For-profit
replace sector = 4 if control == 2                            // Private nonprofit

label define sec 1 "Public 4-year" ///
                 2 "Public 2-year" ///
                 3 "For-profit" ///
                 4 "Private nonprofit"
label values sector sec

drop if missing(sector)

tempfile working
save `working'

*===============================================================
* FIGURE 3A: Count of under-1-year undergrad certs by sector
*===============================================================

use `working', clear
keep if inlist(awlevel, 1, 20, 21)

collapse (sum) ctotalt, by(year sector)
reshape wide ctotalt, i(year) j(sector)
rename ctotalt1 pub4yr
rename ctotalt2 pub2yr
rename ctotalt3 fp
rename ctotalt4 pnp

gen lbl_pub4yr = string(pub4yr, "%9.0fc") if year == 2024
gen lbl_pub2yr = string(pub2yr, "%9.0fc") if year == 2024
gen lbl_fp     = string(fp,     "%9.0fc") if year == 2024
gen lbl_pnp    = string(pnp,    "%9.0fc") if year == 2024

twoway (line pub4yr year, lwidth(medthick) lcolor("31 119 180")) ///
       (line pub2yr year, lwidth(medthick) lcolor("214 39 40")) ///
       (line fp     year, lwidth(medthick) lcolor("44 160 44")) ///
       (line pnp    year, lwidth(medthick) lcolor("255 127 14")) ///
       (scatter pub4yr year, msymbol(none) mlabel(lbl_pub4yr) mlabposition(2) mlabsize(vsmall) mlabcolor("31 119 180")) ///
       (scatter pub2yr year, msymbol(none) mlabel(lbl_pub2yr) mlabposition(3) mlabsize(vsmall) mlabcolor("214 39 40")) ///
       (scatter fp     year, msymbol(none) mlabel(lbl_fp)     mlabposition(3) mlabsize(vsmall) mlabcolor("44 160 44")) ///
       (scatter pnp    year, msymbol(none) mlabel(lbl_pnp)    mlabposition(4) mlabsize(vsmall) mlabcolor("255 127 14")), ///
       ytitle("Certificates conferred", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2000(4)2024, labsize(small)) ///
       xscale(range(2000 2027)) ///
       ylabel(, format(%9.0fc) angle(horizontal) labsize(small)) ///
       legend(order(1 "Public 4-year" 2 "Public 2-year" ///
                    3 "For-profit" 4 "Private nonprofit") ///
              rows(1) position(6) size(small) region(lstyle(none))) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)

graph export "output/figures/fig_3A_under1yr_certs_by_sector_undergrad.png", ///
    replace width(2100)

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
rename share2 s_pub2yr
rename share3 s_fp
rename share4 s_pnp

gen lbl_pub4yr = string(s_pub4yr, "%4.1f") + "%" if year == 2024
gen lbl_pub2yr = string(s_pub2yr, "%4.1f") + "%" if year == 2024
gen lbl_fp     = string(s_fp,     "%4.1f") + "%" if year == 2024
gen lbl_pnp    = string(s_pnp,    "%4.1f") + "%" if year == 2024

twoway (line s_pub4yr year, lwidth(medthick) lcolor("31 119 180")) ///
       (line s_pub2yr year, lwidth(medthick) lcolor("214 39 40")) ///
       (line s_fp     year, lwidth(medthick) lcolor("44 160 44")) ///
       (line s_pnp    year, lwidth(medthick) lcolor("255 127 14")) ///
       (scatter s_pub4yr year, msymbol(none) mlabel(lbl_pub4yr) mlabposition(2) mlabsize(vsmall) mlabcolor("31 119 180")) ///
       (scatter s_pub2yr year, msymbol(none) mlabel(lbl_pub2yr) mlabposition(3) mlabsize(vsmall) mlabcolor("214 39 40")) ///
       (scatter s_fp     year, msymbol(none) mlabel(lbl_fp)     mlabposition(3) mlabsize(vsmall) mlabcolor("44 160 44")) ///
       (scatter s_pnp    year, msymbol(none) mlabel(lbl_pnp)    mlabposition(4) mlabsize(vsmall) mlabcolor("255 127 14")), ///
       ytitle("Share of under-1-year undergrad certs (%)", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2000(4)2024, labsize(small)) ///
       xscale(range(2000 2027)) ///
       ylabel(0(10)80, angle(horizontal) labsize(small)) ///
       legend(order(1 "Public 4-year" 2 "Public 2-year" ///
                    3 "For-profit" 4 "Private nonprofit") ///
              rows(1) position(6) size(small) region(lstyle(none))) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)

graph export "output/figures/fig_3B_sector_share_under1yr_certs_undergrad.png", ///
    replace width(2100)

*===============================================================
* FIGURE 3C: Count of graduate certificates by sector
* (codes 6 = postbacc, 8 = post-master's, combined)
*===============================================================

use `working', clear
keep if inlist(awlevel, 6, 8)

collapse (sum) ctotalt, by(year sector)
reshape wide ctotalt, i(year) j(sector)
rename ctotalt1 pub4yr
rename ctotalt2 pub2yr
rename ctotalt3 fp
rename ctotalt4 pnp

gen lbl_pub4yr = string(pub4yr, "%9.0fc") if year == 2024
gen lbl_pub2yr = string(pub2yr, "%9.0fc") if year == 2024
gen lbl_fp     = string(fp,     "%9.0fc") if year == 2024
gen lbl_pnp    = string(pnp,    "%9.0fc") if year == 2024

twoway (line pub4yr year, lwidth(medthick) lcolor("31 119 180")) ///
       (line pub2yr year, lwidth(medthick) lcolor("214 39 40")) ///
       (line fp     year, lwidth(medthick) lcolor("44 160 44")) ///
       (line pnp    year, lwidth(medthick) lcolor("255 127 14")) ///
       (scatter pub4yr year, msymbol(none) mlabel(lbl_pub4yr) mlabposition(3) mlabsize(vsmall) mlabcolor("31 119 180")) ///
       (scatter pub2yr year, msymbol(none) mlabel(lbl_pub2yr) mlabposition(4) mlabsize(vsmall) mlabcolor("214 39 40")) ///
       (scatter fp     year, msymbol(none) mlabel(lbl_fp)     mlabposition(2) mlabsize(vsmall) mlabcolor("44 160 44")) ///
       (scatter pnp    year, msymbol(none) mlabel(lbl_pnp)    mlabposition(3) mlabsize(vsmall) mlabcolor("255 127 14")), ///
       ytitle("Graduate certificates conferred", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2000(4)2024, labsize(small)) ///
       xscale(range(2000 2027)) ///
       ylabel(, format(%9.0fc) angle(horizontal) labsize(small)) ///
       legend(order(1 "Public 4-year" 2 "Public 2-year" ///
                    3 "For-profit" 4 "Private nonprofit") ///
              rows(1) position(6) size(small) region(lstyle(none))) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)

graph export "output/figures/fig_3C_grad_certs_by_sector.png", ///
    replace width(2100)

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
rename share2 s_pub2yr
rename share3 s_fp
rename share4 s_pnp

gen lbl_pub4yr = string(s_pub4yr, "%4.1f") + "%" if year == 2024
gen lbl_pub2yr = string(s_pub2yr, "%4.1f") + "%" if year == 2024
gen lbl_fp     = string(s_fp,     "%4.1f") + "%" if year == 2024
gen lbl_pnp    = string(s_pnp,    "%4.1f") + "%" if year == 2024

twoway (line s_pub4yr year, lwidth(medthick) lcolor("31 119 180")) ///
       (line s_pub2yr year, lwidth(medthick) lcolor("214 39 40")) ///
       (line s_fp     year, lwidth(medthick) lcolor("44 160 44")) ///
       (line s_pnp    year, lwidth(medthick) lcolor("255 127 14")) ///
       (scatter s_pub4yr year, msymbol(none) mlabel(lbl_pub4yr) mlabposition(3) mlabsize(vsmall) mlabcolor("31 119 180")) ///
       (scatter s_pub2yr year, msymbol(none) mlabel(lbl_pub2yr) mlabposition(4) mlabsize(vsmall) mlabcolor("214 39 40")) ///
       (scatter s_fp     year, msymbol(none) mlabel(lbl_fp)     mlabposition(2) mlabsize(vsmall) mlabcolor("44 160 44")) ///
       (scatter s_pnp    year, msymbol(none) mlabel(lbl_pnp)    mlabposition(3) mlabsize(vsmall) mlabcolor("255 127 14")), ///
       ytitle("Share of graduate certs (%)", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2000(4)2024, labsize(small)) ///
       xscale(range(2000 2027)) ///
       ylabel(0(10)70, angle(horizontal) labsize(small)) ///
       legend(order(1 "Public 4-year" 2 "Public 2-year" ///
                    3 "For-profit" 4 "Private nonprofit") ///
              rows(1) position(6) size(small) region(lstyle(none))) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)

graph export "output/figures/fig_3D_sector_share_grad_certs.png", ///
    replace width(2100)

display _newline "=== Section 2.3 figures done ==="