/*==============================================================================
  ECON 580 Thesis — CS NDA Drug-Level Investigation

  Purpose: Two pre-drafting diagnostics to support the manuscript:
    (1) Identify the specific CS NDA approvals in 2009-2013 to confirm or
        refute the hypothesis that the late-2000s opioid product wave
        (extended-release and abuse-deterrent branded opioids) explains
        the apparent CS share spike that the year-FE Poisson DD picks up
        as a "post-PDUFA effect" — even though it occurs 15-18 years after
        PDUFA enactment.
    (2) Replace the noisy annual CS-NDA top-10 sponsor share figure with a
        static table of the top sponsors of CS NDAs over the full 1970-2025
        period. Annual counts are too small (often single-digit) for the
        time-series figure to be informative.

  Read-only on data/event_study/stata/event_study_drug_panel.dta.
  Produces two CSV tables. No figures, no .dta modifications, no changes
  to other do-files.

  Input:   ${dtapath}/event_study_drug_panel.dta
  Output:  ${tables}/cs_nda_2009_2013_drugs.csv
           ${tables}/cs_nda_top_sponsors_1970_2025.csv
==============================================================================*/

do "${code}/globals.do"
capture log close
log using "${statalogs}/09_cs_nda_drug_investigation.log", replace


/*==============================================================================
  PART 1: CS NDA approvals, 2009-2013
==============================================================================*/

di as txt _newline "===== PART 1: CS NDA approvals, 2009-2013 ====="

use "${dtapath}/event_study_drug_panel.dta", clear

keep if is_nda == 1
keep if is_controlled_substance == 1
keep if approval_year >= 2009 & approval_year <= 2013

sort approval_year applno
di as txt "CS NDA approvals 2009-2013: `c(N)' drugs"

/* Display the list in the log for direct inspection */
di as txt _newline "--- Drug-level detail ---"
list approval_year applno sponsorname drugname_list activeingredient_list ///
    dea_schedule_highest, ///
    sep(0) abbreviate(20) noobs

/* Annual count summary */
di as txt _newline "--- Annual counts ---"
tab approval_year, missing

/* Schedule breakdown */
di as txt _newline "--- DEA schedule breakdown ---"
tab dea_schedule_highest, missing

/* Sponsor breakdown */
di as txt _newline "--- Top sponsors in this window ---"
gsort -approval_year sponsorname
contract sponsorname, freq(n_approvals)
gsort -n_approvals
list sponsorname n_approvals, sep(0) noobs

/* Export the full drug-level list to CSV for paper exhibit */
use "${dtapath}/event_study_drug_panel.dta", clear
keep if is_nda == 1
keep if is_controlled_substance == 1
keep if approval_year >= 2009 & approval_year <= 2013

keep approval_year applno sponsorname drugname_list ///
    activeingredient_list dea_schedule_highest dea_schedule ///
    is_multi_ingredient

sort approval_year applno
export delimited "${tables}/cs_nda_2009_2013_drugs.csv", replace
di as txt "Exported: cs_nda_2009_2013_drugs.csv (`c(N)' rows)"


/*==============================================================================
  PART 2: Top CS-NDA sponsors, 1970-2025 (static table)
==============================================================================*/

di as txt _newline "===== PART 2: Top CS NDA sponsors, 1970-2025 ====="

use "${dtapath}/event_study_drug_panel.dta", clear

keep if is_nda == 1
keep if is_controlled_substance == 1
keep if approval_year >= 1970 & approval_year <= 2025
keep if !missing(sponsorname)

di as txt "Total CS NDAs in window: `c(N)'"

/* Aggregate by sponsor */
contract sponsorname, freq(n_cs_nda)
gsort -n_cs_nda

/* Compute share of total */
qui sum n_cs_nda
local total_cs = r(sum)
gen share_pct = 100 * n_cs_nda / `total_cs'
format share_pct %5.2f

label variable n_cs_nda  "Number of CS NDA approvals (1970-2025)"
label variable share_pct "% of all CS NDAs in window"

/* Display top 20 in log */
di as txt _newline "--- Top 20 sponsors of CS NDAs, 1970-2025 ---"
list sponsorname n_cs_nda share_pct in 1/20, sep(0) noobs abbreviate(40)

/* Export full ranked list */
export delimited "${tables}/cs_nda_top_sponsors_1970_2025.csv", replace
di as txt "Exported: cs_nda_top_sponsors_1970_2025.csv (`c(N)' sponsors)"

di as txt _newline "===== 09_cs_nda_drug_investigation.do complete ====="
log close
