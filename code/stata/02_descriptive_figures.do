/*==============================================================================
  ECON 580 Thesis — Descriptive Tables and Figures

  Purpose: Generate descriptive cross-tabulations (Tables 1–10) and time-series
           figures (Figures 1–8) from the drug-level event-study panel.

  Structure:
    PART A: Descriptive tables — displayed in log AND exported as CSV
    PART B: Figures          — exported as PNG to ${figures}/

  Input:   ${dtapath}/event_study_drug_panel.dta
             25,908 obs, one row per original approved drug application
             Variable names are lowercase (import used case(lower))

  Outputs: ${tables}/overview_by_pdufa_era.csv
           ${tables}/cs_by_appltype.csv
           ${tables}/cs_by_pdufa_era.csv
           ${tables}/cs_by_schedule.csv
           ${tables}/cs_schedule_by_era.csv
           ${tables}/appltype_by_era.csv
           ${tables}/cs_appltype_by_era.csv
           ${tables}/annual_summary_panel.csv
           ${tables}/pre_post_pdufa_comparison.csv
           ${tables}/cs_top_sponsors.csv
           ${figures}/fig_annual_approvals.png
           ${figures}/fig_annual_cs_approvals.png
           ${figures}/fig_cs_share.png
           ${figures}/fig_cs_share_by_appltype.png
           ${figures}/fig_cs_by_schedule.png
           ${figures}/fig_cs_share_pdufa_eras.png
           ${figures}/fig_annual_approvals_by_appltype.png
           ${figures}/fig_cs_share_broad_vs_conservative.png

  Notes:
    - preserve/restore wraps every collapse operation
    - Built-in Stata commands only (no estout, outreg2, coefplot, etc.)
    - PNG exports at width(2400)
    - Key variable notes:
        has_controlled_ingredient_in_com  (32-char truncation of _in_combo)
        is_schedule_i/ii/iii/iv/v         (lowercase roman numerals)
        sponsorname                        (lowercase)
        pdufa_era                          (encoded numeric, 1–9, labeled)
        pdufa_era_str                      (string original)
==============================================================================*/

do "${code}/globals.do"
log using "${statalogs}/02_descriptive_figures.log", replace
use "${dtapath}/event_study_drug_panel.dta", clear

/* Reset font for all figures */
graph set window fontface "Times New Roman"

/* Shared note text for all figures */
local data_note "Source: FDA Drugs@FDA, DEA controlled substance schedules. ORIG+AP submissions only."


/* ============================================================
   PART A: DESCRIPTIVE TABLES
   ============================================================ */


/* --- Table 1: Full sample overview by PDUFA era --- */

di as txt _newline "==== TABLE 1: Full Sample Overview by PDUFA Era ===="

preserve

    gen n_total = 1
    gen n_nda   = is_nda
    gen n_anda  = is_anda
    gen n_bla   = is_bla
    gen n_cs    = is_controlled_substance

    collapse (sum) n_total n_nda n_anda n_bla n_cs, by(pdufa_era pdufa_era_str)
    gen cs_share = n_cs / n_total
    sort pdufa_era

    label variable pdufa_era_str "PDUFA Era"
    label variable n_total       "Total Approvals"
    label variable n_nda         "NDA Approvals"
    label variable n_anda        "ANDA Approvals"
    label variable n_bla         "BLA Approvals"
    label variable n_cs          "CS Approvals (Conservative)"
    label variable cs_share      "CS Share"

    format cs_share %6.4f
    list pdufa_era_str n_total n_nda n_anda n_bla n_cs cs_share, sep(0) noobs

    export delimited "${tables}/overview_by_pdufa_era.csv", replace
    di as txt "Exported: overview_by_pdufa_era.csv"

restore


/* --- Table 2: Controlled substances by application type --- */

di as txt _newline "==== TABLE 2: Controlled Substances by Application Type ===="
di as txt "  Panel A: Full sample — appltype_str distribution"
tab appltype_str

