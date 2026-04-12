# ECON 580 Thesis Context

> This file is the **authoritative project context** for the ECON 580 thesis.
>
> It should remain **concise, stable, and high‑signal**. Unlike decision or progress logs, this file should not accumulate detailed history.
>
> Think of this as the **README for the thesis project** so that any new ChatGPT or Codex session can immediately understand the project.

---

# How to Use This File

### Purpose

This file exists to:

- preserve the **current thesis state**
- provide **sufficient context for AI tools** (ChatGPT / Codex)
- summarize the **research question, data, and empirical direction**
- document **persistent constraints and assumptions**

This file should remain **short (1–2 pages ideally)** and should not contain detailed logs.

### What goes here

Add or update content when:

- the thesis question changes
- the empirical strategy changes
- major datasets are added or removed
- the interpretation of the project shifts

### What does NOT go here

Do **not** include:

- detailed coding logs
- experiment-by-experiment notes
- minor analysis updates

Those belong in:

- `logs/thesis_decisions.md`

---

# 1. Thesis Snapshot

This section provides the **quickest possible orientation** to the project.

### Working Title

[Current working title of the thesis]

### Core Research Question

[The central research question the thesis is trying to answer]

### Motivation

Briefly explain the **policy or economic motivation** for the project.

Aim for **4–6 sentences**.

### Current Thesis Claim (Tentative)

State the **current working argument or hypothesis**.

This can evolve over time.

---

# 2. Research Scope

Describe the **intellectual boundaries of the thesis**.

Clarify:

- what the thesis studies
- what it does **not** attempt to study
- the conceptual frame (economic, regulatory, policy, etc.)

---

# 3. Literature Context

The most relevant literature now falls into three groups.

- **Institutional / background FDA papers**: Darrow, Avorn, and Kesselheim (2017, 2020) map the evolution of FDA regulation, user fees, shrinking review times, growing industry-funding dependence, and approval standards; these papers are most useful for institutional background and for framing the speed–safety–industry-funding debate rather than for clean causal inference.
- **Core speed / PDUFA / review-timing papers**: Dranove and Meltzer (1994) studies whether more important drugs reach the market sooner; Olson (1997) studies how firm characteristics affect FDA approval speed; Olson (2009) studies whether PDUFA and faster FDA review increased the likelihood of initial U.S. drug launches; Carpenter, Chernew, Smith, and Fendrick (2003) finds that additional FDA staffing substantially reduced NDA review times and argues that the amount of review resources mattered more than the source of funding; Carpenter, Zucker, and Avorn (2008) studies whether PDUFA deadlines are associated with later safety problems; Philipson et al. (2008) provides a welfare framework for the FDA speed–safety tradeoff under PDUFA.
- **Accelerated approval / coverage / uncertain-benefit papers**: Gellad and Kesselheim (2017) is useful for understanding accelerated approval as a pathway that can bring expensive drugs to market before confirmatory evidence is complete, while still triggering strong Medicare and Medicaid coverage obligations for many products; this is especially useful for thinking about downstream public-spending and regulatory-externality channels even if it is not itself a controlled-substance paper.
- **Still-needed downstream literature**: the project still needs the prescription supply / opioid / diversion / illicit-market literature that can connect faster approval and earlier or greater legal drug availability to downstream misuse or diversion outcomes.

Major debates:

- whether faster FDA review improves welfare by accelerating access to beneficial drugs
- whether faster approval or deadline pressure increases safety risk
- whether PDUFA primarily changed review speed, firm launch behavior, or both
- whether the main downstream consequence of regulatory acceleration should be studied through safety only, or also through broader market externalities
- whether the key mechanism behind shrinking review times is user-fee dependence itself or simply greater staffing and review resources
- whether accelerated approval and other expedited pathways create downstream public costs when products with uncertain clinical benefit still trigger broad public-payer coverage

Current fit of the thesis:

