# Working Reserach Idea
> Do participation fees limit low-income students’ access to high school athletics, and do fee-waiver mandates reduce socioeconomic participation gaps? Evidence from Washington’s HB 1660 reporting system, with track/XC state-meet performance as downstream outcomes.

## Conceptual Framing (Labor Market Perspective)

One way to frame this project theoretically is to treat high school athletics — particularly competitive sports like track and cross-country — as a type of labor market. Student-athletes invest in skill development (training, competition, performance signaling), and colleges and universities act as recruiting firms that “hire” skilled athletes through roster spots and, in some cases, athletic scholarships. Performance serves as a signal of productivity, and participation itself is an input into human capital accumulation.

Under this framework, pay-to-play participation fees function as an entry cost into the market. If low-income students face higher effective entry barriers, this may reduce their participation, limit skill development, and weaken their ability to compete for collegiate recruitment opportunities. Fee-waiver mandates, therefore, can be interpreted as policies that reduce barriers to entry in this quasi-labor market. This framing provides an economic rationale for studying both participation gaps and downstream performance outcomes.


## Background
Washington enacted House Bill 1660 (as reflected in legislative documents and OSPI guidance) with three features that are unusually useful for causal inference:

- Fee-waiver policy for low-income students for optional noncredit extracurricular participation/attendance fees (implemented through changes to the state’s fee framework), with OSPI FAQ guidance emphasizing the law’s scope over optional noncredit extracurricular events. 

- Mandatory school-level reporting of athletic participation counts and fee data (including athletic participation fees and discounted fees), with explicit publication timelines in the bill report. 

- “Opportunity gap” goals and a plan requirement: the bill report specifies that the target opportunity gap for ASB-card possession and extracurricular participation reduces from 20 percentage points (2020–21) to 5 percentage points beginning 2024–25, with districts required to develop/publish an “opportunity gap reduction plan” if they do not meet goals. 

## Feasibility Constraints and Research Scope Considerations

A key practical constraint is data availability. While Washington’s HB 1660 reporting system provides school-level data on fees, participation counts, low-income status, and participation gaps, sport-specific athlete-level performance data (e.g., from Athletic.net) may be legally or technically difficult to scrape at scale. This creates tradeoffs in research design.

There are three possible empirical scopes:

1. Participation-Focused Design: Restrict the analysis to school-by-year participation rates and participation gaps across all athletic programs. This is the most feasible and policy-aligned approach using the HB 1660 reporting system.

2. Performance as School-Level Outcome: Use publicly available state meet results (e.g., qualifiers, placements, points) to construct school-level track and cross-country performance measures, without relying on full athlete-level scraping.

3. Athlete-Level Panel (High Risk): Construct a detailed athlete-by-year panel from meet databases. This would allow stronger performance analysis but is data-intensive, legally uncertain, and may exceed feasible time constraints.

Given current time and capacity constraints, it may be advisable to prioritize a participation-focused design, with performance analysis as a secondary extension if reliable school-level performance data can be assembled without large-scale scraping.


## What a Feasible Econ 580 Version Would Look Like

A feasible and rigorous Econ 580 version of this project would prioritize identification and clarity over maximal data ambition. The core paper would focus on the causal relationship between participation fees (and fee-waiver implementation) and socioeconomic participation gaps, using school-by-year panel data from Washington’s HB 1660 reporting system.

### 1. Research Question (Tightly Scoped)

Do higher athletic participation fees increase the participation gap between low-income and non-low-income students, and does stronger implementation of fee-waiver mandates reduce that gap?

The primary outcome would be the participation opportunity gap as defined in the statute:
(non-low-income participation rate – low-income participation rate).

The central treatment variables would include:
- Athletic participation fee levels
- Discounted/waived fee levels for low-income students
- Indicators for automatic waiver implementation (if observable)
- Indicators for schools subject to formal “opportunity gap reduction plans”

### 2. Data Structure

Unit of observation: High school × school year (panel dataset).

Core variables:
- Total enrollment
- Low-income enrollment (FRPM or equivalent)
- Total athletic participation
- Low-income athletic participation
- Athletic participation fee
- Discounted fee for low-income students
- ASB fee levels (as control for broader cost environment)

Constructed variables:
- Overall participation rate
- Low-income participation rate
- Participation gap
- Fee generosity measures (e.g., percent discount)

This creates a balanced or semi-balanced panel suitable for fixed effects estimation.

### 3. Empirical Strategy

The primary design would rely on within-school variation over time:

$Gap_{st} = β₁ Fee_{st} + β₂ WaiverIntensity_{st} + α_s + γ_t + X_{st} + ε_{st}$

Where:
- $α_s$ = school fixed effects
- $γ_t$ = year fixed effects
- $X_{st}$ = time-varying school controls (enrollment size, low-income share, etc.)

This absorbs time-invariant school characteristics and common statewide shocks.

If feasible, a secondary design could exploit:
- Schools crossing the statutory participation gap threshold (triggering required plans),
- Or differential changes in effective fee levels over time.

This keeps the paper squarely in applied microeconomics: panel data, policy variation, and credible identification assumptions.

### 4. Performance as a Secondary Extension

If state-meet data can be reliably compiled at the school-year level (without scraping proprietary athlete databases), a secondary analysis could examine whether reductions in participation gaps are associated with changes in competitive depth (e.g., number of state qualifiers or points). 

This would be explicitly framed as exploratory and downstream, not as the main causal test.

### 5. Contribution and Framing

The contribution would be threefold:

1. Provide empirical evidence on whether pay-to-play fees function as economically meaningful barriers to entry in extracurricular participation.
2. Evaluate whether fee-waiver mandates measurably reduce socioeconomic participation inequality.
3. Conceptually frame athletics participation as a quasi-labor market with entry costs and signaling, linking education policy to human capital and opportunity access.

Importantly, this version avoids high-risk data scraping, remains feasible within a semester timeline, and still delivers a credible applied econometrics paper appropriate for Econ 580 and a senior thesis.

This design sacrifices athlete-level performance granularity in exchange for identification strength, feasibility, and policy relevance — a tradeoff that is likely optimal given current time and resource constraints.