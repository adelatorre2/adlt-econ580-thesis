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


/*==============================================================================
  PART 7: NDA sponsor concentration (parallel to Part 5 for ANDAs)

  Part 7 adds NDA sponsor concentration to mirror Part 5's ANDA analysis.
  Substantively this is PDUFA-relevant (NDAs are subject to PDUFA fees),
  but it lives here because Part 5 already contains the HHI/top-10
  computation machinery. Analogous figures in 07 keep ANDA and NDA
  concentration work co-located for reader comparison.
==============================================================================*/

di as txt _newline "===== PART 7: NDA sponsor concentration (PDUFA window) ====="

use "${dtapath}/event_study_drug_panel.dta", clear

/* Restrict to NDA, valid approval years, non-missing sponsor */
keep if is_nda == 1
keep if approval_year >= 1970 & approval_year <= 2025
keep if !missing(sponsorname)
di as txt "NDA drug-level panel: `c(N)' rows"

/* ---- ALL NDA sponsors ---- */
di as txt _newline "--- All NDA sponsors: HHI and top-10 share by year ---"

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
    label variable hhi         "HHI (NDA sponsors, all)"
    label variable top10_share "Top-10 sponsor share (%), all NDA"

    /* PDUFA timing */
    gen post_pdufa       = (approval_year >= 1993)
    gen hatchwaxman_era  = (approval_year >= 1984)

    /* Shading bounds — no transition band for PDUFA analysis */
    sum top10_share
    gen shade_lo = 0
    gen shade_hi = ceil(r(max)) + 5

    twoway                                                                  ///
        (line top10_share approval_year, lcolor(navy) lwidth(medium)),      ///
        yline(50, lpattern(dot) lcolor(gs7) lwidth(thin))                   ///
        xline(1984, lpattern(dot)  lcolor(gs7)      lwidth(medthin))        ///
        xline(1992, lpattern(dash) lcolor(cranberry) lwidth(medthin))       ///
        title("Top-10 Sponsor Share of NDA Approvals by Year",              ///
              size(medlarge))                                               ///
        ytitle("Share of Annual NDA Approvals (%)")                        ///
        xtitle("Approval Year")                                             ///
        xlabel(1970(5)2025, angle(45))                                     ///
        note("Top-10 sponsors ranked by annual NDA approval count."        ///
             "Dotted: Hatch-Waxman (1984). Dashed red: PDUFA (1992)."      ///
             "Source: FDA Drugs@FDA. NDA submissions only.", size(vsmall)) ///
        legend(off)                                                         ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/pdufa_nda_sponsor_concentration_top10.png",    ///
        replace width(2400)
    di as txt "Exported: pdufa_nda_sponsor_concentration_top10.png"

    sum hhi
    replace shade_hi = r(max) * 1.1

    twoway                                                                  ///
        (line hhi approval_year, lcolor(navy) lwidth(medium)),              ///
        xline(1984, lpattern(dot)  lcolor(gs7)      lwidth(medthin))        ///
        xline(1992, lpattern(dash) lcolor(cranberry) lwidth(medthin))       ///
        title("Herfindahl-Hirschman Index: NDA Sponsor Concentration",      ///
              size(medlarge))                                               ///
        ytitle("HHI (sum of squared sponsor market shares)")               ///
        xtitle("Approval Year")                                             ///
        xlabel(1970(5)2025, angle(45))                                     ///
        note("HHI = sum of squared annual market share across sponsors."    ///
             "Dotted: Hatch-Waxman (1984). Dashed red: PDUFA (1992)."      ///
             "Source: FDA Drugs@FDA. NDA submissions only.", size(vsmall)) ///
        legend(off)                                                         ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/pdufa_nda_sponsor_concentration_hhi.png",      ///
        replace width(2400)
    di as txt "Exported: pdufa_nda_sponsor_concentration_hhi.png"

    keep approval_year hhi top10_share post_pdufa
    gen is_cs_sample = 0
    tempfile nda_conc_all
    save `nda_conc_all'
restore

/* ---- CS-only NDA sponsors ---- */
di as txt _newline "--- CS-only NDA sponsors: top-10 share by year ---"

preserve
    keep if is_controlled_substance == 1
    keep if approval_year >= 1970 & approval_year <= 2025
    di as txt "CS NDA drug-level panel: `c(N)' rows"

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

    gen post_pdufa = (approval_year >= 1993)

    /* Shading bounds */
    sum top10_share
    gen shade_lo = 0
    gen shade_hi = ceil(r(max)) + 5

    twoway                                                                  ///
        (rarea shade_lo shade_hi approval_year if post_pdufa == 0,         ///
             fcolor(none) lwidth(none))                                    ///
        (line top10_share approval_year, lcolor(cranberry) lwidth(medium)), ///
        yline(50, lpattern(dot) lcolor(gs7) lwidth(thin))                   ///
        xline(1984, lpattern(dot)  lcolor(gs7)      lwidth(medthin))        ///
        xline(1992, lpattern(dash) lcolor(cranberry) lwidth(medthin))       ///
        title("Top-10 Sponsor Share of CS NDA Approvals by Year",           ///
              size(medlarge))                                               ///
        subtitle("CS = Controlled Substance (conservative: confident DEA scheduled matches only)", ///
                 size(small))                                               ///
        ytitle("Share of Annual CS NDA Approvals (%)")                     ///
        xtitle("Approval Year")                                             ///
        xlabel(1970(5)2025, angle(45))                                     ///
        note("Top-10 sponsors ranked by annual CS NDA approval count."     ///
             "Dotted: Hatch-Waxman (1984). Dashed red: PDUFA (1992)."      ///
             "Source: FDA Drugs@FDA. NDA submissions only.", size(vsmall)) ///
        legend(off)                                                         ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/pdufa_cs_nda_sponsor_concentration_top10.png", ///
        replace width(2400)
    di as txt "Exported: pdufa_cs_nda_sponsor_concentration_top10.png"

    keep approval_year hhi top10_share post_pdufa
    gen is_cs_sample = 1
    tempfile nda_conc_cs
    save `nda_conc_cs'
restore

/* ---- Export NDA concentration comparison table ---- */
di as txt _newline "--- Exporting NDA concentration comparison table ---"

use `nda_conc_all', clear
append using `nda_conc_cs'
sort is_cs_sample approval_year

label variable hhi          "HHI"
label variable top10_share  "Top-10 Sponsor Share (%)"
label variable post_pdufa   "Post-PDUFA (1993+)"
label variable is_cs_sample "=1 if CS NDA sample"

export delimited "${tables}/pdufa_nda_concentration_comparison.csv", replace
di as txt "Exported: pdufa_nda_concentration_comparison.csv"

/* Pre/post summary */
di as txt _newline "--- Pre/post-PDUFA NDA concentration summary ---"
tabstat hhi top10_share if is_cs_sample == 0, by(post_pdufa) stats(mean sd) nototal format(%8.3f)


/*==============================================================================
  PART 8: Rate-vs-count diagnostics (GDUFA ANDA-only)
==============================================================================*/

di as txt _newline "===== PART 8: Rate-vs-count diagnostics (GDUFA ANDA-only) ====="
di as txt "Motivation: G-P1 Poisson IRR ~1.22-1.44 vs G-D3 stacked DD IRR ~0.67."
di as txt "CS ANDA rate and absolute count can tell different stories simultaneously."

/*----------------------------------------------------------------------
  8a: Rate vs count two-panel visual
----------------------------------------------------------------------*/

use "${dtapath}/gdufa_anda_annual.dta", clear
keep if approval_year >= 1984 & approval_year <= 2025

capture drop anda_cs_share
capture drop n_noncs_anda
capture drop shade_lo
capture drop shade_hi
gen anda_cs_share = n_anda_cs / n_anda_total if n_anda_total > 0
gen n_noncs_anda  = n_anda_total - n_anda_cs

/* Pre-GDUFA mean for rate panel (excl. transition) */
qui sum anda_cs_share if approval_year >= 1984 & approval_year <= 2012
local anda_rate_premean     = r(mean)
local anda_rate_premean_fmt = string(`anda_rate_premean', "%5.3f")
gen pre_anda_rate = `anda_rate_premean' if approval_year >= 1984 & approval_year <= 2012

/* Shading for transition */
qui sum anda_cs_share
gen shade_lo = 0
gen shade_hi = r(max) + 0.02

/* Panel A: CS ANDA share (rate) */
twoway                                                                    ///
    (rarea shade_lo shade_hi approval_year if gdufa_transition == 1,      ///
         fcolor(gs14) lwidth(none))                                       ///
    (line anda_cs_share approval_year, lcolor(navy) lwidth(medium))       ///
    (line pre_anda_rate  approval_year,                                   ///
         lcolor(navy) lwidth(medium) lpattern(dash)),                     ///
    xline(2012, lpattern(dash) lcolor(cranberry) lwidth(medthin))         ///
    title("Panel A: CS Share of ANDA Approvals (Rate)", size(medium))    ///
    ytitle("CS ANDA / Total ANDA") xtitle("")                             ///
    xlabel(1984(4)2024, angle(45)) ylabel(, format(%4.2f))                ///
    legend(order(2 "Annual CS ANDA rate"                                   ///
                 3 "Pre-GDUFA mean (`anda_rate_premean_fmt')")             ///
           position(11) ring(0) cols(1) size(small))                      ///
    graphregion(color(white)) bgcolor(white)                              ///
    name(panel_anda_rate, replace)

