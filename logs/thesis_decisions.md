# ECON 580 Thesis Decision Log

> This file records **important research, data, and coding decisions** made during the development of the ECON 580 thesis.
>
> Unlike `thesis_context.md`, this file is **historical and append-only**. It functions as a **research notebook** documenting how the project evolved.

---

# Logging Instructions

This file is an append‑only research log documenting meaningful decisions made during the thesis project. Each entry should summarize the outcome of a work session (research, coding, data work, empirical design, or interpretation). Entries should be concise paragraphs that describe: the type of work performed, the context of the problem, the reasoning process, the decision or implementation chosen, the implications for the thesis going forward, any limitations or risks discovered, and the next steps that follow from the decision. New entries must always be added **at the top of the "Decision Entries" section** so the most recent work appears first. Existing entries should never be rewritten unless they were clearly incorrect.

---

# Decision Entries

(Newest entries should always appear **at the top** of this section.)

---

## 2026-03-15 — Full Drugs@FDA audit and unfiltered master panel build

Task completed: the FDA backbone workflow was overhauled from a narrow `ORIG`/`AP` exploratory subset into a documented full-table audit and export pipeline. The main files modified were [code/notebooks/01_fda_backbone_and_scope.ipynb](/Users/alexdelatorre/Desktop/econ580-thesis/code/notebooks/01_fda_backbone_and_scope.ipynb) and [data/processed/fda_backbone.csv](/Users/alexdelatorre/Desktop/econ580-thesis/data/processed/fda_backbone.csv). Data work performed: all 12 tables in `data/raw/dafdata20260313/` were inspected and documented, a malformed row in `ApplicationDocs.txt` was handled explicitly, identifiers were preserved as strings, many-to-one child tables were aggregated before merge, and an unfiltered submission-event master file was exported using `ApplNo + SubmissionType + SubmissionNo` as the unique key. The methodological decision was to treat the submission event as the master observational unit and to save the full panel first, then derive approval-only or original-submission subsets downstream rather than hard-coding those filters into the exported data. The main implication for the thesis is that descriptive work on approvals, supplements, review priority, application type, and later controlled-substance merges can now start from one reproducible processed dataset rather than raw FDA text files. Limitations and risks remain important: Drugs@FDA is still approval-centered rather than a complete universe of failed applications, product descriptors are application-level aggregates rather than exact submission-to-product matches, and some supporting fields remain partially documented or missing lookup support. Suggested next steps are to build the first descriptive analysis notebook from the full master file, generate time-series summaries around 1992/PDUFA, and only then create narrower analytic subsets as needed for the thesis question.


## 2026-03-14 — Introduction restructuring and policy‑context framing

Task completed: the thesis introduction was revised to improve narrative focus and align the manuscript with a conventional empirical economics introduction structure. Earlier draft paragraphs that redundantly described the FDA’s mission and controversies were condensed into a single institutional paragraph introducing the FDA as the regulatory gatekeeper of pharmaceutical markets, drawing on Carpenter (2010) to emphasize the role of institutional reputation in FDA authority. The subsequent paragraph was rewritten to frame the central regulatory tension between drug accessibility and safety/efficacy rather than summarizing individual papers. The revised version situates the thesis within a broader historical policy context by highlighting major legislative responses to this tension, particularly the Hatch–Waxman Act of 1984 and the creation of the ANDA pathway for generic drugs. The paragraph now references Mehl (2006) to acknowledge potential incentive distortions created by these reforms.

Implications: the introduction now follows a clearer logical progression—FDA institutional role → regulatory tradeoff → historical policy reforms (Hatch–Waxman) → PDUFA → public‑health stakes in controlled‑substance markets → thesis research question regarding the composition of FDA drug approvals. The revision removes unnecessary literature summaries and instead uses the literature primarily to frame the policy environment motivating the empirical question.

Next steps: continue refining the introduction once preliminary descriptive results are available so the empirical contribution can be previewed more clearly in the final paragraphs.


## 2026-03-09 — Literature mapping around FDA speed, PDUFA, and thesis positioning

Task completed: a focused literature scan and note-building session clarified which FDA-regulation papers are core to the thesis and how they should be used. The session reviewed and summarized several papers on FDA review speed, PDUFA, approval timing, and safety, including Dranove and Meltzer (1994), Carpenter, Zucker, and Avorn (2008), Darrow, Avorn, and Kesselheim (2020), Olson (2009) on initial U.S. drug launches, and Philipson et al. (2008). The key conceptual decision was to distinguish among three literature roles: (1) institutional and background papers that map the evolution of the FDA approval regime, (2) core economic papers that study the speed–safety tradeoff or the effect of PDUFA on firm behavior and review times, and (3) the still-needed downstream literature on diversion, opioid supply, and illicit market spillovers. The thesis is now more clearly positioned as an extension of the speed–safety literature into a different downstream outcome domain: rather than only asking whether faster review changes safety or launch timing, the project may ask whether regulatory acceleration changes supply conditions in ways that increase diversion risk. Implications: the literature review should be structured around the upstream mechanism `regulatory speed -> firm launch / drug availability / safety tradeoff` before moving to downstream diversion consequences. New limitations and risks identified during this session are that several “core” FDA papers are descriptive or partial-equilibrium rather than causal, many welfare analyses rely on strong assumptions about consumer surplus and safety harms, and the thesis still lacks the second-half literature needed to link approvals to diversion or misuse. Next steps: build a more explicit literature map in the context file, preserve the distinction between background vs core causal papers, and begin collecting the diversion / illicit-market literature needed to connect the FDA approval channel to the final thesis outcome.
