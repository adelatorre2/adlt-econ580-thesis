/*==============================================================================
  ECON 580 Thesis — Subsample Alternative Specifications (NDA-only / ANDA-only)

  Purpose: Produce PDUFA and GDUFA alternative-specification analyses restricted
           to the policy-relevant submission pathway — NDA-only for PDUFA and
           ANDA-only for GDUFA — so that the stacked DD and share-measure
           figures are not contaminated by submission types outside the policy's
           scope. Parallels 06_alt_specs_pdufa.do and 07_alt_specs_gdufa.do in
           design and output style.

  Motivation:
    The pooled stacked DD in 06_alt_specs_pdufa.do contrasts CS approvals
    (86.6% ANDAs) against non-CS approvals (also ANDA-dominated post-Hatch-
    Waxman). The result identifies the Hatch-Waxman ANDA expansion, not a
    PDUFA effect. The NDA-only Poisson (06 Model P3) returns a null, confirming
    the subsample matters. This file extends the NDA-only logic to the stacked
    DD and event-study DD. A parallel ANDA-only share figure for GDUFA is added
    for visual symmetry.

  Key design notes:
    - PDUFA NDA-only DD: CS group = n_cs_nda; non-CS group = n_nda - n_cs_nda.
      Both groups are subject to PDUFA user fees.
    - Years where n_nda == 0 produce undefined (missing) n_approvals for both
      groups. These rows are kept in the stacked panel as zero-count observations
      (n_approvals = 0 for the non-CS group; n_cs_nda = 0 for the CS group in
      early 1970s years). They enter the regressions with zero counts and do not
      distort results. Missing values would be worse (unbalanced panel). A log
      note confirms this choice.
    - All DD specs: group FE + year FE + 1.is_cs#1.post_pdufa. post_pdufa main
      effect is collinear with year FE and drops — expected and correct.
    - IHS and Poisson DD variants included for functional-form sensitivity.
    - GDUFA ANDA-only share figure matches the PDUFA NDA-only figure's style.

  Input:   ${dtapath}/event_study_annual.dta    (from 03_event_study.do)
           ${dtapath}/gdufa_anda_annual.dta      (from 05_gdufa_analysis.do)
  Output:  ${dtapath}/pdufa_nda_stacked_dd.dta
           ${figures}/pdufa_nda_only_share.png
           ${figures}/pdufa_nda_only_dd_event_study.png
           ${figures}/gdufa_anda_only_share.png
           ${tables}/subsample_alt_specs_results.csv
==============================================================================*/

do "${code}/globals.do"
capture log close
log using "${statalogs}/08_subsample_alt_specs.log", replace

graph set window fontface "Times New Roman"

local data_note_pdufa "Source: FDA Drugs@FDA, DEA controlled substance schedules. NDA submissions only."
local data_note_gdufa "Source: FDA Drugs@FDA, DEA controlled substance schedules. ANDA submissions only."
local cs_def          "CS = Controlled Substance (conservative: confident DEA scheduled matches only)."
local pdufa_note      "PDUFA enacted Oct 1992. NDA-only subsample is the policy-relevant unit."
local gdufa_note      "GDUFA enacted 2012; performance goals began FY2015. 2013-2014 = backlog transition."


/*==============================================================================
  PART 2: PDUFA NDA-only — stacked DD and event-study DD
==============================================================================*/

di as txt _newline "===== PART 2: PDUFA NDA-only stacked DD ====="

use "${dtapath}/event_study_annual.dta", clear
keep if approval_year >= 1970 & approval_year <= 2025

/* n_cs_nda and n_nda are already in the annual .dta (saved by 03_event_study.do).
   Compute the non-CS NDA count. Years with n_nda == 0 give n_noncs_nda = 0, which
   is correct — both groups get zero counts for those years. */
capture drop n_noncs_nda
gen n_noncs_nda = n_nda - n_cs_nda

di as txt "Check for years with n_nda == 0:"
count if n_nda == 0
di as txt "Rows where n_nda = 0: `r(N)'. Both groups will have n_approvals = 0."
di as txt "These are kept in the stacked panel as zeros (balanced panel)."

