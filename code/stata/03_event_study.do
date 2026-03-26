/*==============================================================================
  ECON 580 Thesis — First-Pass Event Study (Interrupted Time Series)

  Purpose: Estimate whether PDUFA (1992) shifted the controlled-substance share
           of U.S. drug approvals, using a single national annual time series.

  DESIGN NOTE — READ FIRST:
    This is NOT a canonical two-way fixed-effects event study with treated and
    untreated units. The data have a single common event date (1992) and no
    cross-sectional variation in treatment timing. The design is therefore an
    interrupted time series (ITS): one national series before and after a known
    policy date. Identification requires the counterfactual assumption that the
    pre-PDUFA trend would have continued absent treatment. Pre-event coefficients
    serve only as a diagnostic — they test whether the series was trending
    smoothly before 1992, not a formal parallel-trends test.
    All results should be interpreted as suggestive policy diagnostics,
    not causal estimates.

  Structure:
    PART 1  Collapse drug-level .dta → annual panel; save annual .dta
    PART 2  Main event study: CS share (nonparametric dummies)
    PART 3  Event study: log CS counts vs log non-CS counts
    PART 4  Event study: NDA-only subsample
    PART 5  Simple parametric pre/post regressions (ITS models)
    PART 6  Summary figure: raw series + pre/post mean lines

  Input:   ${dtapath}/event_study_drug_panel.dta
  Outputs: ${dtapath}/event_study_annual.dta
           ${figures}/event_study_*.png

  Sample restriction (all event study parts): 1970–2025
    Pre-1970 years have very small denominators (< 30 total approvals/yr in
    many years) that produce volatile shares and would dominate the pre-period.

  Serial-correlation note:
    OLS standard errors are reported throughout as a first pass. In a
    paper-facing version, Newey-West (HAC) SEs with lag ~3 would be appropriate
    via -newey y x, lag(3)-. The coefficient point estimates are identical; only
    the SEs change.

  Event-time binning:
    event_time = approval_year - 1992
    End-cap pre:  bin all event_time < -20 as -20  (1970–1972 grouped)
    End-cap post: bin all event_time >  30 as  30  (2022–2025 grouped)
    Shifted var:  event_time_shifted = event_time_bin + 21  → range [1, 51]
    Reference:    event_time = -1 (1991) → shifted = 20  (omitted)
    Hatch-Waxman (1984): event_time = -8, shifted = 13

  Input variables (lowercase — imported with case(lower) in 01_load_and_prep):
    approval_year, event_time, is_controlled_substance,
    is_controlled_substance_broad, is_nda, is_anda,
    is_schedule_ii/iii/iv/v
==============================================================================*/

do "${code}/globals.do"
capture log close
log using "${statalogs}/03_event_study.log", replace

/* Shared note text for figures */
local data_note "Source: FDA Drugs@FDA, DEA controlled substance schedules. ORIG+AP submissions only."
local cs_def    "CS = Controlled Substance (conservative: confident DEA scheduled matches only)."
local its_note  "Interrupted time series. No cross-sectional variation. Treat as descriptive diagnostics."


/*==============================================================================
  PART 1: Collapse to annual panel
==============================================================================*/

di as txt _newline "===== PART 1: Building annual panel ====="

use "${dtapath}/event_study_drug_panel.dta", clear

/*  Create counts before collapse  */
gen n_cs_nda  = (is_controlled_substance == 1 & is_nda  == 1)
gen n_cs_anda = (is_controlled_substance == 1 & is_anda == 1)
gen n_one     = 1

collapse                                         ///
    (sum) n_total     = n_one                    ///
          n_cs        = is_controlled_substance  ///
          n_nda       = is_nda                   ///
          n_anda      = is_anda                  ///
          n_cs_nda                               ///
          n_cs_anda,                             ///
    by(approval_year)

sort approval_year

/*  Shares and log outcomes  */
gen cs_share      = n_cs     / n_total
gen ln_cs         = ln(n_cs  + 1)
gen ln_total      = ln(n_total)
gen ln_noncs      = ln(n_total - n_cs + 1)
gen cs_share_nda  = n_cs_nda  / n_nda   if n_nda  > 0
gen cs_share_anda = n_cs_anda / n_anda  if n_anda > 0

