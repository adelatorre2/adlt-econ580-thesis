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

**Specification sketch:**
$$Y_{ct} = \alpha + \beta_1 \cdot \text{Controlled}_c + \beta_2 \cdot \text{Post-PDUFA}_t + \beta_3 (\text{Controlled}_c \times \text{Post-PDUFA}_t) + \gamma X_{ct} + \epsilon_{ct}$$

Where:
- $Y_{ct}$ = count or share of approvals for drug category $c$ in year $t$
- $\beta_3$ = the DiD estimate — did controlled substances see disproportionate growth post-PDUFA?
- $X_{ct}$ = controls (review priority mix, application type shares, therapeutic class trends)

**Strengths:**
- Uses existing data — can start immediately
- Clean policy event with a known date
- Pre-PDUFA data goes back decades for parallel trends checks

**Limitations:**
- PDUFA is a single national policy shock — no cross-sectional variation in treatment
- Many confounds around 1992 (pain management movement, pharma industry consolidation)
- Need to argue why controlled substances would differentially benefit from faster review

**Possible refinements:**
- Use staggered PDUFA reauthorizations (1992, 1997, 2002, 2007, 2012, 2017) as multiple shocks with progressively tighter timelines
- Exploit variation in expedited pathway usage (Priority Review, Fast Track, Accelerated Approval) across drug categories
- Restrict to original NDA approvals only to get cleaner "new market entry" signal

---

### Direction 2: Expedited Pathways and Drug Class Selection

**Question:** Are expedited review pathways (Priority Review, Fast Track, Accelerated Approval) disproportionately used for controlled substances?

**Setup:**
- Cross-sectional or panel analysis of which drugs use expedited pathways
- Test whether controlled substance status predicts expedited pathway usage, controlling for therapeutic area, novelty, orphan status

**Why it matters:**
- If expedited pathways systematically channel high-abuse-potential drugs to market faster, that's a design feature of the regulatory system with policy implications
- More granular than the PDUFA DiD — gets at *mechanisms* within the regulatory apparatus

**Data availability:** Already in our backbone (ReviewPriority, SubmissionClassCode, SubmissionPropertyType for orphan/fast track flags)

---

### Direction 3: Post-Market Safety Outcomes (Feasible, Moderate New Data)

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

### Direction 4: Firm-Level and Market Incentives (Requires IQVIA or Similar)

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

---

## Key Talking Points for Meeting

1. **We have a strong data foundation** — the FDA-DEA linked panel is built and audited, covering the full universe of Drugs@FDA submissions with controlled substance classification

2. **The most feasible causal strategy is a composition DiD around PDUFA** — did the 1992 reform disproportionately increase controlled substance approvals? We can check parallel pre-trends with our pre-1992 data immediately

3. **The mechanism story works through commercial incentives** — controlled substances (especially opioids, stimulants) are high-revenue drug classes, so firms producing them may have been best positioned to take advantage of faster review

4. **We can strengthen identification** by exploiting within-period variation in expedited pathway usage across drug classes, and by using the staggered PDUFA reauthorizations

5. **The policy relevance is clear** — if the design of drug review institutions systematically favors high-abuse-potential drugs, that's something policymakers should know about when designing future PDUFA reauthorizations

6. **Timeline is realistic** — primary DiD and expedited pathway analysis use existing data; post-market safety analysis is a feasible stretch goal; IQVIA/firm-level work is parked unless access materializes quickly

7. **Immediate next steps:** run pre-trend visualizations for controlled vs. non-controlled approvals, estimate the baseline DiD specification, and audit the DEA linkage confidence tiers to finalize the controlled substance classification
