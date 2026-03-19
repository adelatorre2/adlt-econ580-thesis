# ECON 580 Thesis — Professor Meeting Notes

**Date:** March 19, 2026
**Topic:** Moving from descriptive to causal — next steps for the thesis

---

## Where We Are Now

### Data Infrastructure (Complete)
- **FDA backbone**: ~191K submission-event rows from Drugs@FDA (Applications, Products, Submissions, Marketing Status, TE codes, Submission Properties, Action Types, Application Docs)
- **DEA linkage**: Every FDA row enriched with controlled substance flags via normalized active-ingredient token matching against DEA schedules
- **Confidence tiers**: Confident scheduled matches, List I chemicals, uncertain substring/parent-compound candidates, and clean non-matches
- Three notebooks documenting the full pipeline with audit trails

### Writing (In Progress)
- Introduction drafted — covers FDA institutional context, Hatch–Waxman, PDUFA, controlled substance public health stakes, and the research question
- Literature review covers Philipson et al., Carpenter et al., Olson, Dranove & Meltzer, Darrow et al. on the FDA speed-safety tradeoff, plus Alpert et al. on supply-side drug policy
- LaTeX manuscript structure in place with sectioned .tex files

### The Problem
- The project is currently **descriptive**: we can show trends in the composition of FDA approvals over time, split by controlled vs. non-controlled
- Professor is asking: **what is the causal question?** What policy-relevant mechanism are we identifying?

---

## Potential Causal Directions

### Direction 1: Composition DiD (Most Feasible — No New Data Needed)

**Question:** Did PDUFA disproportionately increase the share of controlled substances among new FDA approvals?

**Setup:**
- Panel of FDA approval counts by year, split by controlled vs. non-controlled
- "Treatment": PDUFA enactment (1992) — speeds up review for all drugs
- "Differential effect": test whether controlled substances saw a larger increase in approvals relative to non-controlled drugs
- Identifying assumption: parallel pre-trends in controlled vs. non-controlled approval shares before 1992

---

## Detailed Specification Sketch — Direction 1 (Composition DiD)

### The Equation

$$Y_{ct} = \alpha + \beta_1 \cdot \text{Controlled}_c + \beta_2 \cdot \text{PostPDUFA}_t + \beta_3 (\text{Controlled}_c \times \text{PostPDUFA}_t) + \gamma X_{ct} + \epsilon_{ct}$$

This is a standard two-group, two-period difference-in-differences specification. The unit of observation is a **drug category $c$ in year $t$**, where we have two categories (controlled substances vs. non-controlled substances) observed across many years. Below is a detailed breakdown of every component.

---

### Outcome Variable: $Y_{ct}$

**What it measures:** The number (or share) of new drug approvals for drug category $c$ in year $t$.

**What the data needs to look like to construct this:**

We collapse our 191K-row submission-level panel down to a **category-by-year** panel. Specifically:

1. **Filter to the analytic sample.** We restrict to rows where:
   - `is_approved == True` (the submission resulted in an actual FDA approval)
   - `is_original_submission == True` (this is the first submission for the application — i.e., a new drug entering the market, not a supplement or labeling change)
   - `ApplType_clean` is in {NDA, ANDA, BLA} (standard drug application types — excludes unknown/unclassifiable legacy records)

   This gives us **~25,115 original approved submissions** spanning 1939–2026. These represent distinct new drug market entries.

2. **Classify each row as controlled or non-controlled** using the `dea_confident_controlled_match_flag` column from our DEA linkage. In the analytic sample, roughly **2,092 rows** (~8.3%) are confidently matched as controlled substances; 23,023 are non-controlled.

3. **Collapse to category × year.** For each year $t$ and each category $c \in \{\text{controlled}, \text{non-controlled}\}$, compute:
   - **Count version:** $Y_{ct}$ = number of approved original submissions in that category-year cell
   - **Share version:** $Y_{ct}$ = (controlled approvals in year $t$) / (total approvals in year $t$) — this version only varies across $t$, not $c$, so it would use a simpler time-series specification

   The count version gives us a two-row-per-year panel (one row for controlled, one for non-controlled) for each year from roughly 1939 to 2025. In practice we would likely start the window around 1970 or 1980 to have a stable pre-period with meaningful controlled substance classification.