/*  Policy timing variables  */
gen event_time = approval_year - 1992
gen post_pdufa = (approval_year >= 1993)

/*  Variable labels  */
label variable approval_year   "Approval Year"
label variable n_total          "Total Approvals"
label variable n_cs             "CS Approvals (Conservative)"
label variable cs_share         "CS Share"
label variable ln_cs            "ln(CS + 1)"
label variable ln_total         "ln(Total Approvals)"
label variable ln_noncs         "ln(Non-CS + 1)"
label variable n_nda            "NDA Count"
label variable n_cs_nda         "CS Among NDA"
label variable cs_share_nda     "CS Share (NDA Only)"
label variable n_anda           "ANDA Count"
label variable n_cs_anda        "CS Among ANDA"
label variable cs_share_anda    "CS Share (ANDA Only)"
label variable event_time       "Event Time (approval_year - 1992)"
label variable post_pdufa       "Post-PDUFA (1993+)"

save "${dtapath}/event_study_annual.dta", replace
di as txt "Saved: event_study_annual.dta  (obs = `c(N)')"

/*  Display the key transition window in the log  */
di as txt _newline "--- Annual panel: transition period 1985-2000 ---"
list approval_year n_total n_cs cs_share if                        ///
    approval_year >= 1985 & approval_year <= 2000,                 ///
    noobs sep(0) abbreviate(12)


/*==============================================================================
  PART 2: Main event study — CS share as outcome
==============================================================================*/

di as txt _newline "===== PART 2: Event study — CS share ====="

use "${dtapath}/event_study_annual.dta", clear

/*  Apply sample restriction  */
keep if approval_year >= 1970 & approval_year <= 2025
di as txt "Sample restricted to 1970-2025. Obs = `c(N)'"

/*  Binned event-time variable  */
gen event_time_bin = event_time
replace event_time_bin = -20 if event_time < -20
replace event_time_bin =  30 if event_time > 30 & !missing(event_time)

/*  Shift to positive integers: event_time_bin in [-20,30] → [1,51]
    Reference: event_time = -1  →  shifted = 20  (omitted)
    Hatch-Waxman: event_time = -8  →  shifted = 13               */
gen event_time_shifted = event_time_bin + 21
label variable event_time_bin     "Event Time (binned; end-caps at -20, +30)"
label variable event_time_shifted "Event Time (shifted; ref=20 i.e. 1991)"

/*  Declare time series (used for diagnostics; OLS below does not require it)  */
tsset approval_year

/*  ---- Specification 1: no time trend ----  */
di as txt _newline "--- Spec 1: cs_share ~ event-time dummies (no trend) ---"
di as txt "OLS; serial correlation likely in a time series — SEs are indicative only."

regress cs_share ib20.event_time_shifted

/*  Extract coefficients into a dataset for plotting  */
preserve
    clear
    set obs 51
    gen event_time_shifted = _n
    gen event_time         = event_time_shifted - 21
    gen coef = .
    gen se   = .
    /* Reference period: event_time = -1 → shifted = 20, coef = 0 by construction */
    replace coef = 0 if event_time_shifted == 20
    replace se   = 0 if event_time_shifted == 20
    /* Extract all non-reference levels */
    forvalues k = 1/51 {
        if `k' != 20 {
            capture replace coef = _b[`k'.event_time_shifted]  if event_time_shifted == `k'
            capture replace se   = _se[`k'.event_time_shifted] if event_time_shifted == `k'
        }
    }
    gen ci_lo = coef - 1.96 * se
    gen ci_hi = coef + 1.96 * se

    twoway                                                              ///
        (rarea ci_lo ci_hi event_time,                                  ///
             fcolor(navy%20) lwidth(none))                              ///
        (connected coef event_time,                                     ///
             lcolor(navy) mcolor(navy)                                  ///
             msymbol(circle_hollow) msize(small) lwidth(thin)),         ///
        yline(0, lpattern(dash) lcolor(gs8) lwidth(thin))               ///
        xline(0, lpattern(dash) lcolor(cranberry) lwidth(medthin))      ///
        xline(-8, lpattern(dot)  lcolor(gs7)      lwidth(medthin))      ///
        title("Event Study: Controlled Substance Share Around PDUFA",   ///
              size(medlarge))                                           ///
        subtitle("Reference period: 1991 (event time = -1)", size(small)) ///
        ytitle("Coefficient Relative to 1991")                         ///
        xtitle("Years Since PDUFA Enactment (1992)")                   ///
        xlabel(-20(5)30)                                                ///
        note("`cs_def'"                                                 ///
             "Dashed red line: PDUFA enactment (event time = 0, 1992)." ///
             "Dotted line: Hatch-Waxman Act (event time = -8, 1984)."   ///
             "Shaded band: 95% CI. `its_note'"                         ///
             "`data_note'", size(vsmall))                              ///
        legend(off)                                                     ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/event_study_cs_share.png", replace width(2400)
    di as txt "Exported: event_study_cs_share.png"
