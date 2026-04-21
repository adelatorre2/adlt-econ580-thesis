# Manuscript Outline — ECON 580 Thesis

**Working title:** *Did User Fees Change What the FDA Approves? Evidence from PDUFA, GDUFA, and Controlled Substances*

**Author:** Alejandro De La Torre
**Course:** ECON 580 — Spring 2026, UW–Madison
**Outline created:** 2026-04-20
**Status:** Pass 1 scaffold in progress (Claude Code)

---

## Framing principle — read this first

This paper reports a **negative result**: PDUFA (1992) and GDUFA (2012) did not change the controlled-substance composition of FDA approvals. Negative-result papers require *more* careful framing than positive-result papers, not less. A positive result reads as "the author found something"; a negative result reads either as "the author failed to find anything" (bad) or "the author tested a theory-relevant hypothesis carefully and discovered the predicted effect is absent" (good). The job of the introduction and framing is to put the reader in the second mode.

The manuscript has to land three claims, in order:

1. The hypothesis was theoretically motivated and plausible ex ante — not a strawman.
2. Multiple well-specified tests all reject it.
3. The alternative driver of the apparent rate shift (the late-2000s branded opioid wave) is substantively interesting and identifiable in the data.

Every section should be evaluable against whether it serves one of those three claims. If a paragraph serves none, cut it.

---

## Target length and format

- **Total:** 26–30 pages double-spaced (12pt, 1-inch margins), excluding tables/figures/references.
- **Syllabus minimum:** 25 pages.
- **Abstract:** ≤150 words.
- **Required elements (from syllabus):** title, abstract, introduction, literature review, model description (if any), data description and empirical methods, discussion of empirical results and robustness, conclusion.

---

## Section-by-section outline

### 0. Title page + Abstract (≤150 words)

Tight structure: question, data, method, finding, contribution. Draft last.

Working version:

> Do FDA user-fee regimes change the therapeutic composition of approved drugs? Economic theory predicts that user fees raise firms' effective cost per application, incentivizing them to prioritize higher-revenue products, including DEA-scheduled controlled substances. Using the FDA's Drugs@FDA approval records merged with DEA controlled-substance schedules for 25,908 drug approvals between 1939 and 2025, I test whether the Prescription Drug User Fee Act of 1992 (PDUFA) and the Generic Drug User Fee Amendments of 2012 (GDUFA) shifted the share of approvals toward controlled substances. Across share-based interrupted time series, Poisson rate models with exposure, and stacked difference-in-differences specifications, the estimated effect of both policies is indistinguishable from zero once group-specific secular trends are modeled. Apparent post-PDUFA compositional shifts in rate-based specifications are traceable to a separable late-2000s wave of extended-release and abuse-deterrent branded opioid approvals that postdates PDUFA by 15–20 years.

---

### 1. Introduction (3–4 pages)

Follow Dudenhefer's four-move structure.

**Move 1 — territory.** Open concretely. Suggested lede: "In fiscal year 2025, the Food and Drug Administration collected roughly $X billion in user fees from pharmaceutical manufacturers, a figure that now exceeds its congressional appropriation for drug review activities." Two–three sentences motivating why user fees matter: they fund half of FDA review activity; they shape firms' per-application costs; they are reauthorized every five years with fierce industry negotiation.

**Move 2 — literature.** One paragraph. The user-fee literature (Olson 2008; Berndt et al. 2005; Philipson et al. 2008; Carpenter, Zucker, Avorn 2008) has focused on speed of approval and post-market safety tradeoffs. A separate literature on controlled substances (Alpert, Powell, Pacula 2018 on abuse-deterrent reformulation; Powell et al. 2020, 2021 on opioid supply shocks) treats the controlled-substance segment as its own market. These literatures have not been joined: no one has asked whether user-fee regimes disproportionately affect approvals in DEA-scheduled categories.

**Move 3 — niche.** One sentence. "Despite substantial attention to both user-fee effects on approval speed and controlled-substance market dynamics, the question of whether user-fee regimes change the *therapeutic composition* of the approval pipeline — specifically, whether they shift approvals toward the more profitable controlled-substance segment — has not been directly tested."

**Move 4 — occupy.** Announce: I build an annual panel of FDA approvals 1939–2025 linked to DEA schedules; I evaluate PDUFA (1992) and GDUFA (2012) using share-based interrupted time series, Poisson rate models with exposure, and stacked difference-in-differences with group-specific trends on the policy-relevant subsamples (NDAs for PDUFA, ANDAs for GDUFA). I find no effect of either policy on controlled-substance composition. Preview three results: the null is robust across specifications; apparent effects in simpler specs are secular-trend artifacts; the 2009–2013 CS-NDA spike that drives year-FE estimates is traceable to branded extended-release and abuse-deterrent opioid approvals, not regulatory incentives.