**Which version to prefer:** The count version is more standard for DiD because it lets us estimate separate group-level effects. The share version is useful for descriptive plots but collapses the cross-sectional variation.

---

### $\alpha$ — The Intercept (Constant Term)

**What it measures:** The baseline expected number of new drug approvals for the **non-controlled substance** category in the **pre-PDUFA** period.

**Interpretation:** When $\text{Controlled}_c = 0$ and $\text{PostPDUFA}_t = 0$, the predicted value is just $\alpha$. So this captures the average annual approval count for non-controlled drugs before 1992.

**In our data:** This would reflect the average number of non-controlled NDA/ANDA/BLA original approvals per year in, say, the 1970–1991 window.

---

### $\beta_1$ — The Controlled Substance Group Effect

**What it measures:** The **time-invariant level difference** between controlled substance approvals and non-controlled substance approvals in the pre-PDUFA period.

**Interpretation:** Before PDUFA was enacted, were there systematically more or fewer controlled substance approvals per year compared to non-controlled approvals? We would expect $\beta_1 < 0$ because controlled substances are a smaller category — there are simply fewer of them being approved in any given year.

**What it captures:** This is not a causal parameter. It just accounts for the fact that the two groups start at different levels. In our data, controlled substances make up only ~8% of original approvals, so the controlled group will have a much lower count baseline.

**What the data needs:** The `dea_confident_controlled_match_flag` column directly gives us this binary split. Each row in the collapsed panel gets $\text{Controlled}_c = 1$ if it's the controlled substance row for that year, and $\text{Controlled}_c = 0$ if it's the non-controlled row.

---

### $\beta_2$ — The Post-PDUFA Time Effect

**What it measures:** The **change in non-controlled substance approvals** after PDUFA, relative to before PDUFA.

**Interpretation:** This captures any time trend affecting drug approvals generally. If the FDA was approving more drugs overall after 1992 — whether because of PDUFA, industry growth, or other secular trends — $\beta_2$ picks that up for the non-controlled group.

**What the data needs:** We define $\text{PostPDUFA}_t = 1$ if $t \geq 1993$ (the first full year under PDUFA implementation, since PDUFA was enacted October 1992 and performance goals took effect in FY1993) and $\text{PostPDUFA}_t = 0$ otherwise. This comes directly from the `submission_status_year` column.

**Important nuance:** $\beta_2$ is NOT the causal effect of PDUFA on approvals generally — it's confounded by all other time-varying factors. It's a control parameter that lets us difference out common time trends so that $\beta_3$ isolates the differential effect.

---

### $\beta_3$ — The Difference-in-Differences Estimate (The Key Parameter)

**What it measures:** The **additional change** in controlled substance approvals after PDUFA, **beyond** whatever change non-controlled substances experienced. This is the causal parameter of interest.

**Interpretation:** If $\beta_3 > 0$ and statistically significant, it means that controlled substance approvals grew by more than non-controlled substance approvals after PDUFA was enacted. This would be evidence that PDUFA disproportionately increased the flow of controlled substances through the FDA pipeline.

**The DiD logic spelled out:**
- (Average controlled approvals post-PDUFA) − (Average controlled approvals pre-PDUFA) = Total change for controlled group
- (Average non-controlled approvals post-PDUFA) − (Average non-controlled approvals pre-PDUFA) = Total change for non-controlled group
- $\beta_3$ = (Total change for controlled) − (Total change for non-controlled)

This double-differencing removes: (a) any time-invariant differences between the two groups ($\beta_1$ handles this), and (b) any common time shocks affecting both groups equally ($\beta_2$ handles this). What remains is the differential treatment effect — the piece attributable to something that affected controlled substances differently from non-controlled substances around the time of PDUFA.

**What the data needs:** This is the interaction term $\text{Controlled}_c \times \text{PostPDUFA}_t$, which equals 1 only for controlled substance observations in post-1992 years. No new data needed — it's computed from the two variables above.

