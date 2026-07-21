*===============================================================
* preddeg_diagnostic.do
* 1. Build Scorecard PREDDEG panel from 25 annual CSVs (1999_00 to 2023_24)
* 2. Merge onto completions panel
* 3. Diagnose how much PREDDEG flipping matters for national trends
*===============================================================

clear all
set more off

cd "C:\Users\mohammadif\Documents\certificate_trends"

*---------------------------------------------------------------
* Part 1: Build Scorecard PREDDEG panel
*---------------------------------------------------------------

tempfile scorecard_stack
save `scorecard_stack', emptyok

forvalues start = 1999/2023 {
    local end_yr = `start' + 1
    local end_2d = string(mod(`end_yr', 100), "%02.0f")
    local fname = "MERGED`start'_`end_2d'_PP.csv"
    
    display "Loading `fname'..."
    
    quietly import delimited "data/raw/scorecard/`fname'", ///
        clear stringcols(_all) case(lower) varnames(1)
    
    keep unitid preddeg
    replace preddeg = "" if inlist(preddeg, "NULL", "PrivacySuppressed", ".")
    destring unitid preddeg, replace force
    
    gen year = `end_yr'
    
    append using `scorecard_stack'
    save `scorecard_stack', replace
}

use `scorecard_stack', clear

label define preddeg_lbl 0 "Not classified" ///
                        1 "Predominantly certificate" ///
                        2 "Predominantly associate's" ///
                        3 "Predominantly bachelor's" ///
                        4 "Entirely graduate"
label values preddeg preddeg_lbl

save "data/clean/scorecard_preddeg_panel.dta", replace

display _newline "=== PREDDEG availability by year ==="
tab year preddeg, missing

*---------------------------------------------------------------
* Part 2: Merge Scorecard PREDDEG onto completions panel
*---------------------------------------------------------------

use "data/clean/completions_panel_2000_2024.dta", clear

merge m:1 unitid year using "data/clean/scorecard_preddeg_panel.dta", ///
    keep(master match)

display _newline "=== Merge results ==="
tab _merge
drop _merge

save "data/clean/completions_panel_with_preddeg.dta", replace

display _newline "=== PREDDEG coverage in completions panel ==="
tab year if missing(preddeg), missing

*===============================================================
* Part 3: Diagnostics (base Stata version)
*===============================================================

clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"

use "data/clean/completions_panel_with_preddeg.dta", clear

preserve
    collapse (sum) ctotalt (first) preddeg, by(unitid year)
    
    * Institution-level modal PREDDEG
    egen preddeg_mode = mode(preddeg), by(unitid) maxmode
    
    * Count distinct non-missing PREDDEG values per institution
    egen tag_up = tag(unitid preddeg) if !missing(preddeg)
    egen n_distinct_preddeg = total(tag_up), by(unitid)
    drop tag_up
    
    egen tag_inst = tag(unitid)
    
    display _newline "=== Diagnostic 1: Distinct PREDDEG values per institution ==="
    tab n_distinct_preddeg if tag_inst
    
    display _newline "=== Diagnostic 2: Detail on switching ==="
    summarize n_distinct_preddeg if tag_inst, detail
    
    gen ever_switched = (n_distinct_preddeg > 1) if n_distinct_preddeg > 0
    
    display _newline "=== Diagnostic 3: Share of national awards from switchers vs non-switchers ==="
    tabstat ctotalt, by(ever_switched) stat(sum N) format(%15.0fc)
    
    save "data/clean/inst_year_preddeg.dta", replace
restore

*---------------------------------------------------------------
* Diagnostic 4: Trends by PREDDEG under annual vs modal classification
*---------------------------------------------------------------

use "data/clean/completions_panel_with_preddeg.dta", clear

merge m:1 unitid using "data/clean/inst_year_preddeg.dta", ///
    keepusing(preddeg_mode) keep(master match) nogen

keep if inrange(year, 2000, 2024)

* Certificates only
gen is_cert = inlist(awlevel, 1, 2, 4, 6, 8, 20, 21)
keep if is_cert == 1

* Version A: annual PREDDEG
preserve
    collapse (sum) ctotalt, by(year preddeg)
    rename ctotalt certs_annual
    save "data/clean/tmp_annual.dta", replace
restore

* Version B: modal PREDDEG
collapse (sum) ctotalt, by(year preddeg_mode)
rename preddeg_mode preddeg
rename ctotalt certs_modal

merge 1:1 year preddeg using "data/clean/tmp_annual.dta", nogen

gen diff = certs_annual - certs_modal
gen pct_diff = 100 * diff / certs_modal

label define preddeg_short 0 "Not class" ///
                           1 "Cert" ///
                           2 "Assoc" ///
                           3 "Bach" ///
                           4 "Grad", replace
label values preddeg preddeg_short

display _newline "=== Diagnostic 4: Cert totals by PREDDEG, annual vs modal (2024) ==="
list year preddeg certs_annual certs_modal diff pct_diff if year == 2024, ///
    sepby(preddeg) noobs

display _newline "=== Same, 2011 (peak for-profit year) ==="
list year preddeg certs_annual certs_modal diff pct_diff if year == 2011, ///
    sepby(preddeg) noobs

erase "data/clean/tmp_annual.dta"

display _newline "=== DONE ==="




clear all
set more off
cd "C:\Users\mohammadif\Documents\certificate_trends"

*---------------------------------------------------------------
* Build institution-level file with just preddeg_mode
*---------------------------------------------------------------
use "data/clean/inst_year_preddeg.dta", clear
collapse (first) preddeg_mode, by(unitid)
save "data/clean/inst_preddeg_mode.dta", replace

*---------------------------------------------------------------
* Diagnostic 4
*---------------------------------------------------------------
use "data/clean/completions_panel_with_preddeg.dta", clear

merge m:1 unitid using "data/clean/inst_preddeg_mode.dta", ///
    keep(master match) nogen

keep if inrange(year, 2000, 2024)

gen is_cert = inlist(awlevel, 1, 2, 4, 6, 8, 20, 21)
keep if is_cert == 1

* Version A: annual PREDDEG
preserve
    collapse (sum) ctotalt, by(year preddeg)
    rename ctotalt certs_annual
    save "data/clean/tmp_annual.dta", replace
restore

* Version B: modal PREDDEG
collapse (sum) ctotalt, by(year preddeg_mode)
rename preddeg_mode preddeg
rename ctotalt certs_modal

merge 1:1 year preddeg using "data/clean/tmp_annual.dta", nogen

gen diff = certs_annual - certs_modal
gen pct_diff = 100 * diff / certs_modal

label define preddeg_short 0 "Not class" 1 "Cert" 2 "Assoc" 3 "Bach" 4 "Grad", replace
label values preddeg preddeg_short

display _newline "=== Diagnostic 4: Cert totals by PREDDEG, annual vs modal (2024) ==="
list year preddeg certs_annual certs_modal diff pct_diff if year == 2024, sepby(preddeg) noobs

display _newline "=== Same, 2011 ==="
list year preddeg certs_annual certs_modal diff pct_diff if year == 2011, sepby(preddeg) noobs

display _newline "=== Same, 2000 ==="
list year preddeg certs_annual certs_modal diff pct_diff if year == 2000, sepby(preddeg) noobs

erase "data/clean/tmp_annual.dta"