di as txt "  Panel B: CS only — appltype_str distribution"
tab appltype_str if is_controlled_substance == 1

preserve

    gen n_full = 1
    collapse (sum) n_full, by(appltype_str)
    sort appltype_str
    tempfile t2_full
    save `t2_full'

restore

preserve

    keep if is_controlled_substance == 1
    gen n_cs = 1
    collapse (sum) n_cs, by(appltype_str)
    sort appltype_str
    merge 1:1 appltype_str using `t2_full', nogenerate
    sort appltype_str
    replace n_cs = 0 if missing(n_cs)
    gen cs_share = n_cs / n_full

    label variable appltype_str "Application Type"
    label variable n_full       "Total (Full Sample)"
    label variable n_cs         "CS Approvals"
    label variable cs_share     "CS Share Within Type"

    format cs_share %6.4f
    list appltype_str n_full n_cs cs_share, sep(0) noobs

    export delimited "${tables}/cs_by_appltype.csv", replace
    di as txt "Exported: cs_by_appltype.csv"

restore


/* --- Table 3: Controlled substances by PDUFA era --- */

di as txt _newline "==== TABLE 3: Controlled Substances by PDUFA Era ===="
tab pdufa_era_str if is_controlled_substance == 1

preserve

    keep if is_controlled_substance == 1
    gen n = 1
    collapse (sum) n, by(pdufa_era pdufa_era_str)
    qui sum n
    gen pct = n / r(sum) * 100
    sort pdufa_era

    label variable pdufa_era_str "PDUFA Era"
    label variable n             "CS Approvals"
    label variable pct           "Pct of All CS Approvals"

    format pct %6.2f
    list pdufa_era_str n pct, sep(0) noobs

    export delimited "${tables}/cs_by_pdufa_era.csv", replace
    di as txt "Exported: cs_by_pdufa_era.csv"

restore


/* --- Table 4: Controlled substances by DEA schedule --- */

di as txt _newline "==== TABLE 4: Controlled Substances by DEA Schedule ===="
tab dea_schedule_highest if is_controlled_substance == 1

preserve

    keep if is_controlled_substance == 1
    keep if !missing(dea_schedule_highest)
    gen n = 1
    collapse (sum) n, by(dea_schedule_highest)
    qui sum n
    gen pct = n / r(sum) * 100
    sort dea_schedule_highest

    label variable dea_schedule_highest "DEA Schedule (Most Restrictive)"
    label variable n                    "CS Approvals"
    label variable pct                  "Percent"

    format pct %6.2f
    list dea_schedule_highest n pct, sep(0) noobs

    export delimited "${tables}/cs_by_schedule.csv", replace
    di as txt "Exported: cs_by_schedule.csv"

restore


/* --- Table 5: DEA schedule by PDUFA era (CS only) --- */

di as txt _newline "==== TABLE 5: DEA Schedule by PDUFA Era (CS Only) ===="
tab dea_schedule_highest pdufa_era_str if is_controlled_substance == 1

preserve

    keep if is_controlled_substance == 1
    keep if !missing(dea_schedule_highest)
    gen n = 1
    collapse (sum) n, by(dea_schedule_highest pdufa_era_str)
    reshape wide n, i(dea_schedule_highest) j(pdufa_era_str) string
    sort dea_schedule_highest

    list, sep(0) noobs abbrev(30)

    export delimited "${tables}/cs_schedule_by_era.csv", replace
    di as txt "Exported: cs_schedule_by_era.csv"

restore


/* --- Table 6: Application type by PDUFA era (full sample) --- */

di as txt _newline "==== TABLE 6: Application Type by PDUFA Era (Full Sample) ===="
tab appltype_str pdufa_era_str, row

preserve

    gen n = 1
    collapse (sum) n, by(appltype_str pdufa_era_str)
    reshape wide n, i(appltype_str) j(pdufa_era_str) string
    sort appltype_str

    list, sep(0) noobs abbrev(30)

    export delimited "${tables}/appltype_by_era.csv", replace
    di as txt "Exported: appltype_by_era.csv"

