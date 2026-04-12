/*==============================================================================
  ECON 580 Thesis — GDUFA Analysis: ANDA Controlled Substance Approvals

  Purpose: Test whether GDUFA (2012) changed the composition of ANDA approvals
           toward or away from controlled substances. GDUFA is the relevant
           user-fee policy for generic drugs; PDUFA (1992) applied to NDAs
           and BLAs only and did not cover ANDAs until GDUFA.

  DESIGN NOTE:
    GDUFA was enacted July 9, 2012. User fees began October 1, 2012 (FY2013).
    Critically, GDUFA had NO performance goals for FY2013 and FY2014 — those
    years were a ramp-up period for hiring and clearing the backlog (~2,866
    applications). Performance goals (15-month first-action target) began
    FY2015 (October 1, 2014). By FY2017 review times had fallen to ~10 months.

    IMPLICATION: 2013–2014 approvals are largely OLD backlogged applications
    being cleared, not new submissions under GDUFA performance incentives.
    The "clean" post-GDUFA treatment window begins 2015, NOT 2013.
    We treat 2013–2014 as a TRANSITION period and handle it explicitly.

  Three-period design:
    Pre-GDUFA:   approval_year <= 2012
    Transition:  approval_year == 2013 or 2014  (backlog washout)
    Post-GDUFA:  approval_year >= 2015          (performance-goal era)

  Event-time binning (centered on 2012):
    event_time_gdufa = approval_year - 2012
    End-cap pre:  event_time_gdufa <= -10   (1984–2002 grouped)
    End-cap post: event_time_gdufa >=  10   (2022–2025 grouped)
    Shifted var:  event_time_gdufa_bin + 11  → range [1, 21]
    Reference:    event_time_gdufa = -1 (2011) → shifted = 10  (omitted)

  Input:   ${dtapath}/event_study_drug_panel.dta
  Output:  ${dtapath}/gdufa_anda_annual.dta
           ${tables}/gdufa_*.csv
           ${figures}/gdufa_*.png
==============================================================================*/

do "${code}/globals.do"
capture log close
log using "${statalogs}/05_gdufa_analysis.log", replace

graph set window fontface "Times New Roman"

/* Shared note locals for figures */
local data_note  "Source: FDA Drugs@FDA, DEA controlled substance schedules. ANDA approvals only."
local cs_def     "CS = Controlled Substance (conservative: confident DEA scheduled matches only)."
local gdufa_note "GDUFA enacted 2012; performance goals began FY2015. 2013-2014 = backlog transition."


/*==============================================================================
  PART 1: Restrict to ANDAs, collapse to annual panel, create timing variables
==============================================================================*/

di as txt _newline "===== PART 1: Building GDUFA ANDA annual panel ====="

use "${dtapath}/event_study_drug_panel.dta", clear

/* Restrict to ANDA applications only */
keep if is_anda == 1
di as txt "ANDA-only sample: `c(N)' drug-application rows"

/* Create schedule-count helpers before collapse */
gen n_sched_ii  = (is_controlled_substance == 1 & is_schedule_ii  == 1)
gen n_sched_iii = (is_controlled_substance == 1 & is_schedule_iii == 1)
gen n_sched_iv  = (is_controlled_substance == 1 & is_schedule_iv  == 1)
gen n_sched_v   = (is_controlled_substance == 1 & is_schedule_v   == 1)
gen n_one       = 1

collapse                                              ///
    (sum) n_anda_total = n_one                        ///
          n_anda_cs    = is_controlled_substance      ///
          n_sched_ii                                  ///
          n_sched_iii                                 ///
          n_sched_iv                                  ///
          n_sched_v,                                  ///
    by(approval_year)

sort approval_year

/* Derived variables */
gen n_anda_noncs  = n_anda_total - n_anda_cs
gen anda_cs_share = n_anda_cs / n_anda_total if n_anda_total > 0

/* Restrict to post-Hatch-Waxman: ANDAs begin in earnest after 1984 */
keep if approval_year >= 1984 & approval_year <= 2025
di as txt "After Hatch-Waxman restriction (1984-2025): obs = `c(N)'"

/* GDUFA policy timing variables */
gen event_time_gdufa  = approval_year - 2012
gen post_gdufa        = (approval_year >= 2015)
gen gdufa_transition  = (approval_year >= 2013 & approval_year <= 2014)
gen pre_gdufa         = (approval_year <= 2012)
gen gdufa_era         = 0 if approval_year <= 2012
replace gdufa_era     = 1 if approval_year >= 2013 & approval_year <= 2014
replace gdufa_era     = 2 if approval_year >= 2015