restore

/*  ---- Specification 2: with linear time trend (display in log only) ----  */
di as txt _newline "--- Spec 2: cs_share ~ event-time dummies + linear trend ---"
di as txt "(Asks whether there are deviations from a linear trend around 1992.)"

regress cs_share ib20.event_time_shifted c.approval_year

di as txt "(Spec 2 shown in log only; no separate figure.)"


/*==============================================================================
  PART 3: Event study — log CS counts vs log non-CS counts
==============================================================================*/

di as txt _newline "===== PART 3: Event study — log counts ====="

use "${dtapath}/event_study_annual.dta", clear
keep if approval_year >= 1970 & approval_year <= 2025

gen event_time_bin    = event_time
replace event_time_bin = -20 if event_time < -20
replace event_time_bin =  30 if event_time > 30 & !missing(event_time)
gen event_time_shifted = event_time_bin + 21

/*  ---- ln_cs regression ----  */
di as txt _newline "--- ln(CS + 1) ~ event-time dummies ---"
regress ln_cs ib20.event_time_shifted

/* Save coefficients for ln_cs */
preserve
    clear
    set obs 51
    gen event_time_shifted = _n
    gen event_time         = event_time_shifted - 21
    gen coef_cs = .
    gen se_cs   = .
    replace coef_cs = 0 if event_time_shifted == 20
    replace se_cs   = 0 if event_time_shifted == 20
    forvalues k = 1/51 {
        if `k' != 20 {
            capture replace coef_cs = _b[`k'.event_time_shifted]  if event_time_shifted == `k'
            capture replace se_cs   = _se[`k'.event_time_shifted] if event_time_shifted == `k'
        }
    }
    tempfile ln_cs_coefs
    save `ln_cs_coefs'
restore

/*  ---- ln_noncs regression ----  */
di as txt _newline "--- ln(Non-CS + 1) ~ event-time dummies ---"
regress ln_noncs ib20.event_time_shifted

/* Merge ln_noncs coefficients and plot combined figure */
preserve
    clear
    set obs 51
    gen event_time_shifted = _n
    gen event_time         = event_time_shifted - 21
    gen coef_noncs = .
    gen se_noncs   = .
    replace coef_noncs = 0 if event_time_shifted == 20
    replace se_noncs   = 0 if event_time_shifted == 20
    forvalues k = 1/51 {
        if `k' != 20 {
            capture replace coef_noncs = _b[`k'.event_time_shifted]  if event_time_shifted == `k'
            capture replace se_noncs   = _se[`k'.event_time_shifted] if event_time_shifted == `k'
        }
    }

    merge 1:1 event_time_shifted using `ln_cs_coefs', nogenerate

    /* Confidence intervals for both series */
    gen ci_lo_cs    = coef_cs    - 1.96 * se_cs
    gen ci_hi_cs    = coef_cs    + 1.96 * se_cs
    gen ci_lo_noncs = coef_noncs - 1.96 * se_noncs
    gen ci_hi_noncs = coef_noncs + 1.96 * se_noncs

    /* Single-series figure: ln_cs */
    twoway                                                               ///
        (rarea ci_lo_cs ci_hi_cs event_time,                            ///
             fcolor(navy%20) lwidth(none))                              ///
        (connected coef_cs event_time,                                  ///
             lcolor(navy) mcolor(navy)                                  ///
             msymbol(circle_hollow) msize(small) lwidth(thin)),         ///
        yline(0, lpattern(dash) lcolor(gs8) lwidth(thin))               ///
        xline(0, lpattern(dash) lcolor(cranberry) lwidth(medthin))      ///
        xline(-8, lpattern(dot) lcolor(gs7) lwidth(medthin))            ///
        title("Event Study: Log CS Approvals Around PDUFA",             ///
              size(medlarge))                                           ///
        subtitle("Reference period: 1991 (event time = -1)", size(small)) ///
        ytitle("Coefficient on ln(CS + 1) Relative to 1991")           ///
        xtitle("Years Since PDUFA Enactment (1992)")                   ///
        xlabel(-20(5)30)                                                ///
        note("`cs_def'"                                                 ///
             "Dashed red line: PDUFA enactment. Dotted line: Hatch-Waxman (1984)." ///
             "Shaded band: 95% CI. `its_note'"                         ///
             "`data_note'", size(vsmall))                              ///
        legend(off)                                                     ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/event_study_ln_cs.png", replace width(2400)
    di as txt "Exported: event_study_ln_cs.png"

    /* Combined figure: CS vs non-CS log counts */
    twoway                                                               ///
        (connected coef_cs    event_time,                               ///
             lcolor(navy)      mcolor(navy)                             ///
             msymbol(circle_hollow) msize(small) lwidth(thin))          ///
        (connected coef_noncs event_time,                               ///
             lcolor(cranberry) mcolor(cranberry)                        ///
             msymbol(triangle_hollow) msize(small) lwidth(thin)         ///
             lpattern(dash)),                                           ///
        yline(0, lpattern(dash) lcolor(gs8) lwidth(thin))               ///
        xline(0, lpattern(dash) lcolor(cranberry) lwidth(medthin))      ///
        xline(-8, lpattern(dot) lcolor(gs7) lwidth(medthin))            ///
        title("Event Study: CS vs Non-CS Log Approvals Around PDUFA",   ///
              size(medlarge))                                           ///
        subtitle("Reference period: 1991 (event time = -1)", size(small)) ///
        ytitle("Coefficient Relative to 1991")                         ///
        xtitle("Years Since PDUFA Enactment (1992)")                   ///
        xlabel(-20(5)30)                                                ///
        note("CS = Controlled Substance. Non-CS = all other approvals." ///
             "Dashed red line: PDUFA enactment. Dotted line: Hatch-Waxman (1984)." ///
             "`its_note'"                                               ///
             "`data_note'", size(vsmall))                              ///
        legend(order(1 "CS: ln(CS + 1)" 2 "Non-CS: ln(Non-CS + 1)")    ///
               position(1) ring(0) cols(1))                            ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/event_study_ln_cs_vs_noncs.png", replace width(2400)
    di as txt "Exported: event_study_ln_cs_vs_noncs.png"
