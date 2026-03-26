/*==============================================================================
  ECON 580 Thesis — Descriptive Figures

  Purpose: Generate descriptive time series figures for the thesis.

  Figures to produce:
    1. Annual count of original drug approvals (full sample)
    2. Annual count of controlled substance approvals (conservative definition)
    3. Annual SHARE of approvals that are controlled substances — this is the
       main descriptive figure for the thesis
    4. Share of controlled substances by application type (NDA vs ANDA)
    5. Annual approvals by DEA schedule (II, III, IV, V)
    6. Share of controlled substances with PDUFA era vertical lines / shading

  Input:   ${dtapath}/event_study_drug_panel.dta
  Output:  ${figures}/*.png
==============================================================================*/

do "${code}/globals.do"
log using "${statalogs}/02_descriptive_figures.log", replace
use "${dtapath}/event_study_drug_panel.dta", clear

* --- Figure 1: Annual original drug approvals ---
* [TODO]

* --- Figure 2: Annual controlled substance approvals ---
* [TODO]

* --- Figure 3: Share of approvals that are controlled substances ---
* [TODO]

* --- Figure 4: Share by application type (NDA vs ANDA) ---
* [TODO]

* --- Figure 5: Approvals by DEA schedule ---
* [TODO]

* --- Figure 6: Share with policy markers ---
* [TODO]

di as txt "===== 02_descriptive_figures.do complete ====="
log close