/* ---- Build two-row-per-year stacked panel (NDA-only) ---- */
preserve
    keep approval_year n_cs_nda post_pdufa event_time
    rename n_cs_nda n_approvals
    gen is_cs = 1
    tempfile cs_nda_rows
    save `cs_nda_rows'
restore

keep approval_year n_noncs_nda post_pdufa event_time
rename n_noncs_nda n_approvals
gen is_cs = 0
append using `cs_nda_rows'
sort approval_year is_cs

label variable is_cs       "=1 if controlled substance group (NDA-only)"
label variable n_approvals "Annual NDA approvals in group (CS or non-CS)"
label variable post_pdufa  "Post-PDUFA (1993+)"

capture drop asinh_n
gen asinh_n = asinh(n_approvals)
label variable asinh_n "IHS of NDA n_approvals (approx. log, defined at 0)"

save "${dtapath}/pdufa_nda_stacked_dd.dta", replace
di as txt "PDUFA NDA-only stacked DD dataset saved. Obs = `c(N)' (2 rows per year)"

/* ---- Model NDA-D1: Linear levels ---- */
di as txt _newline "--- NDA-D1: n_approvals ~ is_cs + year FE + is_cs#post_pdufa ---"
di as txt "(post_pdufa alone collinear with year FE and drops. Expected.)"
di as txt " Key coef: 1.is_cs#1.post_pdufa = differential CS NDA growth post-PDUFA."
regress n_approvals i.is_cs i.approval_year i.is_cs##i.post_pdufa, vce(robust)
estimates store m_nda_d1

/* ---- Model NDA-D2: IHS ---- */
di as txt _newline "--- NDA-D2: IHS(n_approvals) ~ is_cs + year FE + is_cs#post_pdufa ---"
regress asinh_n i.is_cs i.approval_year i.is_cs##i.post_pdufa, vce(robust)
estimates store m_nda_d2

/* ---- Model NDA-D3: Poisson ---- */
di as txt _newline "--- NDA-D3: Poisson n_approvals ~ is_cs + year FE + is_cs#post_pdufa ---"
poisson n_approvals i.is_cs i.approval_year i.is_cs##i.post_pdufa, vce(robust)
estimates store m_nda_d3
di as txt "--- NDA-D3: IRRs ---"
poisson, irr

di as txt _newline "--- DD model summary (NDA-only) ---"
estimates table m_nda_d1 m_nda_d2 m_nda_d3, b(%8.4f) se(%8.4f) stats(N) ///
    title("DD Models: NDA CS vs Non-CS, PDUFA (NDA-only subsample)")


/*------------------------------------------------------------------------------
  PART 2 (cont.): Event-study DD (NDA-only)
------------------------------------------------------------------------------*/

di as txt _newline "===== PART 2 (cont.): PDUFA NDA-only event-study DD ====="

use "${dtapath}/pdufa_nda_stacked_dd.dta", clear

/* Binned event-time: end-caps at -20 and +30, shift +21 → [1,51].
   Reference: event_time = -1 (1991) → shifted = 20 (omitted). */
capture drop event_time_bin
capture drop event_shifted
gen event_time_bin = event_time
replace event_time_bin = -20 if event_time < -20
replace event_time_bin =  30 if event_time > 30 & !missing(event_time)
gen event_shifted = event_time_bin + 21
label variable event_shifted "Event Time (shifted; 20 = ref year 1991)"

di as txt "--- Event study DD (NDA-only): n_approvals ~ is_cs + event FE + is_cs#event ---"
di as txt "Key coefs: k.event_shifted#1.is_cs = differential CS NDA approvals at event time k."
regress n_approvals i.is_cs i.event_shifted i.is_cs#i.event_shifted, vce(robust)

