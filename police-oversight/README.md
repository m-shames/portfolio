# Police Oversight & Accountability Research

Dissertation research evaluating the impact of Chicago's 2017 civilian oversight reforms on police misconduct investigation outcomes and officer discipline. Using an interrupted time series (ITS) design, this project asks whether the transition from the Independent Police Review Authority (IPRA) to the Civilian Office of Police Accountability (COPA) causally changed how complaints are investigated, substantiated, and acted upon.

[View code & data ↓](#data--code) | [View findings ↓](#findings)

----

## Key Findings
- Causal evidence that **CRB allegation substantiation rates increased** for civilian complaints reviewed post-reform (statistically significant).
- **No causal evidence that the 2017 reforms impacted** ***final*** **case or disciplinary outcomes** implemented by the Chicago Police Department.
- Statistical evidence that **racial disparities in substantiation rates persisted post-reform** (statistically significant).

----

## Project Overview

### Background
In 2017, Chicago implemented a series of reforms aimed at strengthening independent oversight and civilian review of the Chicago Police Department (CPD). The reforms centered on the creation of COPA, a new Civilian Review Board (CRB),which replaced IPRA on Sept 15, 2017 with greater resources, jurisdiction, and independence from the CPD. While evidence indicates that complaints are being sustained at higher rates since COPA's launch, no prior empirical research has established whether this increase can be causally attributed to the reforms themselves.

### Research Questions
1. Did Chicago's civilian oversight reforms causally impact complaint substantiation rates, disciplinary recommendations, and CPD implementation of CRB recommendations?
2. Did the reforms reduce racial disparities in police misconduct investigation outcomes?

**Methodological Contribution:** This project also evaluates Predictive Modeling Generated Counterfactual Outcomes (PMGCO), a machine learning approach for generating synthetic controls in policy evaluations where traditional designs (DiD, RDD) are unsuitable due to universal compliance and the absence of a control group.

### Data Sources
A comprehensive database of misconduct complaints and investigation outcomes was built from:

- FOIA-obtained data with final investigation outcomes and officer discipline
- Public complaint data spanning IPRA and COPA (available on the [Chicago Data Portal](https://data.cityofchicago.org/Public-Safety/COPA-Cases-Summary/mft5-nfa8/about_data))
- Demographic data from the American Community Survey  
- Shapefiles and jurisdiction boundaries from the City of Chicago and `tidycensus`  

> A similar complaint-level dataset is publicly available through [the Invisible Institute](https://github.com/invinst/chicago-police-data). The present database extends that work with post-reform coverage, beat-level ACS demographic linkages, and allegation-level recommended and final determinations, allowing for causal analysis of CRB reforms and CPD follow-through.  

### Sample
- **Time period:** Investigations closed between Sept 15, 2013 and Sept 15, 2021 (±4 years around intervention)
- **Complaint type:** Civilian complainants only  
- **Location:** Alleged incident occurred within CPD jurisdiction, excluding O'Hare and Midway Airports  
- **Final sample:** 28,364 unique police misconduct allegations  

### Outcome Variables
- CRB recommended findings  
- Final case finding adopted by CPD  
- CRB recommended discipline  
- Final discipline implemented by CPD  

The distribution of CRB-recommended and CPD-adopted case findings by agency are displayed in Figures 1a and 1b respectively. 


  <div align="center">     
    <figure id="fig1a">                                                         
      <img src="visualizations/fig1a.png" alt="Distribution of CRB-recommended  
  findings by agency. COPA sustained 2.5× more allegations than IPRA (10% vs.   
  4%)" width="70%">                                              
      <figcaption><strong>Figure 1a</strong></figcaption>
    </figure>                                               
  </div>

  <br>

  <div align="center">
    <figure id="fig1b">
      <img src="visualizations/fig1b.png" alt="Distribution of CPD-adopted final
   findings by agency. CPD's final sustain rate shifted only modestly (4% vs. 3%)." width="70%">                                             
      <figcaption><strong>Figure 1b</strong></figcaption>
    </figure>
  </div>

  <br>

>  χ² tests on 2×2 tables (sustained vs. not sustained) indicate the difference in CRB-recommended sustain rates between agencies was small in magnitude (Cramér's V = 0.12) but statistically significant (χ²(1) = 377.92, p < .001). The difference in final findings was also statistically significant (χ²(1) = 42.78, p < .001) but the effect size was negligible (V = 0.04). ***χ² results are exploratory and do not take account of allegations being clustered within officers and cases.***

### Research Design
- Logistic Regression
- Non-parametric Interrupted Time Series (ITS)  
- Predictive Modeling Generated Counterfactual Outcomes (PMGCO)

*Code and results for these analyses are available upon request.*

----

## Findings

**1. Impact on CRB Recommendations:** Strong causal evidence that the 2017 reforms led to an increase in the rate at which the CRB recommended sustaining complaints (see Figure 2).

<div align="center">
  <figure id="fig2">
    <img src="visualizations/fig2.png" alt="CRB recommended outcomes over time" width="70%">
    <br>
    <figcaption><strong>Figure 2:</strong> Predicted Probability of CRB's Recommended Outcome = Sustain</figcaption>
  </figure>
</div>

<br>

**2. Limited Impact on Final Outcomes:** No causal evidence that the reforms led to an increase in final sustain rates, suggesting the 2017 CRB reforms did not impact CPD leadership's adoption of CRB recommendations (see Figure 3).

<div align="center">
  <figure id="fig3">
    <img src="visualizations/fig3.png" alt="CPD final outcomes over time" width="70%">
    <br>
    <figcaption><strong>Figure 3:</strong> Predicted Probability of Final Outcome = Sustain</figcaption>
  </figure>
</div>

<br>

**3. Persistent Racial Disparities:** Racial disparities in complaint substantiation rates persisted in both recommended and final case outcomes despite the reforms (see Figure 4).

<div align="center">
  <figure id="fig4">
    <img src="visualizations/fig4.png" alt="Racial disparities in outcomes" width="70%">
    <br>
    <figcaption><strong>Figure 4:</strong> Racial Disparities in CRB Recommended Sustain Rates</figcaption>
  </figure>
</div>

<br>

----

## Data & Code

### Included in This Repository

**[`data-pipeline/`](https://github.com/m-shames/portfolio/tree/updated/police-oversight/data-pipeline)**: ETL pipeline for constructing misconduct complaint database (32,000+ records, pre-sample filters)

**[`data/`](https://github.com/m-shames/portfolio/tree/updated/police-oversight/data)**: Raw and processed data *(excluded via `.gitignore`; final dataset forthcoming post-defense)*

**[`visualizations/`](https://github.com/m-shames/portfolio/tree/updated/police-oversight/visualizations)**: Rendered readme figures (code available upon request)  


### Available Upon Request
- Complete modeling and analysis code (logistic regression, ITS, PMGCO)
- Sensitivity analyses and robustness checks  
- Detailed results  
- Complaint database

----

## Publication Status

Three manuscripts based on findings from this project are currently in preparation for peer-reviewed publication.

> This repository reflects research in progress and may not represent final findings. 
> The complaint database and more complete findings will be shared publicly upon project completion.