restore


/* --- Table 7: Application type by PDUFA era (CS only) --- */

di as txt _newline "==== TABLE 7: Application Type by PDUFA Era (CS Only) ===="
tab appltype_str pdufa_era_str if is_controlled_substance == 1, row

preserve

    keep if is_controlled_substance == 1
    gen n = 1
    collapse (sum) n, by(appltype_str pdufa_era_str)
    reshape wide n, i(appltype_str) j(pdufa_era_str) string
    sort appltype_str

    list, sep(0) noobs abbrev(30)

    export delimited "${tables}/cs_appltype_by_era.csv", replace
    di as txt "Exported: cs_appltype_by_era.csv"

restore


/* --- Table 8: Annual summary panel --- */

di as txt _newline "==== TABLE 8: Annual Summary Panel (selected columns shown) ===="

preserve

    gen n_total     = 1
    gen cs_and_nda  = (is_controlled_substance == 1 & is_nda  == 1)
    gen cs_and_anda = (is_controlled_substance == 1 & is_anda == 1)

    collapse (sum) n_total is_nda is_anda is_bla                    ///
                   is_controlled_substance cs_and_nda cs_and_anda   ///
                   is_schedule_ii is_schedule_iii                   ///
                   is_schedule_iv is_schedule_v is_schedule_i,      ///
             by(approval_year)

    gen cs_share      = is_controlled_substance / n_total
    gen cs_share_nda  = cs_and_nda  / is_nda   if is_nda  > 0
    gen cs_share_anda = cs_and_anda / is_anda  if is_anda > 0

    sort approval_year

    label variable approval_year         "Year"
    label variable n_total               "Total Approvals"
    label variable is_controlled_substance "CS Count (Conservative)"
    label variable cs_share              "CS Share"
    label variable is_nda                "NDA Count"
    label variable is_anda               "ANDA Count"
    label variable is_bla                "BLA Count"
    label variable cs_and_nda            "CS Among NDA"
    label variable cs_share_nda          "CS Share (NDA)"
    label variable cs_and_anda           "CS Among ANDA"
    label variable cs_share_anda         "CS Share (ANDA)"
    label variable is_schedule_i         "Schedule I"
    label variable is_schedule_ii        "Schedule II"
    label variable is_schedule_iii       "Schedule III"
    label variable is_schedule_iv        "Schedule IV"
    label variable is_schedule_v         "Schedule V"

    format cs_share cs_share_nda cs_share_anda %6.4f
    list approval_year n_total is_controlled_substance cs_share     ///
         is_nda is_anda cs_and_nda cs_and_anda, sep(0) noobs abbrev(20)

    export delimited "${tables}/annual_summary_panel.csv", replace
    di as txt "Exported: annual_summary_panel.csv"

restore


/* --- Table 9: Pre-PDUFA vs Post-PDUFA comparison --- */

di as txt _newline "==== TABLE 9: Pre-PDUFA vs Post-PDUFA Comparison ===="
di as txt "  CS by post_pdufa:"
tab is_controlled_substance post_pdufa, col

