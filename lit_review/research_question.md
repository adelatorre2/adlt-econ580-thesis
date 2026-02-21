

# Thesis Working Plan

## 0. One-Sentence Summary

Do participation fees act as price barriers that reduce low-income students’ access to high school athletics, and do fee-waiver mandates (WA HB 1660) reduce socioeconomic participation gaps? Evidence from Washington’s school-level fee + participation reporting, with a difference-in-differences comparison to a similar control state.

---

## 1. Research Question (Tightly Defined)

### Main Question
**Do participation fees limit low-income students’ participation in high school athletics, and does WA’s fee-waiver/reporting regime reduce the socioeconomic participation gap in athletic participation?**

### Core Outcomes (school-year level)
- **Overall athletic participation rate**
- **Low-income athletic participation rate**
- **Participation gap (Opportunity Gap):**  
  non-low-income participation rate − low-income participation rate  
  (matching the statute’s definition)

### Core Treatments / Policy Variables
- **Athletic participation fee level** (and/or fee schedule)
- **Effective low-income fee** (discounted/waived fee)
- **Waiver intensity / implementation proxy** (if observable in reporting language; e.g., automatic waiver, universal waiver, etc.)
- **Post-policy indicator** tied to HB 1660 reporting/implementation timing (and/or school adoption timing if staggered)

---

## 2. Why This Is an Economics Paper

This project fits applied micro/public economics because it studies **user fees** for a publicly provided good (extracurricular access) and asks how **prices and liquidity constraints** shape **take-up** and **distributional inequality**.

Economic framing:
- **User fees as prices / entry costs** → demand/take-up response (elasticity)
- **Liquidity constraints** and **incidence**: low-income students face higher effective barriers for the same nominal fee
- **Policy evaluation**: fee-waiver mandates as a subsidy/price reduction targeted to low-income students
- **Inequality / opportunity**: the participation gap is a distributional outcome, not just a mean effect
- **Human capital investment**: athletics participation is a form of skill formation and non-cognitive capital; the paper can cite prior work linking extracurricular participation to downstream schooling/college outcomes (motivation section)

This is not “sports sociology” because the estimand is explicitly economic: **how prices and subsidies affect access**.

---

## 3. Data: What It Would Look Like (Realistically)

### 3.1 Unit of Observation
**High school × School year** (panel).

### 3.2 Washington (Treatment State) Data Components
From HB 1660 reporting (district/school publications and/or OSPI-compiled reports):
- Total high school enrollment
- Low-income enrollment (FRPM or equivalent)
- Total students participating in athletics
- Low-income students participating in athletics
- Athletic participation fees
- Discounted/waived athletic participation fees for low-income students
- ASB card fees and discounted ASB fees (useful as a broader “cost environment” control)
- Stated “opportunity gap” measures and whether goals are met (if published)
- If available: plan requirement triggers and plan text (as a proxy for implementation effort)

Constructed variables:
- Participation rate = athletic participants / enrollment
- Low-income participation rate = low-income participants / low-income enrollment
- Non-low-income participation rate = (participants − low-income participants) / (enrollment − low-income enrollment)
- Participation gap = non-low-income rate − low-income rate
- Fee discount generosity = 1 − (low-income fee / full fee)

### 3.3 Control State Data Components (Needed for DiD)
Goal: a state that (i) has no comparable fee-waiver mandate timed like WA, (ii) has comparable high school athletics participation reporting (at least overall participation by school-year), and (iii) has similar demographics/trends.

Minimum viable for DiD:
- School-year athletics participation (overall; ideally low-income vs non-low-income but this is unlikely)
- School enrollment
- School/district poverty proxy (FRPM share if available, or community SES)
- Optional: fee information (likely not systematically available; can still do DiD on participation totals)

Important note:
- The cleanest “gap” outcome is likely WA-only (because HB 1660 forces low-income vs non-low-income reporting). The DiD can still be valuable for **overall participation** as the outcome, while WA-only models handle the **gap** outcome.

---

## 4. Feasibility and Order of Magnitude (Back-of-the-Envelope)

### 4.1 How Many Observations?
Let:
- N_schools = number of WA high schools covered (order of magnitude: a few hundred)
- T_years = number of school years with consistent reporting (order of magnitude: ~5–8 depending on availability)

Then WA panel size ≈ N_schools × T_years ≈ **1,000–3,000 school-year observations**.

If adding a control state with a similar number of schools and years, total ≈ **2,000–6,000 school-year observations**.

This is a realistic size for an Econ 580 applied econometrics paper.

### 4.2 What “Getting the Data” Entails
- Identify the WA HB 1660 reporting repository (OSPI and/or district ASB publications)
- Build a school-year dataset by:
  1) downloading/scraping district/school reports (PDF/HTML)
  2) extracting fee + counts fields into a structured table
  3) harmonizing school identifiers across years