/* Trend-break interaction */
gen trend_post_gdufa = event_time_gdufa * post_gdufa

/* Variable labels */
label variable approval_year      "Approval Year"
label variable n_anda_total       "Total ANDA Approvals"
label variable n_anda_cs          "CS ANDA Approvals (Conservative)"
label variable n_anda_noncs       "Non-CS ANDA Approvals"
label variable anda_cs_share      "CS Share of ANDA Approvals"
label variable n_sched_ii         "Schedule II ANDA CS Approvals"
label variable n_sched_iii        "Schedule III ANDA CS Approvals"
label variable n_sched_iv         "Schedule IV ANDA CS Approvals"
label variable n_sched_v          "Schedule V ANDA CS Approvals"
label variable event_time_gdufa   "Event Time (approval_year - 2012)"
label variable post_gdufa         "Post-GDUFA (2015+, performance-goal era)"
label variable gdufa_transition   "GDUFA Transition (2013-2014, backlog washout)"
label variable pre_gdufa          "Pre-GDUFA (<=2012)"
label variable trend_post_gdufa   "Event Time x Post-GDUFA (slope change)"

label define lbl_gdufa_era        ///
    0 "Pre-GDUFA (<=2012)"        ///
    1 "Transition (2013-2014)"    ///
    2 "Post-GDUFA (2015+)"
label values gdufa_era lbl_gdufa_era

/* Declare as time series */
tsset approval_year

save "${dtapath}/gdufa_anda_annual.dta", replace
di as txt "Saved: gdufa_anda_annual.dta  (obs = `c(N)')"

/* Display transition window in log */
di as txt _newline "--- ANDA annual panel: transition window 2008-2020 ---"
list approval_year n_anda_total n_anda_cs anda_cs_share  ///
    if approval_year >= 2008 & approval_year <= 2020,    ///
    noobs sep(0) abbreviate(14)


/*==============================================================================
  PART 2: Descriptive tables
==============================================================================*/

di as txt _newline "===== PART 2: Descriptive tables ====="


/* --- Table G1: ANDA overview by GDUFA era --- */

di as txt _newline "==== TABLE G1: ANDA Overview by GDUFA Era ===="

preserve

    gen cs_sched_ii  = n_sched_ii
    gen cs_sched_iii = n_sched_iii
    gen cs_sched_iv  = n_sched_iv
    gen cs_sched_v   = n_sched_v

    collapse                                                    ///
        (sum)  n_anda_total n_anda_cs cs_sched_ii cs_sched_iii ///
               cs_sched_iv cs_sched_v                          ///
        (mean) anda_cs_share,                                  ///
        by(gdufa_era)

    gen cs_share_era = n_anda_cs / n_anda_total

    format anda_cs_share cs_share_era %6.4f
    label variable n_anda_total    "Total ANDA Approvals"
    label variable n_anda_cs       "CS ANDA Approvals"
    label variable cs_share_era    "CS Share (from totals)"
    label variable anda_cs_share   "Mean Annual CS Share"
    label variable cs_sched_ii     "Schedule II"
    label variable cs_sched_iii    "Schedule III"
    label variable cs_sched_iv     "Schedule IV"
    label variable cs_sched_v      "Schedule V"

    list, sep(0) noobs
    export delimited "${tables}/gdufa_overview_by_era.csv", replace
    di as txt "Exported: gdufa_overview_by_era.csv"

restore


/* --- Table G2: Annual ANDA summary panel --- */

di as txt _newline "==== TABLE G2: Annual ANDA Summary Panel ===="

format anda_cs_share %6.4f
list approval_year n_anda_total n_anda_cs anda_cs_share ///
     n_sched_ii n_sched_iii n_sched_iv n_sched_v,       ///
     noobs sep(5) abbreviate(16)

export delimited "${tables}/gdufa_annual_anda_panel.csv", replace
di as txt "Exported: gdufa_annual_anda_panel.csv"


/* --- Table G3: Pre vs Post-GDUFA (excluding transition) --- */

di as txt _newline "==== TABLE G3: Pre vs Post-GDUFA Comparison (excluding transition) ===="

