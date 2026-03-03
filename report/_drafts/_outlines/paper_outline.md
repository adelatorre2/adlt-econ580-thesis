

# Paper Outline + Introduction Blueprint
**Working topic:** Regulatory speed and diversion risk in U.S. drug markets

This file is a **writing scaffold** for the *Introduction* (and the minimum surrounding sections needed to make the intro land). It is intentionally **question-driven** so you can draft in LaTeX while checking off what you’ve actually said.

---

## 0) One-sentence thesis claim (keep this fixed)
> I test whether drugs reviewed faster by the FDA (e.g., Priority vs Standard review classification and/or other expedited flags) exhibit faster post-approval growth in legal retail distribution and stronger downstream diversion/illicit-market signals, using a drug × state × time panel constructed from FDA approval records, ARCOS retail distribution summaries, and NFLIS drug-report indicators.

**Non-negotiable discipline:** You are not claiming that “speed is randomly assigned.” You are claiming you can measure **post-approval dynamics** and evaluate whether they differ systematically by review classification, with transparent assumptions and robustness checks.

---

## 1) What your Introduction must accomplish (economics framing)
By the end of the introduction, a reader should know:

1. **The economic problem:** Regulatory speed changes *market entry timing* and the *availability/returns* environment for legal and illicit actors.
2. **Why we care:** diversion/misuse imposes externalities (public health, enforcement, welfare losses) and interacts with supply.
3. **What is novel:** a new linkage/measurement exercise that merges regulatory “speed” with downstream distribution and illicit signals at scale.
4. **What you do:** describe your panel, outcomes, and the empirical strategy at a high level.
5. **What is (and is not) identified:** reduced-form dynamics + careful interpretation; you will not oversell causality.
6. **What the paper contributes:** (i) dataset + (ii) descriptive/event-time evidence + (iii) normalization and measurement choices consistent with data caveats.

---

## 2) Introduction structure (recommended: 7 paragraphs)
### Paragraph 1 — Hook + core question (welcome the reader)
**Goal:** establish the tension: faster approval can be welfare-improving medically, but may shift downstream incentives.

**Questions to answer (write 2–4 sentences):**
- What does “regulatory speed” mean in the policy discourse?
- Why might speed matter outside the clinic (availability, marketing, composition of products)?
- What is your central research question in one clean line?

**Draft starter (optional):**
- “Expedited FDA pathways are designed to speed therapies to patients. But speed also shifts the timing and conditions under which products enter markets—potentially altering incentives for diversion and illicit supply.”

### Paragraph 2 — Economics mechanism (make it econ, not admin)
**Goal:** translate into applied micro language: speed is a shock to availability; diversion is a response to incentives.

**Questions to answer:**
- What are the economic actors? (manufacturers, prescribers, distributors, diversion networks, counterfeiters, enforcement)
- What are the margins? (availability/timing, expected returns, local illicit demand, enforcement intensity)
- What are the testable implications you will operationalize (supply growth, illicit signal growth)?

### Paragraph 3 — Why it matters (policy + welfare)
**Goal:** show welfare relevance without promising long-run individual outcomes.

**Questions to answer:**
- What are the externalities you are proxying (not fully measuring)?
- Why should regulators/economists care about the downstream channel?
- What would change if your results show no relationship vs a strong relationship?

### Paragraph 4 — Institutional background (only what you need)
**Goal:** define “speed” and why your measure is credible.

**Questions to answer:**
- Which “speed” measure do you use first (Priority vs Standard) and why is it clean?
- What are other optional measures (Accelerated Approval time-to-approval) and how might you use them as sensitivity/secondary analysis?
- What is the key selection/endogeneity issue (serious conditions/unmet need; therapeutic area differences) that you will address via design/controls/interpretation?

### Paragraph 5 — Data advantage (sell the feasibility)
**Goal:** explain that your contribution is *measurable* and *repeatable*.

**Questions to answer:**
- What is each dataset measuring in one line?
  - FDA: approval timing + review classification
  - ARCOS: distribution to retail/dispensing registrants (legal supply proxy)
  - NFLIS: law-enforcement lab identifications (illicit presence proxy)
- What is your unit of observation (drug/substance × state × quarter/year)?
- What is your core outcome construction (e.g., ARCOS grams per 100k; NFLIS share/rate to address reporting cautions)?

### Paragraph 6 — Empirical approach (high-level, not full methods)
**Goal:** signal credible design choices and what you’ll show in Figure 1.