/* Part A: group-level sums and shares */
preserve

    gen n_total     = 1
    gen cs_and_nda  = (is_controlled_substance == 1 & is_nda  == 1)
    gen cs_and_anda = (is_controlled_substance == 1 & is_anda == 1)
    gen cs_sched_ii  = (is_controlled_substance == 1 & is_schedule_ii  == 1)
    gen cs_sched_iii = (is_controlled_substance == 1 & is_schedule_iii == 1)
    gen cs_sched_iv  = (is_controlled_substance == 1 & is_schedule_iv  == 1)
    gen cs_sched_v   = (is_controlled_substance == 1 & is_schedule_v   == 1)

    collapse (sum) n_total is_nda is_anda is_controlled_substance    ///
                   cs_and_nda cs_and_anda                            ///
                   cs_sched_ii cs_sched_iii cs_sched_iv cs_sched_v,  ///
             by(post_pdufa)

    gen cs_share      = is_controlled_substance / n_total
    gen cs_share_nda  = cs_and_nda  / is_nda   if is_nda  > 0
    gen cs_share_anda = cs_and_anda / is_anda  if is_anda > 0

    label variable post_pdufa            "Post-PDUFA (0=pre, 1=post)"
    label variable n_total               "Total Approvals"
    label variable is_controlled_substance "CS (Conservative)"
    label variable cs_share              "CS Share"
    label variable is_nda                "NDA Count"
    label variable is_anda               "ANDA Count"
    label variable cs_and_nda            "CS Among NDA"
    label variable cs_share_nda          "CS Share (NDA)"
    label variable cs_and_anda           "CS Among ANDA"
    label variable cs_share_anda         "CS Share (ANDA)"
    label variable cs_sched_ii           "CS: Schedule II"
    label variable cs_sched_iii          "CS: Schedule III"
    label variable cs_sched_iv           "CS: Schedule IV"
    label variable cs_sched_v            "CS: Schedule V"

    format cs_share cs_share_nda cs_share_anda %6.4f
    list, sep(0) noobs

    export delimited "${tables}/pre_post_pdufa_comparison.csv", replace
    di as txt "Exported: pre_post_pdufa_comparison.csv"

restore

/* Part B: mean annual approvals by post_pdufa */
di as txt "  Mean annual approvals by post_pdufa era:"
preserve

    gen n_total = 1
    gen n_cs    = is_controlled_substance
    collapse (sum) n_total n_cs, by(approval_year post_pdufa)
    collapse (mean) n_total n_cs, by(post_pdufa)
    gen cs_share = n_cs / n_total
    format cs_share %6.4f
    list, sep(0) noobs

restore


/* --- Table 10: Top 20 sponsors of controlled substances --- */

di as txt _newline "==== TABLE 10: Top 20 Sponsors of Controlled Substances ===="

preserve

    keep if is_controlled_substance == 1
    gen n = 1
    collapse (sum) n, by(sponsorname)
    gsort -n
    keep if _n <= 20
    gen rank = _n

    label variable rank        "Rank"
    label variable sponsorname "Sponsor Name"
    label variable n           "CS Approvals"

    list rank sponsorname n, sep(0) noobs

    export delimited "${tables}/cs_top_sponsors.csv", replace
    di as txt "Exported: cs_top_sponsors.csv"

restore


/* ============================================================
   PART B: FIGURES
   ============================================================ */

graph set window fontface "Times New Roman"


/* ---- Figure 1: Annual original drug approvals ---- */

di as txt _newline "==== FIGURE 1: Annual Original Drug Approvals ===="

preserve

    gen n = 1
    collapse (sum) n, by(approval_year)
    sort approval_year

    twoway (line n approval_year, lcolor(navy) lwidth(medthin)),    ///
        xline(${hatchwaxman_year}, lpattern(dash) lcolor(gs9))      ///
        xline(${pdufa_year},       lpattern(dash) lcolor(cranberry)) ///
        xline(2012,                lpattern(dash) lcolor(olive) lwidth(medthin)) ///
        title("Annual Original Drug Approvals, 1939-2025",           ///
              size(medlarge))                                        ///
        ytitle("Number of Approvals")                               ///
        xtitle("Year")                                              ///
        xlabel(1940(10)2020, angle(45))                             ///
        ylabel(, format(%9.0f))                                     ///
        note("Dashed lines: 1984 (Hatch-Waxman), 1992 (PDUFA), 2012 (GDUFA)." ///
             "`data_note'", size(vsmall))                           ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/fig_annual_approvals.png", replace width(2400)
    di as txt "Exported: fig_annual_approvals.png"

restore


/* ---- Figure 2: Annual controlled substance approvals ---- */

di as txt _newline "==== FIGURE 2: Annual Controlled Substance Approvals ===="