preserve

    keep if gdufa_transition == 0

    collapse                                                         ///
        (sum)  n_anda_total n_anda_cs n_sched_ii n_sched_iii        ///
               n_sched_iv n_sched_v                                 ///
        (mean) anda_cs_share,                                       ///
        by(post_gdufa)

    gen cs_share_from_totals = n_anda_cs / n_anda_total
    format anda_cs_share cs_share_from_totals %6.4f

    label variable post_gdufa              "Post-GDUFA (0=pre, 1=post)"
    label variable n_anda_total            "Total ANDA Approvals"
    label variable n_anda_cs               "CS ANDA Approvals"
    label variable cs_share_from_totals    "CS Share (totals)"
    label variable anda_cs_share           "Mean Annual CS Share"
    label variable n_sched_ii              "Schedule II"
    label variable n_sched_iii             "Schedule III"
    label variable n_sched_iv              "Schedule IV"
    label variable n_sched_v               "Schedule V"

    list, sep(0) noobs
    export delimited "${tables}/gdufa_pre_post_comparison.csv", replace
    di as txt "Exported: gdufa_pre_post_comparison.csv"

restore


/*==============================================================================
  PART 3: Descriptive figures
==============================================================================*/

di as txt _newline "===== PART 3: Descriptive figures ====="

use "${dtapath}/gdufa_anda_annual.dta", clear

/* Compute max CS share for shading bounds */
qui sum anda_cs_share
local max_share = r(max) + 0.03

