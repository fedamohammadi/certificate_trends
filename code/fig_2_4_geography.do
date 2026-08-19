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
*---------------------------------------------------------------
capture confirm file "data/clean/us_state_db.dta"
if _rc {
    shp2dta using "data/raw/shapefiles/cb_2022_us_state_20m", ///
        database("data/clean/us_state_db") ///
        coordinates("data/clean/us_state_coord") ///
        genid(id) replace
}

*---------------------------------------------------------------
* One-time: Albers equal-area conic projection of state coords
* Standard parallels 29.5N and 45.5N, central meridian 96W
*---------------------------------------------------------------
capture confirm file "data/clean/us_state_coord_albers.dta"
if _rc {
    use "data/clean/us_state_coord.dta", clear

    local p1 = 29.5 * _pi/180
    local p2 = 45.5 * _pi/180
    local p0 = 37.5 * _pi/180
    local l0 = -96  * _pi/180

    local n    = (sin(`p1') + sin(`p2')) / 2
    local C    = cos(`p1')^2 + 2*`n'*sin(`p1')
    local rho0 = sqrt(`C' - 2*`n'*sin(`p0')) / `n'

    gen double phi   = _Y * _pi/180
    gen double lam   = _X * _pi/180
    gen double rho   = sqrt(`C' - 2*`n'*sin(phi)) / `n'
    gen double theta = `n' * (lam - `l0')

    replace _X = rho * sin(theta)
    replace _Y = `rho0' - rho * cos(theta)

    drop phi lam rho theta
    save "data/clean/us_state_coord_albers.dta", replace
}

*---------------------------------------------------------------
* Prep base panel (saved to disk so blocks can be run separately)
*---------------------------------------------------------------
use "data/clean/completions_panel_with_preddeg.dta", clear

gen is_ug_cert = inlist(awlevel, 1, 2, 4, 20, 21)
gen is_assoc = (awlevel == 3)
keep if is_ug_cert == 1 | is_assoc == 1

gen certs = ctotalt * is_ug_cert
gen assocs = ctotalt * is_assoc

save "data/clean/geo_base.dta", replace

*===============================================================
* FIGURE 4A: State choropleth for 2024
*===============================================================

use "data/clean/geo_base.dta", clear
keep if year == 2024
collapse (sum) certs assocs, by(stabbr)
gen ratio = certs / assocs

keep stabbr ratio
rename stabbr STUSPS
save "data/clean/state_ratio_2024.dta", replace

use "data/clean/us_state_db.dta", clear
merge 1:1 STUSPS using "data/clean/state_ratio_2024.dta", keep(master match) nogen

* Drop Alaska, Hawaii, DC, and all territories
drop if inlist(STUSPS, "AK", "HI", "DC", "PR", "VI", "GU", "AS", "MP")
drop if inlist(STUSPS, "PW", "MH", "FM")

local brk 0 0.5 1.0 1.5 2.0 3.0 4.0

spmap ratio using "data/clean/us_state_coord_albers.dta", id(id) ///
    clmethod(custom) clbreaks(`brk') fcolor(Blues) ///
    ocolor(white ..) osize(vthin ..) ndfcolor(gs13) ///
    legend(on position(5) ring(0) size(vsmall) symysize(3) symxsize(3) ///
           label(2 "0.0 to 0.5") ///
           label(3 "0.5 to 1.0") ///
           label(4 "1.0 to 1.5") ///
           label(5 "1.5 to 2.0") ///
           label(6 "2.0 to 3.0") ///
           label(7 "3.0 to 4.0")) ///
    legtitle("Cert per associate") ///
    graphregion(color(white)) ///
    xsize(7) ysize(4.2)

graph export "output/figures/fig_4A_state_cert_assoc_ratio_2024.png", ///
    replace width(2100)

*===============================================================
* FIGURE 4B: 50-state trends with highlights
*===============================================================

use "data/clean/geo_base.dta", clear
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

gen lbl_LA = stabbr if year == 2024 & stabbr == "LA"
gen lbl_IN = stabbr if year == 2024 & stabbr == "IN"
gen lbl_KY = stabbr if year == 2024 & stabbr == "KY"
gen lbl_GA = stabbr if year == 2024 & stabbr == "GA"
gen lbl_WI = stabbr if year == 2024 & stabbr == "WI"
gen lbl_HI = stabbr if year == 2024 & stabbr == "HI"
gen lbl_NY = stabbr if year == 2024 & stabbr == "NY"
gen lbl_NH = stabbr if year == 2024 & stabbr == "NH"