/* Extract interaction coefficients */
preserve
    clear
    set obs 51
    gen event_shifted = _n
    gen event_time    = event_shifted - 21
    gen coef = .
    gen se   = .
    /* Reference: event_shifted = 20 (event_time = -1, year 1991), coef = 0 */
    replace coef = 0 if event_shifted == 20
    replace se   = 0 if event_shifted == 20
    forvalues k = 1/51 {
        if `k' != 20 {
            capture replace coef = _b[`k'.event_shifted#1.is_cs]  if event_shifted == `k'
            capture replace se   = _se[`k'.event_shifted#1.is_cs] if event_shifted == `k'
        }
    }
    gen ci_lo = coef - 1.96 * se
    gen ci_hi = coef + 1.96 * se

    /* Shading bounds */
    gen band_lo = .
    gen band_hi = .
    qui sum ci_lo
    local ymin = r(min) - 0.5
    qui sum ci_hi
    local ymax = r(max) + 0.5
    replace band_lo = `ymin'
    replace band_hi = `ymax'

    twoway                                                                ///
        (rarea ci_lo ci_hi event_time, fcolor(navy%20) lwidth(none))     ///
        (connected coef event_time,                                      ///
             lcolor(navy) mcolor(navy)                                   ///
             msymbol(circle_hollow) msize(small) lwidth(thin)),          ///
        yline(0, lpattern(dash) lcolor(gs8) lwidth(thin))                ///
        xline(0, lpattern(dash) lcolor(cranberry) lwidth(medthin))       ///
        xline(-8, lpattern(dot) lcolor(gs7) lwidth(medthin))             ///
        title("PDUFA NDA-Only DD Event Study"                            ///
              "Differential CS vs Non-CS NDA Growth",                    ///
              size(medium))                                              ///
        subtitle("Reference period: 1991 (event time = -1)", size(small)) ///
        ytitle("Differential Approvals" "(CS NDA minus non-CS NDA trend)", size(small)) ///
        xtitle("Years Since PDUFA Enactment (1992)")                    ///
        xlabel(-20(5)30)                                                 ///
        plotregion(margin(l=2))                                          ///
        note("`cs_def'"                                                  ///
             "Coefficients on is_cs#event_time interaction (NDA-only)."  ///
             "Reference: 1991. Flat pre-period supports parallel trends." ///
             "Dashed red: PDUFA (1992). Dotted: Hatch-Waxman (1984)."   ///
             "Shaded band: 95% CI. OLS; serial correlation not corrected." ///
             "`data_note_pdufa'", size(vsmall))                          ///
        legend(off)                                                      ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/pdufa_nda_only_dd_event_study.png",         ///
        replace width(2400)
    di as txt "Exported: pdufa_nda_only_dd_event_study.png"
restore


/*==============================================================================
  PART 3: PDUFA NDA-only share-measure descriptive figure
==============================================================================*/

di as txt _newline "===== PART 3: PDUFA NDA-only share figure ====="

use "${dtapath}/event_study_annual.dta", clear
keep if approval_year >= 1970 & approval_year <= 2025

/* cs_share_nda is already in the .dta. Regenerate to be safe. */
capture drop cs_share_nda
gen cs_share_nda = n_cs_nda / n_nda if n_nda > 0