**What would make $\beta_3$ credible as causal:**
- **Parallel pre-trends.** Before 1992, the controlled and non-controlled approval series should move roughly in parallel (or at least not diverge). If they were already diverging pre-PDUFA, $\beta_3$ is contaminated by a pre-existing trend. We can test this by plotting both series and/or running an event-study version (see below).
- **No contemporaneous confounders.** Nothing else around 1992 should have differentially affected controlled substance approvals. The biggest threat is the pain management movement of the 1990s (increased clinical acceptance of opioid prescribing), which could independently drive more controlled substance applications. This is a limitation to acknowledge.

---

### $\gamma X_{ct}$ — Control Variables

**What they measure:** Observable characteristics of the approval pool in each category-year cell that might confound the relationship between PDUFA and controlled substance approvals.

**Candidate controls and where they come from in the data:**

1. **Review priority composition** — Constructed from `ReviewPriority_clean`. For each category-year cell, compute the share of approvals that received Priority Review vs. Standard Review. This controls for the possibility that changes in what the FDA prioritizes (e.g., more Priority Reviews for all drugs over time) could mechanically shift composition.

2. **Application type mix** — Constructed from `ApplType_clean`. For each cell, compute the share that are NDAs vs. ANDAs vs. BLAs. The Hatch-Waxman Act (1984) massively expanded ANDA filings; if controlled substances were disproportionately NDAs vs. ANDAs, the application type mix could confound the PDUFA effect.

3. **Orphan drug designation share** — Constructed from `has_orphan_property`. The Orphan Drug Act (1983) created incentives for rare disease drugs. If orphan designations trend differently for controlled vs. non-controlled, this could confound.

4. **Year fixed effects (alternative to $\beta_2$)** — Instead of a single PostPDUFA dummy, we could include a full set of year dummies $\delta_t$. This absorbs ALL common time variation (not just a before/after shift), making the identifying variation purely cross-sectional: within each year, did the controlled substance share shift differentially? This is the more flexible and standard modern approach.

**What the data needs:** All of these are already in our backbone. We just aggregate them to the category-year level (e.g., "share of controlled substance approvals in 2003 that had Priority Review").

---

### $\epsilon_{ct}$ — The Error Term

**What it captures:** Everything that affects approval counts that we haven't modeled — unobserved demand-side shifts in disease burden, firm-level strategic behavior, FDA staffing changes, etc.