The thesis is increasingly positioned as an extension of the FDA speed–safety literature into a downstream market-outcomes question. Existing core papers mainly study review time, launch timing, and safety; the project may contribute by asking whether regulatory acceleration also changed the composition or supply conditions of approved drugs in ways that matter for controlled-substance exposure and diversion risk. New reading also suggests two useful refinements for the project: first, the thesis should distinguish sharply between the effect of *more FDA review resources* and the effect of *industry-funded user fees as such*; second, accelerated approval and coverage mandates may be a parallel downstream-externalities channel worth tracking even if the main empirical focus remains controlled substances.

---

# 4. Data Context

Describe the datasets currently used in the project.

For each dataset, include:

Dataset name

Source

What it contains

Role in the thesis

Example structure:

### Dataset: Drugs@FDA Extract

Source: FDA Drugs@FDA database

Content:

- submission events
- approval status
- regulatory action types

Role in thesis:

Forms the **core panel of regulatory submissions** used for descriptive analysis.

### Dataset: Drugs@FDA Extract (`data/raw/dafdata20260313/`)

Source: FDA Drugs@FDA data files downloaded from the FDA website and extracted locally in March 2026.

Content:

- `Applications`, `Submissions`, and `Products` as the core linked tables
- supporting lookup and child tables for submission classes, action types, submission properties, documents, marketing status, and therapeutic equivalence

Role in thesis:

Provides the raw regulatory source data used to construct the current FDA submission-event master panel.

### Dataset: FDA Backbone (`data/processed/fda_backbone.csv`)

Source: built locally from the 12-table Drugs@FDA extract in `code/notebooks/01_fda_backbone_and_scope.ipynb`.

Content:

- one row per submission event keyed by `ApplNo + SubmissionType + SubmissionNo`
- application attributes such as `ApplType` and `SponsorName`
- submission attributes such as status, status date, review priority, and submission class
- aggregated product, action-type, document, marketing-status, and TE information attached conservatively to avoid duplicate row inflation

Role in thesis:

This is the current processed master dataset for exploratory descriptive analysis and for downstream derivation of approval-only or original-submission subsets.

### Dataset: DEA Controlled-Substance Raw Reference Materials (`data/raw/dea_controlled_substances_20260315/`)

Source: official DEA materials downloaded from DEA / Diversion Control webpages and PDFs in March 2026.

Content:

- current DEA schedule-reference web content
- DEA conversion-factor table with controlled-substance names, schedules, and drug codes
- DEA Orange Book PDFs and exempted-product materials used for edge-case audit and scope checking

Role in thesis:

Provides the raw controlled-substance reference material used to construct a first-pass DEA linkage layer without replacing the FDA backbone.

### Dataset: FDA+DEA Intermediate Linkage (`data/intermediate/fda_dea_controlled_substance_linkage.csv`)

Source: built locally in `code/notebooks/03_dea_controlled_substance_linkage.ipynb` from the processed FDA backbone plus official DEA reference material.

Content:

- one row per FDA submission event from the master backbone
- DEA linkage status fields distinguishing confident scheduled matches, `List I` matches, uncertain candidate-only cases, and rows lacking FDA-side ingredient information
- matched DEA substance names, schedules, drug codes, match methods, uncertainty flags, and audit notes

Role in thesis:

This is the current intermediate enrichment layer for studying controlled-substance involvement in FDA regulatory activity.

### Dataset: FDA+DEA Annual Event-Study Panel (`data/intermediate/fda_dea_event_study_annual_panel.csv`)

Source: built locally in [code/notebooks/05_event_study_setup.ipynb](/Users/alexdelatorre/Desktop/econ580-thesis/code/notebooks/05_event_study_setup.ipynb) from the FDA backbone plus the first-pass DEA linkage layer.

Content:

- annual numerators, denominators, and shares for candidate controlled-substance outcome series
- separate series for `ORIG`, `AP`, and `ORIG + NDA-only` sample definitions
- conservative DEA confidence-tier outcomes including confident scheduled matches, confident plus `List I`, and any DEA signal
- policy-timing variables for 1984, 1992, and later PDUFA renewal years

Role in thesis:

Provides the current annual panel used for first-pass interrupted-time-series / event-study diagnostics before any paper-facing causal notebook is built.

---

# 5. Unit of Observation

