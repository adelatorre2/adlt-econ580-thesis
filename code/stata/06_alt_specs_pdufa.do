/*==============================================================================
  ECON 580 Thesis — Alternative Specifications: PDUFA (1992)

  Purpose: Address the denominator problem in the share-based analysis by
           running Poisson count models (CS counts with total as exposure)
           and a stacked difference-in-differences where CS and non-CS
           approval counts are separate groups. The key question: did CS
           approvals grow differentially FASTER than non-CS approvals after
           PDUFA? This is theoretically more appropriate than the composition
           share, which conflates numerator and denominator dynamics.

  Key design notes:
    - Poisson with exposure: ln(E[n_cs]) = b0 + b1*post + b2*year + ln(n_total)
      Equivalent to modeling the CS rate. exp(b1) = IRR on post_pdufa.
    - Stacked DD: two rows per year (CS and non-CS). Group FE + year FE +
      group×post interaction. With year FE, post_pdufa alone is collinear and
      drops out; the identified coefficient is 1.is_cs#1.post_pdufa = the
      differential growth in CS relative to non-CS after PDUFA.
    - IHS transformation: inverse hyperbolic sine (asinh) approximates log but
      is defined at zero and avoids the +1 bias. Used in Model D2.
    - DD parallel trends is an assumption, not tested here. Pre-trend
      coefficients from the event study DD (Part 4) serve as a diagnostic.

  Input:   ${dtapath}/event_study_annual.dta
  Output:  ${dtapath}/pdufa_stacked_dd.dta
           ${figures}/pdufa_dd_event_study.png
           ${tables}/pdufa_alt_specs_results.csv
==============================================================================*/

do "${code}/globals.do"
capture log close
log using "${statalogs}/06_alt_specs_pdufa.log", replace

graph set window fontface "Times New Roman"

local data_note "Source: FDA Drugs@FDA, DEA controlled substance schedules. ORIG+AP submissions only."
local cs_def    "CS = Controlled Substance (conservative: confident DEA scheduled matches only)."


/*==============================================================================
  PART 1: Load and prepare annual panel
==============================================================================*/

di as txt _newline "===== PART 1: Annual panel preparation (PDUFA) ====="

use "${dtapath}/event_study_annual.dta", clear
keep if approval_year >= 1970 & approval_year <= 2025
di as txt "Sample restricted to 1970-2025. Obs = `c(N)'"

/* Derived variables not saved in the .dta */
gen n_noncs          = n_total - n_cs
gen trend_post_pdufa = event_time * post_pdufa

label variable n_noncs          "Non-CS Approvals (n_total - n_cs)"
label variable trend_post_pdufa "Event Time x Post-PDUFA (slope break)"

tsset approval_year

di as txt "Variables available:"
describe


/*==============================================================================
  PART 2: Poisson count models with exposure
==============================================================================*/

di as txt _newline "===== PART 2: Poisson count models (PDUFA) ====="
di as txt "Outcome: n_cs. Exposure: n_total (ln offset)."
di as txt "exp(post_pdufa coef) = IRR = multiplicative change in CS rate after PDUFA."

/* --- Model P1: Level shift ---- */
di as txt _newline "--- Model P1: CS count ~ post_pdufa + trend, exposure(n_total) ---"
poisson n_cs post_pdufa c.approval_year,                            ///
    exposure(n_total) vce(robust)
estimates store m_p1
di as txt "--- Model P1: Incidence Rate Ratios ---"
poisson, irr

/* --- Model P2: Level shift + slope change --- */
di as txt _newline "--- Model P2: CS count ~ post_pdufa + trend + slope change ---"
poisson n_cs post_pdufa c.approval_year trend_post_pdufa,           ///
    exposure(n_total) vce(robust)
estimates store m_p2
di as txt "--- Model P2: Incidence Rate Ratios ---"
poisson, irr

/* --- Model P3: NDA-only (CS-NDA counts, NDA total as exposure) --- */
di as txt _newline "--- Model P3: NDA-only CS count ~ post_pdufa + trend ---"
di as txt "(Restrict to years where n_nda > 0; n_cs_nda is CS NDA count)"
poisson n_cs_nda post_pdufa c.approval_year if n_nda > 0,           ///
    exposure(n_nda) vce(robust)
estimates store m_p3
di as txt "--- Model P3: Incidence Rate Ratios ---"
poisson, irr