restore


/*==============================================================================
  PART 4: Event study — NDA-only subsample
==============================================================================*/

di as txt _newline "===== PART 4: Event study — NDA-only subsample ====="
di as txt "(Conceptually cleanest channel: new molecular entities, not generics.)"

/*  Load drug-level .dta and restrict to NDA applications  */
use "${dtapath}/event_study_drug_panel.dta", clear
keep if is_nda == 1
di as txt "NDA-only sample: `c(N)' drug-application rows"

/*  Collapse to annual NDA panel  */
gen n_one    = 1
gen n_cs_nda = is_controlled_substance

collapse                                          ///
    (sum) n_nda = n_one                           ///
          n_cs_nda,                              ///
    by(approval_year)

gen cs_share_nda = n_cs_nda / n_nda if n_nda > 0
gen event_time   = approval_year - 1992
gen post_pdufa   = (approval_year >= 1993)

sort approval_year

/*  Apply sample restriction and create binned event time  */
keep if approval_year >= 1970 & approval_year <= 2025
di as txt "NDA-only annual panel, 1970-2025. Obs = `c(N)'"

gen event_time_bin    = event_time
replace event_time_bin = -20 if event_time < -20
replace event_time_bin =  30 if event_time > 30 & !missing(event_time)
gen event_time_shifted = event_time_bin + 21

