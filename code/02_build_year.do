*===============================================================================
* Project 2: Postsecondary Certificate Trends
* File: 02_build_year.do
* Purpose: Clean one year of IPEDS Completions and save to data/clean/by_year/
* Usage:   From another do-file or command window:
*          do "$code\02_build_year.do" 2015
* Author:  Feda Mohammadi
*===============================================================================

* Grab the year passed in as an argument
local yr `1'
display "=== Building year `yr' ==="

* Make sure by_year subfolder exists
capture mkdir "$clean\by_year"

*-------------------------------------------------------------------------------
* Step 1: HD file (institution directory)
*-------------------------------------------------------------------------------
import delimited "$raw\ipeds\hd`yr'_data_stata.csv", clear varnames(1)
rename *, lower

keep unitid instnm stabbr control iclevel

tempfile hd_year
save `hd_year'

*-------------------------------------------------------------------------------
* Step 2: C_A file (completions)
*-------------------------------------------------------------------------------
import delimited "$raw\ipeds\c`yr'_a_data_stata.csv", clear varnames(1) stringcols(2)
rename *, lower

* MAJORNUM check: exists 2001+, missing in 2000
capture confirm variable majornum
if _rc == 0 {
    keep unitid cipcode majornum awlevel ctotalt
    keep if majornum == 1
    drop majornum
}
else {
    keep unitid cipcode awlevel ctotalt
}

*-------------------------------------------------------------------------------
* Step 3: Clean CIPCODE
* Format varies across years:
*   - 2000-2010ish: "1.0101" (has decimal, no leading zero on 2-digit part)
*   - 2011ish-2024: "010101" (no decimal, leading zero)
* Normalize everything to 6-digit no-decimal string with leading zeros.
*-------------------------------------------------------------------------------
replace cipcode = strtrim(cipcode)

* Drop summary rows (both formats: "99" modern, "99.0000" old)
drop if cipcode == "99" | cipcode == "99.0000"

* Remove decimal if present (converts "1.0101" -> "10101")
replace cipcode = subinstr(cipcode, ".", "", .)

* Pad with leading zeros to reach 6 characters
* (e.g. "10101" -> "010101", "1000" -> "001000")
replace cipcode = string(real(cipcode), "%06.0f")

* Build 2-digit CIP
gen cip2 = substr(cipcode, 1, 2)

*-------------------------------------------------------------------------------
* Step 4: Collapse and add year
*-------------------------------------------------------------------------------
collapse (sum) ctotalt, by(unitid cip2 awlevel)
gen year = `yr'

*-------------------------------------------------------------------------------
* Step 5: Merge institution attributes
*-------------------------------------------------------------------------------
merge m:1 unitid using `hd_year', keep(match master) nogen

*-------------------------------------------------------------------------------
* Step 6: Tag award categories using unified crosswalk
* Verified across 2000, 2010, 2022, 2024 dictionaries.
*   cert_under_1yr: old code 1 (2000-2010), new codes 20/21 (2011+)
*   doctorate:      old codes 9/10/11 (first-prof era), new codes 17/18/19
*-------------------------------------------------------------------------------
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

* Sanity check: every row must have a category
assert award_category != ""

gen is_certificate = inlist(awlevel, 1, 2, 4, 6, 8, 20, 21)

*-------------------------------------------------------------------------------
* Step 7: Save
*-------------------------------------------------------------------------------
order year unitid instnm stabbr control iclevel cip2 awlevel award_category is_certificate ctotalt
sort unitid cip2 awlevel

save "$clean\by_year\completions_`yr'.dta", replace
display "  Saved: completions_`yr'.dta with `=_N' rows"



