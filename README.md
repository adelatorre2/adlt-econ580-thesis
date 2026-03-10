# ECON 580 Thesis

This is the repo for everything related to my thesis. Very much a work in progress at the moment, but welcome to browse as I am working on this.



So right now I am exploring whether

Are expedited review programs disproportionately used for controlled substances?

Potentially also whether PDUFA increase the approval of controlled substances?



PDUFA and controlled-substance drug entry:
policy shock
→ FDA approvals
→ controlled-substance supply

otherwise: Priority review and drug safety outcome or Controlled-substance approvals and opioid mortality

# ECON 580 Thesis

This repository contains all code, notes, literature, and data work related to my undergraduate economics thesis (ECON 580). The project is currently in development and this document serves as a high‑level description of the research direction, core questions, and relevant literature.

---

# Current Thesis Direction

This thesis studies whether regulatory policies designed to accelerate FDA drug approvals changed the *composition* of drugs entering the U.S. market, focusing specifically on drugs with abuse potential (i.e., controlled substances).

Beginning with the **Prescription Drug User Fee Act (PDUFA) of 1992**, the FDA began collecting user fees from pharmaceutical firms in exchange for meeting review-time performance goals. This reform substantially increased FDA resources and reduced drug review times.

While a large literature evaluates the **speed–safety tradeoff** associated with faster drug approval, much less work examines whether regulatory acceleration may have changed *which types of drugs* enter the market.

This project investigates whether faster regulatory approval increased the entry of drugs that fall under the **Controlled Substances Act (CSA)** schedules, potentially affecting downstream drug supply and misuse risks.

---

# Draft Abstract (Working)

Regulatory reforms aimed at accelerating pharmaceutical innovation may generate unintended downstream consequences. The Prescription Drug User Fee Act (PDUFA) of 1992 introduced industry user fees and review-time performance goals that substantially reduced FDA drug approval times. While prior research primarily evaluates the tradeoff between faster approval and post‑marketing safety outcomes, relatively little attention has been given to how regulatory acceleration may affect the *composition* of drugs entering the market.

This paper examines whether policies designed to accelerate FDA drug approvals increased the approval of drugs classified as controlled substances under the U.S. Controlled Substances Act. Using data on FDA drug approvals and regulatory review pathways, the analysis investigates whether the post‑PDUFA period saw disproportionate growth in the approval of drugs with abuse potential. The study also examines whether expedited FDA review pathways—such as priority review and other accelerated programs—are disproportionately used for drugs with abuse potential.

By studying how regulatory acceleration affects the composition of approved pharmaceuticals, the project contributes to the broader literature on pharmaceutical regulation, drug supply, and the unintended consequences of health policy.

---

# Core Research Questions

## Primary Question

Did the **Prescription Drug User Fee Act (PDUFA)** increase the approval of drugs classified as **controlled substances**?

Conceptual mechanism:

PDUFA (1992)
→ faster FDA review times
→ more drug approvals / earlier drug entry
→ increased approvals of drugs with abuse potential

Empirical goal:

Measure whether the share or number of FDA‑approved drugs that are DEA‑scheduled controlled substances increased following the introduction of PDUFA.


## Secondary Question

Are **expedited FDA review programs** disproportionately used for drugs with abuse potential?

Programs of interest include:

- Priority Review
- Fast Track
- Accelerated Approval
- Breakthrough Therapy designation

Empirical goal:

Test whether drugs that fall under controlled substance schedules are more likely to receive expedited review designations.

---

# Key Conceptual Components

## Regulatory Policy Shock

The main institutional change studied in the thesis is the **Prescription Drug User Fee Act (PDUFA) of 1992**, which:

- introduced industry user fees
- expanded FDA review capacity
- imposed review deadlines
- significantly reduced approval times


## Controlled Substances

Drugs will be classified using the **Controlled Substances Act (CSA)** scheduling system administered by the DEA (Schedules I–V).

Key step for the empirical work:

Match FDA‑approved drugs with DEA scheduling classifications.

Important consideration:

The analysis must verify whether classification rules or scheduling practices changed over time and ensure that the definition of "controlled substance" is consistently applied across the study period.

---

# Data Sources (Planned)

Potential datasets for the project include:

**FDA datasets**

- Drugs@FDA approval database
- FDA approval pathways (priority review, accelerated approval, etc.)

**DEA datasets**

- DEA Controlled Substance Scheduling information
- ARCOS retail drug distribution data

**Public health datasets (possible extensions)**

- CDC overdose mortality data
- NFLIS drug seizure data

The primary empirical analysis will likely rely on **drug‑level approval data matched with DEA scheduling classifications**.

---

# Relevant Literature (Initial)

The literature currently being reviewed falls into several categories.

## FDA Regulation and Approval Speed

- Philipson et al. (2008) — Cost‑benefit analysis of PDUFA and the speed–safety tradeoff.
- Carpenter, Zucker, and Avorn (2008) — Evidence that review deadlines affect safety outcomes.
- Olson (2008) — Faster review speed and adverse drug reactions.
- Olson (2009) — PDUFA and U.S. drug launch timing.
- Dranove and Meltzer (1994) — Importance of drugs and approval speed.

## Institutional and Descriptive FDA Literature

- Darrow, Avorn, and Kesselheim (2020) — Historical overview of FDA drug approval and regulatory reforms.

## Drug Policy and Supply‑Side Interventions

- Alpert, Powell, and Pacula (2018) — Supply‑side opioid policy and substitution toward heroin.
- Powell and Pacula (2021) — Long‑run consequences of OxyContin reformulation.
- Dobkin and Nicosia (2009) — Methamphetamine supply disruptions.

## Related Health Policy and Opioid Literature

- Kim (2021) — Prescription drug monitoring programs and heroin deaths.

These papers provide the institutional background and empirical strategies relevant for studying the effects of regulatory policy on drug supply and downstream outcomes.

---

# Repository Structure

The repository currently includes:

- `report/` — thesis manuscript and LaTeX files
- `references/` — bibliography and literature notes
- datasets and exploratory analysis (in progress)

---

# Project Status

This project is currently in the **early research design and literature review stage**.

The immediate goals are:

1. Expand the literature review on FDA approval speed and regulatory policy.
2. Construct a dataset of FDA drug approvals matched with DEA scheduling classifications.
3. Explore descriptive trends in controlled‑substance approvals before and after PDUFA.
4. Develop an empirical strategy to test the main research questions.


---

*Last updated: research direction pivot toward studying regulatory acceleration and controlled‑substance approvals.*