di as txt _newline "--- Poisson model summary ---"
estimates table m_p1 m_p2 m_p3, b(%8.4f) se(%8.4f) stats(N) ///
    title("Poisson Models: CS Counts with Exposure (PDUFA)")


/*==============================================================================
  PART 3: Stacked DD panel — CS vs non-CS as treatment/control
==============================================================================*/

di as txt _newline "===== PART 3: Stacked DD (PDUFA) ====="

use "${dtapath}/event_study_annual.dta", clear
keep if approval_year >= 1970 & approval_year <= 2025
gen n_noncs = n_total - n_cs

/* Build two-row-per-year dataset */
preserve
    keep approval_year n_cs post_pdufa event_time
    rename n_cs n_approvals
    gen is_cs = 1
    tempfile cs_rows
    save `cs_rows'
restore

keep approval_year n_noncs post_pdufa event_time
rename n_noncs n_approvals
gen is_cs = 0
append using `cs_rows'
sort approval_year is_cs

label variable is_cs       "=1 if controlled substance group"
label variable n_approvals "Annual approvals in group (CS or non-CS)"
label variable post_pdufa  "Post-PDUFA (1993+)"

/* IHS transformation for log-like outcome */
gen asinh_n = asinh(n_approvals)
label variable asinh_n "IHS of n_approvals (approx. log, defined at 0)"

save "${dtapath}/pdufa_stacked_dd.dta", replace
di as txt "Stacked DD dataset saved. Obs = `c(N)' (2 rows per year)"

/* --- Model D1: Levels with group + year FE + DD interaction --- */
di as txt _newline "--- Model D1: n_approvals ~ is_cs FE + year FE + is_cs#post_pdufa ---"
di as txt "(post_pdufa alone is collinear with year FE and drops out.)"
di as txt " Key coef: 1.is_cs#1.post_pdufa = differential CS growth post-PDUFA."
regress n_approvals i.is_cs i.approval_year i.is_cs##i.post_pdufa, vce(robust)
estimates store m_d1

/* --- Model D2: IHS transformation --- */
di as txt _newline "--- Model D2: IHS(n_approvals) ~ is_cs FE + year FE + is_cs#post_pdufa ---"
di as txt "(IHS approximates log but is defined at zero. Avoids +1 bias.)"
regress asinh_n i.is_cs i.approval_year i.is_cs##i.post_pdufa, vce(robust)
estimates store m_d2

/* --- Model D3: Poisson DD --- */
di as txt _newline "--- Model D3: Poisson n_approvals ~ is_cs FE + year FE + is_cs#post_pdufa ---"
poisson n_approvals i.is_cs i.approval_year i.is_cs##i.post_pdufa, vce(robust)
estimates store m_d3
di as txt "--- Model D3: IRRs ---"
poisson, irr


/*==============================================================================
  PART 4: Event study DD — differential CS growth year by year around PDUFA
==============================================================================*/

di as txt _newline "===== PART 4: Event study DD (PDUFA) ====="

use "${dtapath}/pdufa_stacked_dd.dta", clear

/* Binned event-time: same approach as 03_event_study.do
   Range [-20,30], shift +21 → [1,51]. Reference: event_time = -1 → shifted = 20 */
gen event_time_bin    = event_time
replace event_time_bin = -20 if event_time < -20
replace event_time_bin =  30 if event_time > 30 & !missing(event_time)
gen event_shifted = event_time_bin + 21

label variable event_shifted "Event Time (shifted; 20 = ref year 1991)"

di as txt "--- Event study DD: n_approvals ~ is_cs + event_time FE + is_cs#event_time ---"
di as txt "Key coefs: k.event_shifted#1.is_cs = differential CS approvals at event time k."
di as txt "Pre-period flatness tests the parallel trends assumption."

regress n_approvals i.is_cs i.event_shifted i.is_cs#i.event_shifted, vce(robust)

