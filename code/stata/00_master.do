/*==============================================================================
  ECON 580 Thesis — Master Do-File

  Purpose: Run the complete Stata analysis pipeline in order.
           Each script is self-contained but expects globals.do to be run first.

  Instructions:
    1. Open Stata
    2. cd to the project root:
         cd "/Users/alexdelatorre/Desktop/econ580-thesis"
    3. Run this file:
         do "code/stata/00_master.do"

  Pipeline:
    01 — Import CSV, clean, label variables, save .dta
    02 — Descriptive figures (time series, summary tables)
    03 — Event study estimation (annual collapse, event-time dummies)
    04 — Robustness checks and sensitivity analyses
==============================================================================*/

* --- Bootstrap: define root and code before globals.do can be called ---
* (globals.do requires ${code} to exist; we set it here so 00_master.do
*  is fully self-starting without requiring a prior cd or global.)
global root "/Users/alexdelatorre/Desktop/econ580-thesis"
global code "${root}/code/stata"

* --- Load all globals (harmlessly re-sets root and code along with the rest) ---
do "${code}/globals.do"

* --- Pipeline ---
do "${code}/01_load_and_prep.do"
do "${code}/02_descriptive_figures.do"    // descriptive figures and tables
do "${code}/03_event_study.do"            // PDUFA event study (ITS, full sample)
do "${code}/05_gdufa_analysis.do"         // GDUFA event study (ANDA-only)
* do "${code}/04_robustness.do"           // robustness checks (not yet built)

di as txt _newline "===== 00_master.do complete ====="