Close with the standard roadmap paragraph: "The remainder of this paper is organized as follows. Section 2 reviews…" etc.

---

### 2. Background and Related Literature (4–5 pages)

Three subsections.

**2.1 Institutional background** (~1 page)

PDUFA history: 1992 enactment, motivation (review backlogs in 1980s), fee structure (user fees per NDA/BLA submission, with waivers for small firms and orphan drugs). GDUFA history: 2012 enactment, pre-GDUFA ANDA backlog problem, performance goals beginning FY2015.

Key institutional fact for identification: ANDA applications were not subject to PDUFA fees — this justifies the NDA-only subsample for the PDUFA test.

Cite: Berndt et al. 2018; FDA user-fee documentation.

**2.2 Theory of user-fee incentives** (~1 page)

This is the load-bearing section for negative-result papers. Has to make the pro-hypothesis case strongly.

Sketch the economic mechanism: per-application user fees raise firms' fixed cost per approval, which (holding expected revenue constant) should make lower-margin applications submarginal and higher-margin applications relatively more attractive. Controlled substances have higher expected per-patient revenue for several reasons:
- abuse-deterrent formulations command premium pricing
- scheduled drugs face less generic competition due to DEA production quotas
- patent-protected branded CS products have durable market power

Hypothesis: user-fee regimes should shift the approval-pipeline composition toward CS products.

Cite: Philipson et al. 2008 (user-fee welfare); Kaitin 2011 (industry response); Hofer et al. 2025 (biopharmaceutical investment).

**2.3 Prior empirical work and its gaps** (~1.5 pages)

Organized by theme per Dudenhefer guidelines:

- *Speed of approval literature:* Olson 1997, 2008; Berndt 2005; Philipson 2008. All find PDUFA sped approvals. None examine composition.
- *Post-market safety tradeoffs:* Carpenter, Zucker, Avorn 2008; Darrow, Avorn, Kesselheim 2020. Faster review → more label revisions, black-box warnings.
- *Controlled substances as a separate market:* Alpert, Powell, Pacula 2018 (OxyContin reformulation heroin substitution); Powell et al. 2020, 2021; McGinty et al. 2016 (CS relationship to policy). None examine user-fee effects on CS approvals.
- *Generic market dynamics:* Berndt 2018 on GDUFA. The central claim is that GDUFA raised barriers to entry and would concentrate generic manufacturing among large firms. I test this prediction with HHI and find no supporting evidence.

Close by naming the gap: "No existing work directly tests whether FDA user-fee regimes change the composition of approvals with respect to controlled-substance status. This paper fills that gap."

---

### 3. Data (2–3 pages)

**3.1 Sources**

FDA Drugs@FDA data files (monthly download, March 2026 snapshot); DEA controlled-substance scheduling data (public lookup tables). Merge: by active ingredient, with conservative matching (confident DEA schedule assignment only). 25,908 drug approvals 1939–2025 retained after restricting to ORIG+AP submissions.

**3.2 Variable construction**

Key variables:
- `approval_year`
- `is_nda`, `is_anda`, `is_bla` (application-type indicators)
- `is_controlled_substance` (binary)
- `dea_schedule_highest` (II–V; I is effectively never approved for commerce)
- `sponsorname`

Define the "conservative" CS indicator (confident DEA schedule matches only) and the "broad" indicator (includes List I precursors and candidates). Primary results use conservative; robustness uses broad.

**3.3 Panel structure**

Two levels of aggregation:
- Drug-level panel (`event_study_drug_panel.dta`, 25,908 rows) for sponsor concentration and drug-level diagnostics.
- Annual aggregated panels: `event_study_annual.dta` (NDA/BLA), `gdufa_anda_annual.dta` (ANDA) for regression analyses.

**3.4 Summary statistics**

One table + two paragraphs.

> **Table 1** (use `appltype_by_era.csv`, `cs_by_pdufa_era.csv`, `cs_by_schedule.csv`): Counts and CS shares by era and application type.

Key descriptive facts to highlight in text:
- ANDAs are 73% of all approvals (19,022/25,908)
- CS approvals are 8.0% overall (2,067/25,908)
- 86.6% of CS approvals are ANDAs
- Schedule II and IV dominate (approximately equal shares, with III a distant third)

**3.5 Limitations of the data**

Explicit paragraph:

- DEA scheduling data is contemporary, not historical — a drug classified Schedule II today may have been III before the 2014 hydrocodone reschedule; this is a known limitation affecting schedule-specific but not CS/non-CS comparisons.
- Drugs@FDA is approval data, not submission data — we observe neither rejected applications nor withdrawn applications.
- The panel is national and treats the entire FDA review apparatus as a single entity; we cannot examine cross-division variation.

---

### 4. Empirical Strategy (3–4 pages)

Cite Miller 2023 event-study framework where relevant; cite Kothari & Warner 2006; Roth 2022 on pre-trend diagnostics.

**4.1 Research design at a high level**

Two-sentence framing. Without a cross-sectional control group, this is a series of interrupted-time-series and quasi-difference-in-differences analyses around two national policy dates. The paper treats identification as descriptive and emphasizes specification-consistency as the standard of evidence, not a single preferred estimator.

**4.2 Share-based interrupted time series**

Specification: annual CS share regressed on event-time dummies relative to 1992 (PDUFA) or 2012 (GDUFA), with reference period t−1. Display as event-study figures. Weakness explicitly acknowledged: no cross-sectional variation means common shocks are not identified.

**4.3 Poisson rate models with exposure**

Specification: `poisson n_cs_event post_policy controls, exposure(n_total_event)`.

IRR gives multiplicative change in CS rate after the policy. This is the policy-relevant rate measure — it answers "conditional on an approval, did the CS probability change?"

Subsample-specific: NDA-only for PDUFA (fee-relevant), ANDA-only for GDUFA.

**4.4 Stacked difference-in-differences**

Build a two-row-per-year panel: one row for CS counts, one for non-CS counts, stacked. Estimate `regress n_approvals i.is_cs i.year i.is_cs##i.post_policy`.

The interaction `is_cs#post_policy` is the differential-growth coefficient. Three functional forms: linear levels, IHS, Poisson. Also estimate with group-specific linear trends (key diagnostic).

**4.5 Key threats to identification**

Three explicit paragraphs:

- *Hatch-Waxman confound.* The Hatch-Waxman Act (1984) triggered explosive ANDA growth that compositionally dilutes the CS share. Any pooled analysis conflates Hatch-Waxman's denominator effect with PDUFA. Addressed by NDA-only subsampling.
- *Concurrent shocks.* No plausible cross-sectional control. Addressed by (a) multiple specifications, (b) timing diagnostics (does effect appear near policy date?), (c) narrow windows around policy.
- *Group-specific trends.* CS and non-CS approval series may have different secular growth rates. Year FE alone forces them to share the calendar-year shock; group-specific trends allow honest differential drift. This is the diagnostic that collapses apparent effects.

**4.6 What the design can and cannot show**

One short paragraph. This is a descriptive interrupted time series, not causal identification. Conclusions about PDUFA's causal effect require either cross-sectional control or a theoretical model allowing secular-trend counterfactual construction. The null result is therefore "no evidence of a composition shift coincident with the policy date," not "PDUFA had no causal effect."

---

### 5. Results (6–8 pages — empirical core)

Organized by test, with convergence as the theme.

**5.1 Share-based event study: null at both 1992 and 2012**

- Figure 1: `event_study_cs_share.png` (PDUFA event study on conservative CS share)
- Figure 2: `event_study_cs_share_nda.png` (NDA-only)
- Figure 3: GDUFA event study on ANDA CS share (from `05_gdufa_analysis`)
- Table 2: pre/post mean comparisons from `pre_post_pdufa_comparison.csv` and `gdufa_pre_post_comparison.csv`

**5.2 Poisson rate models on policy-relevant subsamples**

- Table 3: PDUFA NDA-only diagnostics. Rows: m_p3 (pooled), m_p3_nda, with year-FE vs. linear-trend vs. group-specific trends. Source: `pdufa_nda_diagnostics.csv`.
- Table 4: GDUFA ANDA-only diagnostics. Source: `gdufa_diagnostics.csv`.

Narrative: rate-based Poisson shows IRR = 1.46 (p = 0.06) with year FE, drops to IRR = 1.19 (p = 0.62) with group-specific trends for PDUFA. GDUFA shows IRR = 0.67 (p < 0.001) with year FE, flips to IRR = 1.38 (p = 0.18) with group-specific trends. Both null once trend is honestly modeled.

**5.3 Stacked difference-in-differences**