/* Panel B: CS vs non-CS ANDA absolute counts */
qui sum n_anda_cs n_noncs_anda
gen count_shade_hi = max(n_anda_cs, n_noncs_anda) * 1.05 if gdufa_transition == 1
gen count_shade_lo = 0 if gdufa_transition == 1

twoway                                                                    ///
    (rarea count_shade_lo count_shade_hi approval_year                    ///
         if gdufa_transition == 1, fcolor(gs14) lwidth(none))            ///
    (line n_anda_cs   approval_year, lcolor(navy)     lwidth(medium))    ///
    (line n_noncs_anda approval_year,                                     ///
         lcolor(cranberry) lwidth(medium) lpattern(dash)),                ///
    xline(2012, lpattern(dash) lcolor(cranberry) lwidth(medthin))         ///
    title("Panel B: CS and Non-CS ANDA Annual Counts", size(medium))     ///
    ytitle("Annual ANDA Approvals") xtitle("Year")                        ///
    xlabel(1984(4)2024, angle(45)) ylabel(, format(%9.0f))                ///
    legend(order(2 "CS ANDA" 3 "Non-CS ANDA")                             ///
           position(1) ring(0) cols(1) size(small))                       ///
    note("`cs_def'"                                                       ///
         "Dashed red: GDUFA (2012). Gray band: 2013-2014 backlog transition." ///
         "Source: FDA Drugs@FDA. ANDA submissions only.", size(vsmall))   ///
    graphregion(color(white)) bgcolor(white)                              ///
    name(panel_anda_count, replace)

