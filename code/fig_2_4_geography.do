
*===============================================================
* fig_2_4_geography.do
* Section 2.4: Geography
*   4A: State choropleth, cert-to-associate ratio, 2024
*   4B: 50-state trends of cert-to-associate ratio, 2000-2024
*   4C: Community college ratio by locale (rural vs urban)
*===============================================================

clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"

capture which spmap
if _rc ssc install spmap
capture which shp2dta
if _rc ssc install shp2dta

*---------------------------------------------------------------
* One-time: convert shapefile to spmap format
* (comment this block out after first successful run)
*---------------------------------------------------------------
capture confirm file "data/clean/us_state_db.dta"
if _rc {
    shp2dta using "data/raw/shapefiles/cb_2022_us_state_20m", ///
        database("data/clean/us_state_db") ///
        coordinates("data/clean/us_state_coord") ///
        genid(id) replace
}

*---------------------------------------------------------------
* Prep base panel (state-level, all years)
*---------------------------------------------------------------
use "data/clean/completions_panel_with_preddeg.dta", clear

gen is_ug_cert = inlist(awlevel, 1, 2, 4, 20, 21)
gen is_assoc = (awlevel == 3)
keep if is_ug_cert == 1 | is_assoc == 1

gen certs = ctotalt * is_ug_cert
gen assocs = ctotalt * is_assoc

tempfile base
save `base'

*===============================================================
* FIGURE 4A: State choropleth for 2024
*===============================================================

use `base', clear
keep if year == 2024
collapse (sum) certs assocs, by(stabbr)
gen ratio = certs / assocs

* Save state ratios
keep stabbr ratio
rename stabbr STUSPS
save "data/clean/state_ratio_2024.dta", replace

* Load shapefile database, merge, filter to lower 48
use "data/clean/us_state_db.dta", clear
merge 1:1 STUSPS using "data/clean/state_ratio_2024.dta", keep(master match) nogen

* Drop Alaska, Hawaii, and territories
drop if inlist(STUSPS, "AK", "HI", "PR", "VI", "GU", "AS", "MP")

local brk 0 0.25 0.5 0.75 1.0 1.5 3.0

spmap ratio using "data/clean/us_state_coord.dta", id(id) ///
    clmethod(custom) clbreaks(`brk') fcolor(Blues) ///
    ocolor(white ..) osize(vthin ..) ndfcolor(gs13) ///
    legend(on position(5) size(vsmall) symysize(2) symxsize(2)) ///
    legtitle("Cert / Assoc") ///
    title("Certificate-to-associate degree ratio by state, 2024", size(medsmall)) ///
    graphregion(color(white))

graph export "output/figures/fig_4A_state_cert_assoc_ratio_2024.png", ///
    replace width(1600)

	
	
	
clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"

*---------------------------------------------------------------
* Rebuild base
*---------------------------------------------------------------
use "data/clean/completions_panel_with_preddeg.dta", clear

gen is_ug_cert = inlist(awlevel, 1, 2, 4, 20, 21)
gen is_assoc = (awlevel == 3)
keep if is_ug_cert == 1 | is_assoc == 1
gen certs = ctotalt * is_ug_cert
gen assocs = ctotalt * is_assoc

tempfile base
save `base'

*===============================================================
* FIGURE 4B: 50-state trends with highlights
*===============================================================
use `base', clear
collapse (sum) certs assocs, by(stabbr year)
gen ratio = certs / assocs

drop if inlist(stabbr, "AS", "GU", "MP", "PR", "VI")
drop if inlist(stabbr, "PW", "MH", "FM", "DC", "")

replace ratio = 5.5 if ratio > 5.5 & !missing(ratio)

encode stabbr, gen(state_id)
qui summ state_id
local N = r(max)

* Gray background: 50 lines
local gray_cmd ""
forvalues i = 1/`N' {
    local gray_cmd `gray_cmd' (line ratio year if state_id == `i', ///
        lcolor(gs13) lwidth(vthin))
}

* Highlight states, each with its own end-of-line label position.
* Top cluster (GA, HI, KY, LA near 3.0): stagger with positions 1, 2, 3, 4
* Bottom cluster (NY, NH near 0.5): stagger with 2 and 4

gen lbl_LA = stabbr if year == 2024 & stabbr == "LA"
gen lbl_KY = stabbr if year == 2024 & stabbr == "KY"
gen lbl_GA = stabbr if year == 2024 & stabbr == "GA"
gen lbl_HI = stabbr if year == 2024 & stabbr == "HI"
gen lbl_NY = stabbr if year == 2024 & stabbr == "NY"
gen lbl_NH = stabbr if year == 2024 & stabbr == "NH"

