# Rebuilding a Defensible Event-Study Workflow for PDUFA and Controlled-Substance Composition

## Why your current “event-study panel” felt wrong

Your instinct—that “this doesn’t look like an event study dataset”—is pointing at a real mismatch between (a) what event study models in applied economics typically require, and (b) what you can identify if the “event” is a **single national policy enacted at a single common time for everyone**.

If the outcome you want is “the share of FDA approvals that are controlled substances each year,” then **two different datasets are useful**:

1. A **micro/long dataset** with one row per approval (or per application approval) that lets you audit what is being counted (what drug, what sponsor, what type, what date, what controlled indicator).
2. An **aggregated time-series dataset** (monthly or annual) that contains the numerator/denominator and the share.

Your anger is mostly about transparency: you expected to see the micro rows, not just the aggregate series. That’s a valid demand for auditing and credibility.

But there’s a second, deeper issue: even if you built the perfect micro dataset, a “standard event study” (dynamic DiD with event-time coefficients and unit/year fixed effects) is **not automatically identified** with a single national break unless you have either a valid control group or staggered timing.

## What “event study” means in economics versus finance, and the identification constraint you’re running into

In applied economics/policy evaluation, “event study” usually refers to a **difference-in-differences design with dynamic treatment effects** (leads/lags), most commonly relying on variation in *timing* of treatment across units. Borusyak, Jaravel, and Spiess define event studies exactly this way: “an event study is a difference-in-differences (DiD) design in which a set of units in the panel receive treatment at different points in time.” citeturn9view0

That timing variation (or a never-treated control group) is not a technical detail—it is the backbone of identification. In fact, Borusyak et al. show that fully dynamic event-study specifications can fail to be point-identified without a never-treated group, and they give a formal proposition illustrating the under-identification problem. citeturn13view1

This is the exact problem with a national single-date policy like PDUFA (1992) when you are looking at U.S.-wide outcomes only: **everything is “treated” at once**, and you do not have an untreated counterfactual series inside the same national dataset.

The StataCorp DiD guidance makes the intuition blunt: before/after among exposed units alone “would not be enough” because there could be a general trend, so you also need a group “not exposed.” citeturn15view0

So you have two honest options:

- **Option A (credible for your data):** treat this as an **interrupted time series (ITS)** / segmented regression problem (a single national intervention at a clearly defined time), and be explicit that identification is limited. Bernal, Cummins, and Gasparrini describe ITS as valuable for population-level interventions introduced at a clearly defined time and show how segmented regression formalizes level/slope changes. citeturn14view0  
- **Option B (closer to “event study” in the DiD sense):** create a credible **comparison group** inside your U.S. drug data (or add outside data). This becomes a DiD-type event study where you estimate “differential change” between two groups around the policy.

Your current annual panel is not “worthless”—it’s simply aligned with Option A (ITS), not Option B (dynamic DiD event study). And it’s missing the micro rows you want for auditing.

## The cleanest way to rebuild: decide the estimand first, then build two datasets

Before writing code, you need one disciplined sentence:

**What exactly counts as an “FDA-approved drug” in your outcome?**

Given the structure of Drugs@FDA, there are several plausible “approval units,” and choosing one is not optional—this is the root of your confusion.

The FDA Drugs@FDA downloadable database is explicitly a relational database with **12 tables** (Applications, Submissions, Products, etc.) and clearly defined keys and fields. citeturn11view0 The Submissions table is keyed by `(ApplNo, SubmissionType, SubmissionNo)` and contains a status and status date (including approval dates via `SubmissionStatusDate`). citeturn11view0turn13view2 The Products table is keyed by `(ApplNo, ProductNo)` and contains `DrugName` and `ActiveIngredient`. citeturn11view0

However, Drugs@FDA does **not** straightforwardly provide “one row per drug approval per year” unless you define the unit carefully, because:

- There are many submission events per application (supplements, labeling changes, etc.).
- The Products table is not keyed to submission events; it is keyed to applications and products. citeturn11view0  
- So “list all products approved in year Y” is not automatically a clean query unless you define your unit as application-level approval events (and accept product info as attached at the application level).

This leads to a disciplined two-dataset plan:

### Dataset 1 (micro, auditable): “Approval roster”
One row per *approval event* under your chosen definition, including enough columns to inspect what you’re counting.

### Dataset 2 (analysis panel): “Time series / group-time panel”
Monthly or annual aggregates that compute numerators/denominators/shares from Dataset 1.

The annual panel you currently have is basically Dataset 2 without a transparent Dataset 1.