- Table 5: NDA-only DD (D1 levels, D2 IHS, D3 Poisson). Source: `subsample_alt_specs_results.csv`.
- Table 6: ANDA-only DD (G-D1, G-D2, G-D3). Source: `gdufa_alt_specs_results.csv`.
- Figure 4: `pdufa_nda_only_dd_event_study.png` — event-study DD on NDA-only.
- Figure 5: `gdufa_dd_event_study.png` — event-study DD on ANDA-only.

**5.4 Rate-vs-count reconciliation**

- Figure 6: `pdufa_nda_rate_vs_count.png` — two-panel figure showing why rate and count specifications can disagree.
- Figure 7: `gdufa_anda_rate_vs_count.png` — same for GDUFA.

Narrative: the apparent disagreement between Poisson-rate and DD-count specifications resolves into a single story about denominator growth and secular trends.

**5.5 Timing of rate movements**

Figure 8 or inline text: extract IRRs at event times 0, 5, 10, 15, 18, 20, 25 from the Poisson event-study DD. Highlight the 2010–2011 and 2017 spikes as non-policy-aligned.

Narrative: if PDUFA had caused a 1992 composition shift, we would expect IRR ≠ 1 near event time 0. Instead, IRRs near 1.0 until ~2007, with 6× and 9× spikes at 2010–2011 (event times 18–19). This does not match the PDUFA hypothesis; it matches an industry product cycle.

**5.6 The 2009–2013 branded opioid wave**

Table 7: top 15 drugs in the 2009–2013 CS-NDA cohort, from `cs_nda_2009_2013_drugs.csv`. Columns: year, brand name, active ingredient, DEA schedule.

Narrative: of 43 CS NDAs in 2009–2013, 25 (58%) are Schedule II; the branded opioid product wave (Opana ER, Exalgo, OxyContin reformulation, Zohydro ER, Nucynta, transmucosal fentanyl products) accounts for the majority; these are products of industry response to evolving pain-management markets and abuse-deterrent reformulation pressure, not regulatory-incentive responses to PDUFA fee schedules.

**5.7 Sponsor concentration**

- Figure 9: `gdufa_anda_sponsor_concentration_hhi.png`.
- Figure 10: `pdufa_nda_sponsor_concentration_hhi.png`.
- Table 8: top 10 CS-NDA sponsors 1970–2025 from `cs_nda_top_sponsors_1970_2025.csv` (replaces the noisy time-series figure).

Narrative: Berndt (2018) predicted GDUFA would raise barriers and concentrate the ANDA market. HHI fell monotonically from ~0.05 in the early 1990s to ~0.013 by 2024; no break at 2012. NDA HHI also declined. The CS-NDA market is radically diffuse (127 sponsors over 55 years; top 10 account for <30% of all CS NDAs).

---

### 6. Discussion (3–4 pages)

Four subsections.

**6.1 Interpretation of the null** (~1 page)

The economic-theory prediction was reasonable, and it's not the case that the data are too noisy to detect effects — precision is adequate to rule out effects of practical magnitude (note CI widths from Tables 3/4). The null result therefore is informative: user fees do not appear to distort the approval-pipeline composition toward the more profitable controlled-substance segment.

Alternative explanations:
- The per-application fee may be small relative to firms' total R&D cost per application.
- CS products face constraints beyond approval cost (DEA production quotas, state PDMP compliance, abuse-deterrent formulation costs) that dominate user-fee incentives.
- Firms' application portfolio choices may be set years before approval, breaking the timing assumption of the test.

**6.2 The branded opioid wave as a separable phenomenon** (~1 page)

The 2009–2013 CS-NDA spike — driven by Opana ER, OxyContin reformulation, Zohydro ER, and transmucosal fentanyl products — postdates PDUFA by 17–21 years. The timing rules out direct PDUFA causation.

Substantive driver: the 2007 Purdue felony plea and the 2010 OxyContin reformulation triggered a wave of abuse-deterrent and extended-release reformulations across the branded opioid segment, as firms repositioned under mounting regulatory and legal scrutiny. Tie to Alpert, Powell, Pacula 2018 (OxyContin reformulation substitution effects).

Note that rate-based econometric specifications that don't model this wave will misattribute it to PDUFA.

**6.3 Implications for the Berndt (2018) barriers-to-entry hypothesis** (~1 page)

Berndt et al. predicted GDUFA would concentrate the ANDA market by raising fixed costs for small generic firms. The HHI data reject this: the ANDA market has grown more diffuse, not more concentrated, through the GDUFA era.

Possible explanations:
- Small-firm fee waivers
- International generic entry
- The sheer scale of post-GDUFA approval volume (~800/year vs ~500/year pre-GDUFA)

The prediction may yet be correct on a longer horizon; current data do not support it.

