# Claude Code Task: Populate the Thesis Appendix from Notebook Results

## Your job

Populate `report/sections/appendices.tex` with properly formatted LaTeX appendix sections that document the key quantitative results produced in the three analysis notebooks. The appendix is currently a stub (one `\section{Appendix}` heading with a placeholder comment). You will replace its contents with properly structured, LaTeX-compilable appendix sections.

Do not invent numbers or describe results that are not in the notebooks. Every statistic, table, and figure in the appendix must correspond to something actually produced by the code.

---

## Repo layout you need to know

```
/Users/alexdelatorre/Desktop/econ580-thesis/
├── report/
│   ├── main.tex                  ← top-level document (do not modify)
│   ├── sections/
│   │   └── appendices.tex        ← THE FILE YOU WILL REWRITE
│   └── references/
│       └── adlt-econ580-thesis.bib
├── data/
│   ├── raw/
│   │   ├── dafdata20260313/      ← 12 raw FDA text files
│   │   └── dea_controlled_substances_20260315/  ← scraped DEA HTML/PDF files
│   ├── processed/
│   │   └── fda_backbone.csv      ← 191,265 rows × 59 columns
│   └── intermediate/
│       ├── dea_controlled_substance_reference.csv   ← 1,210 rows
│       ├── dea_source_manifest.csv                  ← 6 rows
│       ├── fda_dea_ingredient_token_audit.csv       ← 4,442 rows
│       ├── fda_dea_active_ingredient_linkage_audit.csv  ← 3,202 rows
│       └── fda_dea_controlled_substance_linkage.csv ← 191,265 rows × 81 columns
└── code/
    └── notebooks/
        ├── 01_fda_backbone_and_scope.ipynb
        ├── 02_fda_descriptive_analysis.ipynb
        └── 03_dea_controlled_substance_linkage.ipynb
```

The main document compiles with:
```
cd /Users/alexdelatorre/Desktop/econ580-thesis/report
latexmk -pdf main.tex
```

The appendices file is included via `\appendix \input{sections/appendices}` at the end of main.tex, after `\printbibliography`.

The document class is `scrartcl`. Packages already loaded in main.tex include: `booktabs`, `tabularx`, `threeparttable`, `longtable`, `pdflscape`, `siunitx`, `graphicx`, `subcaption`, `float`, `enumitem`, `xcolor`, `hyperref`, `cleveref`, `amsmath`, `amssymb`, `mathtools`. Do not add `\usepackage` calls inside appendices.tex — they go in main.tex only.

---

## What the notebooks produced — use these exact numbers

### Notebook 01 (`01_fda_backbone_and_scope.ipynb`)
- Built `data/processed/fda_backbone.csv`: a submission-event panel keyed on `ApplNo + SubmissionType + SubmissionNo`
- Shape: **191,265 rows × 59 columns**
- Source: 12 raw text files from the March 13 2026 Drugs@FDA extract (`dafdata20260313`)
- The 12 files and their roles: `Applications.txt` (application identifiers and sponsor names), `Submissions.txt` (submission events, review priority, submission class), `Products.txt` (product names, active ingredients, forms, strengths), `MarketingStatus.txt` and `MarketingStatus_Lookup.txt` (marketing status codes), `TE.txt` (therapeutic equivalence codes), `SubmissionPropertyType.txt` (orphan and other property flags), `ActionTypes_Lookup.txt` and `Join_Submission_ActionTypes_Lookup.txt` (action type codes), `ApplicationDocs.txt` and `ApplicationsDocsType_Lookup.txt` (document metadata), `SubmissionClass_Lookup.txt` (submission class codes)
- Key design decision: the backbone is a **submission-event panel**, not a drug-approval panel. Supplements (`SUPPL`) outnumber original submissions (`ORIG`) by roughly 6:1.

### Notebook 02 (`02_fda_descriptive_analysis.ipynb`)

These are the exact statistics produced. Use them verbatim.

**Panel-level counts:**
| Metric | Value |
|---|---|
| Submission-event rows | 191,265 |
| Distinct application numbers | 27,662 |
| Distinct sponsor names | 2,205 |
| Distinct drug-name aggregates | 7,152 |
| Distinct active-ingredient aggregates | 3,202 |
| Applications with at least one AP row | 26,539 |
| Applications with at least one TA row | 1,201 |

**Submission type breakdown (full panel):**
| Period | ORIG count | ORIG share | SUPPL count | SUPPL share |
|---|---|---|---|---|
| Before 1992 | 7,041 | 14.1% | 42,919 | 85.9% |
| 1992 and after | 20,390 | 14.4% | 120,909 | 85.6% |