preserve

    keep if is_controlled_substance == 1
    gen n = 1
    collapse (sum) n, by(approval_year)
    sort approval_year

    twoway (line n approval_year, lcolor(navy) lwidth(medthin)),    ///
        xline(${hatchwaxman_year}, lpattern(dash) lcolor(gs9))      ///
        xline(${pdufa_year},       lpattern(dash) lcolor(cranberry)) ///
        xline(2012,                lpattern(dash) lcolor(olive) lwidth(medthin)) ///
        title("Annual Controlled Substance Approvals, 1939-2025",        ///
              size(medlarge))                                        ///
        ytitle("Number of Approvals")                               ///
        xtitle("Year")                                              ///
        xlabel(1940(10)2020, angle(45))                             ///
        ylabel(, format(%9.0f))                                     ///
        note("Dashed lines: 1984 (Hatch-Waxman), 1992 (PDUFA), 2012 (GDUFA)." ///
             "`data_note'", size(vsmall))                           ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/fig_annual_cs_approvals.png", replace width(2400)
    di as txt "Exported: fig_annual_cs_approvals.png"

restore


/* ---- Figure 3: CS share — primary figure ---- */

di as txt _newline "==== FIGURE 3: CS Share (Primary Figure) ===="

preserve

    gen n_total = 1
    gen n_cs    = is_controlled_substance
    collapse (sum) n_total n_cs, by(approval_year)
    gen cs_share = n_cs / n_total
    sort approval_year

    twoway (line cs_share approval_year, lcolor(navy) lwidth(medium)), ///
        xline(${hatchwaxman_year}, lpattern(dash) lcolor(gs9))         ///
        xline(${pdufa_year},       lpattern(dash) lcolor(cranberry))   ///
        xline(2012,                lpattern(dash) lcolor(olive) lwidth(medthin)) ///
        title("Share of Approvals That Are Controlled Substances",     ///
              size(medlarge))                                           ///
        subtitle("Conservative definition: confident DEA scheduled matches only", ///
                 size(small))                                           ///
        ytitle("Proportion")                                           ///
        xtitle("Year")                                                 ///
        xlabel(1940(10)2020, angle(45))                                ///
        ylabel(0(0.05)0.35, format(%4.2f))                             ///
        note("Dashed lines: 1984 (Hatch-Waxman), 1992 (PDUFA), 2012 (GDUFA)." ///
             "`data_note'", size(vsmall))                              ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/fig_cs_share.png", replace width(2400)
    di as txt "Exported: fig_cs_share.png"

restore


/* ---- Figure 4: CS share by application type (NDA vs ANDA) ---- */

di as txt _newline "==== FIGURE 4: CS Share by Application Type ===="

preserve

    gen cs_nda  = (is_controlled_substance == 1 & is_nda  == 1)
    gen cs_anda = (is_controlled_substance == 1 & is_anda == 1)

    collapse (sum) is_nda is_anda cs_nda cs_anda, by(approval_year)

    /* Set shares to missing when denominator < 5 (avoids noisy small-cell ratios) */
    gen cs_share_nda  = cs_nda  / is_nda   if is_nda  >= 5
    gen cs_share_anda = cs_anda / is_anda  if is_anda >= 5

    sort approval_year

    twoway                                                               ///
        (line cs_share_nda  approval_year,                              ///
             lcolor(navy)     lwidth(medium))                           ///
        (line cs_share_anda approval_year,                              ///
             lcolor(cranberry) lwidth(medium) lpattern(dash)),          ///
        xline(${hatchwaxman_year}, lpattern(shortdash) lcolor(gs11))   ///
        xline(${pdufa_year},       lpattern(shortdash) lcolor(gs7))    ///
        xline(2012,                lpattern(dash) lcolor(olive) lwidth(medthin)) ///
        title("CS Share by Application Type", size(medlarge))           ///
        ytitle("CS Share")                                              ///
        xtitle("Year")                                                  ///
        xlabel(1940(10)2020, angle(45))                                 ///
        ylabel(, format(%4.2f))                                         ///
        legend(order(1 "NDA" 2 "ANDA") position(1) ring(0))            ///
        note("CS = Controlled Substance (conservative: confident DEA scheduled matches only)." ///
             "Years with < 5 NDA or ANDA approvals excluded for that type."                 ///
             "Dashed lines: 1984 (Hatch-Waxman), 1992 (PDUFA), 2012 (GDUFA)."              ///
             "`data_note'", size(vsmall))                                                   ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/fig_cs_share_by_appltype.png", replace width(2400)
    di as txt "Exported: fig_cs_share_by_appltype.png"