- Merge in school-level covariates (enrollment, FRPM share, demographics) from standard education datasets if needed
- For the control state:
  - identify an equivalent athletics participation reporting source (state activities association or education agency)
  - ingest school-year participation counts and enrollment
  - harmonize school identifiers and years
  - merge in comparable covariates

---

## 5. Empirical Strategy (What We Would Actually Estimate)

### 5.1 Within-Washington Panel (Two-Way Fixed Effects)
Primary specification for the participation gap (WA-only):

$Gap_{s,t} = β1 * Fee_{s,t} + β2 * DiscountGenerosity_{s,t} + α_s + γ_t + X_{s,t} + ε_{s,t}$

Where:
- $α_s$ = school fixed effects (absorbs time-invariant school characteristics)
- $γ_t$ = year fixed effects (absorbs statewide shocks/trends)
- $X_{s,t}$ = time-varying controls (enrollment size, low-income share, etc.)

Interpretation:
- $β_1$ captures how changes in fees within a school over time relate to changes in the participation gap.
- $β_2$ captures whether more generous discounts/waivers are associated with reductions in the gap.

Key identifying assumption:
- Conditional on FE and controls, fee changes are not driven by unobserved time-varying shocks that also affect participation gaps.

### 5.2 Difference-in-Differences (WA vs Control State)
DiD is most credible for outcomes observable in both states (likely overall participation).

Outcome: $P$articipationRate_{s,t}$

$ParticipationRate_{s,t} = δ * (WA_s × Post_t) + α_s + γ_t + X_{s,t} + ε_{s,t}$

Interpretation:
- $δ$ is the causal DiD estimand: differential change in participation in WA after HB 1660 relative to the control state.

Key identifying assumption:
- Parallel trends: absent the policy, WA and the control state would have evolved similarly in participation outcomes.

Validation / diagnostics:
- Pre-trend event study if enough pre-years exist
- Placebo tests (other outcomes, or earlier fake policy dates)
- Sensitivity to alternative control states / synthetic control weights (if feasible)

### 5.3 How the Two Designs Fit Together
- **WA-only TWFE**: best for low-income vs non-low-income participation gap outcomes (unique to HB 1660 reporting).
- **WA vs control DiD**: best for overall participation outcomes and an external counterfactual.

This combined approach strengthens credibility while respecting data constraints.

---

## 6. Threats to Validity (and How We Address Them)

### Threat 1: Fee changes are endogenous (schools adjust fees when demand changes)
Mitigation:
- School FE + year FE
- Control for enrollment and low-income share
- If feasible, include district-by-year fixed effects to soak up district-level budget shocks

### Threat 2: Measurement inconsistency across schools/years
Mitigation:
- Document reporting definitions and standardize field extraction
- Robustness checks excluding schools with missing/inconsistent reporting
- Sensitivity to balanced panel only

### Threat 3: Control state not comparable / parallel trends violated
Mitigation:
- Pre-trend plots and event studies
- Multiple candidate control states
- Synthetic control as robustness (if data allow)

### Threat 4: Policy timing is not a clean “shock”
Mitigation:
- Use the most defensible implementation/reporting start date
- Consider staggered adoption of “automatic waiver” as within-WA variation if observable

---

## 7. Motivation / “Why Should We Care?” (What Prof. Braxton Flagged)

The introduction should cite and synthesize prior research showing that extracurricular participation is associated with positive educational outcomes (e.g., attendance, GPA, graduation, college enrollment) and broader early-adulthood indicators.

Two feasible options:
1) **Literature-only motivation** (lowest data burden): cite prior empirical evidence and position this paper as a policy evaluation of access barriers.
2) **Add a small downstream outcome** (if data exist): e.g., school-level college enrollment/attendance rates (aggregated), as an exploratory extension.

The core paper remains about participation and inequality; downstream outcomes are optional.

---

## 8. Deliverables (What This Produces)

- A clean school-year panel dataset for WA (and a control state if feasible)
- A set of main results:
  - Fee levels / waiver generosity → participation gap (WA-only)
  - Policy period (Post) → overall participation (DiD)
- Robustness checks (pre-trends, alternative controls, sample restrictions)
- A clear policy and economics interpretation: user fees, targeted subsidies, and access inequality

---

## 9. Next Step Checklist (Immediate)

1) Confirm the exact years where HB 1660 reporting is consistently available across districts/schools.
2) Identify 1–3 plausible control states with comparable participation reporting (shortlist).
3) Do a “pilot scrape” for ~10 WA schools across 2–3 years to verify fields and missingness.
4) Decide the main outcomes:
   - Must-have: overall participation and gap (WA)
   - Nice-to-have: DiD overall participation (WA vs control)