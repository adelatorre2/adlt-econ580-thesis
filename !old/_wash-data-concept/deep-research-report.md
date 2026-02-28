Data-Backed Thesis Designs for Socioeconomic Constraints in U.S. High School Running
Why this is a strong economics question and where the empirical novelty is
Your core idea—sports participation as a choice under budget constraints—maps cleanly into standard microeconomic frameworks: students (and families) face a “price” of participation (fees plus time and incidental costs), and schools choose supply-side inputs (coaches, travel, facilities) that shape the “production function” for athletic performance and the size/quality of the participation pipeline. The most testable economics implication is that raising the effective price reduces participation, and that the participation response should be more elastic for low-income students (larger marginal utility of money, tighter liquidity constraints). This is also consistent with education/human-capital logic: participation can generate noncognitive skills, social capital, and potentially educational attainment effects, but selection makes causal inference nontrivial—hence the attraction of policy-induced cost shocks. 

The biggest empirical gap (and opportunity) for an undergraduate thesis is that sport-specific, school-level panels linking (i) prices/fees, (ii) participation by income group, and (iii) objective performance outcomes are rare nationally—because most U.S. pay-to-play policies are local and data are fragmented. 

A key “deep research” finding is that you can get surprisingly far by pivoting from a national scraping approach to one or two states with unusually transparent data infrastructures, yielding a credible empirical design and a clean contribution.

What you can measure without impossible data collection
Participation outcomes that are feasible at scale
State-level participation by sport, annually (all states + DC): The National Federation of State High School Associations publishes an annual participation survey archive with sport-by-state “schools” and “participants” counts (track & field and cross country included), separated by boys/girls, where “participants” reflect the common “counted once per sport played” convention. 
This is a strong “fallback” dataset because it is public, structured, and national—though it is not granular enough to identify district fee changes directly.

School-level athletics participation by income group (Washington): Washington Office of Superintendent of Public Instruction reporting templates (see below) collect counts of (i) total enrolled, (ii) low-income enrolled, (iii) total athletic participants, and (iv) low-income athletic participants—allowing you to compute participation rates by income group and an “opportunity gap.” 

Performance outcomes that are feasible without private microdata
Official state championship results (track + cross country):
In Washington, Washington Interscholastic Activities Association maintains “past results” archives for both track & field and cross country. Track results include PDF outputs (e.g., inclusive division scoring) with athlete-school mappings and points; cross country results include HTML tables with team points, finish placements, and average times. 

This means you can construct school-year measures of “competitive running pipeline strength” without needing individual-level education records, such as:

number of state qualifiers from each school (track)
team placement/points at state (XC; track scoring formats vary)
distributional measures (e.g., number of top-8 finishes, medal counts, average of top-5 times for XC teams)
In Kentucky, Kentucky High School Athletic Association posts detailed track and cross-country tournament results and data files (including historical results pages and downloadable artifacts). 

A critical constraint on scraping-based national performance data
Your original instinct—use athletic.net and aggregate by school/city-year—is conceptually workable, but there is a major practical risk: athletic.net’s terms explicitly prohibit “scraping,” “spidering,” and other automated extraction, and also prohibit collecting information about users in certain ways. 

That doesn’t mean you can’t use it at all, but it changes the safest thesis path:

prefer official state associations’ public archives (like Washington/Kentucky) for performance data, or
obtain explicit permission / licensed access if you want a national athletic.net-based panel. 
The most “workable + causal” policy-shock design found in the literature and data
A high-quality policy setting: Washington’s HB 1660 fee-waiver and reporting regime
Washington enacted House Bill 1660 (as reflected in legislative documents and OSPI guidance) with three features that are unusually useful for causal inference:

Fee-waiver policy for low-income students for optional noncredit extracurricular participation/attendance fees (implemented through changes to the state’s fee framework), with OSPI FAQ guidance emphasizing the law’s scope over optional noncredit extracurricular events. 
Mandatory school-level reporting of athletic participation counts and fee data (including athletic participation fees and discounted fees), with explicit publication timelines in the bill report. 
“Opportunity gap” goals and a plan requirement: the bill report specifies that the target opportunity gap for ASB-card possession and extracurricular participation reduces from 20 percentage points (2020–21) to 5 percentage points beginning 2024–25, with districts required to develop/publish an “opportunity gap reduction plan” if they do not meet goals. 
Even more importantly for econometrics, OSPI’s templates operationalize the gap definition: the “opportunity gap in athletic program participation” is computed as the difference between non–low-income and low-income participation rates.

A thesis-ready, specific research question that stays true to your running-focus
A tight, empirically feasible version of your question (that still reads like an economics paper):

“Do participation fees limit low-income students’ access to high school athletics, and do fee-waiver mandates reduce socioeconomic participation gaps? Evidence from Washington’s HB 1660 reporting system, with track/XC state-meet performance as downstream outcomes.” 

This stays consistent with your original motivation (cost shocks, SES gradients, pipeline), while anchoring the analysis in a real policy-imposed change plus unusually rich administrative-style reporting.

Empirical framework and econometric methods that fit the available data
Core dataset structure (school-year panel)
Using the OSPI ASB/Athletics reporting templates, you can define (for each high school s and year t):

Fees (price proxies):

athletic participation fee (general/“list” fee)
discounted fee for low-income students (often $0 under waiver policies, but empirically vary across schools/years and in compliance transitions)
Participation outcomes (by income group):

