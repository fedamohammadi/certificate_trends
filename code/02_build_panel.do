*===============================================================================
* Project 2: Postsecondary Certificate Trends
* File: 02_build_panel.do
* Purpose: Build clean 2000-2024 IPEDS completions panel in ONE file
* Author:  Feda Mohammadi
*===============================================================================

clear all
set more off
set maxvar 32767

*-------------------------------------------------------------------------------
* Setup
*-------------------------------------------------------------------------------
global root   "C:\Users\mohammadif\Documents\certificate_trends"
global raw    "$root\data\raw"
global clean  "$root\data\clean"

capture mkdir "$clean\by_year"

* Delete any old year files from previous broken runs
cd "$clean\by_year"
local oldfiles : dir . files "completions_*.dta"
foreach f of local oldfiles {
    erase "`f'"
}

*-------------------------------------------------------------------------------
* Loop over all years
*-------------------------------------------------------------------------------
forvalues yr = 2000/2024 {

    display _newline "########## Processing year `yr' ##########"

    *---------------------------------------------------------------------------
    * Step 1: HD file (institution directory)
    *---------------------------------------------------------------------------
    import delimited "$raw\ipeds\hd`yr'_data_stata.csv", clear varnames(1)
    rename *, lower
    keep unitid instnm stabbr control iclevel
    tempfile hd_year
    save `hd_year'

    *---------------------------------------------------------------------------
    * Step 2: Completions file
    *---------------------------------------------------------------------------
    import delimited "$raw\ipeds\c`yr'_a_data_stata.csv", clear varnames(1) stringcols(2)
    rename *, lower

    * Older files use crace15 + crace16 instead of ctotalt
    capture confirm variable ctotalt
    if _rc != 0 {
        gen ctotalt = crace15 + crace16
    }

    * Older files may store majornum/awlevel as strings
    capture confirm numeric variable awlevel
    if _rc != 0 {
        destring awlevel, replace force
    }

    * MAJORNUM filter (variable exists 2001+, missing in 2000)
    capture confirm variable majornum
    if _rc == 0 {
        capture confirm numeric variable majornum
        if _rc != 0 {
            destring majornum, replace force
        }
        keep unitid cipcode majornum awlevel ctotalt
        keep if majornum == 1
        drop majornum
    }
    else {
        keep unitid cipcode awlevel ctotalt
    }

    *---------------------------------------------------------------------------
    * Step 3: Clean CIPCODE
    *---------------------------------------------------------------------------
    replace cipcode = strtrim(cipcode)
    replace cipcode = subinstr(cipcode, ".", "", .)
    replace cipcode = string(real(cipcode), "%06.0f")

    * Drop institutional summary rows
    drop if cipcode == "990000"

    * Build 2-digit CIP
    gen cip2 = substr(cipcode, 1, 2)

    *---------------------------------------------------------------------------
    * Step 4: Collapse to (UNITID x CIP2 x AWLEVEL)
    *---------------------------------------------------------------------------
    collapse (sum) ctotalt, by(unitid cip2 awlevel)
    gen year = `yr'

    *---------------------------------------------------------------------------
    * Step 5: Merge institution attributes
    *---------------------------------------------------------------------------
    merge m:1 unitid using `hd_year', keep(match master) nogen

    *---------------------------------------------------------------------------
    * Step 6: Tag award categories
    *---------------------------------------------------------------------------
    gen award_category = ""
    replace award_category = "cert_under_1yr"     if inlist(awlevel, 1, 20, 21)
    replace award_category = "cert_1_to_2yr"      if awlevel == 2
    replace award_category = "cert_2_to_4yr"      if awlevel == 4
    replace award_category = "cert_postbacc"      if awlevel == 6
    replace award_category = "cert_postmasters"   if awlevel == 8
    replace award_category = "associate"          if awlevel == 3
    replace award_category = "bachelor"           if awlevel == 5
    replace award_category = "master"             if awlevel == 7
    replace award_category = "doctorate"          if inlist(awlevel, 9, 10, 11, 17, 18, 19)

    assert award_category != ""

    gen is_certificate = inlist(awlevel, 1, 2, 4, 6, 8, 20, 21)

    *---------------------------------------------------------------------------
    * Step 7: Save this year
    *---------------------------------------------------------------------------
    order year unitid instnm stabbr control iclevel cip2 awlevel award_category is_certificate ctotalt
    sort unitid cip2 awlevel

    save "$clean\by_year\completions_`yr'.dta", replace
    display "  Saved year `yr' with `=_N' rows"
}

*-------------------------------------------------------------------------------
* Stack all years into one panel
*-------------------------------------------------------------------------------
display _newline "########## Stacking all years ##########"

clear
forvalues yr = 2000/2024 {
    append using "$clean\by_year\completions_`yr'.dta"
}

*-------------------------------------------------------------------------------
* Label and save final panel
*-------------------------------------------------------------------------------
label variable year "Award year"
label variable unitid "IPEDS institution ID"
label variable cip2 "2-digit CIP code"
label variable awlevel "IPEDS award level code"
label variable award_category "Unified award category (harmonized across years)"
label variable is_certificate "1 if certificate, 0 if degree"
label variable ctotalt "Total completions (first majors only)"

order year unitid instnm stabbr control iclevel cip2 awlevel award_category is_certificate ctotalt
sort year unitid cip2 awlevel

save "$clean\completions_panel_2000_2024.dta", replace

*-------------------------------------------------------------------------------
* Sanity check
*-------------------------------------------------------------------------------
display _newline "########## Final totals by year ##########"
table year is_certificate, statistic(sum ctotalt)