**Questions to answer:**
- What is the main comparison? (post-approval trajectories by review class)
- What is your baseline estimator? (event-time / stacked cohorts; avoid overselling TWFE if you can)
- What are the key diagnostics? (placebos, sensitivity to normalization, heterogeneity)
- What is the main limitation? (selection into expedited review; measurement limits)

### Paragraph 7 — Contribution + roadmap
**Goal:** state contributions as a bullet list (2–3 items), then preview the paper.

**Contribution bullets (examples):**
- Build a merged panel linking FDA review classification and approval timing to ARCOS retail distribution and normalized NFLIS illicit signals.
- Provide event-time evidence on whether expedited review classifications are associated with steeper post-approval legal supply growth and stronger illicit presence signals.
- Document measurement choices and limitations (ARCOS ≠ patient consumption; NFLIS ≠ prevalence) and show robustness to alternative normalizations and samples.

**Roadmap sentence:** “Section 2 describes institutional background; Section 3 describes data and construction; Section 4 outlines the empirical strategy; Section 5 presents results and robustness; Section 6 concludes.”

---

## 3) “Intro checklist” (copy/paste into LaTeX comments)
- [ ] Defined “speed” in my own words + stated operational measure (Priority vs Standard).
- [ ] Explained why speed is an economic shock (timing/availability/incentives).
- [ ] Explained what diversion proxy means (and what it does *not* mean).
- [ ] Named data sources (FDA, ARCOS, NFLIS) and what each measures.
- [ ] Stated unit of observation and basic time span.
- [ ] Stated empirical design at a high level (event-time dynamics; DiD logic).
- [ ] Flagged selection/endogeneity + measurement limitations explicitly.
- [ ] Claimed contributions modestly and honestly.

---

## 4) What belongs in “Background” vs “Literature” (so the intro stays tight)
### Background / Institutional (what the world looks like)
- What expedited pathways are and what “Priority review timelines” mean.
- What ARCOS measures (distribution to registrants) and key caveats.
- What NFLIS measures (lab identifications) and key caveats + why shares/rates.

### Literature (what economists already know)
Organize literature into 3 mini-buckets (each 1 paragraph in the lit review section, not in the intro):
1. **Regulatory speed and evidence tradeoffs** (approval speed vs evidentiary standards).
2. **Legal supply and illicit markets / diversion** (how legal channels and enforcement interact with illicit markets).
3. **Methods / measurement** (event studies, staggered adoption pitfalls, using shares/rates to address reporting changes).

---

## 5) What you should NOT promise in the introduction
- Do **not** claim you measure “diversion” directly.
- Do **not** claim ARCOS equals consumption or misuse.
- Do **not** claim NFLIS equals prevalence of use.
- Do **not** claim causal effects of expedited review without qualifying assumptions.

Instead, use language like:
- “consistent with,” “associated with,” “post-approval dynamics,” “reduced-form,” “proxy,” “signal.”

---

## 6) Figure 1 + Table 1 (intro should foreshadow these)
### Figure 1 (anchor)
Event-time plot around approval:
- y: ARCOS grams per 100k (log optional)
- x: quarters relative to approval
- lines: Priority vs Standard (or expedited vs non-expedited)

### Table 1 (credibility)
Drug-level summary stats:
- count of substances in sample by review class
- median ARCOS in first 4 post-approval quarters
- median NFLIS share in years 1–3 post-approval
- approval-year distribution

---

## 7) Mini-template: a “first-pass” intro you can draft in 30–45 minutes
Use the paragraph plan above. If you get stuck, draft **only the topic sentences** first (one per paragraph), then fill.

**Topic sentences (fill in later):**
1. Expedited approval is designed to speed access, but speed may also change downstream diversion incentives.
2. Economically, speed shifts market entry timing and availability, affecting expected returns for diversion and enforcement.
3. Diversion externalities motivate examining downstream channels of regulatory design.
4. I operationalize regulatory speed using FDA review classifications (Priority vs Standard) and related expedited indicators.
5. I construct a new drug×state×time panel linking FDA approval timing to ARCOS distribution and normalized NFLIS illicit signals.
6. I estimate post-approval dynamics using an event-time design and assess robustness/heterogeneity.
7. The paper contributes a merged dataset and evidence on whether faster review classifications coincide with steeper post-approval supply growth and illicit presence signals.

---

## 8) Immediate next step (today)
1) Draft the 7 intro paragraphs in LaTeX (ugly draft is fine).
2) Create a Zotero tag `must_cite_intro` and assign it to the 8–12 sources you will cite in the intro.
3) Make sure the intro includes one sentence each clarifying:
   - ARCOS ≠ consumption
   - NFLIS ≠ prevalence
   - expedited review ≠ random assignment
