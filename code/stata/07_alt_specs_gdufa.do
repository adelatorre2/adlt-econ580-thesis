/*==============================================================================
  ECON 580 Thesis — Alternative Specifications: GDUFA (2012)

  Purpose: Address the denominator problem in the ANDA share-based analysis by
           running Poisson count models (ANDA CS counts with ANDA total as
           exposure) and a stacked DD where ANDA CS and non-CS approval counts
           are separate groups. The key question: did CS ANDA approvals grow
           differentially FASTER than non-CS ANDA approvals after GDUFA?

  Key design notes:
    - Three-period structure:
        Pre-GDUFA:   approval_year <= 2012
        Transition:  2013-2014 (backlog washout, NOT clean treatment)
        Post-GDUFA:  approval_year >= 2015 (performance-goal era)
      Primary DD specs EXCLUDE 2013-2014. All-years versions are sensitivity.
    - Poisson with exposure: ln(E[n_anda_cs]) = b0 + b1*post + b2*year +
      ln(n_anda_total). exp(b1) = IRR on post_gdufa.
    - Stacked DD: two rows per year (ANDA CS and non-CS). Group + year FE +
      group*post interaction. Transition years excluded from primary spec.
    - IHS transformation: asinh(n_approvals) approximates log, defined at zero.
    - Sponsor concentration: HHI and top-10 share from drug-level panel.

  Input:   ${dtapath}/gdufa_anda_annual.dta
           ${dtapath}/event_study_drug_panel.dta
  Output:  ${dtapath}/gdufa_stacked_dd.dta
           ${figures}/gdufa_dd_event_study.png
           ${figures}/gdufa_sponsor_concentration_top10.png
           ${figures}/gdufa_sponsor_concentration_hhi.png
           ${figures}/gdufa_cs_sponsor_concentration_top10.png
           ${tables}/gdufa_alt_specs_results.csv
           ${tables}/gdufa_concentration_comparison.csv
==============================================================================*/

do "${code}/globals.do"
capture log close
log using "${statalogs}/07_alt_specs_gdufa.log", replace

graph set window fontface "Times New Roman"

local data_note  "Source: FDA Drugs@FDA, DEA controlled substance schedules. ANDA approvals only."
local cs_def     "CS = Controlled Substance (conservative: confident DEA scheduled matches only)."
local gdufa_note "GDUFA enacted 2012; performance goals began FY2015. 2013-2014 = backlog transition."


/*==============================================================================
  PART 1: Load and prepare GDUFA ANDA annual panel
==============================================================================*/

di as txt _newline "===== PART 1: Annual panel preparation (GDUFA) ====="

use "${dtapath}/gdufa_anda_annual.dta", clear
keep if approval_year >= 1984 & approval_year <= 2025
di as txt "Sample restricted to 1984-2025. Obs = `c(N)'"

/* Derived variables — use capture drop to make idempotent and tolerate
   variables that may already exist in the saved .dta (trend_post_gdufa
   is created by 05_gdufa_analysis.do) */
capture drop n_noncs_anda
capture drop trend_post_gdufa
gen n_noncs_anda     = n_anda_total - n_anda_cs
gen trend_post_gdufa = event_time_gdufa * post_gdufa

label variable n_noncs_anda     "Non-CS ANDA Approvals (n_anda_total - n_anda_cs)"
label variable trend_post_gdufa "Event Time x Post-GDUFA (slope break)"

tsset approval_year

di as txt "Variables available:"
describe


/*==============================================================================
  PART 2: Poisson count models with exposure
==============================================================================*/

di as txt _newline "===== PART 2: Poisson count models (GDUFA) ====="
di as txt "Outcome: n_anda_cs. Exposure: n_anda_total (ln offset)."
di as txt "Primary specs EXCLUDE transition years 2013-2014."
di as txt "exp(post_gdufa coef) = IRR = multiplicative change in CS ANDA rate after GDUFA."

/* --- Model G-P1: Level shift, excluding transition --- */
di as txt _newline "--- Model G-P1: ANDA CS ~ post_gdufa + trend, excl. 2013-2014 ---"
poisson n_anda_cs post_gdufa c.approval_year                              ///
    if gdufa_transition == 0,                                              ///
    exposure(n_anda_total) vce(robust)