**Application type shares at selected years (submission-event level):**
| Year | ANDA | BLA | NDA | UNKNOWN |
|---|---|---|---|---|
| 1980 | 5.0% | 1.3% | 85.8% | 7.9% |
| 1985 | 34.8% | 0.4% | 62.3% | 2.5% |
| 1990 | 55.0% | 0.6% | 40.8% | 3.6% |
| 1992 | 60.9% | 0.5% | 34.7% | 3.9% |
| 1995 | 51.2% | 1.4% | 43.8% | 3.7% |
| 2000 | 54.3% | 2.0% | 42.8% | 0.9% |
| 2010 | 55.3% | 4.2% | 39.5% | 1.0% |
| 2020 | 71.4% | 4.8% | 23.5% | 0.3% |
| 2025 | 70.2% | 7.5% | 21.8% | 0.5% |

**Missingness in selected key fields:**
| Field | Missing N | Missing Share |
|---|---|---|
| ReviewPriority\_raw | 82,442 | 43.1% |
| has\_orphan\_property | 48,442 | 25.3% |
| SubmissionClassCode | 12,431 | 6.5% |
| DrugName\_list | 5,737 | 3.0% |
| ActiveIngredient\_list | 5,737 | 3.0% |
| ApplType\_raw | 5,361 | 2.8% |
| SponsorName | 5,361 | 2.8% |
| SubmissionStatusDate | 6 | 0.0% |
| submission\_status\_year | 6 | 0.0% |
| SubmissionStatus | 1 | 0.0% |
| ApplNo | 0 | 0.0% |
| SubmissionType | 0 | 0.0% |
| SubmissionNo | 0 | 0.0% |

**Review priority (full panel):**
| Category | N | Share |
|---|---|---|
| STANDARD | 93,661 | 49.0% |
| MISSING | 82,442 | 43.1% |
| PRIORITY | 11,092 | 5.8% |
| UNKNOWN | 3,108 | 1.6% |
| OTHER RAW CODE | 962 | 0.5% |

**Sponsor concentration:**
- Top 10 sponsors: 19.6% of submission-event rows, 14.5% of distinct applications
- Total distinct sponsors: 2,205

**Application-level sensitivity check:**
- Distinct applications: 27,662
- Applications with any AP (approved) row: 26,539
- Applications with any TA (tentative approval) row: 1,201
- Median submission rows per application: 3
- Mean submission rows per application: 6.91

**Orphan property:**
- All submission-event rows: 191,265
- Rows with any observed submission-property information: 142,823
- Rows flagged with orphan property: 3,430
- Share orphan among all rows: 2.4%
- Share orphan among rows with observed property info: 2.4%

**Observed categories (full panel):**
- SubmissionType: SUPPL = 163,831; ORIG = 27,434
- SubmissionStatus: AP = 190,051; TA = 1,213; MISSING = 1
- ApplType\_clean: ANDA = 99,441; NDA = 80,915; BLA = 5,548; UNKNOWN = 5,361
- Year range: 1939 to 2026

**Uniqueness check:**
- Rows in processed file: 191,265
- Duplicate submission-event keys: 0
- Rows with any missing key component: 0

### Notebook 03 (`03_dea_controlled_substance_linkage.ipynb`)

**DEA source manifest (6 sources preserved locally):**
| Source name | Role |
|---|---|
| DEA controlled substance schedules page | Scope and caveat source |
| DEA conversion factors for controlled substances | Primary parsed reference (741 raw rows) |
| DEA scheduling actions in alphabetical order | Secondary PDF reference |
| DEA controlled substances by drug code | Secondary PDF reference |
| DEA controlled substances by CSA schedule | Secondary PDF reference |
| DEA exempted prescription products table | Edge-case reference |

**DEA parsed reference (from conversion factors table):**
- Raw rows in DEA conversion-factor table: 741
- Candidate rows in parsed DEA reference: 1,210
- Unique DEA source names: 741
- Unique DEA candidate strings: 919
- Candidate rows flagged as CSA Schedules I–V: 1,197
- Candidate rows flagged as List I chemicals: 13

**DEA schedule breakdown:**
| Schedule | Unique DEA source names |
|---|---|
| I | 399 |
| II | 182 |
| IV | 110 |
| III | 32 |
| List I | 11 |
| V | 7 |

**FDA-side ingredient scope:**
- Distinct ActiveIngredient\_list values: 3,202
- Distinct values containing a semicolon (multi-ingredient): 686
- Distinct values containing a pipe: 7
- Distinct values containing a comma: 74
- Distinct values with mixed delimiters: 18

**Confident match methods (token-level):**
| Match method | Token count |
|---|---|
| exact | 176 |
| normalized\_root\_exact | 5 |
| exact\_alias\_fragment | 2 |

**Final linkage results (row-level, attached to all 191,265 backbone rows):**
| Linkage status | Row count |
|---|---|
| no\_dea\_signal\_from\_first\_pass | 166,098 |
| confident\_scheduled\_controlled\_substance\_match | 17,395 |
| no\_active\_ingredient\_available\_in\_fda\_backbone | 5,737 |
| possible\_parent\_or\_isomer\_candidate\_only | 1,421 |
| list\_i\_chemical\_only\_match | 614 |