twoway `gray_cmd' ///
       (line ratio year if stabbr == "LA", lwidth(medthick) lcolor(navy)) ///
       (line ratio year if stabbr == "IN", lwidth(medthick) lcolor(purple)) ///
       (line ratio year if stabbr == "KY", lwidth(medthick) lcolor(maroon)) ///
       (line ratio year if stabbr == "GA", lwidth(medthick) lcolor(forest_green)) ///
       (line ratio year if stabbr == "WI", lwidth(medthick) lcolor(dknavy)) ///
       (line ratio year if stabbr == "HI", lwidth(medthick) lcolor(dkorange)) ///
       (line ratio year if stabbr == "NY", lwidth(medthick) lcolor(teal)) ///
       (line ratio year if stabbr == "NH", lwidth(medthick) lcolor(cranberry)) ///
       (scatter ratio year if stabbr == "LA", msymbol(none) ///
            mlabel(lbl_LA) mlabposition(3) mlabsize(vsmall) mlabgap(2) mlabcolor(navy)) ///
       (scatter ratio year if stabbr == "IN", msymbol(none) ///
            mlabel(lbl_IN) mlabposition(2) mlabsize(vsmall) mlabgap(2) mlabcolor(purple)) ///
       (scatter ratio year if stabbr == "KY", msymbol(none) ///
            mlabel(lbl_KY) mlabposition(4) mlabsize(vsmall) mlabgap(2) mlabcolor(maroon)) ///
       (scatter ratio year if stabbr == "GA", msymbol(none) ///
            mlabel(lbl_GA) mlabposition(2) mlabsize(vsmall) mlabgap(3) mlabcolor(forest_green)) ///
       (scatter ratio year if stabbr == "WI", msymbol(none) ///
            mlabel(lbl_WI) mlabposition(3) mlabsize(vsmall) mlabgap(2) mlabcolor(dknavy)) ///
       (scatter ratio year if stabbr == "HI", msymbol(none) ///
            mlabel(lbl_HI) mlabposition(1) mlabsize(vsmall) mlabgap(3) mlabcolor(dkorange)) ///
       (scatter ratio year if stabbr == "NY", msymbol(none) ///
            mlabel(lbl_NY) mlabposition(2) mlabsize(vsmall) mlabgap(2) mlabcolor(teal)) ///
       (scatter ratio year if stabbr == "NH", msymbol(none) ///
            mlabel(lbl_NH) mlabposition(4) mlabsize(vsmall) mlabgap(2) mlabcolor(cranberry)), ///
       ytitle("Certificates / associate degrees", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2000(4)2024, labsize(small)) ///
       xscale(range(2000 2027)) ///
       ylabel(0(1)5, angle(horizontal) labsize(small)) ///
       legend(off) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)

graph export "output/figures/fig_4B_state_ratio_trends.png", ///
    replace width(2100)

*===============================================================
* FIGURE 4C: Community colleges by locale
*===============================================================

import delimited "data/raw/ipeds/hd2022_data_stata.csv", ///
    clear stringcols(_all) case(lower) varnames(1)

keep unitid locale
destring unitid locale, replace force
tempfile locale_map
save `locale_map'

