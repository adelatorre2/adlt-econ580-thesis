/*==============================================================================
  ECON 580 Thesis — Event Study Estimation

  Purpose: Estimate event study models for the effect of PDUFA (1992) on the
           share/probability of controlled substance approval.

  Data structure:
    Drug-level panel, common event date (1992), no cross-sectional variation
    in treatment timing. This is effectively an interrupted time series /
    pre-post design at the national level.

  Approach:
    - Collapse to annual level: year-level shares of controlled substances
    - Event time dummies centered on 1992
    - Consider both simple pre/post and flexible event-time specification
    - Reference period: normalize pre-event coefficients to average zero
    - Plot event study coefficients with confidence intervals

  Key considerations:
    - With a common event date and no untreated units, identification requires
      assuming that pre-event trends would have continued absent treatment
    - Pre-event coefficients serve as a diagnostic for trending confounders
    - Endpoint ("end-cap") treatment must be chosen explicitly
    - Hatch-Waxman (1984) is a potential confounder / co-treatment —
      consider modeling both breaks or restricting the sample window

  Input:   ${dtapath}/event_study_drug_panel.dta
  Output:  ${figures}/event_study_*.png
           ${tables}/event_study_*.tex
==============================================================================*/

do "${code}/globals.do"
use "${dtapath}/event_study_drug_panel.dta", clear

* --- Collapse to annual panel ---
* [TODO]: collapse (mean) is_controlled_substance ... = (sum) n_approvals, by(approval_year event_time post_pdufa post_hatchwaxman)

* --- Define event time and reference period ---
* [TODO]: create event-time dummies; choose omitted (reference) period

* --- Main event study specification ---
* [TODO]: regress share_controlled i.event_time_dummy ..., options

* --- Plot coefficients ---
* [TODO]: coefplot or manual twoway scatter + rcap

di as txt "===== 03_event_study.do complete ====="