## How to build the micro approval dataset you described, using what Drugs@FDA actually contains

This is the “take matters into my own hands” roadmap you asked for, but grounded in the real fields available in Drugs@FDA.

### Step to define the unit of observation
You have three realistic choices:

- **Application-level original approvals:** one row per application’s original approval (closest to “new drug application approval,” but still includes ANDAs if you don’t restrict).  
- **Submission-event approvals:** one row per submission event with `SubmissionStatus == AP` (this inflates with supplements; your previous notebooks already found this).  
- **Product-level approvals:** one row per product under an application, but Drugs@FDA does not map product approvals cleanly to submission dates in a way that avoids duplication, because Products is keyed to ApplNo not submissions. citeturn11view0

For your goal (“share of approvals that are controlled substances”), the least misleading micro unit is usually:

**ORIG approvals at the application-submission level:** `SubmissionType == ORIG` and `SubmissionStatus == AP`.

That gives you a list you can inspect and count. It also avoids supplement inflation by construction.

### Step to construct core fields you expected

You can reliably create:

- **approval_date / approval_year / approval_month** from `Submissions.SubmissionStatusDate` citeturn11view0  
- **application type (NDA/ANDA/BLA)** from `Applications.ApplType` citeturn11view0  
- **sponsor** from `Applications.SponsorName` citeturn11view0  
- **drug name and active ingredient** from `Products.DrugName` and `Products.ActiveIngredient` (attached at ApplNo-level; you may aggregate to a list per ApplNo). citeturn11view0  
- **review priority** from `Submissions.ReviewPriority` citeturn11view0  

You *may not* be able to get what you described as “the date the application was submitted” from these downloadable tables, because the Submissions table as documented emphasizes status and `SubmissionStatusDate`, not a “received date.” citeturn11view0 What’s in your version of the extract matters; you must verify whether a received/submission date exists in your local file headers.

You also likely do **not** have a clean “accelerated approval” flag directly in these tables. If you want it, you will either (a) proxy with `ReviewPriority` or submission class, or (b) bring in an external FDA expedited-program dataset.

### Step to merge DEA controlled-substance flags
Your idea of a simple “is ingredient on the controlled list?” dummy is correct in structure, but you must preserve the same tiering you already built (confident scheduled vs List I vs candidates vs missing ingredient), because the DEA reference lists are not perfectly comprehensive and your current linkage is ingredient-based.

At the micro approval-row level, you want at minimum:

- `cs_confident = 1` if any active ingredient matched confidently to a scheduled substance  
- `cs_list1_only = 1` if only List I  
- `cs_candidate_only = 1` if only fuzzy candidate  
- `cs_missing_ing = 1` if no ingredient data  
- `cs_any_signal = 1` if any of the above signals, but keep it as sensitivity, not headline

This gives you a micro dataset you can literally sort by year and manually sanity-check.

## How to make this a real “event study” (or a defensible ITS) once the micro dataset exists

Once you have the approval roster (Dataset 1), you have three estimation paths. Only two are defensible without outside data.

### Path 1: Interrupted time series (single national break)
This is the correct design if you truly have only one national series and no control. Bernal et al. describe ITS specifically for population-level interventions at a clearly defined time and show segmented regression as the main analytic approach. citeturn14view0

Key requirements and best practices from ITS guidance:

- Decide the impact model *a priori* (level change, slope change, lagged change, etc.), rather than selecting it based on what looks significant. citeturn14view0  
- Inspect pre-trends visually and consider whether long historical periods reflect different regimes (they caution that “more time points” isn’t always better if underlying trends changed). citeturn14view0  
- Address autocorrelation/seasonality if you go monthly. citeturn14view0  

**Important improvement:** build the series at **monthly** frequency using `SubmissionStatusDate`. That increases time points dramatically and is exactly the kind of routine-data time series Bernal et al. have in mind. citeturn14view0

What the dataset looks like for ITS:
- `month` (or `year`)
- `total_orig_approvals`
- `cs_confident_orig_approvals`
- `share_cs_confident`
- `post1992`
- `time_trend`
- `post1992_trend`

That’s not “worthless.” That’s exactly what ITS uses.

### Path 2: DiD-type event study using an internal comparison series
If you want something closer to an event-study graph with dynamic coefficients, you must create a comparison group. The Stata DiD guidance is explicit: without a non-exposed group, you can’t separate the policy from general trends. citeturn15view0

A workable internal comparison is to stack two series and use group×time interactions, for example:

- Controlled vs non-controlled approvals (group dimension), or  
- NDA vs ANDA approvals (group dimension), or  
- NDA controlled vs NDA non-controlled (tighter, smaller sample)

This gives a group-time panel:

- `group` (e.g., controlled=1 vs controlled=0)
- `month` or `year`
- `count` (or share)
- `post1992`
- event-time dummies interacted with group

This is still not bulletproof—parallel trends between groups is an assumption—but now you have a coherent DiD event-study structure.

This structure also aligns with the canonical definition of event study as DiD with differential timing or unit comparisons; Borusyak et al. emphasize that “event studies” in applied economics are fundamentally DiD objects. citeturn9view0turn13view1

### Path 3: “Long-horizon event study” muscle-memory (don’t do this)
If what you’re reading is corporate finance event study methodology (Kothari & Warner), note that those methods were built for abnormal stock returns around corporate announcements and have warnings about long-horizon inference being “treacherous.” citeturn13view3

That doesn’t map one-to-one to your policy problem, but the spirit carries: once you stretch time windows and rely on modeling assumptions, inference becomes fragile. citeturn13view3 For you, that’s another reason to prefer (a) higher-frequency ITS with clear diagnostics, or (b) explicit group comparisons rather than “pure single-series causality claims.”

## A step-by-step rebuild checklist you can implement immediately

This is the concrete workflow you asked for, written as deliverables and QA gates.

### Build the micro “approval roster” dataset
Define and extract `ORIG` + `AP` approvals from Submissions (keyed by ApplNo/SubmissionType/SubmissionNo) with approval date fields from `SubmissionStatusDate`. citeturn11view0  
Join Applications for ApplType and SponsorName. citeturn11view0  
Attach product info by aggregating Products (DrugName, ActiveIngredient) to ApplNo-level so you can display names and ingredients without duplicating rows. citeturn11view0  
Merge in DEA linkage flags at the same unit, keeping confidence tiers.

QA checks:
- Verify key uniqueness for your chosen unit (no duplicates).
- Print the first 20 approvals in a given year and manually inspect DrugName/ActiveIngredient plausibility.
- Confirm that counts by year match what you compute from the roster.

### Build the aggregate analysis panels from the roster
From the roster, compute:
- monthly and annual totals
- monthly and annual controlled-substance totals (confident tier)
- shares
- NDA-only and ANDA-only variants (sensitivity)

QA checks:
- Shares must equal numerator/denominator exactly.
- Exclude partial years (like your March 2026 snapshot) from inference.

### Choose the estimation design explicitly
If single-series only, run ITS with segmented regression and diagnostics consistent with ITS guidance (impact model chosen a priori, check autocorrelation, consider seasonality at monthly frequency). citeturn14view0  
If you want a real event-study graph, build the stacked group×time panel and estimate differential changes; justify parallel trends using pre-period behavior (and show it).

### Implement in Stata (your stated preference)
For ITS:
- `tsset month` (or `tsset year`)
- run segmented regression with Newey–West/HAC standard errors if autocorrelation is present
- include sensitivity specs with alternative break dates or placebo breaks

For DiD-type group-time panel:
- use a two-way FE regression with group FE and time FE and group×post interactions
- interpret as differential change, not absolute national effect

The key reminder here is the same one Stata’s own teaching materials stress: without some “non-exposed” series, before/after cannot isolate the policy effect because common trends confound it. citeturn15view0

### Decide what your thesis can claim after the rebuild
If ITS shows no 1992 break in the cleanest series, that becomes a result.
If group-time DiD shows differential movement (with flat pre-trends), you have a more “econ-style” event study figure, subject to the comparison-group assumption.

Either way, the point is: the rebuild lets you know what the data can actually say, and it makes the analysis auditable because the roster of approvals exists.

## Bottom line

You’re right to demand a micro-level approval roster before trusting any aggregate series. That’s foundational.

But you also need to recognize the identification constraint: for a single national policy date, a “standard event study” in the dynamic DiD sense is not available unless you construct a valid comparison series or add outside data—an insight formalized in modern event study/DiD theory and also emphasized in practical DiD instruction. citeturn9view0turn13view1turn15view0

Given your constraints, the disciplined rebuild is:

- Build the auditable micro “approval roster” (what you expected to see).
- Aggregate it to monthly and annual shares.
- Choose either ITS (single-series, honest, limited causal strength) or group-time DiD (requires a comparison group, but yields a genuine event-study plot).
- Only then interpret results and decide whether the PDUFA story survives.