total athletes (unduplicated per template guidance)
low-income athletes (unduplicated)
participation rate_lowinc = lowinc_athletes / lowinc_enrollment
participation rate_nonlow = (total_athletes − lowinc_athletes) / (total_enrollment − lowinc_enrollment)
opportunity_gap = participation rate_nonlow − participation rate_lowinc
This is directly aligned with your “pipeline” framing: participation is the extensive margin, and the gap is your inequality metric.

Identification options, ranked by credibility and feasibility
Option A: Fee-change event study / difference-in-differences inside Washington (recommended if you can build a small panel)
If you observe meaningful changes over time in listed fees (or in how low-income discounts are applied), estimate:

[ Y_{st} = \alpha_s + \lambda_t + \beta \cdot Fee_{st} + \gamma X_{st} + \varepsilon_{st} ]

Where (Y_{st}) can be low-income participation, the opportunity gap, or log(athletic participants). School fixed effects absorb time-invariant differences; year fixed effects absorb statewide shocks. The interpretation is “within-school” association between fee changes and participation changes.

This gets closer to causal inference when fee changes are plausibly policy-driven (e.g., compliance changes, standardized district fee reforms) rather than pure demand shifts. The bill report and OSPI guidance create a clear policy backdrop for fee-waiver expectations. 

Threats: COVID-era disruptions to sports participation and reporting are a major confound around 2019–2021, so you would want sensitivity checks or focus on later years where participation is less administratively constrained. The OSPI templates explicitly reference March/April reporting timing and publication deadlines. 

Option B: Regression discontinuity around “gap plan required” thresholds (high upside, more technical)
The OSPI gap plan template indicates that in 2024–25, gap plans are required when opportunity gaps exceed 5%. 
The bill report also describes the policy trajectory toward 5 percentage points beginning 2024–25 and a plan requirement for districts that fail to meet goals. 

If districts near the cutoff are otherwise similar, you can compare schools barely above vs barely below the threshold and estimate whether plan requirements (and associated interventions) lead to subsequent improvements in low-income participation or reductions in gap. This is an economics-style design with a clear, policy-defined running variable.

Challenges: you need at least one post-threshold year of outcomes, and you must confirm the exact operational rule used in the relevant year (templates + district practice + OSPI guidance).

Option C: State-level DID or synthetic control using NFHS participation (fallback, broad and publishable as a thesis)
If you want two-state DID in the spirit of your earlier approach, NFHS gives you sport-by-state participation counts. 
You can treat Washington as “policy-treated” starting in the early 2020s and compare its track/XC participation trends to a control group of states (ideally selected through a synthetic control approach rather than a single comparator).

A caveat surfaced in the deep research: states differ widely in fee policies, and other states have enacted reforms too (e.g., Oregon legislative activity in this area), which complicates simple two-state DID if the control state also changes policy. 

Linking “fees → running pipeline” without violating privacy
Because WIAA provides meet results by school, you can define downstream outcomes that are about program competitiveness rather than identifying individuals:

number of state meet participants per school (track) extracted from WIAA PDFs 
XC team finishes, points, and average time spreads (team competitiveness) from WIAA HTML tables 
You can then estimate whether fee levels (or gap plans) predict changes in these running outcomes, with the interpretation: fees alter participation; participation depth affects likelihood of producing state-level qualifiers.

Alternative “safe” empirical option that still fits your lived-experience motivation
If you want a project that is explicitly about resources, coaching/travel budgets, and performance (less about fee shocks, more about production functions), Kentucky offers an unusually direct measurement channel:

Kentucky’s Title IX athletic expenditure reporting as a resource dataset
Kentucky high schools file Title IX-related reports through Kentucky High School Athletic Association that include per-sport spending breakdowns—equipment/supplies, travel, awards, coaches salaries, and facilities improvements—separately for girls’ and boys’ programs. In one example report, you can literally see line items for cross country and track embedded in the spending tables. 

This is extremely rare: it gives you a measurable “input vector” for a running performance production function.

Matching to performance outcomes is also feasible in Kentucky
KHSAA posts extensive track and cross-country historical results and meet files (state/region entries, performance listings, complete results), enabling school-year outcome construction without relying on third-party scraping. 

What you can credibly claim (and what might be null)
With Kentucky-style data, you can usually estimate:

strong cross-sectional gradients: higher spending correlates with stronger competitive outcomes (more qualifiers, higher placements), but causal interpretation is limited by endogeneity (successful programs may attract more booster money). 
gender/resource parity patterns by sport (a clean descriptive contribution, potentially with within-school comparisons across boys vs girls teams). 
A realistic “null” finding possibility: marginal dollars may matter less for track/XC than for equipment-intensive sports, especially if coaching quality and community running culture dominate. Track/XC often has lower equipment barriers than sports like hockey or football, so spending-performance relationships could be weaker than intuition suggests.

What the literature says you should expect and what could surprise you
The broader economics and public-health literature provides two disciplined expectations:

Selection is substantial: naïve correlations between sports participation and academic outcomes often overstate causal effects; stronger designs (fixed effects/IV) tend to shrink estimates, which is why policy shocks (like Title IX expansions or fee-waiver mandates) are valuable. 
Pay-to-play policies are common and plausibly exclusionary: research and policy discussions emphasize that participation fees and associated costs can be barriers, especially for lower-income families; evidence from Michigan-focused work suggests fee structures and waivers matter, and policy/legal mapping shows wide variation in state approaches. 
The “deep research” novelty is that Washington’s HB 1660 ecosystem operationalizes the question in a way most states do not: it forces measurement of the participation gap, and it ties the gap to compliance obligations and fee-waiver policy, giving you an unusually clean empirical playground for a senior thesis. 