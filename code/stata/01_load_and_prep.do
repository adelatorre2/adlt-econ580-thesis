/*==============================================================================
  ECON 580 Thesis — Data Import and Preparation

  Purpose: Import the drug-approval-level event study CSV, enforce variable
           types, apply variable and value labels, validate key invariants,
           and save a labeled .dta file for downstream analysis.

  Input:   ${data}/event_study_drug_panel.csv
             25,908 rows x 31 columns
             One row per unique original approved drug application (ApplNo)
             Source: code/notebooks/06_event_study_dataset_build.ipynb

  Output:  ${dtapath}/event_study_drug_panel.dta

  Notes:
    - ApplNo is column 1 in the CSV and MUST be imported as string (leading
      zeros are meaningful identifiers; e.g., "000004" not 4).
    - stringcols() forces string import for all text columns including
      free-text fields that may contain commas or quoted content.
    - approval_date is imported as string and left as-is (use approval_year
      for all temporal analyses).
    - DEA schedule fields (dea_schedule, dea_schedule_highest) are string
      because they contain Roman numerals (I, II, III, IV, V).
    - pdufa_era, ApplType, and dea_confidence_tier are encoded into labeled
      numeric variables for use in regressions; originals kept as _str copies.
==============================================================================*/

do "${code}/globals.do"

/*------------------------------------------------------------------------------
  1. Import CSV with explicit string-column protection
------------------------------------------------------------------------------*/
* Column positions (1-indexed):
*   1  ApplNo                  ← MUST be string (leading zeros)
*   2  ApplType                ← string categorical
*   4  approval_date           ← string date (use approval_year instead)
*   5  SponsorName             ← string
*   6  DrugName_list           ← string (semicolon-delimited names)
*   7  ActiveIngredient_list   ← string (semicolon-delimited)
*   8  ReviewPriority_raw      ← string
*   9  ReviewPriority_clean    ← string
*  10  SubmissionClassCode     ← string
*  17  dea_schedule            ← string (pipe-delimited Roman numerals)
*  18  dea_schedule_highest    ← string (Roman numeral: I/II/III/IV/V)
*  26  dea_confidence_tier     ← string categorical
*  27  dea_substance_name_list ← string
*  30  pdufa_era               ← string categorical

import delimited using "${data}/event_study_drug_panel.csv", ///
    stringcols(1 2 4 5 6 7 8 9 10 17 18 26 27 30) ///
    varnames(1) ///
    case(lower) ///
    clear

di as txt "Import complete. Obs = `c(N)', Vars = `c(k)'"

/*------------------------------------------------------------------------------
  2. Variable labels (all 31 columns)
------------------------------------------------------------------------------*/
label variable applno                        "FDA application number (string, leading zeros preserved)"
label variable appltype                      "Application type (NDA/ANDA/BLA/etc.)"
label variable approval_year                 "Year of FDA approval"
label variable approval_date                 "Date of FDA approval (string; use approval_year for analysis)"
label variable sponsorname                   "FDA applicant/sponsor name"
label variable drugname_list                 "Drug/product name(s), semicolon-delimited"
label variable activeingredient_list         "Active ingredient(s), semicolon-delimited; DEA linkage key"
label variable reviewpriority_raw            "Review priority (raw from Submissions table)"
label variable reviewpriority_clean          "Review priority (cleaned: S=standard, P=priority, UNKNOWN)"
label variable submissionclasscode          "Submission class code (e.g., Type 1 New Molecular Entity)"
label variable is_nda                        "=1 if New Drug Application (NDA)"
label variable is_anda                       "=1 if Abbreviated NDA (generic)"
label variable is_bla                        "=1 if Biologics License Application (BLA)"
label variable is_controlled_substance       "=1 if confident DEA scheduled match (conservative, primary outcome)"
label variable is_controlled_substance_broad "=1 if any DEA signal: confident, List I, or candidate (broad)"
label variable is_controlled_or_list1        "=1 if confident scheduled or DEA List I chemical (intermediate)"
label variable dea_schedule                  "DEA schedule(s) for matched ingredients, pipe-delimited"
label variable dea_schedule_highest          "Most restrictive DEA schedule among matched ingredients"
label variable is_schedule_i                 "=1 if any matched ingredient is Schedule I"
label variable is_schedule_ii                "=1 if any matched ingredient is Schedule II"
label variable is_schedule_iii               "=1 if any matched ingredient is Schedule III"
label variable is_schedule_iv                "=1 if any matched ingredient is Schedule IV"
label variable is_schedule_v                 "=1 if any matched ingredient is Schedule V"
label variable is_multi_ingredient           "=1 if application has 2+ active ingredients (combination product)"
label variable has_controlled_ingredient_in_combo "=1 if controlled substance AND multi-ingredient combo product"
label variable dea_confidence_tier           "DEA linkage confidence tier (string, for audit)"
label variable dea_substance_name_list       "Matched DEA substance name(s)"
label variable post_pdufa                    "=1 if approval_year >= 1993 (post-PDUFA)"
label variable post_hatchwaxman              "=1 if approval_year >= 1984 (post-Hatch-Waxman)"
label variable pdufa_era                     "PDUFA era label (string categorical)"
label variable event_time                    "Years since PDUFA enactment (approval_year - 1992)"