use "data/clean/geo_base.dta", clear
merge m:1 unitid using `locale_map', keep(master match) nogen


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

twoway (line city   year, lwidth(medthick) lcolor("31 119 180")) ///
       (line suburb year, lwidth(medthick) lcolor("214 39 40")) ///
       (line town   year, lwidth(medthick) lcolor("44 160 44")) ///
       (line rural  year, lwidth(medthick) lcolor("255 127 14")) ///
       (scatter city   year, msymbol(none) mlabel(lbl_city)   mlabposition(2) mlabsize(vsmall) mlabcolor("31 119 180")) ///
       (scatter suburb year, msymbol(none) mlabel(lbl_suburb) mlabposition(3) mlabsize(vsmall) mlabcolor("214 39 40")) ///
       (scatter town   year, msymbol(none) mlabel(lbl_town)   mlabposition(3) mlabsize(vsmall) mlabcolor("44 160 44")) ///
       (scatter rural  year, msymbol(none) mlabel(lbl_rural)  mlabposition(4) mlabsize(vsmall) mlabcolor("255 127 14")), ///
       ytitle("Certificates / associate degrees", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2000(4)2024, labsize(small)) ///
       xscale(range(2000 2027)) ///
       ylabel(, angle(horizontal) labsize(small)) ///
       legend(order(1 "City" 2 "Suburb" 3 "Town" 4 "Rural") ///
              rows(1) position(6) size(small) region(lstyle(none))) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)

graph export "output/figures/fig_4C_cc_ratio_by_locale.png", ///
    replace width(2100)

display _newline "=== Section 2.4 figures done ==="





use "data/clean/geo_base.dta", clear
keep if year == 2024

gen certs_u1 = ctotalt * inlist(awlevel, 1, 20, 21)

collapse (sum) certs certs_u1 assocs, by(stabbr)
gen ratio_all = certs / assocs
gen ratio_u1  = certs_u1 / assocs

drop if inlist(stabbr, "AS","GU","MP","PR","VI")
drop if inlist(stabbr, "PW","MH","FM","DC","")

format ratio_all ratio_u1 %5.2f
gsort -ratio_all
list stabbr ratio_all ratio_u1 in 1/8, noobs
gsort ratio_all
list stabbr ratio_all ratio_u1 in 1/6, noobs
count





*===============================================================
* FIGURE 6B: State choropleth, under-1-year cert ratio, 2024
*===============================================================

use "data/clean/geo_base.dta", clear
keep if year == 2024

gen certs_u1 = ctotalt * inlist(awlevel, 1, 20, 21)

collapse (sum) certs_u1 assocs, by(stabbr)
gen ratio = certs_u1 / assocs

keep stabbr ratio
rename stabbr STUSPS
save "data/clean/state_ratio_u1_2024.dta", replace

use "data/clean/us_state_db.dta", clear
merge 1:1 STUSPS using "data/clean/state_ratio_u1_2024.dta", keep(master match) nogen

drop if inlist(STUSPS, "AK", "HI", "DC", "PR", "VI", "GU", "AS", "MP")

local brk 0 0.5 1.0 1.5 2.0 3.0

spmap ratio using "data/clean/us_state_coord_albers.dta", id(id) ///
    clmethod(custom) clbreaks(`brk') fcolor(Blues) ///
    ocolor(white ..) osize(vthin ..) ndfcolor(gs13) ///
    legend(on position(5) ring(0) size(vsmall) symysize(3) symxsize(3) ///
           label(2 "0.0 to 0.5") ///
           label(3 "0.5 to 1.0") ///
           label(4 "1.0 to 1.5") ///
           label(5 "1.5 to 2.0") ///
           label(6 "2.0 to 3.0")) ///
    legtitle("Under-1-year certs per associate") ///
    graphregion(color(white)) ///
    xsize(7) ysize(4.2)

graph export "output/figures/fig_6B_state_cert_assoc_ratio_u1_2024.png", ///
    replace width(2100)




*===============================================================
* FIGURE 7B: State trends, under-1-year cert-to-associate ratio
*===============================================================

use "data/clean/geo_base.dta", clear

gen certs_u1 = ctotalt * inlist(awlevel, 1, 20, 21)

collapse (sum) certs_u1 assocs, by(stabbr year)
gen ratio = certs_u1 / assocs

drop if inlist(stabbr, "AS", "GU", "MP", "PR", "VI")
drop if inlist(stabbr, "PW", "MH", "FM", "DC", "")

encode stabbr, gen(state_id)
qui summ state_id
local N = r(max)

local gray_cmd ""
forvalues i = 1/`N' {
    local gray_cmd `gray_cmd' (line ratio year if state_id == `i', ///
        lcolor(gs13) lwidth(vthin))
}

gen lbl_KY = stabbr if year == 2024 & stabbr == "KY"
gen lbl_GA = stabbr if year == 2024 & stabbr == "GA"
gen lbl_LA = stabbr if year == 2024 & stabbr == "LA"
gen lbl_WI = stabbr if year == 2024 & stabbr == "WI"
gen lbl_IN = stabbr if year == 2024 & stabbr == "IN"
gen lbl_HI = stabbr if year == 2024 & stabbr == "HI"
gen lbl_NY = stabbr if year == 2024 & stabbr == "NY"
gen lbl_NH = stabbr if year == 2024 & stabbr == "NH"