/*  Drop years with no NDA approvals (undefined share)  */
drop if missing(cs_share_nda)
di as txt "After dropping missing cs_share_nda. Obs = `c(N)'"

/*  Regression  */
di as txt _newline "--- cs_share_nda ~ event-time dummies (NDA only) ---"
regress cs_share_nda ib20.event_time_shifted

/*  Extract and plot  */
preserve
    clear
    set obs 51
    gen event_time_shifted = _n
    gen event_time         = event_time_shifted - 21
    gen coef = .
    gen se   = .
    replace coef = 0 if event_time_shifted == 20
    replace se   = 0 if event_time_shifted == 20
    forvalues k = 1/51 {
        if `k' != 20 {
            capture replace coef = _b[`k'.event_time_shifted]  if event_time_shifted == `k'
            capture replace se   = _se[`k'.event_time_shifted] if event_time_shifted == `k'
        }
    }
    gen ci_lo = coef - 1.96 * se
    gen ci_hi = coef + 1.96 * se

    twoway                                                              ///
        (rarea ci_lo ci_hi event_time,                                  ///
             fcolor(navy%20) lwidth(none))                              ///
        (connected coef event_time,                                     ///
             lcolor(navy) mcolor(navy)                                  ///
             msymbol(circle_hollow) msize(small) lwidth(thin)),         ///
        yline(0, lpattern(dash) lcolor(gs8) lwidth(thin))               ///
        xline(0, lpattern(dash) lcolor(cranberry) lwidth(medthin))      ///
        xline(-8, lpattern(dot) lcolor(gs7) lwidth(medthin))            ///
        title("Event Study: CS Share Among NDA Approvals Around PDUFA", ///
              size(medlarge))                                           ///
        subtitle("NDA only (new molecular entities, not generics). Ref: 1991.", ///
                 size(small))                                           ///
        ytitle("Coefficient Relative to 1991")                         ///
        xtitle("Years Since PDUFA Enactment (1992)")                   ///
        xlabel(-20(5)30)                                                ///
        note("`cs_def'"                                                 ///
             "Restricted to NDA applications. Small annual denominators — wide CIs expected." ///
             "Dashed red line: PDUFA enactment. Dotted line: Hatch-Waxman (1984)." ///
             "Shaded band: 95% CI. `its_note'"                         ///
             "`data_note'", size(vsmall))                              ///
        legend(off)                                                     ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/event_study_cs_share_nda.png", replace width(2400)
    di as txt "Exported: event_study_cs_share_nda.png"
restore


/*==============================================================================
  PART 5: Simple parametric pre/post regressions
==============================================================================*/

di as txt _newline "===== PART 5: Parametric ITS regressions ====="

use "${dtapath}/event_study_annual.dta", clear
keep if approval_year >= 1970 & approval_year <= 2025

/*  Trend-break interaction term  */
gen trend_post = event_time * post_pdufa
label variable trend_post "Event time x Post-PDUFA (slope change)"

tsset approval_year

/*  ---- CS share models ----  */
di as txt _newline "--- CS Share: Models A-D ---"
di as txt ""
di as txt "Model A: Level shift only"
regress cs_share post_pdufa
estimates store m_cs_A

di as txt _newline "Model B: Level shift + linear trend"
regress cs_share post_pdufa c.approval_year
estimates store m_cs_B

di as txt _newline "Model C: Level shift + trend + slope change"
regress cs_share post_pdufa c.approval_year trend_post
estimates store m_cs_C

di as txt _newline "Model D: Same as C but log CS count as outcome"
regress ln_cs post_pdufa c.approval_year trend_post
estimates store m_cs_D

di as txt _newline "--- Summary table: CS share models A-C, log count model D ---"
estimates table m_cs_A m_cs_B m_cs_C m_cs_D,                         ///
    b(%8.4f) se(%8.4f) stats(N r2 rmse)                               ///
    title("ITS Regressions: CS Share (A-C) and ln(CS+1) (D)")

/*  ---- NDA-only and ANDA-only subsample models ----  */
di as txt _newline "--- CS Share (NDA only): Models A-C ---"

/* Flag years with valid NDA and ANDA shares */
gen valid_nda  = (n_nda  >= 5)
gen valid_anda = (n_anda >= 5)