estimates store m_gp1
di as txt "--- Model G-P1: Incidence Rate Ratios ---"
poisson, irr

/* --- Model G-P2: Level shift + slope change, excluding transition --- */
di as txt _newline "--- Model G-P2: ANDA CS ~ post_gdufa + trend + slope change, excl. 2013-2014 ---"
poisson n_anda_cs post_gdufa c.approval_year trend_post_gdufa             ///
    if gdufa_transition == 0,                                              ///
    exposure(n_anda_total) vce(robust)
estimates store m_gp2
di as txt "--- Model G-P2: Incidence Rate Ratios ---"
poisson, irr

/* --- Model G-P3: All years (sensitivity — transition included) --- */
di as txt _newline "--- Model G-P3: ANDA CS ~ post_gdufa + trend, ALL years (sensitivity) ---"
poisson n_anda_cs post_gdufa c.approval_year,                             ///
    exposure(n_anda_total) vce(robust)
estimates store m_gp3
di as txt "--- Model G-P3: Incidence Rate Ratios ---"
poisson, irr

di as txt _newline "--- Poisson model summary ---"
estimates table m_gp1 m_gp2 m_gp3, b(%8.4f) se(%8.4f) stats(N) ///
    title("Poisson Models: ANDA CS Counts with Exposure (GDUFA)")


/*==============================================================================
  PART 3: Stacked DD panel — ANDA CS vs non-CS as treatment/control
==============================================================================*/

di as txt _newline "===== PART 3: Stacked DD (GDUFA) ====="

use "${dtapath}/gdufa_anda_annual.dta", clear
keep if approval_year >= 1984 & approval_year <= 2025
gen n_noncs_anda = n_anda_total - n_anda_cs

/* Build two-row-per-year dataset */
preserve
    keep approval_year n_anda_cs post_gdufa event_time_gdufa gdufa_transition gdufa_era
    rename n_anda_cs n_approvals
    gen is_cs = 1
    tempfile cs_rows
    save `cs_rows'
restore

keep approval_year n_noncs_anda post_gdufa event_time_gdufa gdufa_transition gdufa_era
rename n_noncs_anda n_approvals
gen is_cs = 0
append using `cs_rows'
sort approval_year is_cs

label variable is_cs       "=1 if controlled substance group"
label variable n_approvals "Annual ANDA approvals in group (CS or non-CS)"
label variable post_gdufa  "Post-GDUFA (2015+)"

/* IHS transformation */
gen asinh_n = asinh(n_approvals)
label variable asinh_n "IHS of n_approvals (approx. log, defined at 0)"

save "${dtapath}/gdufa_stacked_dd.dta", replace
di as txt "Stacked DD dataset saved. Obs = `c(N)' (2 rows per year)"

/* --- Model G-D1: Levels, EXCLUDING transition years (primary) --- */
di as txt _newline "--- Model G-D1: n_approvals ~ is_cs + year FE + is_cs#post_gdufa, excl. 2013-2014 ---"
di as txt "(post_gdufa alone is collinear with year FE and drops out.)"
di as txt " Key coef: 1.is_cs#1.post_gdufa = differential CS ANDA growth post-GDUFA."
regress n_approvals i.is_cs i.approval_year i.is_cs##i.post_gdufa         ///
    if gdufa_transition == 0, vce(robust)
estimates store m_gd1

/* --- Model G-D2: IHS, excluding transition --- */
di as txt _newline "--- Model G-D2: IHS(n_approvals) ~ is_cs + year FE + is_cs#post_gdufa, excl. 2013-2014 ---"
regress asinh_n i.is_cs i.approval_year i.is_cs##i.post_gdufa             ///
    if gdufa_transition == 0, vce(robust)
estimates store m_gd2

/* --- Model G-D3: Poisson DD, excluding transition --- */
di as txt _newline "--- Model G-D3: Poisson n_approvals ~ is_cs + year FE + is_cs#post_gdufa, excl. 2013-2014 ---"
poisson n_approvals i.is_cs i.approval_year i.is_cs##i.post_gdufa         ///
    if gdufa_transition == 0, vce(robust)