twoway `gray_cmd' ///
       (line ratio year if stabbr == "KY", lwidth(medthick) lcolor(maroon)) ///
       (line ratio year if stabbr == "GA", lwidth(medthick) lcolor(forest_green)) ///
       (line ratio year if stabbr == "LA", lwidth(medthick) lcolor(navy)) ///
       (line ratio year if stabbr == "WI", lwidth(medthick) lcolor(dknavy)) ///
       (line ratio year if stabbr == "IN", lwidth(medthick) lcolor(purple)) ///
       (line ratio year if stabbr == "HI", lwidth(medthick) lcolor(dkorange)) ///
       (line ratio year if stabbr == "NY", lwidth(medthick) lcolor(teal)) ///
       (line ratio year if stabbr == "NH", lwidth(medthick) lcolor(cranberry)) ///
       (scatter ratio year if stabbr == "KY", msymbol(none) ///
            mlabel(lbl_KY) mlabposition(2) mlabsize(vsmall) mlabgap(2) mlabcolor(maroon)) ///
       (scatter ratio year if stabbr == "GA", msymbol(none) ///
            mlabel(lbl_GA) mlabposition(4) mlabsize(vsmall) mlabgap(2) mlabcolor(forest_green)) ///
       (scatter ratio year if stabbr == "LA", msymbol(none) ///
            mlabel(lbl_LA) mlabposition(2) mlabsize(vsmall) mlabgap(3) mlabcolor(navy)) ///
       (scatter ratio year if stabbr == "WI", msymbol(none) ///
            mlabel(lbl_WI) mlabposition(4) mlabsize(vsmall) mlabgap(3) mlabcolor(dknavy)) ///
       (scatter ratio year if stabbr == "IN", msymbol(none) ///
            mlabel(lbl_IN) mlabposition(3) mlabsize(vsmall) mlabgap(2) mlabcolor(purple)) ///
       (scatter ratio year if stabbr == "HI", msymbol(none) ///
            mlabel(lbl_HI) mlabposition(1) mlabsize(vsmall) mlabgap(4) mlabcolor(dkorange)) ///
       (scatter ratio year if stabbr == "NY", msymbol(none) ///
            mlabel(lbl_NY) mlabposition(3) mlabsize(vsmall) mlabgap(2) mlabcolor(teal)) ///
       (scatter ratio year if stabbr == "NH", msymbol(none) ///
            mlabel(lbl_NH) mlabposition(5) mlabsize(vsmall) mlabgap(4) mlabcolor(cranberry)), ///
       ytitle("Under-1-year certificates / associate degrees", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2000(4)2024, labsize(small)) ///
       xscale(range(2000 2027)) ///
       ylabel(0(0.5)3.5, angle(horizontal) labsize(small)) ///
       legend(off) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)

graph export "output/figures/fig_7B_state_ratio_trends_u1.png", ///
    replace width(2100)


	
*===============================================================
* FIGURE 8A: Cert-to-associate ratio by locale, all institutions
*===============================================================

import delimited "data/raw/ipeds/hd2022_data_stata.csv", ///
    clear stringcols(_all) case(lower) varnames(1)

keep unitid locale
destring unitid locale, replace force
tempfile locale_map
save `locale_map'

use "data/clean/geo_base.dta", clear
merge m:1 unitid using `locale_map', keep(master match) nogen

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

twoway (line city   year, lwidth(medthick) lcolor("31 119 180")) ///
       (line suburb year, lwidth(medthick) lcolor("214 39 40")) ///
       (line town   year, lwidth(medthick) lcolor("44 160 44")) ///
       (line rural  year, lwidth(medthick) lcolor("255 127 14")) ///
       (scatter city   year, msymbol(none) mlabel(lbl_city)   mlabposition(2) mlabsize(vsmall) mlabcolor("31 119 180")) ///
       (scatter suburb year, msymbol(none) mlabel(lbl_suburb) mlabposition(3) mlabsize(vsmall) mlabcolor("214 39 40")) ///
       (scatter town   year, msymbol(none) mlabel(lbl_town)   mlabposition(1) mlabsize(vsmall) mlabcolor("44 160 44")) ///
       (scatter rural  year, msymbol(none) mlabel(lbl_rural)  mlabposition(5) mlabsize(vsmall) mlabcolor("255 127 14")), ///
       ytitle("Certificates / associate degrees", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2000(4)2024, labsize(small)) ///
       xscale(range(2000 2027)) ///
       ylabel(, angle(horizontal) labsize(small)) ///
       legend(order(1 "City" 2 "Suburb" 3 "Town" 4 "Rural") ///
              rows(1) position(6) size(small) region(lstyle(none))) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)

graph export "output/figures/fig_8A_ratio_by_locale_all.png", ///
    replace width(2100)