graph combine panel_anda_rate panel_anda_count, cols(1)                  ///
    title("ANDA-only CS Rate vs Absolute Count Around GDUFA (2012)",      ///
          size(medlarge))                                                 ///
    note("Both panels can simultaneously be true: rate rises if CS ANDA grows" ///
         "proportionally faster; count diverges if totals grow differently.", ///
         size(vsmall))                                                    ///
    graphregion(color(white))

graph export "${figures}/gdufa_anda_rate_vs_count.png", replace width(2400)
di as txt "Exported: gdufa_anda_rate_vs_count.png"
graph drop panel_anda_rate panel_anda_count


/*----------------------------------------------------------------------
  8b: Trend-control sensitivity for GDUFA stacked DD Poisson (G-D3)
----------------------------------------------------------------------*/

di as txt _newline "--- Part 8b: Trend-control sensitivity (GDUFA ANDA-only Poisson DD) ---"
di as txt "Replace year FE with linear trend / group-specific trends."

use "${dtapath}/gdufa_stacked_dd.dta", clear

/* G-D3-trend: linear year trend, excluding transition */
di as txt _newline "--- G-D3-trend: Poisson, linear year trend, excl. 2013-2014 ---"
poisson n_approvals i.is_cs c.approval_year i.is_cs##i.post_gdufa         ///
    if gdufa_transition == 0, vce(robust)
estimates store m_gd3_trend
poisson, irr

/* G-D3-grouptrend: group-specific linear year trends, excluding transition */
di as txt _newline "--- G-D3-grouptrend: Poisson, group-specific year trends, excl. 2013-2014 ---"
poisson n_approvals i.is_cs c.approval_year c.approval_year#i.is_cs       ///
    i.is_cs##i.post_gdufa if gdufa_transition == 0, vce(robust)
estimates store m_gd3_grouptrend
poisson, irr