/* Pre/post means */
qui sum cs_share_nda if approval_year >= 1970 & approval_year <= 1992
local pre_mean_nda     = r(mean)
local pre_mean_nda_fmt = string(`pre_mean_nda', "%5.3f")

qui sum cs_share_nda if approval_year >= 1993 & approval_year <= 2025
local post_mean_nda     = r(mean)
local post_mean_nda_fmt = string(`post_mean_nda', "%5.3f")

di as txt "Pre-PDUFA NDA CS share mean  (1970-1992): `pre_mean_nda_fmt'"
di as txt "Post-PDUFA NDA CS share mean (1993-2025): `post_mean_nda_fmt'"

/* Horizontal reference lines scoped to each period */
capture drop pre_nda_line
capture drop post_nda_line
gen pre_nda_line  = `pre_mean_nda'  if approval_year >= 1970 & approval_year <= 1992
gen post_nda_line = `post_mean_nda' if approval_year >= 1993 & approval_year <= 2025

twoway                                                                   ///
    (line cs_share_nda approval_year,                                    ///
         lcolor(gs10) lwidth(medthin))                                   ///
    (line pre_nda_line  approval_year,                                   ///
         lcolor(navy)     lwidth(medium) lpattern(solid))                ///
    (line post_nda_line approval_year,                                   ///
         lcolor(cranberry) lwidth(medium) lpattern(solid)),              ///
    xline(1984, lpattern(dot)  lcolor(gs7) lwidth(medthin))              ///
    xline(1992, lpattern(dash) lcolor(cranberry) lwidth(medthin))        ///
    title("NDA-only CS Share of Approvals, 1970-2025",                   ///
          size(medlarge))                                                ///
    subtitle("Share = CS NDA approvals / total NDA approvals",           ///
             size(small))                                                ///
    ytitle("Share of NDA Approvals That Are Controlled Substances")      ///
    xtitle("Year")                                                       ///
    xlabel(1970(5)2025, angle(45))                                       ///
    ylabel(, format(%4.2f))                                              ///
    legend(order(1 "Annual NDA CS share"                                 ///
                 2 "Pre-PDUFA mean (`pre_mean_nda_fmt')"                 ///
                 3 "Post-PDUFA mean (`post_mean_nda_fmt')")              ///
           position(1) ring(0) cols(1))                                  ///
    note("`cs_def'"                                                      ///
         "Dashed red line: PDUFA enactment (1992). Dotted line: Hatch-Waxman (1984)." ///
         "`pdufa_note'"                                                  ///
         "`data_note_pdufa'", size(vsmall))                             ///
    graphregion(color(white)) bgcolor(white)

graph export "${figures}/pdufa_nda_only_share.png", replace width(2400)
di as txt "Exported: pdufa_nda_only_share.png"


/*==============================================================================
  PART 4: GDUFA ANDA-only share-measure descriptive figure
==============================================================================*/

di as txt _newline "===== PART 4: GDUFA ANDA-only share figure ====="

use "${dtapath}/gdufa_anda_annual.dta", clear
keep if approval_year >= 1984 & approval_year <= 2025

/* anda_cs_share already in the .dta. Regenerate to be safe. */
capture drop anda_cs_share
gen anda_cs_share = n_anda_cs / n_anda_total if n_anda_total > 0

/* Pre/post means (excludes transition 2013-2014) */
qui sum anda_cs_share if approval_year >= 1984 & approval_year <= 2012
local pre_mean_anda     = r(mean)
local pre_mean_anda_fmt = string(`pre_mean_anda', "%5.3f")

qui sum anda_cs_share if approval_year >= 2015 & approval_year <= 2025
local post_mean_anda     = r(mean)
local post_mean_anda_fmt = string(`post_mean_anda', "%5.3f")

di as txt "Pre-GDUFA ANDA CS share mean  (1984-2012): `pre_mean_anda_fmt'"
di as txt "Post-GDUFA ANDA CS share mean (2015-2025): `post_mean_anda_fmt'"

/* Horizontal reference lines scoped to each period */
capture drop pre_anda_line
capture drop post_anda_line
gen pre_anda_line  = `pre_mean_anda'  if approval_year >= 1984 & approval_year <= 2012
gen post_anda_line = `post_mean_anda' if approval_year >= 2015 & approval_year <= 2025

/* Transition shading (2013-2014) */
capture drop shade_lo
capture drop shade_hi
qui sum anda_cs_share
local ymax_shade = r(max) + 0.02
gen shade_lo = 0
gen shade_hi = `ymax_shade'

twoway                                                                   ///
    (rarea shade_lo shade_hi approval_year if                            ///
         approval_year >= 2013 & approval_year <= 2014,                  ///
         fcolor(gs14) lwidth(none))                                      ///
    (line anda_cs_share approval_year,                                   ///
         lcolor(gs10) lwidth(medthin))                                   ///
    (line pre_anda_line  approval_year,                                  ///
         lcolor(navy)     lwidth(medium) lpattern(solid))                ///
    (line post_anda_line approval_year,                                  ///
         lcolor(cranberry) lwidth(medium) lpattern(solid)),              ///
    xline(2012, lpattern(dash) lcolor(cranberry) lwidth(medthin))        ///
    title("ANDA-only CS Share of Approvals, 1984-2025",                  ///
          size(medlarge))                                                ///
    subtitle("Share = CS ANDA approvals / total ANDA approvals",         ///
             size(small))                                                ///
    ytitle("Share of ANDA Approvals That Are Controlled Substances")     ///
    xtitle("Year")                                                       ///
    xlabel(1984(4)2024, angle(45))                                       ///
    ylabel(, format(%4.2f))                                              ///
    legend(order(2 "Annual ANDA CS share"                                ///
                 3 "Pre-GDUFA mean (`pre_mean_anda_fmt')"                ///
                 4 "Post-GDUFA mean (`post_mean_anda_fmt')")             ///
           position(1) ring(0) cols(1))                                  ///
    note("`cs_def'"                                                      ///
         "Dashed red line: GDUFA enactment (2012)."                      ///
         "Gray band: 2013-2014 backlog transition (excluded from means)." ///
         "`gdufa_note'"                                                  ///
         "`data_note_gdufa'", size(vsmall))                             ///
    graphregion(color(white)) bgcolor(white)

