*===============================================================
* fig_2_5_field.do
* Section 2.5: Field
*   5A (treemap version):     top fields, 2024
*   5A (bar chart version):   top fields, 2024
*   5B: Stacked area chart, field composition over time
*===============================================================

clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"
capture mkdir "output/editable_figs"

* One-time treemap install (run once, then comment out):
*capture which treemap
*if _rc net install treemap, ///
    from("https://raw.githubusercontent.com/asjadnaqvi/stata-treemap/main/installation/") ///
    replace

*---------------------------------------------------------------
* Base: undergraduate certificates only, by year and cip2
*---------------------------------------------------------------
use "data/clean/completions_panel_2000_2024.dta", clear
keep if inlist(awlevel, 1, 2, 4, 20, 21)
keep if inrange(year, 2000, 2024)

collapse (sum) ctotalt, by(year cip2)

* Human-readable CIP names
gen cip_name = ""
replace cip_name = "Agriculture" if cip2 == "01"
replace cip_name = "Natural resources" if cip2 == "03"
replace cip_name = "Architecture" if cip2 == "04"
replace cip_name = "Communications" if cip2 == "09"
replace cip_name = "Communication tech" if cip2 == "10"
replace cip_name = "Computer science" if cip2 == "11"
replace cip_name = "Personal services" if cip2 == "12"
replace cip_name = "Education" if cip2 == "13"
replace cip_name = "Engineering" if cip2 == "14"
replace cip_name = "Engineering tech" if cip2 == "15"
replace cip_name = "Foreign languages" if cip2 == "16"
replace cip_name = "Family & consumer sci" if cip2 == "19"
replace cip_name = "Legal" if cip2 == "22"
replace cip_name = "English" if cip2 == "23"
replace cip_name = "Liberal arts" if cip2 == "24"
replace cip_name = "Library science" if cip2 == "25"
replace cip_name = "Biological sci" if cip2 == "26"
replace cip_name = "Mathematics" if cip2 == "27"
replace cip_name = "Military" if cip2 == "29"
replace cip_name = "Multi/interdisciplinary" if cip2 == "30"
replace cip_name = "Parks & recreation" if cip2 == "31"
replace cip_name = "Philosophy" if cip2 == "38"
replace cip_name = "Theology" if cip2 == "39"
replace cip_name = "Physical sci" if cip2 == "40"
replace cip_name = "Psychology" if cip2 == "42"
replace cip_name = "Homeland sec/protective" if cip2 == "43"
replace cip_name = "Public admin" if cip2 == "44"
replace cip_name = "Social sciences" if cip2 == "45"
replace cip_name = "Construction trades" if cip2 == "46"
replace cip_name = "Mechanic & repair" if cip2 == "47"
replace cip_name = "Precision production" if cip2 == "48"
replace cip_name = "Transportation" if cip2 == "49"
replace cip_name = "Visual & performing arts" if cip2 == "50"
replace cip_name = "Health professions" if cip2 == "51"
replace cip_name = "Business" if cip2 == "52"
replace cip_name = "History" if cip2 == "54"

replace cip_name = "Other" if missing(cip_name) | cip_name == ""

save "data/clean/field_panel.dta", replace

*===============================================================
* FIGURE 5A (treemap): Top fields, 2024
*===============================================================

use "data/clean/field_panel.dta", clear
keep if year == 2024

egen total_2024 = total(ctotalt)
gen share = 100 * ctotalt / total_2024

gsort -share
gen rk = _n
keep if rk <= 15

* Full field names, wrapped to fit inside the boxes
replace cip_name = "Homeland security"        if cip_name == "Homeland sec/protective"
replace cip_name = "Engineering tech"         if cip_name == "Engineering tech"
replace cip_name = "Family & consumer sci"    if cip_name == "Family & consumer sci"
replace cip_name = "Visual & perf arts" if cip_name == "Visual & performing arts"

* Build the label ourselves so we can add the percent sign
gen tm_label = cip_name + " " + string(share, "%3.0f") + "%"

treemap share, by(tm_label) ///
    novalues ///
    wrap(10) ///
    labsize(2.3) ///
    graphregion(color(white))

graph export "output/figures/fig_5A_treemap_field_share_2024.png", ///
    replace width(2400) height(1600)