/* Compute pre/post means for reference lines */
qui sum anda_cs_share if approval_year >= 1984 & approval_year <= 2012
local pre_mean  = r(mean)
local pre_fmt   = string(`pre_mean',  "%5.3f")

qui sum anda_cs_share if approval_year >= 2015 & approval_year <= 2025
local post_mean = r(mean)
local post_fmt  = string(`post_mean', "%5.3f")

/* Transition shading helpers */
gen shade_lo = 0
gen shade_hi = `max_share'


/* ---- Figure G1: Total ANDA approvals per year ---- */

di as txt _newline "==== FIGURE G1: Total ANDA Approvals ===="

twoway                                                                ///
    (rarea shade_lo shade_hi approval_year if gdufa_transition == 1, ///
         fcolor(gs14) lwidth(none))                                  ///
    (line n_anda_total approval_year, lcolor(navy) lwidth(medthin)), ///
    xline(${gdufa_year}, lpattern(dash) lcolor(cranberry)            ///
          lwidth(medthin))                                           ///
    title("Total ANDA Approvals per Year, 1984-2025",               ///
          size(medlarge))                                            ///
    ytitle("Number of ANDA Approvals")                              ///
    xtitle("Year")                                                   ///
    xlabel(1984(4)2024, angle(45))                                   ///
    ylabel(, format(%9.0f))                                          ///
    note("Gray band: 2013-2014 GDUFA transition (backlog washout)."  ///
         "Dashed red line: GDUFA enacted (2012)."                   ///
         "`data_note'", size(vsmall))                               ///
    legend(off)                                                      ///
    graphregion(color(white)) bgcolor(white)

graph export "${figures}/gdufa_anda_approvals.png", replace width(2400)
di as txt "Exported: gdufa_anda_approvals.png"


/* ---- Figure G2: CS share among ANDA approvals (main GDUFA figure) ---- */

di as txt _newline "==== FIGURE G2: ANDA CS Share — Main GDUFA Figure ===="

gen pre_mean_line  = `pre_mean'  if approval_year >= 1984 & approval_year <= 2012
gen post_mean_line = `post_mean' if approval_year >= 2015 & approval_year <= 2025

twoway                                                                ///
    (rarea shade_lo shade_hi approval_year if gdufa_transition == 1, ///
         fcolor(gs14) lwidth(none))                                  ///
    (line anda_cs_share approval_year,                               ///
         lcolor(navy) lwidth(medium))                                ///
    (line pre_mean_line  approval_year,                              ///
         lcolor(navy) lwidth(medium) lpattern(dash))                 ///
    (line post_mean_line approval_year,                              ///
         lcolor(cranberry) lwidth(medium) lpattern(dash)),           ///
    xline(${gdufa_year}, lpattern(dash) lcolor(cranberry)            ///
          lwidth(medthin))                                           ///
    title("CS Share of ANDA Approvals, 1984-2025",                  ///
          size(medlarge))                                            ///
    subtitle("Conservative definition: confident DEA scheduled matches only", ///
             size(small))                                            ///
    ytitle("Proportion of ANDA Approvals That Are CS")              ///
    xtitle("Year")                                                   ///
    xlabel(1984(4)2024, angle(45))                                   ///
    ylabel(, format(%4.2f))                                          ///
    legend(order(2 "Annual CS share"                                 ///
                 3 "Pre-GDUFA mean (`pre_fmt')"                      ///
                 4 "Post-GDUFA mean (`post_fmt')")                   ///
           position(1) ring(0) cols(1))                              ///
    note("`cs_def'"                                                  ///
         "Gray band: 2013-2014 transition. `gdufa_note'"            ///
         "`data_note'", size(vsmall))                               ///
    graphregion(color(white)) bgcolor(white)

graph export "${figures}/gdufa_anda_cs_share.png", replace width(2400)
di as txt "Exported: gdufa_anda_cs_share.png"

drop pre_mean_line post_mean_line


/* ---- Figure G3: Annual CS ANDA approval count ---- */

di as txt _newline "==== FIGURE G3: ANDA CS Count ===="

twoway                                                                ///
    (rarea shade_lo shade_hi approval_year if gdufa_transition == 1, ///
         fcolor(gs14) lwidth(none))                                  ///
    (line n_anda_cs approval_year, lcolor(navy) lwidth(medium)),     ///
    xline(${gdufa_year}, lpattern(dash) lcolor(cranberry)            ///
          lwidth(medthin))                                           ///
    title("Annual CS ANDA Approvals, 1984-2025",                    ///
          size(medlarge))                                            ///
    ytitle("Number of CS ANDA Approvals")                           ///
    xtitle("Year")                                                   ///
    xlabel(1984(4)2024, angle(45))                                   ///
    ylabel(, format(%9.0f))                                          ///
    note("`cs_def'"                                                  ///
         "Gray band: 2013-2014 transition. Dashed red line: GDUFA (2012)." ///
         "`data_note'", size(vsmall))                               ///
    legend(off)                                                      ///
    graphregion(color(white)) bgcolor(white)

graph export "${figures}/gdufa_anda_cs_counts.png", replace width(2400)
di as txt "Exported: gdufa_anda_cs_counts.png"


/* ---- Figure G4: CS ANDA approvals by schedule ---- */

di as txt _newline "==== FIGURE G4: ANDA CS by Schedule ===="

twoway                                                                ///
    (rarea shade_lo shade_hi approval_year if gdufa_transition == 1, ///
         fcolor(gs14) lwidth(none))                                  ///
    (line n_sched_ii  approval_year,                                 ///
         lcolor(navy)         lwidth(medium))                        ///
    (line n_sched_iv  approval_year,                                 ///
         lcolor(cranberry)    lwidth(medium) lpattern(dash))         ///
    (line n_sched_iii approval_year,                                 ///
         lcolor(forest_green) lwidth(medium) lpattern(longdash))     ///
    (line n_sched_v   approval_year,                                 ///
         lcolor(dkorange)     lwidth(medium) lpattern(dot)),         ///
    xline(${gdufa_year}, lpattern(dash) lcolor(gs7) lwidth(medthin)) ///
    title("CS ANDA Approvals by DEA Schedule, 1984-2025",           ///
          size(medlarge))                                            ///
    ytitle("Number of CS ANDA Approvals")                           ///
    xtitle("Year")                                                   ///
    xlabel(1984(4)2024, angle(45))                                   ///
    ylabel(, format(%9.0f))                                          ///
    legend(order(2 "Schedule II" 3 "Schedule IV"                     ///
                 4 "Schedule III" 5 "Schedule V")                    ///
           position(1) ring(0) cols(1) size(small))                  ///
    note("`cs_def'"                                                  ///
         "Gray band: 2013-2014 transition. Dashed line: GDUFA (2012)." ///
         "`data_note'", size(vsmall))                               ///
    graphregion(color(white)) bgcolor(white)

graph export "${figures}/gdufa_anda_cs_by_schedule.png", replace width(2400)
di as txt "Exported: gdufa_anda_cs_by_schedule.png"


/* ---- Figure G5: Mean ANDA CS share by GDUFA era (bar chart) ---- */

di as txt _newline "==== FIGURE G5: Mean ANDA CS Share by GDUFA Era ===="

preserve

    collapse (mean) anda_cs_share, by(gdufa_era)
    sort gdufa_era
    format anda_cs_share %6.4f
    list gdufa_era anda_cs_share, sep(0) noobs

    graph bar (asis) anda_cs_share,                                  ///
        over(gdufa_era, label(angle(45) labsize(small)))             ///
        bar(1, color(navy))                                          ///
        title("Mean Annual ANDA CS Share by GDUFA Era",              ///
              size(medlarge))                                        ///
        ytitle("Mean Annual CS Share")                              ///
        ylabel(, format(%4.2f))                                      ///
        note("`cs_def'"                                              ///
             "`gdufa_note'"                                          ///
             "`data_note'", size(vsmall))                           ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/gdufa_anda_cs_share_eras.png", replace width(2400)
    di as txt "Exported: gdufa_anda_cs_share_eras.png"

restore


/*==============================================================================
  PART 4: Parametric interrupted time series
==============================================================================*/

di as txt _newline "===== PART 4: Parametric ITS regressions ====="

use "${dtapath}/gdufa_anda_annual.dta", clear

/* Model GA: Simple level shift (excluding transition) */
di as txt _newline "--- Model GA: Level shift only (excl. transition) ---"
regress anda_cs_share post_gdufa if gdufa_transition == 0
estimates store m_ga

/* Model GB: Level shift + linear trend (excluding transition) */
di as txt _newline "--- Model GB: Level shift + trend (excl. transition) ---"
regress anda_cs_share post_gdufa c.approval_year if gdufa_transition == 0
estimates store m_gb

/* Model GC: Level shift + trend + slope change (excluding transition) */
di as txt _newline "--- Model GC: Level shift + trend + slope change (excl. transition) ---"
regress anda_cs_share post_gdufa c.approval_year trend_post_gdufa   ///
    if gdufa_transition == 0
estimates store m_gc

/* Model GD: Three-period model (all years including transition) */
di as txt _newline "--- Model GD: Three-period model (all years) ---"
regress anda_cs_share i.gdufa_era c.approval_year
estimates store m_gd

/* Model GE: Narrower pre-period (2002-2025, excluding transition) */
di as txt _newline "--- Model GE: Level shift + trend + slope change (2002-2025, excl. transition) ---"
di as txt "(Narrower pre-period avoids noisy early ANDA years.)"
regress anda_cs_share post_gdufa c.approval_year trend_post_gdufa   ///
    if approval_year >= 2002 & gdufa_transition == 0
estimates store m_ge

/* Summary table */
di as txt _newline "--- Summary: All GDUFA parametric models ---"
estimates table m_ga m_gb m_gc m_gd m_ge,                          ///
    b(%8.4f) se(%8.4f) stats(N r2 rmse)                            ///
    title("ITS Regressions: ANDA CS Share Around GDUFA (2012)")


/*==============================================================================
  PART 5: Event study with event-time dummies (centered on 2012)
==============================================================================*/

di as txt _newline "===== PART 5: GDUFA Event Study ====="

use "${dtapath}/gdufa_anda_annual.dta", clear

/* Binned event time: end-caps at <=−10 and >=+10, shift to [1, 21]
   event_time_gdufa in [-10, 10] → shifted in [1, 21]
   Reference: event_time_gdufa = -1 (2011) → shifted = 10  (omitted) */
gen event_time_gdufa_bin = event_time_gdufa
replace event_time_gdufa_bin = -10 if event_time_gdufa < -10
replace event_time_gdufa_bin =  10 if event_time_gdufa > 10 & !missing(event_time_gdufa)
gen event_time_gdufa_shifted = event_time_gdufa_bin + 11

label variable event_time_gdufa_bin    "GDUFA Event Time (binned; end-caps at -10, +10)"
label variable event_time_gdufa_shifted "GDUFA Event Time (shifted; ref=10 i.e. 2011)"

di as txt _newline "--- GDUFA event study, full sample 1984-2025 ---"
di as txt "NOTE: OLS; serial correlation not corrected — treat as descriptive."

regress anda_cs_share ib10.event_time_gdufa_shifted

/* Extract coefficients for plot */
preserve
    clear
    set obs 21
    gen event_time_gdufa_shifted = _n
    gen event_time_gdufa         = event_time_gdufa_shifted - 11
    gen coef = .
    gen se   = .
    /* Reference: event_time_gdufa = -1 → shifted = 10, coef = 0 */
    replace coef = 0 if event_time_gdufa_shifted == 10
    replace se   = 0 if event_time_gdufa_shifted == 10
    forvalues k = 1/21 {
        if `k' != 10 {
            capture replace coef = _b[`k'.event_time_gdufa_shifted]  ///
                if event_time_gdufa_shifted == `k'
            capture replace se   = _se[`k'.event_time_gdufa_shifted] ///
                if event_time_gdufa_shifted == `k'
        }
    }
    gen ci_lo = coef - 1.96 * se
    gen ci_hi = coef + 1.96 * se

    /* Shade transition years (event_time 1-2 = 2013-2014) */
    gen shade_lo = min(ci_lo, 0) - 0.02
    gen shade_hi = max(ci_hi, 0) + 0.02
    /* Use fixed bounds to avoid missing-dependent shading */
    qui sum ci_lo
    local ylo = r(min) - 0.01
    qui sum ci_hi
    local yhi = r(max) + 0.01

    gen band_lo = `ylo'
    gen band_hi = `yhi'

    twoway                                                           ///
        (rarea band_lo band_hi event_time_gdufa                     ///
             if event_time_gdufa >= 1 & event_time_gdufa <= 2,      ///
             fcolor(gs14) lwidth(none))                             ///
        (rarea ci_lo ci_hi event_time_gdufa,                        ///
             fcolor(navy%20) lwidth(none))                          ///
        (connected coef event_time_gdufa,                           ///
             lcolor(navy) mcolor(navy)                              ///
             msymbol(circle_hollow) msize(small) lwidth(thin)),     ///
        yline(0, lpattern(dash) lcolor(gs8) lwidth(thin))           ///
        xline(0, lpattern(dash) lcolor(cranberry) lwidth(medthin))  ///
        title("Event Study: ANDA CS Share Around GDUFA (2012)",     ///
              size(medlarge))                                        ///
        subtitle("Reference period: 2011 (event time = -1)", size(small)) ///
        ytitle("Coefficient Relative to 2011")                     ///
        xtitle("Years Since GDUFA Enactment (2012)")               ///
        xlabel(-10(2)10)                                            ///
        note("`cs_def'"                                             ///
             "Dashed red line: GDUFA enactment (event time = 0)."   ///
             "Gray band: 2013-2014 backlog transition (event time 1-2)." ///
             "Navy band: 95% CI. `gdufa_note'"                     ///
             "`data_note'", size(vsmall))                           ///
        legend(off)                                                  ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/gdufa_event_study_anda_cs_share.png",  ///
        replace width(2400)
    di as txt "Exported: gdufa_event_study_anda_cs_share.png"
restore

/* ---- Narrower window: 2002-2025 ---- */

di as txt _newline "--- GDUFA event study, narrow window 2002-2025 ---"
di as txt "NOTE: Only `c(N)' annual observations after restriction."

preserve
    keep if approval_year >= 2002

    regress anda_cs_share ib10.event_time_gdufa_shifted

    /* Extract coefficients */
    tempfile narrow_coefs
    preserve
        clear
        set obs 21
        gen event_time_gdufa_shifted = _n
        gen event_time_gdufa         = event_time_gdufa_shifted - 11
        gen coef = .
        gen se   = .
        replace coef = 0 if event_time_gdufa_shifted == 10
        replace se   = 0 if event_time_gdufa_shifted == 10
        forvalues k = 1/21 {
            if `k' != 10 {
                capture replace coef = _b[`k'.event_time_gdufa_shifted]  ///
                    if event_time_gdufa_shifted == `k'
                capture replace se   = _se[`k'.event_time_gdufa_shifted] ///
                    if event_time_gdufa_shifted == `k'
            }
        }
        gen ci_lo = coef - 1.96 * se
        gen ci_hi = coef + 1.96 * se

        qui sum ci_lo
        local ylo = r(min) - 0.01
        qui sum ci_hi
        local yhi = r(max) + 0.01
        gen band_lo = `ylo'
        gen band_hi = `yhi'

        twoway                                                       ///
            (rarea band_lo band_hi event_time_gdufa                 ///
                 if event_time_gdufa >= 1 & event_time_gdufa <= 2,  ///
                 fcolor(gs14) lwidth(none))                         ///
            (rarea ci_lo ci_hi event_time_gdufa,                    ///
                 fcolor(navy%20) lwidth(none))                      ///
            (connected coef event_time_gdufa,                       ///
                 lcolor(navy) mcolor(navy)                          ///
                 msymbol(circle_hollow) msize(small) lwidth(thin)), ///
            yline(0, lpattern(dash) lcolor(gs8) lwidth(thin))       ///
            xline(0, lpattern(dash) lcolor(cranberry) lwidth(medthin)) ///
            title("Event Study: ANDA CS Share Around GDUFA (2012)", ///
                  size(medlarge))                                   ///
            subtitle("Narrow window: 2002-2025. Reference: 2011.", size(small)) ///
            ytitle("Coefficient Relative to 2011")                 ///
            xtitle("Years Since GDUFA Enactment (2012)")           ///
            xlabel(-10(2)10)                                        ///
            note("`cs_def'"                                         ///
                 "N = 24 annual observations. Wide CIs expected."   ///
                 "Gray band: 2013-2014 backlog transition."         ///
                 "`data_note'", size(vsmall))                       ///
            legend(off)                                             ///
            graphregion(color(white)) bgcolor(white)

        graph export "${figures}/gdufa_event_study_anda_cs_share_narrow.png", ///
            replace width(2400)
        di as txt "Exported: gdufa_event_study_anda_cs_share_narrow.png"
    restore
restore


/*==============================================================================
  PART 6: Three-period summary figure
==============================================================================*/

di as txt _newline "===== PART 6: Three-period summary figure ====="

use "${dtapath}/gdufa_anda_annual.dta", clear

/* Pre/post means (excluding transition) */
qui sum anda_cs_share if approval_year >= 1984 & approval_year <= 2012
local pre_mean  = r(mean)
local pre_fmt   = string(`pre_mean',  "%5.3f")

qui sum anda_cs_share if approval_year >= 2015 & approval_year <= 2025
local post_mean = r(mean)
local post_fmt  = string(`post_mean', "%5.3f")

di as txt "Pre-GDUFA mean CS share  (1984-2012): `pre_fmt'"
di as txt "Post-GDUFA mean CS share (2015-2025): `post_fmt'"

/* Reference line variables */
gen pre_line  = `pre_mean'  if approval_year >= 1984 & approval_year <= 2012
gen post_line = `post_mean' if approval_year >= 2015 & approval_year <= 2025

/* Transition shading */
qui sum anda_cs_share
local ymax = r(max) + 0.02
gen shade_lo = 0
gen shade_hi = `ymax'

twoway                                                                ///
    (rarea shade_lo shade_hi approval_year if gdufa_transition == 1, ///
         fcolor(gs14) lwidth(none))                                  ///
    (line anda_cs_share approval_year,                               ///
         lcolor(gs10) lwidth(medthin))                               ///
    (line pre_line  approval_year,                                   ///
         lcolor(navy)     lwidth(medium) lpattern(solid))            ///
    (line post_line approval_year,                                   ///
         lcolor(cranberry) lwidth(medium) lpattern(solid)),          ///
    xline(${gdufa_year}, lpattern(dash) lcolor(cranberry)            ///
          lwidth(medthin))                                           ///
    title("ANDA CS Share, 1984-2025",                               ///
          size(medlarge))                                            ///
    subtitle("Raw annual series with pre- and post-GDUFA period means", ///
             size(small))                                            ///
    ytitle("CS Share of ANDA Approvals")                            ///
    xtitle("Year")                                                   ///
    xlabel(1984(4)2024, angle(45))                                   ///
    ylabel(, format(%4.2f))                                          ///
    legend(order(2 "Annual CS share"                                 ///
                 3 "Pre-GDUFA mean (`pre_fmt')"                      ///
                 4 "Post-GDUFA mean (`post_fmt')")                   ///
           position(1) ring(0) cols(1))                              ///
    note("`cs_def'"                                                  ///
         "Gray band: 2013-2014 backlog transition (excluded from means)." ///
         "Dashed red line: GDUFA enacted (2012). `gdufa_note'"      ///
         "`data_note'", size(vsmall))                               ///
    graphregion(color(white)) bgcolor(white)

graph export "${figures}/gdufa_summary.png", replace width(2400)
di as txt "Exported: gdufa_summary.png"


/*==============================================================================
  Done
==============================================================================*/

di as txt _newline "===== 05_gdufa_analysis.do complete ====="
di as txt "Annual panel saved: ${dtapath}/gdufa_anda_annual.dta"
di as txt "Figures written to: ${figures}"
di as txt "Tables written to:  ${tables}"
log close