twoway `gray_cmd' ///
       (line ratio year if stabbr == "LA", lwidth(medthick) lcolor(navy)) ///
       (line ratio year if stabbr == "KY", lwidth(medthick) lcolor(maroon)) ///
       (line ratio year if stabbr == "GA", lwidth(medthick) lcolor(forest_green)) ///
       (line ratio year if stabbr == "HI", lwidth(medthick) lcolor(dkorange)) ///
       (line ratio year if stabbr == "NY", lwidth(medthick) lcolor(teal)) ///
       (line ratio year if stabbr == "NH", lwidth(medthick) lcolor(cranberry)) ///
       (scatter ratio year if stabbr == "LA", msymbol(none) ///
            mlabel(lbl_LA) mlabposition(3) mlabsize(vsmall) mlabgap(2) mlabcolor(navy)) ///
       (scatter ratio year if stabbr == "KY", msymbol(none) ///
            mlabel(lbl_KY) mlabposition(2) mlabsize(vsmall) mlabgap(2) mlabcolor(maroon)) ///
       (scatter ratio year if stabbr == "GA", msymbol(none) ///
            mlabel(lbl_GA) mlabposition(4) mlabsize(vsmall) mlabgap(2) mlabcolor(forest_green)) ///
       (scatter ratio year if stabbr == "HI", msymbol(none) ///
            mlabel(lbl_HI) mlabposition(1) mlabsize(vsmall) mlabgap(3) mlabcolor(dkorange)) ///
       (scatter ratio year if stabbr == "NY", msymbol(none) ///
            mlabel(lbl_NY) mlabposition(2) mlabsize(vsmall) mlabgap(2) mlabcolor(teal)) ///
       (scatter ratio year if stabbr == "NH", msymbol(none) ///
            mlabel(lbl_NH) mlabposition(4) mlabsize(vsmall) mlabgap(2) mlabcolor(cranberry)), ///
       title("Certificate-to-associate ratio trends by state, 2000-2024", ///
             size(medsmall)) ///
       ytitle("Certificates / associate degrees") ///
       xtitle("Year") ///
       xlabel(2000(4)2024) ///
       xscale(range(2000 2027)) ///
       ylabel(0(1)5, angle(horizontal)) ///
       legend(off) ///
       graphregion(color(white)) plotregion(color(white))

graph export "output/figures/fig_4B_state_ratio_trends.png", ///
    replace width(1600)

*===============================================================
* FIGURE 4C: Community colleges by locale
*===============================================================

import delimited "data/raw/ipeds/hd2022_data_stata.csv", ///
    clear stringcols(_all) case(lower) varnames(1)

keep unitid locale
destring unitid locale, replace force
tempfile locale_map
save `locale_map'

use `base', clear
merge m:1 unitid using `locale_map', keep(master match) nogen

keep if control == 1 & preddeg == 2

gen locale_bkt = .
replace locale_bkt = 1 if inrange(locale, 11, 13)
replace locale_bkt = 2 if inrange(locale, 21, 23)
replace locale_bkt = 3 if inrange(locale, 31, 33)
replace locale_bkt = 4 if inrange(locale, 41, 43)
drop if missing(locale_bkt)

collapse (sum) certs assocs, by(year locale_bkt)
gen ratio = certs / assocs

keep year locale_bkt ratio
reshape wide ratio, i(year) j(locale_bkt)
rename ratio1 city
rename ratio2 suburb
rename ratio3 town
rename ratio4 rural

gen lbl_city   = string(city,   "%3.2f") if year == 2024
gen lbl_suburb = string(suburb, "%3.2f") if year == 2024
gen lbl_town   = string(town,   "%3.2f") if year == 2024
gen lbl_rural  = string(rural,  "%3.2f") if year == 2024

twoway (line city   year, lwidth(medthick)) ///
       (line suburb year, lwidth(medthick)) ///
       (line town   year, lwidth(medthick)) ///
       (line rural  year, lwidth(medthick)) ///
       (scatter city   year, msymbol(none) mlabel(lbl_city)   mlabposition(3) mlabsize(vsmall)) ///
       (scatter suburb year, msymbol(none) mlabel(lbl_suburb) mlabposition(3) mlabsize(vsmall)) ///
       (scatter town   year, msymbol(none) mlabel(lbl_town)   mlabposition(3) mlabsize(vsmall)) ///
       (scatter rural  year, msymbol(none) mlabel(lbl_rural)  mlabposition(3) mlabsize(vsmall)), ///
       title("Certificate-to-associate ratio at community colleges, by locale", ///
             size(medsmall)) ///
       ytitle("Certificates / associate degrees") ///
       xtitle("Year") ///
       xlabel(2000(4)2024) ///
       xscale(range(2000 2026)) ///
       ylabel(, angle(horizontal)) ///
       legend(order(1 "City" 2 "Suburb" 3 "Town" 4 "Rural") ///
              rows(1) position(6) size(small)) ///
       graphregion(color(white)) plotregion(color(white))

graph export "output/figures/fig_4C_cc_ratio_by_locale.png", ///
    replace width(1600)

display _newline "=== Section 2.4 figures done ==="