/* Extract interaction coefficients for plot */
preserve
    clear
    set obs 51
    gen event_shifted  = _n
    gen event_time     = event_shifted - 21
    gen coef = .
    gen se   = .
    /* Reference: event_shifted = 20 (event_time = -1), coef = 0 by construction */
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

    twoway                                                               ///
        (rarea ci_lo ci_hi event_time, fcolor(navy%20) lwidth(none))    ///
        (connected coef event_time,                                      ///
             lcolor(navy) mcolor(navy)                                   ///
             msymbol(circle_hollow) msize(small) lwidth(thin)),          ///
        yline(0, lpattern(dash) lcolor(gs8) lwidth(thin))                ///
        xline(0, lpattern(dash) lcolor(cranberry) lwidth(medthin))       ///
        xline(-8, lpattern(dot) lcolor(gs7) lwidth(medthin))             ///
        title("DD Event Study: Differential CS vs Non-CS Growth (PDUFA)", ///
              size(medlarge))                                            ///
        subtitle("Coefficient = excess CS approvals relative to non-CS, vs 1991", ///
                 size(small))                                            ///
        ytitle("Differential Approvals (CS minus non-CS trend)")        ///
        xtitle("Years Since PDUFA Enactment (1992)")                    ///
        xlabel(-20(5)30)                                                 ///
        note("`cs_def'"                                                  ///
             "Coefficients on is_cs#event_time interaction."             ///
             "Reference: 1991. Flat pre-period supports parallel trends." ///
             "Dashed red: PDUFA (1992). Dotted: Hatch-Waxman (1984)."   ///
             "Shaded band: 95% CI. OLS; serial correlation not corrected." ///
             "`data_note'", size(vsmall))                               ///
        legend(off)                                                      ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/pdufa_dd_event_study.png", replace width(2400)
    di as txt "Exported: pdufa_dd_event_study.png"
restore


/*==============================================================================
  PART 5: Export key results to CSV
==============================================================================*/

di as txt _newline "===== PART 5: Export results table ====="

preserve
    clear
    set obs 6
    gen model = ""
    replace model = "P1_Poisson_levelshift"       if _n == 1
    replace model = "P2_Poisson_slopechange"      if _n == 2
    replace model = "P3_Poisson_NDA"              if _n == 3
    replace model = "D1_DD_levels"                if _n == 4
    replace model = "D2_DD_asinh"                 if _n == 5
    replace model = "D3_DD_Poisson"               if _n == 6
    gen coef_main = .
    gen se_main   = .
    gen irr_or_exp = .

    /* Poisson models: post_pdufa coef and IRR */
    estimates restore m_p1
    replace coef_main  = _b[post_pdufa]        if _n == 1
    replace se_main    = _se[post_pdufa]       if _n == 1
    replace irr_or_exp = exp(_b[post_pdufa])   if _n == 1

    estimates restore m_p2
    replace coef_main  = _b[post_pdufa]        if _n == 2
    replace se_main    = _se[post_pdufa]       if _n == 2
    replace irr_or_exp = exp(_b[post_pdufa])   if _n == 2

    estimates restore m_p3
    replace coef_main  = _b[post_pdufa]        if _n == 3
    replace se_main    = _se[post_pdufa]       if _n == 3
    replace irr_or_exp = exp(_b[post_pdufa])   if _n == 3

    /* DD models: 1.is_cs#1.post_pdufa interaction */
    estimates restore m_d1
    replace coef_main  = _b[1.is_cs#1.post_pdufa]  if _n == 4
    replace se_main    = _se[1.is_cs#1.post_pdufa] if _n == 4

    estimates restore m_d2
    replace coef_main  = _b[1.is_cs#1.post_pdufa]  if _n == 5
    replace se_main    = _se[1.is_cs#1.post_pdufa] if _n == 5

    estimates restore m_d3
    replace coef_main  = _b[1.is_cs#1.post_pdufa]  if _n == 6
    replace se_main    = _se[1.is_cs#1.post_pdufa] if _n == 6
    replace irr_or_exp = exp(_b[1.is_cs#1.post_pdufa]) if _n == 6

    gen z_stat = coef_main / se_main
    gen p_value_approx = 2 * (1 - normal(abs(z_stat)))

    label variable model        "Model"
    label variable coef_main    "Key Coefficient (post_pdufa or is_cs#post_pdufa)"
    label variable se_main      "Standard Error"
    label variable irr_or_exp   "IRR or exp(coef) where applicable"
    label variable z_stat       "z-statistic"
    label variable p_value_approx "Approx. p-value (2-sided)"

    format coef_main se_main irr_or_exp z_stat p_value_approx %8.4f
    list, sep(0) noobs

    export delimited "${tables}/pdufa_alt_specs_results.csv", replace
    di as txt "Exported: pdufa_alt_specs_results.csv"
restore


di as txt _newline "===== 06_alt_specs_pdufa.do complete ====="
log close