**Ingredient-aggregate level:**
- Distinct ingredient aggregates with confident controlled-substance match: 144
- Distinct ingredient aggregates with List I only match: 23
- Distinct ingredient aggregates with possible candidate only: 49

**Intermediate export manifest:**
| File | Rows |
|---|---|
| dea\_controlled\_substance\_reference.csv | 1,210 |
| dea\_source\_manifest.csv | 6 |
| fda\_dea\_ingredient\_token\_audit.csv | 4,442 |
| fda\_dea\_active\_ingredient\_linkage\_audit.csv | 3,202 |
| fda\_dea\_controlled\_substance\_linkage.csv | 191,265 |

---

## What to write in appendices.tex

Structure the appendix as three clearly labelled subsections inside the already-opened `\section{Appendix}` command (the main.tex calls `\appendix` then `\input{sections/appendices}`, so `\section` gives you Appendix A automatically under scrartcl). Use `\subsection` for each notebook's content.

### Appendix A.1 — FDA Backbone Construction
Document the data source and construction decisions from Notebook 01. Include:
- A brief paragraph describing the 12 raw files, the March 13 2026 Drugs@FDA extract, and the backbone design
- A `booktabs` table listing each of the 12 raw source files and their roles in the backbone
- A `booktabs` summary table of the final backbone dimensions (rows, columns, key range)

### Appendix A.2 — Descriptive Analysis of the FDA Submission-Event Panel
Document the key descriptive statistics from Notebook 02. Include:
- A paragraph restating the unit of observation (submission-event, not drug) and the panel span (1939–2026)
- A `booktabs` table of panel-level counts (the 7-metric count table above)
- A `booktabs` table of the submission type breakdown before/after 1992
- A `booktabs` table of application type shares at selected years (ANDA/BLA/NDA/UNKNOWN)
- A `booktabs` table of missingness in key fields
- A `booktabs` table of review priority distribution
- A brief paragraph on sponsor concentration and the orphan property signal with inline numbers (no separate table needed for these)

### Appendix A.3 — DEA Controlled-Substance Linkage
Document the linkage strategy and results from Notebook 03. Include:
- A paragraph describing the linkage approach: active-ingredient token matching against the DEA conversion factors table, why this source was chosen, and the DEA's own caveat that the list is not comprehensive
- A `booktabs` table of the DEA source manifest (6 sources and their roles)
- A `booktabs` table of the DEA reference composition (schedule breakdown by count)
- A `booktabs` table of the final row-level linkage results (the 5 linkage-status categories and counts)
- A `booktabs` table of the intermediate file export manifest
- A paragraph explicitly stating the limitations: the linkage uses current DEA schedules (not historical), does not capture preparation-specific exemptions, and treats possible-candidate rows as an audit queue rather than confident matches

---

## LaTeX requirements

- Use `\subsection` for each of the three appendix sections
- Use `booktabs` tables (`\toprule`, `\midrule`, `\bottomrule`) — the package is already loaded
- Wrap each table in `\begin{table}[H]` with `\centering` and a `\caption{}` and `\label{tab:appX}` so they can be cross-referenced from the main text later
- For tables with many rows, prefer `longtable` if needed (package already loaded), but for tables under ~20 rows, standard `tabular` is fine
- Use `\num{}` from `siunitx` to format large integers (e.g. `\num{191265}`) — the package is already loaded with `detect-all` and `group-minimum-digits=4`
- Use `\%` for percent signs inside tabular cells
- Do not use `\usepackage` — all packages are already in main.tex
- Do not add `\begin{document}` or `\end{document}` — appendices.tex is an included file
- Do not modify main.tex
- Every label should follow the pattern `tab:app-XXX` (e.g. `tab:app-backbone-sources`, `tab:app-panel-counts`)

---

## After writing the file, verify compilation

Run:
```bash
cd /Users/alexdelatorre/Desktop/econ580-thesis/report
latexmk -pdf main.tex 2>&1 | tail -20
```

If there are LaTeX errors, fix them and recompile until the document compiles cleanly. Common issues to watch for:
- `siunitx` `\num{}` inside tabular cells sometimes needs `\sisetup{detect-all}` — already set in main.tex, so this should be fine
- `longtable` does not accept `[H]` float specifier — if you use `longtable`, drop the `[H]`
- Unescaped `_` (underscores) in column names or text must be written as `\_` or wrapped in `\texttt{}`
- Percent signs in table cells must be `\%`
- Ampersands in table rows must be `&` (not `and`)
- Make sure `\label{}` comes after `\caption{}`, not before

Once the document compiles without errors, confirm the PDF contains the new appendix sections by checking the output.