di as txt "NDA Models (years with n_nda >= 5):"
regress cs_share_nda  post_pdufa if valid_nda
estimates store m_nda_A
regress cs_share_nda  post_pdufa c.approval_year if valid_nda
estimates store m_nda_B
regress cs_share_nda  post_pdufa c.approval_year trend_post if valid_nda
estimates store m_nda_C

di as txt _newline "ANDA Models (years with n_anda >= 5):"
regress cs_share_anda post_pdufa if valid_anda
estimates store m_anda_A
regress cs_share_anda post_pdufa c.approval_year if valid_anda
estimates store m_anda_B
regress cs_share_anda post_pdufa c.approval_year trend_post if valid_anda
estimates store m_anda_C

di as txt _newline "--- Summary table: NDA and ANDA subsample models ---"
estimates table m_nda_A m_nda_B m_nda_C m_anda_A m_anda_B m_anda_C, ///
    b(%8.4f) se(%8.4f) stats(N r2)                                   ///
    title("ITS Regressions: NDA-only and ANDA-only subsamples")


/*==============================================================================
  PART 6: Summary figure
==============================================================================*/

di as txt _newline "===== PART 6: Summary figure ====="

use "${dtapath}/event_study_annual.dta", clear
keep if approval_year >= 1970 & approval_year <= 2025

/*  Compute pre- and post-PDUFA mean CS share for horizontal reference lines  */
qui sum cs_share if approval_year >= 1970 & approval_year <= 1992
local pre_mean  = r(mean)
local pre_mean_fmt = string(`pre_mean', "%5.3f")

qui sum cs_share if approval_year >= 1993 & approval_year <= 2025
local post_mean = r(mean)
local post_mean_fmt = string(`post_mean', "%5.3f")

di as txt "Pre-PDUFA mean CS share  (1970-1992): `pre_mean_fmt'"
di as txt "Post-PDUFA mean CS share (1993-2025): `post_mean_fmt'"

/*  Create horizontal mean lines scoped to each period  */
gen pre_mean_line  = `pre_mean'  if approval_year >= 1970 & approval_year <= 1992
gen post_mean_line = `post_mean' if approval_year >= 1993 & approval_year <= 2025

twoway                                                                   ///
    (line cs_share approval_year,                                        ///
         lcolor(gs10) lwidth(medthin))                                   ///
    (line pre_mean_line  approval_year,                                  ///
         lcolor(navy)    lwidth(medium) lpattern(solid))                 ///
    (line post_mean_line approval_year,                                  ///
         lcolor(cranberry) lwidth(medium) lpattern(solid)),              ///
    xline(1984, lpattern(dot)  lcolor(gs7) lwidth(medthin))              ///
    xline(1992, lpattern(dash) lcolor(cranberry) lwidth(medthin))        ///
    title("CS Share of Drug Approvals, 1970-2025",                       ///
          size(medlarge))                                                ///
    subtitle("Raw annual series with pre- and post-PDUFA period means",  ///
             size(small))                                                ///
    ytitle("Share of Approvals That Are Controlled Substances")          ///
    xtitle("Year")                                                       ///
    xlabel(1970(5)2025, angle(45))                                       ///
    ylabel(, format(%4.2f))                                              ///
    legend(order(1 "Annual CS share"                                     ///
                 2 "Pre-PDUFA mean (`pre_mean_fmt')"                     ///
                 3 "Post-PDUFA mean (`post_mean_fmt')")                  ///
           position(1) ring(0) cols(1))                                  ///
    note("`cs_def'"                                                      ///
         "Dashed red line: PDUFA enactment (1992). Dotted line: Hatch-Waxman (1984)." ///
         "`data_note'", size(vsmall))                                   ///
    graphregion(color(white)) bgcolor(white)

graph export "${figures}/event_study_summary.png", replace width(2400)
di as txt "Exported: event_study_summary.png"


/*==============================================================================
  Done
==============================================================================*/

di as txt _newline "===== 03_event_study.do complete ====="
di as txt "Figures written to: ${figures}"
di as txt "Annual panel saved: ${dtapath}/event_study_annual.dta"
log close