**6.4 Limitations** (~0.5 page)

Restate what's in §4.6: no cross-sectional control; timing is national; DEA scheduling is contemporary; submission data unavailable. Do not oversell what the paper can do.

---

### 7. Conclusion (1 page)

One paragraph per thesis of the paper:

- What was tested, on what data, using what methods.
- What was found, including the null.
- What the substantive takeaway is: user-fee regimes do not appear to shift approval composition; the observed rate movements in the late 2000s reflect a separable industry product cycle.
- Two sentences on future work: the 2014 hydrocodone reschedule as a natural experiment; user-fee magnitude dose-response analysis using fee-schedule data.

---

### 8. References

Use the existing `report/references/adlt-econ580-thesis.bib`.

---

## Figures and tables — master list

**Figures (target max: 10)**

| # | Filename | Section |
|---|---|---|
| 1 | `event_study_cs_share.png` | §5.1 |
| 2 | `event_study_cs_share_nda.png` | §5.1 |
| 3 | GDUFA event study (from `05_gdufa_analysis`) | §5.1 |
| 4 | `pdufa_nda_only_dd_event_study.png` | §5.3 |
| 5 | `gdufa_dd_event_study.png` | §5.3 |
| 6 | `pdufa_nda_rate_vs_count.png` | §5.4 |
| 7 | `gdufa_anda_rate_vs_count.png` | §5.4 |
| 8 | Poisson event-study IRR timing (inline or separate fig) | §5.5 |
| 9 | `gdufa_anda_sponsor_concentration_hhi.png` | §5.7 |
| 10 | `pdufa_nda_sponsor_concentration_hhi.png` | §5.7 |

**Tables (target max: 8)**

| # | Source CSV | Section |
|---|---|---|
| 1 | `cs_by_pdufa_era.csv`, `appltype_by_era.csv` | §3.4 |
| 2 | `pre_post_pdufa_comparison.csv`, `gdufa_pre_post_comparison.csv` | §5.1 |
| 3 | `pdufa_nda_diagnostics.csv` | §5.2 |
| 4 | `gdufa_diagnostics.csv` | §5.2 |
| 5 | `subsample_alt_specs_results.csv` | §5.3 |
| 6 | `gdufa_alt_specs_results.csv` | §5.3 |
| 7 | `cs_nda_2009_2013_drugs.csv` (top 15 rows) | §5.6 |
| 8 | `cs_nda_top_sponsors_1970_2025.csv` (top 10) | §5.7 |

---

## Writing workflow — three passes

**Pass 1 (this week).** Draft every section *short* — roughly 60% of target length. Don't polish. Get the skeleton in LaTeX. Results section can largely be assembled from the CSVs and figures already produced. Literature review can be 1-paragraph-per-theme from the bib abstracts. Introduction will be the hardest section; leave it for last in pass 1 so the author knows exactly what the paper claims before trying to motivate it.

**Pass 2 (next week).** Expand each section. This is where citation grounding matters most — every claim about prior literature gets verified against the actual PDF from Zotero before being asserted. This is where the Zotero-reading workflow (in `CLAUDE.md`) pays off.

**Pass 3 (polish).** Cut. Economics papers over-tell. McCloskey's *Economical Writing* lives here. Target cutting 10–15% of total words on the third pass.

---

## Notes for future sessions

- **Hardest section:** §2.2 (theory of user-fee incentives). Pro-hypothesis case must be made strongly without overselling — a weak theoretical setup makes the null result look trivial. Spend real time on §2.2 in pass 2. A half-page formal sketch may be appropriate if the advisor wants one, though Braxton's course materials suggest it's optional.
- **Introduction always last.** Draft the intro after the rest of the paper exists. You cannot write an intro for a paper that doesn't know what it claims.
- **The 2014 hydrocodone reschedule is the strongest extension.** Keep it in the conclusion as a preview of future work; it's a cleaner natural experiment than PDUFA/GDUFA.
- **Negative results require precision claims.** Every null result section should include a confidence-interval statement so the reader can see that "null" means "effect ruled out at practical magnitude," not "underpowered and inconclusive."

---

## Related files

- `logs/thesis_context.md` — stable project context
- `logs/thesis_decisions.md` — append-only decision log
- `CLAUDE.md` — Claude Code workflow conventions (including Zotero citation grounding rule)
- `report/main.tex` — manuscript root
- `report/sections/*.tex` — section files (pass 1 scaffold in progress)
- `report/references/adlt-econ580-thesis.bib` — bibliography (managed by Zotero via Better BibTeX)