estimates store m_gd3
di as txt "--- Model G-D3: IRRs ---"
poisson, irr

/* --- Model G-D4: Three-period version (all years, gdufa_era dummies) --- */
di as txt _newline "--- Model G-D4: Three-period DD — i.gdufa_era#i.is_cs (sensitivity, all years) ---"
di as txt "(gdufa_era: 0=pre, 1=transition, 2=post. Key coef: 2.gdufa_era#1.is_cs.)"
regress n_approvals i.is_cs i.approval_year i.gdufa_era##i.is_cs,         ///
    vce(robust)
estimates store m_gd4


/*==============================================================================
  PART 4: Event study DD — differential CS ANDA growth year by year around GDUFA
==============================================================================*/

di as txt _newline "===== PART 4: Event study DD (GDUFA) ====="

use "${dtapath}/gdufa_stacked_dd.dta", clear

/* Binned event-time: same approach as 05_gdufa_analysis.do
   Range [-10,10], shift +11 → [1,21]. Reference: event_time_gdufa = -1 → shifted = 10 */
gen event_gdufa_bin    = event_time_gdufa
replace event_gdufa_bin = -10 if event_time_gdufa < -10
replace event_gdufa_bin =  10 if event_time_gdufa > 10 & !missing(event_time_gdufa)
gen event_gdufa_shifted = event_gdufa_bin + 11

label variable event_gdufa_shifted "GDUFA Event Time (shifted; 10 = ref year 2011)"

/* Gray shading for transition period (2013-2014 = event_time -1 to +2 inclusive)
   Shade covers event_time 1 and 2 (post-GDUFA years in transition window) */
gen shade_lo_dd = .
gen shade_hi_dd = .
sum n_approvals
replace shade_lo_dd = 0                if event_time_gdufa >= 1 & event_time_gdufa <= 2
replace shade_hi_dd = r(max) * 1.1     if event_time_gdufa >= 1 & event_time_gdufa <= 2

di as txt "--- Event study DD: n_approvals ~ is_cs + event FE + is_cs#event_time ---"
di as txt "Key coefs: k.event_gdufa_shifted#1.is_cs = differential ANDA CS approvals at time k."
di as txt "Pre-period flatness tests parallel trends. Transition years (event_time 1-2) shaded."

regress n_approvals i.is_cs i.event_gdufa_shifted                         ///
    i.is_cs#i.event_gdufa_shifted, vce(robust)

/* Extract interaction coefficients for plot */
preserve
    clear
    set obs 21
    gen event_gdufa_shifted = _n
    gen event_time          = event_gdufa_shifted - 11
    gen coef = .
    gen se   = .
    /* Reference: event_gdufa_shifted = 10 (event_time = -1, year 2011), coef = 0 */
    replace coef = 0 if event_gdufa_shifted == 10
    replace se   = 0 if event_gdufa_shifted == 10
    forvalues k = 1/21 {
        if `k' != 10 {
            capture replace coef = _b[`k'.event_gdufa_shifted#1.is_cs]  if event_gdufa_shifted == `k'
            capture replace se   = _se[`k'.event_gdufa_shifted#1.is_cs] if event_gdufa_shifted == `k'
        }
    }
    gen ci_lo = coef - 1.96 * se
    gen ci_hi = coef + 1.96 * se

    /* Gray shading for transition (event_time 1 and 2 = 2013 and 2014) */
    gen shade_lo = .
    gen shade_hi = .
    sum ci_hi
    local ymax = r(max) + 5
    sum ci_lo
    local ymin = r(min) - 5
    replace shade_lo = `ymin' if event_time == 1 | event_time == 2
    replace shade_hi = `ymax' if event_time == 1 | event_time == 2

    twoway                                                                  ///
        (rarea shade_lo shade_hi event_time,                               ///
             fcolor(gs14) lwidth(none))                                    ///
        (rarea ci_lo ci_hi event_time, fcolor(navy%20) lwidth(none))       ///
        (connected coef event_time,                                        ///
             lcolor(navy) mcolor(navy)                                     ///
             msymbol(circle_hollow) msize(small) lwidth(thin)),            ///
        yline(0, lpattern(dash) lcolor(gs8) lwidth(thin))                  ///
        xline(0, lpattern(dash) lcolor(cranberry) lwidth(medthin))         ///
        title("DD Event Study: Differential CS vs Non-CS ANDA Growth (GDUFA)", ///
              size(medlarge))                                              ///
        subtitle("Coefficient = excess CS ANDA approvals relative to non-CS, vs 2011", ///
                 size(small))                                              ///
        ytitle("Differential ANDA Approvals (CS minus non-CS trend)")     ///
        xtitle("Years Since GDUFA Enactment (2012)")                      ///
        xlabel(-10(2)10)                                                   ///
        note("`cs_def'"                                                    ///
             "Coefficients on is_cs#event_time_gdufa interaction."         ///
             "Reference: 2011. Flat pre-period supports parallel trends."  ///
             "Dashed red: GDUFA (2012). Gray band: 2013-2014 transition."  ///
             "Shaded CI band: 95%. OLS; serial correlation not corrected." ///
             "`data_note'", size(vsmall))                                  ///
        legend(off)                                                        ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/gdufa_dd_event_study.png", replace width(2400)
    di as txt "Exported: gdufa_dd_event_study.png"