Clearly define the **main observational unit**.

Examples:

- drug
- application
- submission event
- drug‑year

If multiple units exist, explain how they relate.

Current main unit: **submission event** (`ApplNo + SubmissionType + SubmissionNo`).

Relationship to other units:

- applications are the parent regulatory entity
- products are child records under applications and are attached to the master file only through conservative application-level aggregates
- future thesis analysis may derive approval-year or drug-year summaries from the submission-event panel

---

# 6. Empirical Framework

Describe the **current empirical approach**.

Include:

- descriptive goals
- causal questions (if any)
- key variables of interest

Also mention if the project currently focuses on:

- descriptive analysis
- causal inference
- policy evaluation

Current empirical direction:

- primary near-term focus is **descriptive analysis**
- the core processed dataset is an unfiltered FDA submission-event panel
- approval-only, original-submission, NDA-only, and other analytic subsets should be derived from the master panel rather than stored as the primary processed file
- a first-pass DEA linkage layer now exists and should be used as an intermediate enrichment rather than treated as final truth about product-level schedule status
- the broader thesis question remains whether PDUFA changed the composition of FDA-approved drugs, especially controlled substances
- early descriptive work now explicitly compares the full submission-event panel to narrower views such as `AP` and `ORIG + AP` rather than assuming one unit or subset is always appropriate
- the project has now moved into **first-pass event-study / interrupted-time-series setup**, using annualized outcome series derived from the submission-event panel rather than treating the raw panel itself as the estimation dataset
- the current leading candidate outcome is the annual share of **confident scheduled DEA matches within the `ORIG` subset**, with broader DEA tiers and `NDA-only` restrictions treated as sensitivity analyses rather than as the default main series

---

# 7. Current Project Status

Summarize the **current stage of the thesis**.

Example structure:

Thesis stage:

- literature review
- dataset construction
- descriptive analysis
- empirical modeling
- writing

Thesis stage:

- dataset construction completed for a first-pass FDA master panel
- descriptive analysis notebook built and executed from the processed backbone
- first-pass DEA controlled-substance linkage notebook built and executed
- first-pass FDA–DEA descriptive-comparison notebook built and executed
- first-pass event-study setup notebook built and executed, including an annual panel export

Primary datasets currently constructed:

- `data/processed/fda_backbone.csv`
- `data/intermediate/fda_dea_controlled_substance_linkage.csv`
- `data/intermediate/fda_dea_event_study_annual_panel.csv`
- `data/event_study/event_study_drug_panel.csv` — drug-approval-level analytical dataset (25,908 rows, 1939–2025), one row per unique approved original application; built in `code/notebooks/06_event_study_dataset_build.ipynb`. Contains all DEA controlled-substance dummies, schedule indicators, policy timing variables, and combination-product flags needed for Stata estimation. Read with `dtype={'ApplNo': str}` to preserve leading zeros.
- `data/event_study/stata/event_study_drug_panel.dta` — Stata-ready version of the above; produced by `code/stata/01_load_and_prep.do`. Variables are lowercase; `appltype_str`, `pdufa_era_str`, and `dea_confidence_tier_str` are string originals; encoded numeric versions available without `_str` suffix.
- `data/event_study/stata/event_study_annual.dta` — annual panel (1939–2025) collapsed from the drug-level .dta by `code/stata/03_event_study.do`. One row per year with CS counts, shares, log outcomes, and NDA/ANDA sub-series. Used for all PDUFA event study and ITS regressions.
- `data/event_study/stata/gdufa_anda_annual.dta` — annual panel (1984–2025) of ANDA approvals only, collapsed by `code/stata/05_gdufa_analysis.do`. Contains ANDA CS counts, shares, schedule breakdowns, and GDUFA timing variables (`post_gdufa`, `gdufa_transition`, `gdufa_era`, `trend_post_gdufa`). Three-period design: pre-GDUFA (≤2012), transition/backlog-washout (2013–2014), post-GDUFA performance-goal era (2015+).

Current analytical tasks:

- review PDUFA event study output from `03_event_study.do` and GDUFA analysis output from `05_gdufa_analysis.do`; assess whether either produces a paper-facing result
- decide whether to anchor the thesis on the GDUFA/ANDA channel (more tractable: 86.6% of CS approvals are ANDAs; GDUFA is the directly relevant policy) or on a broader ITS framing
- consider whether historical DEA scheduling data would materially change the retroactive-linkage limitation before committing to a main specification

Current bottlenecks:

- DEA reference materials are useful but not fully comprehensive for salts, isomers, derivatives, and preparation-specific schedule distinctions
- the current linkage operates through ingredient aggregates rather than exact product-level identities
- some FDA submission-event rows have no ingredient information, which limits controlled-substance classification coverage
- Drugs@FDA is not a full universe of failed applications
- exact submission-to-product mapping remains limited because product fields are attached conservatively at the application level
- some supporting fields remain only partially interpretable without additional lookup support
- review-priority coding quality varies over time and may be too noisy to serve as a central variable without caution
- the national annual event-study design remains identification-limited and is better treated as a first-pass interrupted-time-series exercise than as strong causal evidence
- the intended row-level FDA+DEA linkage file may not be materialized in every environment because it can appear as a Git LFS pointer rather than a directly readable CSV

---

# 8. Repository Orientation

Minimal map of the project repository so AI tools understand the workflow.

### Key folders

`logs/`

Project context and decision logs

`code/analysis/notebooks/`

Exploratory notebooks

`code/src/`

Reusable scripts

`data/raw/`

Original datasets

`data/intermediate/`

Temporary processing outputs

`data/processed/`

Clean analytical datasets

`output/figures/`

Figures for analysis or reporting

`output/tables/`

Generated tables

`report/`

Thesis writing

---

# 9. Persistent Constraints

Document **structural constraints** that future analysis must remember.

Examples:

- incomplete regulatory records
- limited data on failed applications
- missing variables
- time constraints of the thesis

- `ApplNo`, `SubmissionNo`, and `ProductNo` must remain string identifiers to preserve leading zeros and safe merges
- placeholder dates such as `1900-01-01` must be treated as missing rather than real event dates
- one-to-many child tables from Drugs@FDA should be aggregated before merge to avoid inflating the submission-event panel
- descriptive patterns can change materially when the unit shifts from submission-event rows to application-level aggregates, so unit changes must always be made explicitly and justified
- DEA linkage should remain auditable and ingredient-based unless a defensible product-level bridge is built later
- current DEA schedule matches should not be interpreted automatically as historical schedule-at-approval classifications
- partial calendar years in the FDA extract, especially the current 2026 snapshot, should not be treated as fully observed years in annual event-study panels
- annual event-study outcomes should remain share-based where possible, because raw counts are more sensitive to supplement inflation and broad secular growth in observed submission activity

---

# 10. Known Risks or Limitations

List limitations that may affect interpretation.

These should persist across sessions.

Examples:

- selection bias
- incomplete regulatory histories
- inability to observe certain outcomes

