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

- **Institutional / background FDA papers**: Darrow, Avorn, and Kesselheim (2020) maps the evolution of FDA regulation, expedited pathways, user fees, and approval standards and is most useful for institutional background rather than causal inference.
- **Core speed / PDUFA / review-timing papers**: Dranove and Meltzer (1994) studies whether more important drugs reach the market sooner; Olson (1997) studies how firm characteristics affect FDA approval speed; Olson (2009) studies whether PDUFA and faster FDA review increased the likelihood of initial U.S. drug launches; Carpenter, Zucker, and Avorn (2008) studies whether PDUFA deadlines are associated with later safety problems; Philipson et al. (2008) provides a welfare framework for the FDA speed–safety tradeoff under PDUFA.
- **Still-needed downstream literature**: the project still needs the prescription supply / opioid / diversion / illicit-market literature that can connect faster approval and earlier or greater legal drug availability to downstream misuse or diversion outcomes.

Major debates:

- whether faster FDA review improves welfare by accelerating access to beneficial drugs
- whether faster approval or deadline pressure increases safety risk
- whether PDUFA primarily changed review speed, firm launch behavior, or both
- whether the main downstream consequence of regulatory acceleration should be studied through safety only, or also through broader market externalities

Current fit of the thesis:

The thesis is increasingly positioned as an extension of the FDA speed–safety literature into a downstream market-outcomes question. Existing core papers mainly study review time, launch timing, and safety; the project may contribute by asking whether regulatory acceleration also changed the composition or supply conditions of approved drugs in ways that matter for controlled-substance exposure and diversion risk.

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
- the broader thesis question remains whether PDUFA changed the composition of FDA-approved drugs, especially controlled substances

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

Primary datasets currently constructed:

- [dataset]

Current analytical tasks:

- [task]

Current bottlenecks:

- [problem]

Thesis stage:

- dataset construction completed for a first-pass FDA master panel
- descriptive analysis is the next active stage

Primary datasets currently constructed:

- `data/processed/fda_backbone.csv`

Current analytical tasks:

- generate descriptive time-series summaries of FDA submissions and approvals
- derive approval-only and original-submission subsets from the master panel for focused analysis
- prepare for future controlled-substance linkage and post-1992 composition analysis

Current bottlenecks:

- Drugs@FDA is not a full universe of failed applications
- exact submission-to-product mapping remains limited because product fields are attached conservatively at the application level
- some supporting fields remain only partially interpretable without additional lookup support

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
- Linking FDA drug approvals to DEA scheduling classifications may require external data sources and careful product‑level matching, which introduces potential measurement error if scheduling status cannot be consistently mapped to the submission‑event dataset.
- Many central FDA-regulation papers are descriptive or reduced-form and do not by themselves identify downstream causal effects on misuse or diversion.
- Welfare analyses in the PDUFA literature often rely on strong assumptions about consumer surplus, producer surplus, and how safety harms should be monetized, so those papers should be used as conceptual anchors rather than taken as definitive estimates for this thesis.
- Several FDA safety papers use withdrawals, black-box warnings, or related regulatory events as downstream outcomes; these are informative but do not directly measure diversion, misuse, or illicit-market spillovers.

---

# 11. Open Research Questions

Important unresolved questions that guide ongoing work.

Examples:

- Which derived subset should anchor the main thesis descriptives: all approved submission events, original submissions only, or an application-level approval series constructed from the master panel?
- Can exact submission-to-product matching be improved beyond conservative application-level product aggregates using additional FDA metadata or document parsing?

- How should regulatory outcomes be coded?
- What is the correct unit for empirical analysis?
- Which regulatory actions should count as "failures"?
- How should "controlled substances" be operationalized in the FDA approval dataset for empirical analysis (e.g., DEA schedule classifications, product‑level vs application‑level coding, and handling of drugs whose scheduling status changes over time)?
- What is the right literature-review structure for separating institutional FDA background papers from core causal or quasi-causal papers on speed, launch timing, and safety?
- Which outcome should anchor the empirical contribution: changes in the composition of approvals, changes in legal drug supply exposure, or a direct downstream measure of diversion / misuse if linkable data can be found?
- Which downstream literature is most appropriate for connecting earlier FDA approval to diversion risk: opioid prescribing and supply, controlled-substance scheduling, illicit substitution, or another channel?
- Should the thesis ultimately frame its contribution as an extension of the classic FDA “speed vs safety” tradeoff into a broader “speed vs downstream externalities” framework?

---

# 12. Immediate Research Priorities

Short list of **current priorities**.

Example:

1. finalize FDA submission-event master dataset
2. construct key regulatory outcome variables
3. generate descriptive statistics

Keep this section **very short and frequently updated**.

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