restore


/* ---- Figure 5: CS approvals by DEA schedule ---- */

di as txt _newline "==== FIGURE 5: CS Approvals by DEA Schedule ===="

preserve

    collapse (sum) is_schedule_i is_schedule_ii is_schedule_iii ///
                   is_schedule_iv is_schedule_v,                ///
             by(approval_year)
    sort approval_year

    twoway                                                                  ///
        (line is_schedule_ii  approval_year, lcolor(navy)     lwidth(medium)) ///
        (line is_schedule_iii approval_year, lcolor(cranberry) lwidth(medium) lpattern(dash)) ///
        (line is_schedule_iv  approval_year, lcolor(forest_green) lwidth(medium) lpattern(longdash)) ///
        (line is_schedule_v   approval_year, lcolor(dkorange) lwidth(medium) lpattern(dot)) ///
        (line is_schedule_i   approval_year, lcolor(purple)   lwidth(medthin) lpattern(shortdash)), ///
        xline(${hatchwaxman_year}, lpattern(dash) lcolor(gs11)) ///
        xline(${pdufa_year},       lpattern(dash) lcolor(gs7))  ///
        xline(2012,                lpattern(dash) lcolor(olive) lwidth(medthin)) ///
        title("Controlled Substance Approvals by DEA Schedule", size(medlarge)) ///
        ytitle("Number of Approvals")                           ///
        xtitle("Year")                                          ///
        xlabel(1940(10)2020, angle(45))                         ///
        ylabel(, format(%9.0f))                                 ///
        legend(order(1 "Schedule II" 2 "Schedule III"           ///
                     3 "Schedule IV" 4 "Schedule V"             ///
                     5 "Schedule I")                            ///
               position(1) ring(0) cols(1) size(small))         ///
        note("Dashed lines: 1984 (Hatch-Waxman), 1992 (PDUFA), 2012 (GDUFA)." ///
             "`data_note'", size(vsmall))                       ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/fig_cs_by_schedule.png", replace width(2400)
    di as txt "Exported: fig_cs_by_schedule.png"

restore


/* ---- Figure 6: Average CS share by PDUFA era (bar chart) ---- */

di as txt _newline "==== FIGURE 6: Average CS Share by PDUFA Era ===="

preserve

    /* Step 1: collapse to annual CS shares */
    gen n_total = 1
    gen n_cs    = is_controlled_substance
    collapse (sum) n_total n_cs, by(approval_year pdufa_era pdufa_era_str)
    gen cs_share = n_cs / n_total

    /* Step 2: average the annual shares within each era */
    collapse (mean) cs_share, by(pdufa_era pdufa_era_str)
    sort pdufa_era

    di as txt "  Era-level mean CS shares:"
    format cs_share %6.4f
    list pdufa_era_str cs_share, sep(0) noobs

    /* Bar chart: pdufa_era is numeric 1–9 with value labels for x-axis */
    graph bar (asis) cs_share,                                       ///
        over(pdufa_era,                                              ///
             label(angle(45) labsize(vsmall)))                       ///
        bar(1, color(navy))                                          ///
        title("Mean Annual CS Share by PDUFA Era", size(medlarge))  ///
        ytitle("Mean Annual CS Share")                              ///
        ylabel(, format(%4.2f))                                     ///
        note("CS = Controlled Substance (conservative: confident DEA scheduled matches only)." ///
             "`data_note'", size(vsmall))                                                   ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/fig_cs_share_pdufa_eras.png", replace width(2400)
    di as txt "Exported: fig_cs_share_pdufa_eras.png"