- Drugs@FDA is approval-centered, so non-approval outcomes are only partially observed
- product descriptors in the processed backbone are application-level aggregates, not exact product matches for each submission
- `ApplicationDocs.txt` required a custom parse because the extract contains at least one malformed row
- some lookup coverage is incomplete or low-information, including gaps in submission-class descriptions and limited support for interpreting `SubmissionPropertyTypeID`
- submission-event descriptives are heavily supplement-driven, so naive counts can overstate growth in distinct drugs or distinct applications
- `ReviewPriority` is informative descriptively but unstable enough over time that raw and cleaned versions should be distinguished carefully
- the orphan-property indicator is only partially observed because many rows have no submission-property data
- Linking FDA drug approvals to DEA scheduling classifications may require external data sources and careful product‑level matching, which introduces potential measurement error if scheduling status cannot be consistently mapped to the submission‑event dataset.
- DEA reference lists used for linkage are explicitly not fully comprehensive and do not exhaustively resolve salts, isomers, esters, ethers, derivatives, or all preparation-specific cases
- the current DEA linkage is strongest for ingredient-level controlled-substance involvement, not for exact product-level schedule assignment
- the parsed DEA reference includes both CSA scheduled substances and `List I` chemicals, so those categories must remain separate in analysis
- some FDA rows in the backbone have no `ActiveIngredient_list`, so they cannot be classified through the current ingredient-based DEA bridge
- the current annual event-study setup is based on a single national time series, so segmented pre/post estimates should be interpreted as suggestive policy diagnostics rather than strong causal estimates
- sharper-looking post-1992 changes in `AP`-based series may be driven partly by supplement composition rather than by the economically cleaner approval-composition margin of interest
- `ORIG + NDA-only` series are conceptually appealing for a more PDUFA-specific channel but can become noisy because annual denominators are much smaller
- Many central FDA-regulation papers are descriptive or reduced-form and do not by themselves identify downstream causal effects on misuse or diversion.
- Welfare analyses in the PDUFA literature often rely on strong assumptions about consumer surplus, producer surplus, and how safety harms should be monetized, so those papers should be used as conceptual anchors rather than taken as definitive estimates for this thesis.
- Several FDA safety papers use withdrawals, black-box warnings, or related regulatory events as downstream outcomes; these are informative but do not directly measure diversion, misuse, or illicit-market spillovers.
- The literature now suggests that shrinking review times may reflect increased FDA staffing and review resources more than the funding source itself, which complicates any attempt to interpret PDUFA as a simple “industry influence” shock.
- Accelerated-approval and public-payer-coverage papers are highly relevant for policy framing, but many of those examples come from oncology or rare-disease markets rather than controlled substances, so external validity to this thesis question may be limited.

---

# 11. Open Research Questions

Important unresolved questions that guide ongoing work.

- How should regulatory outcomes be coded?
- What is the correct unit for empirical analysis?
- Which regulatory actions should count as "failures"?
- How should "controlled substances" be operationalized in the FDA approval dataset for empirical analysis (e.g., DEA schedule classifications, product‑level vs application‑level coding, and handling of drugs whose scheduling status changes over time)?
- What is the right literature-review structure for separating institutional FDA background papers from core causal or quasi-causal papers on speed, launch timing, and safety?
- Which outcome should anchor the empirical contribution: changes in the composition of approvals, changes in legal drug supply exposure, or a direct downstream measure of diversion / misuse if linkable data can be found?
- Which downstream literature is most appropriate for connecting earlier FDA approval to diversion risk: opioid prescribing and supply, controlled-substance scheduling, illicit substitution, or another channel?
- Should the thesis ultimately frame its contribution as an extension of the classic FDA “speed vs safety” tradeoff into a broader “speed vs downstream externalities” framework?
- What is the most appropriate observational lens for early descriptive analysis: drug-level summaries, submission-event counts, or application-level approval series derived from the master FDA backbone?
- Which subset should anchor the core thesis descriptives once DEA linkage is added: the full submission-event panel, `AP`, `ORIG`, or `ORIG + AP`?
- Should the thesis’s core controlled-substance results rely only on confident DEA matches, or should uncertain parent/isomer candidates appear in sensitivity analysis?
- Should the paper’s main event-study specification center entirely on the `ORIG` confident-share series, or should `ORIG + NDA-only` remain closer to the main text despite its higher volatility?
- How should the thesis handle the joint institutional importance of Hatch–Waxman (1984) and PDUFA (1992) when the series may reflect both generic-market expansion and later FDA review-speed changes?
- Does the thesis need a stronger historical schedule-at-approval bridge before making stronger controlled-substance claims, or is the current non-historical DEA linkage adequate for a first-pass composition analysis?
- Should the thesis treat *staffing/resources* rather than *user-fee funding source* as the more credible mechanism linking PDUFA-era institutional change to approval speed?
- Is accelerated approval plus mandated public-payer coverage a more tractable downstream-externalities angle than diversion risk, or should it remain background rather than the main empirical contribution?
- If the thesis stays focused on controlled substances, what is the cleanest way to connect FDA-side regulatory acceleration to a downstream outcome that is closer to economic behavior than to clinical uncertainty alone?

---