**Inference considerations:**
- With only ~50–80 year observations and 2 groups, we have a relatively small panel. Standard errors should be clustered at the year level (or the category level, though with only 2 clusters that's problematic).
- A common concern with DiD on aggregate time series is serial correlation (Bertrand, Duflo & Mullainathan, 2004). With few time periods, we may want to use Newey-West standard errors or collapse to a simple pre/post comparison.
- Alternatively, we could run the specification at the **submission level** (each row is an individual drug approval), with the outcome being a binary indicator $Y_{it} = 1$ if drug $i$ approved in year $t$ is a controlled substance. This gives us more observations but changes the interpretation to a linear probability model of the probability that any given approved drug is a controlled substance.

---

### Event-Study Extension (Recommended for Credibility)

Instead of a single post-PDUFA dummy, replace $\beta_2$ and $\beta_3$ with a set of **year-specific DiD coefficients**:

$$Y_{ct} = \alpha + \beta_1 \cdot \text{Controlled}_c + \sum_{k} \delta_k \cdot \mathbb{1}[t = k] + \sum_{k} \gamma_k \cdot (\text{Controlled}_c \times \mathbb{1}[t = k]) + \epsilon_{ct}$$

**What $\gamma_k$ measures:** The difference between controlled and non-controlled approvals in year $k$, relative to a reference year (typically 1991, the last pre-PDUFA year).

**Why this is important:**
- The sequence of $\gamma_k$ coefficients for $k < 1992$ tests the **parallel trends assumption**. If those pre-period coefficients are statistically indistinguishable from zero, we have evidence that the two groups were tracking each other before PDUFA.
- The $\gamma_k$ coefficients for $k \geq 1993$ show the **dynamic treatment effect** — whether the divergence was immediate, gradual, or delayed. This is more informative than a single $\beta_3$ that averages over the entire post-period.
- These event-study plots are essentially expected in applied micro papers now. Your professor will likely want to see one.

**What the data needs:** Exactly the same data as above. We just replace the single PostPDUFA dummy with year indicators interacted with the controlled dummy.

---

### Submission-Level Alternative Specification

Instead of collapsing to category-year, run the regression at the **individual submission level**:

$$\text{Controlled}_{it} = \alpha + \sum_k \delta_k \cdot \mathbb{1}[t_i = k] + \gamma X_i + \epsilon_{it}$$

Here:
- Each observation $i$ is an individual approved original submission
- $\text{Controlled}_{it} \in \{0, 1\}$ is whether drug $i$ approved in year $t$ is a controlled substance
- The year dummies $\delta_k$ trace out how the probability of a newly approved drug being a controlled substance changes over time
- $X_i$ = submission-level controls: `ApplType_clean`, `ReviewPriority_clean`, `has_orphan_property`, `SubmissionClassCode`

**Advantage:** Uses all ~25,115 observations, allows submission-level controls, standard errors are more straightforward.

**Disadvantage:** The dependent variable is binary, so this is a linear probability model (or use logit/probit). The identification is the same — we're still asking whether the controlled substance share shifts around PDUFA.

---

### What Needs to Be True in the Data for This to Work

| Requirement | Status | Notes |
|---|---|---|
| Sufficient pre-PDUFA observations | **Yes** | Data goes back to 1939; even restricting to 1970+ gives 20+ pre-treatment years |
| Enough controlled substance approvals per year to estimate effects | **Check** | ~2,092 controlled in full sample; need to verify annual counts aren't too sparse pre-1992 |
| Clean controlled/non-controlled classification | **Mostly** | `dea_confident_controlled_match_flag` is our primary classifier; ~1,421 ambiguous "possible candidate" rows need a decision — include, exclude, or sensitivity test |
| Parallel pre-trends | **Must test** | Plot controlled vs. non-controlled approval counts by year pre-1992 and eyeball / formally test |
| No contemporaneous confounders | **Concern** | Pain management movement (1990s), Hatch-Waxman ANDA growth (post-1984) — need to discuss and address |

---

## Direction 2: Expedited Pathways and Drug Class Selection

**Question:** Are expedited review pathways (Priority Review, Fast Track, Accelerated Approval) disproportionately used for controlled substances?

**Setup:**
- Cross-sectional or panel analysis of which drugs use expedited pathways
- Test whether controlled substance status predicts expedited pathway usage, controlling for therapeutic area, novelty, orphan status

**Why it matters:**
- If expedited pathways systematically channel high-abuse-potential drugs to market faster, that's a design feature of the regulatory system with policy implications
- More granular than the PDUFA DiD — gets at *mechanisms* within the regulatory apparatus

**Data availability:** Already in our backbone (ReviewPriority, SubmissionClassCode, SubmissionPropertyType for orphan/fast track flags)

---

## Direction 3: Post-Market Safety Outcomes (Feasible, Moderate New Data)

**Question:** Do controlled substances approved under faster review timelines accumulate more post-market safety actions?

**Setup:**
- Outcome = post-approval safety supplements, labeling changes, REMS requirements, or FDA safety communications
- Treatment = review speed (instrumented by PDUFA cohort or expedited pathway)
- Test: is the speed → safety-action relationship stronger for controlled substances?

**Data sources:**
- Post-market supplements and labeling changes are partially visible in the Drugs@FDA supplement records (we already have these)
- FDA REMS database is publicly available
- FDA safety communications (MedWatch, Dear Doctor letters) are scrapeable but would take time

**Strengths:** Directly policy-relevant — speaks to whether the speed-safety tradeoff has asymmetric stakes for high-risk drug classes

**Limitations:** Post-market outcomes are noisy and partially endogenous (more scrutinized drugs get more safety actions)

---

## Direction 4: Firm-Level and Market Incentives (Requires IQVIA or Similar)

**Question:** Do firms with controlled substance portfolios respond more aggressively to faster review opportunities?

**Why this is harder:**
- Needs firm-level revenue, pricing, or market share data → typically IQVIA
- IQVIA access uncertain — would need to check UW-Madison Business Library, School of Pharmacy, or specific faculty connections
- Even if accessible, integrating and cleaning IQVIA data by May is ambitious

**Recommendation:** Worth checking access (email business librarian and pharmacy faculty ASAP), but do not make this the core identification strategy. Treat as an enrichment if available.

---

## Suggested Empirical Approach for May Deadline

**Primary specification:** Direction 1 (Composition DiD around PDUFA) — this is the backbone of the paper. Clean, feasible, uses existing data.

**Secondary analysis:** Direction 2 (Expedited pathway selection) — strengthens the mechanism story. Also uses existing data.

**Stretch goal:** Direction 3 (Post-market safety) — adds a welfare dimension. Partially feasible with current data, fully feasible with moderate scraping effort.

**Park for now:** Direction 4 (Firm incentives / IQVIA) — check access but don't depend on it.

---

## Literature to Explore

### For the DiD / Composition Question
- **Berndt et al. (2005)** — "The Impact of Incremental Innovation on Biopharmaceuticals" — looks at how regulatory/market forces shape the *types* of drugs developed
- **Budish, Roin & Williams (2015)** — "Do Firms Underinvest in Long-Run Research?" — uses FDA/clinical trial data to study how commercial incentives distort the direction of pharmaceutical R&D
- **Blume-Kohout & Sood (2013)** — "Market Size and Innovation: Effects of Medicare Part D on Pharmaceutical R&D" — example of how policy shocks change the composition of drug development

### For Expedited Pathways
- **Darrow, Avorn & Kesselheim (2020)** — "FDA Approval and Regulation of Pharmaceuticals, 1983–2018" — comprehensive descriptive analysis of how expedited programs have expanded over time
- **Downing et al. (2014)** — "Postmarket Safety Events Among Novel Therapeutics Approved by the FDA" — directly relevant to the speed-safety question
- **Frank & Zeckhauser (2007)** — "Custom-Made Versus Ready-to-Wear Treatments" — economic framework for thinking about drug differentiation and regulatory incentives

### For the Controlled Substance / Policy Angle
- **Alpert, Powell & Pacula (2018)** — "Supply-Side Drug Policy in the Presence of Substitutes" — already in your bib, but central for framing unintended consequences
- **Schnell (2017/2022)** — "Physician Behavior in the Presence of a Secondary Market" — models how prescriber incentives interact with drug scheduling and diversion risk
- **Maclean et al. (2022)** — various NBER working papers on prescription drug regulation and opioid outcomes

### For Empirical Strategy / Methods
- **Olson (2004/2008)** — uses PDUFA as the policy shock for speed-safety tradeoff — closest methodological precedent to what you're doing
- **Carpenter, Zucker & Avorn (2008)** — "Drug-Review Deadlines and Safety Problems" — exploits PDUFA deadline pressure as quasi-experimental variation
- **Bertrand, Duflo & Mullainathan (2004)** — "How Much Should We Trust Differences-in-Differences Estimates?" — essential methods reference for inference in DiD with few clusters or serial correlation

---

## Key Talking Points for Meeting

1. **We have a strong data foundation** — the FDA-DEA linked panel is built and audited, covering the full universe of Drugs@FDA submissions with controlled substance classification

2. **The most feasible causal strategy is a composition DiD around PDUFA** — did the 1992 reform disproportionately increase controlled substance approvals? We can check parallel pre-trends with our pre-1992 data immediately

3. **The mechanism story works through commercial incentives** — controlled substances (especially opioids, stimulants) are high-revenue drug classes, so firms producing them may have been best positioned to take advantage of faster review

4. **We can strengthen identification** by exploiting within-period variation in expedited pathway usage across drug classes, and by using the staggered PDUFA reauthorizations

5. **The policy relevance is clear** — if the design of drug review institutions systematically favors high-abuse-potential drugs, that's something policymakers should know about when designing future PDUFA reauthorizations

6. **Timeline is realistic** — primary DiD and expedited pathway analysis use existing data; post-market safety analysis is a feasible stretch goal; IQVIA/firm-level work is parked unless access materializes quickly

7. **Immediate next steps:** run pre-trend visualizations for controlled vs. non-controlled approvals, estimate the baseline DiD specification, and audit the DEA linkage confidence tiers to finalize the controlled substance classification