/*------------------------------------------------------------------------------
  3. Value labels for dummy variables
------------------------------------------------------------------------------*/
label define lbl_yesno    0 "No" 1 "Yes"
label define lbl_postpre  0 "Pre-PDUFA" 1 "Post-PDUFA"
label define lbl_prehw    0 "Pre-Hatch-Waxman" 1 "Post-Hatch-Waxman"
label define lbl_cs       0 "Not controlled" 1 "Controlled substance"
label define lbl_nda      0 "Not NDA" 1 "NDA"
label define lbl_anda     0 "Not ANDA" 1 "ANDA"
label define lbl_bla      0 "Not BLA" 1 "BLA"

label values post_pdufa                    lbl_postpre
label values post_hatchwaxman              lbl_prehw
label values is_controlled_substance       lbl_cs
label values is_controlled_substance_broad lbl_yesno
label values is_controlled_or_list1        lbl_yesno
label values is_nda                        lbl_nda
label values is_anda                       lbl_anda
label values is_bla                        lbl_bla
label values is_schedule_i                 lbl_yesno
label values is_schedule_ii                lbl_yesno
label values is_schedule_iii               lbl_yesno
label values is_schedule_iv                lbl_yesno
label values is_schedule_v                 lbl_yesno
label values is_multi_ingredient           lbl_yesno
label values has_controlled_ingredient_in_combo lbl_yesno

/*------------------------------------------------------------------------------
  4. Encode string categoricals into labeled numeric variables
     Keep originals as _str copies for merges and display
------------------------------------------------------------------------------*/

* ApplType
rename appltype appltype_str
encode appltype_str, gen(appltype)
label variable appltype     "Application type (encoded)"
label variable appltype_str "Application type (string)"

* pdufa_era — encode in chronological order for clean tabulation
rename pdufa_era pdufa_era_str
* Define explicit order so encode assigns values chronologically
gen pdufa_era_order = .
replace pdufa_era_order = 1 if pdufa_era_str == "pre_hatchwaxman"
replace pdufa_era_order = 2 if pdufa_era_str == "post_hatchwaxman_pre_pdufa"
replace pdufa_era_order = 3 if pdufa_era_str == "pdufa_I"
replace pdufa_era_order = 4 if pdufa_era_str == "pdufa_II"
replace pdufa_era_order = 5 if pdufa_era_str == "pdufa_III"
replace pdufa_era_order = 6 if pdufa_era_str == "pdufa_IV"
replace pdufa_era_order = 7 if pdufa_era_str == "pdufa_V"
replace pdufa_era_order = 8 if pdufa_era_str == "pdufa_VI"
replace pdufa_era_order = 9 if pdufa_era_str == "pdufa_VII"
label define lbl_pdufa_era ///
    1 "pre_hatchwaxman"          ///
    2 "post_hatchwaxman_pre_pdufa" ///
    3 "pdufa_I"                  ///
    4 "pdufa_II"                 ///
    5 "pdufa_III"                ///
    6 "pdufa_IV"                 ///
    7 "pdufa_V"                  ///
    8 "pdufa_VI"                 ///
    9 "pdufa_VII"
rename pdufa_era_order pdufa_era
label values pdufa_era lbl_pdufa_era
label variable pdufa_era     "PDUFA era (encoded, chronological)"
label variable pdufa_era_str "PDUFA era (string)"

* dea_confidence_tier
rename dea_confidence_tier dea_confidence_tier_str
encode dea_confidence_tier_str, gen(dea_confidence_tier)
label variable dea_confidence_tier     "DEA confidence tier (encoded)"
label variable dea_confidence_tier_str "DEA confidence tier (string)"

/*------------------------------------------------------------------------------
  5. Validation checks
------------------------------------------------------------------------------*/
di as txt _newline "===== VALIDATION ====="

describe

di as txt _newline "--- approval_year codebook ---"
codebook approval_year

di as txt _newline "--- is_controlled_substance (expect ~2,067 = 1) ---"
tab is_controlled_substance

di as txt _newline "--- ApplType distribution ---"
tab appltype_str

di as txt _newline "--- pdufa_era distribution ---"
tab pdufa_era_str

di as txt _newline "--- Year range assertion ---"
assert approval_year >= 1939 & approval_year <= 2025
di as txt "PASS: all approval_year in [1939, 2025]"

di as txt _newline "--- No missing approval_year ---"
assert !missing(approval_year)
di as txt "PASS: no missing approval_year"

di as txt _newline "--- ApplNo uniqueness ---"
isid applno
di as txt "PASS: applno is unique identifier"

/*------------------------------------------------------------------------------
  6. Label dataset and save .dta
------------------------------------------------------------------------------*/
label data "ECON 580: Drug-level panel for PDUFA event study (ORIG+AP, 1939-2025)"

save "${dtapath}/event_study_drug_panel.dta", replace
di as txt _newline "Saved: ${dtapath}/event_study_drug_panel.dta"

/*------------------------------------------------------------------------------
  7. Diagnostic summary
------------------------------------------------------------------------------*/
di as txt _newline "===== DIAGNOSTIC SUMMARY ====="
di as txt "Total observations : `c(N)'"
qui sum approval_year
di as txt "Year range         : `r(min)' – `r(max)'"

qui count if is_controlled_substance == 1
local n_cs = r(N)
local share_cs = string(`n_cs' / `c(N)' * 100, "%5.1f")
di as txt "Controlled (confident) : `n_cs' (`share_cs'%)"

di as txt _newline "--- Count by application type ---"
tab appltype_str

di as txt _newline "--- Count by PDUFA era ---"
tab pdufa_era_str

di as txt _newline "===== 01_load_and_prep.do complete ====="