# 12. Immediate Research Priorities

Short list of **current priorities**.

Example:

1. finalize FDA submission-event master dataset
2. construct key regulatory outcome variables
3. generate descriptive statistics

Keep this section **very short and frequently updated**.

1. refine the event-study setup around the `ORIG` confident-share annual series and decide what should appear in the main text versus sensitivity appendix
2. assess whether a stronger paper-facing specification should explicitly address both the 1984 and 1992 policy environment
3. decide whether the main thesis descriptives should be anchored on the full panel, `AP`, `ORIG + AP`, or a companion application-level panel

---

# 13. AI Session Instruction

Whenever starting a new ChatGPT or Codex session, provide this instruction:

```
Please read `logs/thesis_context.md` first.

Treat it as the authoritative project context for this thesis.

Use it to understand the research question, datasets, empirical direction, and current project status before helping with the task.
```

This ensures the AI assistant always begins with the **correct project understanding**.

---

# Guiding Principle

If someone unfamiliar with the project opened this file, they should be able to understand:

- what the thesis studies
- what data it uses
- what the current research direction is
- what the main limitations are

within **5 minutes of reading**.

Keep the file structured to make that possible.

# ECON 580 Thesis Context

Authoritative project context for the ECON 580 thesis.
AI agents must read this file before performing any task.

Rules:
- Treat this file as the current project state
- Do not rewrite existing content unnecessarily
- Update only when core thesis context changes
- Do not add session logs here (use `logs/thesis_decisions.md`)

---

# PROJECT SNAPSHOT

Working title:
[fill]

Research question:
[fill]

Motivation:
[4–6 sentence summary of policy or economic motivation]

Working thesis claim (tentative):
[fill]

---

# RESEARCH SCOPE

Studies:
- [topic]

Does NOT attempt to study:
- [topic]

Conceptual frame:
- economics
- regulation
- policy analysis

---

# LITERATURE CONTEXT

Key literature:
- [paper — role in project]
- [paper — role in project]

Debates relevant to thesis:
- [debate]

Position of this thesis:
- [contribution]

---

# DATA CONTEXT

Dataset:
Name:
Source:
Contains:
Role in thesis:

Dataset:
Name:
Source:
Contains:
Role in thesis:

---

# UNIT OF OBSERVATION

Primary unit:
- [unit]

Secondary units (if any):
- [unit]

Relationship between units:
- [description]

---

# EMPIRICAL FRAMEWORK

Current focus:
- descriptive analysis
- causal inference
- policy evaluation

Key variables of interest:
- [variable]

Empirical approach:
- [method]

---

# PROJECT STATUS

Stage:
- literature review
- dataset construction
- descriptive analysis
- empirical modeling
- writing

Primary datasets built:
- [dataset]

Current analytical tasks:
- [task]

Current bottlenecks:
- [problem]

---

# REPOSITORY MAP

logs/
- thesis_context.md
- thesis_decisions.md
- prompts.md

code/
- analysis/notebooks
- src

data/
- raw
- intermediate
- processed

output/
- figures
- tables

report/
- thesis writing

---

# PERSISTENT CONSTRAINTS

Structural constraints:
- [constraint]

---

# KNOWN RISKS

Potential interpretation risks:
- The cleaned backbone used for descriptive work aggregates some product-level information conservatively to avoid row duplication, which means certain product attributes may be simplified relative to the full raw Drugs@FDA tables.
- [risk]

---

# OPEN QUESTIONS

- [question]
- [question]
- How should "controlled substances" be operationalized in the FDA approval dataset for empirical analysis (e.g., DEA schedule classifications, product‑level vs application‑level coding, and handling of drugs whose scheduling status changes over time)?

---

# CURRENT PRIORITIES

1. [priority]
2. [priority]
3. [priority]

---

# SESSION INSTRUCTION FOR AI

Before doing any work:

1. Read `logs/thesis_context.md`
2. Understand research question, data, and empirical direction
3. Then perform the requested task

If new information changes project context:

- update the relevant section of this file
- do not add session logs here

Session logs belong in:

`logs/thesis_decisions.md`