restore


/* ---- Figure 7: Annual approvals by application type ---- */

di as txt _newline "==== FIGURE 7: Annual Approvals by Application Type ===="

preserve

    collapse (sum) is_nda is_anda is_bla, by(approval_year)
    sort approval_year

    twoway                                                                  ///
        (line is_nda  approval_year, lcolor(navy)         lwidth(medium))  ///
        (line is_anda approval_year, lcolor(cranberry)    lwidth(medium)   ///
             lpattern(dash))                                                ///
        (line is_bla  approval_year, lcolor(forest_green) lwidth(medium)   ///
             lpattern(longdash)),                                           ///
        xline(${hatchwaxman_year}, lpattern(dash) lcolor(gs11))            ///
        xline(${pdufa_year},       lpattern(dash) lcolor(gs7))             ///
        xline(2012,                lpattern(dash) lcolor(olive) lwidth(medthin)) ///
        title("Annual Drug Approvals by Application Type",                  ///
              size(medlarge))                                               ///
        ytitle("Number of Approvals")                                      ///
        xtitle("Year")                                                     ///
        xlabel(1940(10)2020, angle(45))                                    ///
        ylabel(, format(%9.0f))                                            ///
        legend(order(1 "NDA" 2 "ANDA (generic)" 3 "BLA (biologic)")       ///
               position(1) ring(0))                                        ///
        note("Dashed lines: 1984 (Hatch-Waxman), 1992 (PDUFA), 2012 (GDUFA)." ///
             "`data_note'", size(vsmall))                                  ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/fig_annual_approvals_by_appltype.png", replace width(2400)
    di as txt "Exported: fig_annual_approvals_by_appltype.png"

restore


/* ---- Figure 8: CS share — broad vs conservative ---- */

di as txt _newline "==== FIGURE 8: CS Share — Broad vs Conservative ===="

preserve

    gen n_total = 1
    collapse (sum) n_total is_controlled_substance is_controlled_substance_broad, ///
             by(approval_year)
    gen cs_share_conserv = is_controlled_substance       / n_total
    gen cs_share_broad   = is_controlled_substance_broad / n_total
    sort approval_year

    twoway                                                                  ///
        (line cs_share_conserv approval_year,                              ///
             lcolor(navy)     lwidth(medium))                              ///
        (line cs_share_broad   approval_year,                              ///
             lcolor(cranberry) lwidth(medium) lpattern(dash)),             ///
        xline(${hatchwaxman_year}, lpattern(shortdash) lcolor(gs11))      ///
        xline(${pdufa_year},       lpattern(shortdash) lcolor(gs7))       ///
        xline(2012,                lpattern(dash) lcolor(olive) lwidth(medthin)) ///
        title("CS Share: Conservative vs Broad Definition",                ///
              size(medlarge))                                              ///
        ytitle("Proportion")                                               ///
        xtitle("Year")                                                     ///
        xlabel(1940(10)2020, angle(45))                                    ///
        ylabel(, format(%4.2f))                                            ///
        legend(order(1 "Conservative (confident scheduled only)"           ///
                     2 "Broad (any DEA signal: confident + List I + candidate)") ///
               position(1) ring(0) cols(1) size(small))                   ///
        note("CS = Controlled Substance."                                   ///
             "Dashed lines: 1984 (Hatch-Waxman), 1992 (PDUFA), 2012 (GDUFA)." ///
             "`data_note'", size(vsmall))                                  ///
        graphregion(color(white)) bgcolor(white)

    graph export "${figures}/fig_cs_share_broad_vs_conservative.png", replace width(2400)
    di as txt "Exported: fig_cs_share_broad_vs_conservative.png"

restore


di as txt _newline "===== 02_descriptive_figures.do complete ====="
log close