restore


/*==============================================================================
  PART 5: Sponsor concentration descriptives
==============================================================================*/

di as txt _newline "===== PART 5: Sponsor concentration (GDUFA) ====="

use "${dtapath}/event_study_drug_panel.dta", clear

/* Restrict to ANDA, valid approval years, non-missing sponsor */
keep if is_anda == 1
keep if approval_year >= 1984 & approval_year <= 2025
keep if !missing(sponsorname)
di as txt "ANDA drug-level panel: `c(N)' rows"

/* ---- ALL ANDA sponsors ---- */
di as txt _newline "--- All ANDA sponsors: HHI and top-10 share by year ---"

preserve
    bysort approval_year sponsorname: gen n_sponsor_year = _N
    bysort approval_year: gen n_year_total = _N

    /* One row per sponsor-year */
    bysort approval_year sponsorname: keep if _n == 1

    /* HHI and rank */
    gen share_sq = (n_sponsor_year / n_year_total)^2
    gsort approval_year -n_sponsor_year
    bysort approval_year: gen rank = _n

    gen top10_n = n_sponsor_year if rank <= 10

    collapse                                                                ///
        (sum)  hhi = share_sq                                              ///
               top10_n_sum = top10_n                                       ///
               total_n_sum = n_year_total,                                 ///
        by(approval_year)

    gen top10_share = top10_n_sum / total_n_sum * 100
    label variable hhi         "HHI (ANDA sponsors, all)"
    label variable top10_share "Top-10 sponsor share (%), all ANDA"

    /* GDUFA timing */
    gen post_gdufa       = (approval_year >= 2015)
    gen gdufa_transition = (approval_year >= 2013 & approval_year <= 2014)

    /* Shading bounds for transition band */
    sum top10_share
    gen shade_lo = 0
    gen shade_hi = ceil(r(max)) + 5

    twoway                                                                  ///
        (rarea shade_lo shade_hi approval_year if gdufa_transition == 1,   ///
             fcolor(gs14) lwidth(none))                                    ///
        (line top10_share approval_year, lcolor(navy) lwidth(medium)),     ///
        yline(50, lpattern(dot) lcolor(gs7) lwidth(thin))                  ///
        xline(2012, lpattern(dash) lcolor(cranberry) lwidth(medthin))      ///
        title("Top-10 Sponsor Share of ANDA Approvals by Year",            ///
              size(medlarge))                                              ///
        ytitle("Share of Annual ANDA Approvals (%)")                      ///
        xtitle("Approval Year")                                            ///
        xlabel(1984(5)2025, angle(45))                                    ///
        note("Top-10 sponsors ranked by annual ANDA approval count."      ///
             "Dashed red: GDUFA (2012). Gray band: 2013-2014 transition." ///
             "`data_note'", size(vsmall))                                  ///
        legend(off)                                                        ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/gdufa_sponsor_concentration_top10.png",       ///
        replace width(2400)
    di as txt "Exported: gdufa_sponsor_concentration_top10.png"

    replace shade_hi = r(max) * 1.1  /* rescale for HHI axis */
    sum hhi
    replace shade_hi = r(max) * 1.1

    twoway                                                                  ///
        (rarea shade_lo shade_hi approval_year if gdufa_transition == 1,   ///
             fcolor(gs14) lwidth(none))                                    ///
        (line hhi approval_year, lcolor(navy) lwidth(medium)),             ///
        xline(2012, lpattern(dash) lcolor(cranberry) lwidth(medthin))      ///
        title("Herfindahl-Hirschman Index: ANDA Sponsor Concentration",    ///
              size(medlarge))                                              ///
        ytitle("HHI (sum of squared sponsor market shares)")              ///
        xtitle("Approval Year")                                            ///
        xlabel(1984(5)2025, angle(45))                                    ///
        note("HHI = sum of squared annual market share across sponsors."   ///
             "Dashed red: GDUFA (2012). Gray band: 2013-2014 transition." ///
             "`data_note'", size(vsmall))                                  ///
        legend(off)                                                        ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/gdufa_sponsor_concentration_hhi.png",         ///
        replace width(2400)
    di as txt "Exported: gdufa_sponsor_concentration_hhi.png"

    keep approval_year hhi top10_share post_gdufa gdufa_transition
    gen is_cs_sample = 0
    tempfile conc_all
    save `conc_all'
restore

/* ---- CS-ONLY ANDA sponsors ---- */
di as txt _newline "--- CS-only ANDA sponsors: top-10 share by year ---"

preserve
    keep if is_controlled_substance == 1
    keep if approval_year >= 1984 & approval_year <= 2025
    di as txt "CS ANDA drug-level panel: `c(N)' rows"

    bysort approval_year sponsorname: gen n_sponsor_year = _N
    bysort approval_year: gen n_year_total = _N

    /* One row per sponsor-year */
    bysort approval_year sponsorname: keep if _n == 1

    /* HHI */
    gen share_sq = (n_sponsor_year / n_year_total)^2

    /* Rank within year */
    gsort approval_year -n_sponsor_year
    bysort approval_year: gen rank = _n

    gen top10_n = n_sponsor_year if rank <= 10

    collapse                                                                ///
        (sum)  hhi = share_sq                                              ///
               top10_n_sum = top10_n                                       ///
               total_n_sum = n_year_total,                                 ///
        by(approval_year)

    gen top10_share = top10_n_sum / total_n_sum * 100

    /* GDUFA timing */
    gen post_gdufa       = (approval_year >= 2015)
    gen gdufa_transition = (approval_year >= 2013 & approval_year <= 2014)

    /* Shading bounds for transition band */
    sum top10_share
    gen shade_lo = 0
    gen shade_hi = ceil(r(max)) + 5

    twoway                                                                  ///
        (rarea shade_lo shade_hi approval_year if gdufa_transition == 1,   ///
             fcolor(gs14) lwidth(none))                                    ///
        (line top10_share approval_year, lcolor(cranberry) lwidth(medium)), ///
        yline(50, lpattern(dot) lcolor(gs7) lwidth(thin))                  ///
        xline(2012, lpattern(dash) lcolor(cranberry) lwidth(medthin))      ///
        title("Top-10 Sponsor Share of CS ANDA Approvals by Year",         ///
              size(medlarge))                                              ///
        subtitle("`cs_def'", size(small))                                  ///
        ytitle("Share of Annual CS ANDA Approvals (%)")                   ///
        xtitle("Approval Year")                                            ///
        xlabel(1984(5)2025, angle(45))                                    ///
        note("Top-10 sponsors ranked by annual CS ANDA approval count."   ///
             "Dashed red: GDUFA (2012). Gray band: 2013-2014 transition." ///
             "`data_note'", size(vsmall))                                  ///
        legend(off)                                                        ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/gdufa_cs_sponsor_concentration_top10.png",    ///
        replace width(2400)
    di as txt "Exported: gdufa_cs_sponsor_concentration_top10.png"

    keep approval_year hhi top10_share post_gdufa gdufa_transition
    gen is_cs_sample = 1
    tempfile conc_cs
    save `conc_cs'
restore

/* ---- Export concentration comparison table ---- */
di as txt _newline "--- Exporting sponsor concentration comparison table ---"

use `conc_all', clear
append using `conc_cs'
sort is_cs_sample approval_year

label variable hhi          "HHI"
label variable top10_share  "Top-10 Sponsor Share (%)"
label variable is_cs_sample "=1 if CS ANDA sample"

export delimited "${tables}/gdufa_concentration_comparison.csv", replace
di as txt "Exported: gdufa_concentration_comparison.csv"

/* Pre/post summary */
di as txt _newline "--- Pre/post concentration summary ---"
tabstat hhi top10_share, by(post_gdufa) stats(mean sd) nototal format(%8.3f)


/*==============================================================================
  PART 6: Export key model results to CSV
==============================================================================*/

di as txt _newline "===== PART 6: Export model results table ====="

preserve
    clear
    set obs 7
    gen model = ""
    replace model = "GP1_Poisson_levelshift_excl_trans"    if _n == 1
    replace model = "GP2_Poisson_slopechange_excl_trans"   if _n == 2
    replace model = "GP3_Poisson_allyears_sensitivity"     if _n == 3
    replace model = "GD1_DD_levels_excl_trans"             if _n == 4
    replace model = "GD2_DD_asinh_excl_trans"              if _n == 5
    replace model = "GD3_DD_Poisson_excl_trans"            if _n == 6
    replace model = "GD4_DD_threeperiod_allyears"          if _n == 7
    gen coef_main   = .
    gen se_main     = .
    gen irr_or_exp  = .

    /* Poisson models: post_gdufa coef */
    estimates restore m_gp1
    replace coef_main  = _b[post_gdufa]       if _n == 1
    replace se_main    = _se[post_gdufa]      if _n == 1
    replace irr_or_exp = exp(_b[post_gdufa])  if _n == 1

    estimates restore m_gp2
    replace coef_main  = _b[post_gdufa]       if _n == 2
    replace se_main    = _se[post_gdufa]      if _n == 2
    replace irr_or_exp = exp(_b[post_gdufa])  if _n == 2

    estimates restore m_gp3
    replace coef_main  = _b[post_gdufa]       if _n == 3
    replace se_main    = _se[post_gdufa]      if _n == 3
    replace irr_or_exp = exp(_b[post_gdufa])  if _n == 3

    /* DD models: 1.is_cs#1.post_gdufa interaction */
    estimates restore m_gd1
    replace coef_main  = _b[1.is_cs#1.post_gdufa]  if _n == 4
    replace se_main    = _se[1.is_cs#1.post_gdufa] if _n == 4

    estimates restore m_gd2
    replace coef_main  = _b[1.is_cs#1.post_gdufa]  if _n == 5
    replace se_main    = _se[1.is_cs#1.post_gdufa] if _n == 5

    estimates restore m_gd3
    replace coef_main  = _b[1.is_cs#1.post_gdufa]  if _n == 6
    replace se_main    = _se[1.is_cs#1.post_gdufa] if _n == 6
    replace irr_or_exp = exp(_b[1.is_cs#1.post_gdufa]) if _n == 6

    /* Three-period DD: 2.gdufa_era#1.is_cs = post-GDUFA CS differential */
    estimates restore m_gd4
    replace coef_main  = _b[2.gdufa_era#1.is_cs]  if _n == 7
    replace se_main    = _se[2.gdufa_era#1.is_cs] if _n == 7

    gen z_stat          = coef_main / se_main
    gen p_value_approx  = 2 * (1 - normal(abs(z_stat)))

    label variable model          "Model"
    label variable coef_main      "Key Coefficient"
    label variable se_main        "Standard Error"
    label variable irr_or_exp     "IRR or exp(coef) where applicable"
    label variable z_stat         "z-statistic"
    label variable p_value_approx "Approx. p-value (2-sided)"

    format coef_main se_main irr_or_exp z_stat p_value_approx %8.4f
    list, sep(0) noobs

    export delimited "${tables}/gdufa_alt_specs_results.csv", replace
    di as txt "Exported: gdufa_alt_specs_results.csv"
restore


di as txt _newline "===== 07_alt_specs_gdufa.do complete ====="
log close