/* Save IRRs */
estimates restore m_gd3
local coef_gd3_fe       = _b[1.is_cs#1.post_gdufa]
local se_gd3_fe         = _se[1.is_cs#1.post_gdufa]
local irr_gd3_fe        = exp(`coef_gd3_fe')

estimates restore m_gd3_trend
local coef_gd3_trend    = _b[1.is_cs#1.post_gdufa]
local se_gd3_trend      = _se[1.is_cs#1.post_gdufa]
local irr_gd3_trend     = exp(`coef_gd3_trend')

estimates restore m_gd3_grouptrend
local coef_gd3_grptrend = _b[1.is_cs#1.post_gdufa]
local se_gd3_grptrend   = _se[1.is_cs#1.post_gdufa]
local irr_gd3_grptrend  = exp(`coef_gd3_grptrend')

di as txt _newline "=== IRR summary: G-D3 trend-control sensitivity ==="
di as txt "  G-D3 (year FE, full flex): IRR = " %6.3f `irr_gd3_fe'
di as txt "  G-D3-trend (linear)      : IRR = " %6.3f `irr_gd3_trend'
di as txt "  G-D3-grouptrend (by grp) : IRR = " %6.3f `irr_gd3_grptrend'

estimates table m_gd3 m_gd3_trend m_gd3_grouptrend,                      ///
    b(%8.4f) se(%8.4f) stats(N)                                           ///
    keep(1.is_cs#1.post_gdufa c.approval_year)                            ///
    title("ANDA-only Poisson DD: trend-control sensitivity (G-D3)")


/*----------------------------------------------------------------------
  8c: Timing diagnostic — event-study Poisson DD IRRs (GDUFA)
----------------------------------------------------------------------*/

di as txt _newline "--- Part 8c: Timing diagnostic — Poisson event-study DD (GDUFA ANDA-only) ---"
di as txt "A genuine GDUFA effect should show IRR shift at event_time 3+ (post-goals year 2015)."
di as txt "event_gdufa_shifted range [1,21]; ref = 10 (year 2011, event_time = -1)"

use "${dtapath}/gdufa_stacked_dd.dta", clear
capture drop event_gdufa_bin
capture drop event_gdufa_shifted
gen event_gdufa_bin    = event_time_gdufa
replace event_gdufa_bin = -10 if event_time_gdufa < -10
replace event_gdufa_bin =  10 if event_time_gdufa > 10 & !missing(event_time_gdufa)
gen event_gdufa_shifted = event_gdufa_bin + 11

poisson n_approvals i.is_cs i.event_gdufa_shifted                         ///
    i.is_cs#i.event_gdufa_shifted, vce(robust)

di as txt _newline "Poisson event-study DD IRRs: exp(1.is_cs#k.event_gdufa_shifted)"
di as txt "Reference: event_gdufa_shifted = 10 (event_time = -1, year 2011)"
foreach k in 11 12 14 16 19 21 {
    local et = `k' - 11
    local yr = 2012 + `et'
    capture {
        local b   = _b[`k'.event_gdufa_shifted#1.is_cs]
        local irr = exp(`b')
        di as txt "  event_time = `et' (year `yr'): IRR = " %6.3f `irr'
    }
}


/*----------------------------------------------------------------------
  8 (export): GDUFA diagnostics table
----------------------------------------------------------------------*/

di as txt _newline "--- Exporting gdufa_diagnostics.csv ---"
/* Note: exported separately from gdufa_alt_specs_results.csv because
   trend-sensitivity models are run after that file is already closed. */

preserve
    clear
    set obs 3
    gen model      = ""
    gen irr_main   = .
    gen coef_main  = .
    gen se_main    = .
    gen spec_note  = ""

    replace model     = "GD3_yearFE"              if _n == 1
    replace model     = "GD3_trend_linear"         if _n == 2
    replace model     = "GD3_grouptrend"           if _n == 3

    replace coef_main = `coef_gd3_fe'             if _n == 1
    replace coef_main = `coef_gd3_trend'          if _n == 2
    replace coef_main = `coef_gd3_grptrend'       if _n == 3

    replace se_main   = `se_gd3_fe'               if _n == 1
    replace se_main   = `se_gd3_trend'            if _n == 2
    replace se_main   = `se_gd3_grptrend'         if _n == 3

    replace irr_main  = `irr_gd3_fe'              if _n == 1
    replace irr_main  = `irr_gd3_trend'           if _n == 2
    replace irr_main  = `irr_gd3_grptrend'        if _n == 3

    replace spec_note = "Year FE (full flexibility)"        if _n == 1
    replace spec_note = "Linear year trend (restrictive)"   if _n == 2
    replace spec_note = "Group-specific year trends (mid)"  if _n == 3

    gen z_stat         = coef_main / se_main
    gen p_value_approx = 2 * (1 - normal(abs(z_stat)))

    label variable model          "Model"
    label variable irr_main       "IRR on 1.is_cs#1.post_gdufa"
    label variable coef_main      "ln(IRR) = coefficient"
    label variable se_main        "Standard Error"
    label variable z_stat         "z-statistic"
    label variable p_value_approx "Approx. p-value"
    label variable spec_note      "Specification"

    format irr_main coef_main se_main z_stat p_value_approx %8.4f
    list, sep(0) noobs
    export delimited "${tables}/gdufa_diagnostics.csv", replace
    di as txt "Exported: gdufa_diagnostics.csv"
restore


di as txt _newline "===== 07_alt_specs_gdufa.do complete ====="
log close
