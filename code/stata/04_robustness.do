/*==============================================================================
  ECON 580 Thesis — Robustness and Sensitivity Checks

  Purpose: Test sensitivity of main results to alternative specifications,
           sample restrictions, and outcome definitions.

  Planned checks:
    1. Broader controlled substance definition (is_controlled_substance_broad)
    2. Intermediate definition (is_controlled_or_list1)
    3. NDA-only sample (exclude generics / ANDAs)
    4. ANDA-only sample (generics channel separately)
    5. Separate effects by DEA schedule (II, III, IV, V)
    6. Alternative reference / estimation windows
    7. Controlling for linear pre-trends
    8. Excluding the Hatch-Waxman transition period (1984-1992)

  Input:   ${dtapath}/event_study_drug_panel.dta
  Output:  ${figures}/robustness_*.png
           ${tables}/robustness_*.tex
==============================================================================*/

do "${code}/globals.do"
use "${dtapath}/event_study_drug_panel.dta", clear

* --- 1. Broader CS definition ---
* [TODO]

* --- 2. Intermediate CS definition ---
* [TODO]

* --- 3. NDA-only sample ---
* [TODO]

* --- 4. ANDA-only sample ---
* [TODO]

* --- 5. By DEA schedule ---
* [TODO]

* --- 6. Alternative reference periods ---
* [TODO]

* --- 7. Pre-trend controls ---
* [TODO]

* --- 8. Exclude Hatch-Waxman transition ---
* [TODO]

di as txt "===== 04_robustness.do complete ====="