graph export "${figures}/gdufa_anda_only_share.png", replace width(2400)
di as txt "Exported: gdufa_anda_only_share.png"


/*==============================================================================
  PART 5: Export combined results table (PDUFA NDA-only DD models)
==============================================================================*/

di as txt _newline "===== PART 5: Export NDA-only DD results table ====="

preserve
    clear
    set obs 3
    gen model = ""
    replace model = "NDA_D1_DD_levels"  if _n == 1
    replace model = "NDA_D2_DD_asinh"   if _n == 2
    replace model = "NDA_D3_DD_Poisson" if _n == 3
    gen coef_main  = .
    gen se_main    = .
    gen irr_or_exp = .

    estimates restore m_nda_d1
    replace coef_main  = _b[1.is_cs#1.post_pdufa]  if _n == 1
    replace se_main    = _se[1.is_cs#1.post_pdufa] if _n == 1

    estimates restore m_nda_d2
    replace coef_main  = _b[1.is_cs#1.post_pdufa]  if _n == 2
    replace se_main    = _se[1.is_cs#1.post_pdufa] if _n == 2

    estimates restore m_nda_d3
    replace coef_main  = _b[1.is_cs#1.post_pdufa]  if _n == 3
    replace se_main    = _se[1.is_cs#1.post_pdufa] if _n == 3
    replace irr_or_exp = exp(_b[1.is_cs#1.post_pdufa]) if _n == 3

    gen z_stat         = coef_main / se_main
    gen p_value_approx = 2 * (1 - normal(abs(z_stat)))

    label variable model          "Model"
    label variable coef_main      "1.is_cs#1.post_pdufa coefficient"
    label variable se_main        "Standard Error"
    label variable irr_or_exp     "IRR or exp(coef) where applicable"
    label variable z_stat         "z-statistic"
    label variable p_value_approx "Approx. p-value (2-sided)"

    format coef_main se_main irr_or_exp z_stat p_value_approx %8.4f
    list, sep(0) noobs

    export delimited "${tables}/subsample_alt_specs_results.csv", replace
    di as txt "Exported: subsample_alt_specs_results.csv"
restore


/*==============================================================================
  PART 6: Rate-vs-count diagnostics (PDUFA NDA-only)
==============================================================================*/

di as txt _newline "===== PART 6: Rate-vs-count diagnostics (PDUFA NDA-only) ====="
di as txt "Motivation: NDA-D3 Poisson IRR and D1 levels coef can disagree simultaneously."
di as txt "CS rate can rise while non-CS counts grow faster in absolute terms."
di as txt "These diagnostics clarify which story is correct."

/*----------------------------------------------------------------------
  6a: Rate vs count two-panel visual
----------------------------------------------------------------------*/

use "${dtapath}/event_study_annual.dta", clear
keep if approval_year >= 1970 & approval_year <= 2025

capture drop cs_share_nda
capture drop n_noncs_nda
capture drop pre_rate_line
gen cs_share_nda = n_cs_nda / n_nda if n_nda > 0
gen n_noncs_nda  = n_nda - n_cs_nda

qui sum cs_share_nda if approval_year >= 1970 & approval_year <= 1992
local rate_premean     = r(mean)
local rate_premean_fmt = string(`rate_premean', "%5.3f")
gen pre_rate_line = `rate_premean' if approval_year >= 1970 & approval_year <= 1992

/* Panel A: CS NDA share (rate) */
twoway                                                                    ///
    (line cs_share_nda  approval_year,                                    ///
         lcolor(navy) lwidth(medium))                                     ///
    (line pre_rate_line approval_year,                                    ///
         lcolor(navy) lwidth(medium) lpattern(dash)),                     ///
    xline(1992, lpattern(dash) lcolor(cranberry) lwidth(medthin))         ///
    xline(1984, lpattern(dot)  lcolor(gs7)       lwidth(medthin))         ///
    title("Panel A: CS Share of NDA Approvals (Rate)", size(medium))     ///
    ytitle("CS NDA / Total NDA") xtitle("")                               ///
    xlabel(1970(5)2025, angle(45)) ylabel(, format(%4.2f))                ///
    legend(order(1 "Annual CS NDA rate"                                   ///
                 2 "Pre-PDUFA mean (`rate_premean_fmt')")                  ///
           position(11) ring(0) cols(1) size(small))                      ///
    graphregion(color(white)) bgcolor(white)                              ///
    name(panel_nda_rate, replace)

/* Panel B: CS vs non-CS NDA absolute counts */
twoway                                                                    ///
    (line n_cs_nda    approval_year, lcolor(navy)     lwidth(medium))    ///
    (line n_noncs_nda approval_year,                                      ///
         lcolor(cranberry) lwidth(medium) lpattern(dash)),                ///
    xline(1992, lpattern(dash) lcolor(cranberry) lwidth(medthin))         ///
    xline(1984, lpattern(dot)  lcolor(gs7)       lwidth(medthin))         ///
    title("Panel B: CS and Non-CS NDA Annual Counts", size(medium))      ///
    ytitle("Annual NDA Approvals") xtitle("Year")                         ///
    xlabel(1970(5)2025, angle(45)) ylabel(, format(%9.0f))                ///
    legend(order(1 "CS NDA" 2 "Non-CS NDA")                               ///
           position(1) ring(0) cols(1) size(small))                       ///
    note("`cs_def'"                                                       ///
         "Dashed red: PDUFA (1992). Dotted: Hatch-Waxman (1984)."         ///
         "`data_note_pdufa'", size(vsmall))                              ///
    graphregion(color(white)) bgcolor(white)                              ///
    name(panel_nda_count, replace)

graph combine panel_nda_rate panel_nda_count, cols(1)                    ///
    title("NDA-only CS Rate vs Absolute Count Around PDUFA (1992)",       ///
          size(medlarge))                                                 ///
    note("Both panels can simultaneously be true: rate rises if CS NDA grows" ///
         "proportionally faster; count falls if non-CS grows faster absolutely.", ///
         size(vsmall))                                                    ///
    graphregion(color(white))

graph export "${figures}/pdufa_nda_rate_vs_count.png", replace width(2400)
di as txt "Exported: pdufa_nda_rate_vs_count.png"
graph drop panel_nda_rate panel_nda_count


/*----------------------------------------------------------------------
  6b: Trend-control sensitivity for NDA-D3 Poisson
----------------------------------------------------------------------*/

di as txt _newline "--- Part 6b: Trend-control sensitivity (NDA-only Poisson DD) ---"
di as txt "If IRR shrinks to ~1.0 when year FE replaced by linear trend, result is trend artifact."

use "${dtapath}/pdufa_nda_stacked_dd.dta", clear

/* NDA-D3-trend: linear year trend instead of year FE */
di as txt _newline "--- NDA-D3-trend: Poisson, linear year trend only ---"
poisson n_approvals i.is_cs c.approval_year i.is_cs##i.post_pdufa, vce(robust)
estimates store m_nda_d3_trend
poisson, irr

/* NDA-D3-grouptrend: group-specific linear year trends */
di as txt _newline "--- NDA-D3-grouptrend: Poisson, group-specific year trends ---"
poisson n_approvals i.is_cs c.approval_year c.approval_year#i.is_cs     ///
    i.is_cs##i.post_pdufa, vce(robust)
estimates store m_nda_d3_grouptrend
poisson, irr

/* Save IRRs and SEs as locals for export */
estimates restore m_nda_d3
local coef_d3_fe       = _b[1.is_cs#1.post_pdufa]
local se_d3_fe         = _se[1.is_cs#1.post_pdufa]
local irr_d3_fe        = exp(`coef_d3_fe')

estimates restore m_nda_d3_trend
local coef_d3_trend    = _b[1.is_cs#1.post_pdufa]
local se_d3_trend      = _se[1.is_cs#1.post_pdufa]
local irr_d3_trend     = exp(`coef_d3_trend')

estimates restore m_nda_d3_grouptrend
local coef_d3_grptrend = _b[1.is_cs#1.post_pdufa]
local se_d3_grptrend   = _se[1.is_cs#1.post_pdufa]
local irr_d3_grptrend  = exp(`coef_d3_grptrend')

di as txt _newline "=== IRR summary: trend-control sensitivity (NDA-only Poisson DD) ==="
di as txt "  NDA-D3 (year FE, full flex): IRR = " %6.3f `irr_d3_fe'
di as txt "  NDA-D3-trend (linear)      : IRR = " %6.3f `irr_d3_trend'
di as txt "  NDA-D3-grouptrend (by grp) : IRR = " %6.3f `irr_d3_grptrend'
di as txt "  If (2) and (3) << (1), year-FE spec is capturing a trend, not a 1992 break."

estimates table m_nda_d3 m_nda_d3_trend m_nda_d3_grouptrend,            ///
    b(%8.4f) se(%8.4f) stats(N)                                          ///
    keep(1.is_cs#1.post_pdufa c.approval_year)                           ///
    title("NDA-only Poisson DD: trend-control sensitivity (key coefs)")


/*----------------------------------------------------------------------
  6c: Timing diagnostic — event-study Poisson DD IRRs
----------------------------------------------------------------------*/

di as txt _newline "--- Part 6c: Timing diagnostic — Poisson event-study DD (NDA-only) ---"
di as txt "A genuine PDUFA effect should show IRR > 1 beginning at event_time 0 or 1 (1992-93)."
di as txt "IRRs near 1.0 until ~2007 and rising later suggest a different driver."

use "${dtapath}/pdufa_nda_stacked_dd.dta", clear
capture drop event_time_bin
capture drop event_shifted
gen event_time_bin = event_time
replace event_time_bin = -20 if event_time < -20
replace event_time_bin =  30 if event_time > 30 & !missing(event_time)
gen event_shifted = event_time_bin + 21

poisson n_approvals i.is_cs i.event_shifted i.is_cs#i.event_shifted, vce(robust)

di as txt _newline "Poisson event-study DD IRRs: exp(1.is_cs#k.event_shifted)"
di as txt "Reference: event_shifted = 20 (event_time = -1, year 1991)"
foreach k in 21 22 25 30 35 40 45 50 {
    local et = `k' - 21
    local yr = 1992 + `et'
    capture {
        local b   = _b[`k'.event_shifted#1.is_cs]
        local irr = exp(`b')
        di as txt "  event_time = `et' (year `yr'): IRR = " %6.3f `irr'
    }
}


/*----------------------------------------------------------------------
  6 (export): Trend-sensitivity diagnostics table
----------------------------------------------------------------------*/

di as txt _newline "--- Exporting pdufa_nda_diagnostics.csv ---"

preserve
    clear
    set obs 3
    gen model      = ""
    gen irr_main   = .
    gen coef_main  = .
    gen se_main    = .
    gen spec_note  = ""

    replace model     = "NDA_D3_yearFE"         if _n == 1
    replace model     = "NDA_D3_trend_linear"    if _n == 2
    replace model     = "NDA_D3_grouptrend"      if _n == 3

    replace coef_main = `coef_d3_fe'             if _n == 1
    replace coef_main = `coef_d3_trend'          if _n == 2
    replace coef_main = `coef_d3_grptrend'       if _n == 3

    replace se_main   = `se_d3_fe'               if _n == 1
    replace se_main   = `se_d3_trend'            if _n == 2
    replace se_main   = `se_d3_grptrend'         if _n == 3

    replace irr_main  = `irr_d3_fe'              if _n == 1
    replace irr_main  = `irr_d3_trend'           if _n == 2
    replace irr_main  = `irr_d3_grptrend'        if _n == 3

    replace spec_note = "Year FE (full flexibility)"        if _n == 1
    replace spec_note = "Linear year trend (restrictive)"   if _n == 2
    replace spec_note = "Group-specific year trends (mid)"  if _n == 3

    gen z_stat         = coef_main / se_main
    gen p_value_approx = 2 * (1 - normal(abs(z_stat)))

    label variable model          "Model"
    label variable irr_main       "IRR on 1.is_cs#1.post_pdufa"
    label variable coef_main      "ln(IRR) = coefficient"
    label variable se_main        "Standard Error"
    label variable z_stat         "z-statistic"
    label variable p_value_approx "Approx. p-value"
    label variable spec_note      "Specification"

    format irr_main coef_main se_main z_stat p_value_approx %8.4f
    list, sep(0) noobs
    export delimited "${tables}/pdufa_nda_diagnostics.csv", replace
    di as txt "Exported: pdufa_nda_diagnostics.csv"
restore


di as txt _newline "===== 08_subsample_alt_specs.do complete ====="
log close