graph export "output/editable_figs/fig_5A_treemap_field_share_2024.emf", replace
graph export "output/editable_figs/fig_5A_treemap_field_share_2024.pdf", replace
	
*===============================================================
* FIGURE 5A (bar chart): Top fields, 2024
*===============================================================

use "data/clean/field_panel.dta", clear
keep if year == 2024

egen total_2024 = total(ctotalt)
gen share = 100 * ctotalt / total_2024

gsort -share
gen rk = _n
keep if rk <= 15

gsort share
gen order = _n
gen lbl = string(share, "%3.1f") + "%"

graph hbar (asis) share, over(cip_name, sort(order) label(labsize(small))) ///
    blabel(bar, format(%3.1f) size(vsmall)) ///
    ytitle("Share of undergraduate certificates (%)", size(small)) ///
    ylabel(0(5)25, angle(horizontal) labsize(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    ysize(7) xsize(9)

graph export "output/figures/fig_5A_barchart_field_share_2024.png", ///
    replace width(2100)
graph export "output/editable_figs/fig_5A_barchart_field_share_2024.emf", replace
graph export "output/editable_figs/fig_5A_barchart_field_share_2024.pdf", replace

*===============================================================
* FIGURE 5B: Stacked area chart of top 8 field shares over time
*===============================================================

* Identify top 8 fields by 2024 share, with rank
use "data/clean/field_panel.dta", clear
preserve
    keep if year == 2024
    egen total_2024 = total(ctotalt)
    gen share_2024 = 100 * ctotalt / total_2024
    gsort -share_2024
    gen field_rank = _n
    keep in 1/8
    keep cip2 field_rank
    tempfile top8
    save `top8'
restore

* Merge rank onto full panel
merge m:1 cip2 using `top8', keep(master match) nogen

* Group non-top-8 as "Other" (rank 9)
gen field_id = field_rank
replace field_id = 9 if missing(field_rank)
replace cip_name = "Other" if field_id == 9

* Save the rank -> name mapping for the legend
preserve
    keep if field_id <= 8
    keep field_id cip_name
    duplicates drop
    sort field_id
    forvalues j = 1/8 {
        local name_`j' = cip_name[`j']
    }
restore

* Collapse to year x field_id
collapse (sum) ctotalt, by(year field_id)

* Compute shares within year
bysort year: egen year_total = total(ctotalt)
gen share = 100 * ctotalt / year_total

* Reshape to wide
keep year field_id share
reshape wide share, i(year) j(field_id)

forvalues j = 1/9 {
    capture rename share`j' f`j'
    capture confirm variable f`j'
    if _rc gen f`j' = 0
}

* Cumulative sums
gen cum1 = f1
gen cum2 = cum1 + f2
gen cum3 = cum2 + f3
gen cum4 = cum3 + f4
gen cum5 = cum4 + f5
gen cum6 = cum5 + f6
gen cum7 = cum6 + f7
gen cum8 = cum7 + f8
gen cum9 = cum8 + f9

twoway (area cum9 year, color(gs14)) ///
       (area cum8 year) ///
       (area cum7 year) ///
       (area cum6 year) ///
       (area cum5 year) ///
       (area cum4 year) ///
       (area cum3 year) ///
       (area cum2 year) ///
       (area cum1 year), ///
       ytitle("Share of undergrad certs (%)", size(small)) ///
       xtitle("Year", size(small)) ///
       xlabel(2000(4)2024, labsize(small)) ///
       ylabel(0(20)100, angle(horizontal) labsize(small)) ///
       legend(order(1 "Other" ///
                    2 "`name_8'" ///
                    3 "`name_7'" ///
                    4 "`name_6'" ///
                    5 "`name_5'" ///
                    6 "`name_4'" ///
                    7 "`name_3'" ///
                    8 "`name_2'" ///
                    9 "`name_1'") ///
              cols(3) position(6) size(vsmall) region(lstyle(none))) ///
       graphregion(color(white)) plotregion(color(white)) ///
       xsize(7) ysize(4.2)

graph export "output/figures/fig_5B_field_composition_over_time.png", ///
    replace width(2100)
graph export "output/editable_figs/fig_5B_field_composition_over_time.emf", replace
graph export "output/editable_figs/fig_5B_field_composition_over_time.pdf", replace

display _newline "=== Section 2.5 figures done ==="



