# Police Oversight Research  
For part of my dissertation, I evaluated Chicago Civilian Review Board (CRB) reforms and 
their impact on misconduct complaint investigation outcomes and officer discipline. 
  
## Project Background & Research Objectives 
In 2017, Chicago implemented a series of reforms aimed at strengthening civilian 
review and independent oversight of the Chicago Police Department (CPD). 
The reforms centered around the launch of the Civilian Office of Police Accountability 
(COPA), which replaced Chicago's former CRB agency (IPRA). Both agencies investigated 
allegations of CPD misconduct, but COPA was given greater resources, jurisdiction, 
and independence from the CPD than its predecessor agency. While evidence 
indicates that complaints are being sustained at a higher rate since COPA's launch, 
no empirical research has indicating whether this increase can be causally attributed to the 
reforms themselves.

## Guided by these research gaps, this project answers two questions:   
1. Did Chicago's civilian oversight reforms causally impact complaint substantiation rates, 
disciplinary recommendations, and CPD implementation of CRB recommendations?    
2. Did the reforms reduce racial disparities in police misconduct investigation outcomes?    

Parts of this project are also being used as a case study to explore whether a novel use of ML,
which I term PMGCOs, is more suitable for causal research than traditional designs like DiD and 
RDD in policy evaluation settings with universal compliance and no viable control group.
  
## Data 
To answer these research questions, a database of misconduct complaint outcomes was
created using three data sources:  
- Public complaint data spanning IPRA and COPA ([retrieved here](https://data.cityofchicago.org/Public-Safety/COPA-Cases-Summary/mft5-nfa8/about_data))
- FOIA data about investigation outcomes and officer discipline
- Demographic data from the American Community Survey    

An excerpt of the ETL pipeline for building the database is available [here](https://github.com/m-shames/portfolio/blob/main/projects/police-oversight/1_code-sample/sample_v1/2_copa_ETL.R). 

## Sample  
For the reform evaluation, the complaint sample was limited to:   

- 2013-2021 (last 4 years of IPRA & first 4 years of COPA)  
- filed by a civilian (not another CPD officer)    
- Occurred within CPD jurisdiction excluding at O'Hare airport   

This resulted in a final sample of 26,525 unique complaints of misconduct.  

## Outcomes Variables
The outcomes of interest for this project were:  

- CRB's recommended case finding  
- CRB's recommended officer discipline  
- Final case finding adopted by CPD  
- Final discipline implemented by CPD  

The distribution of CRB's recommended case findings by agency are plotted in [Figure 1](#fig1).
(Code for this figure is available [here](https://github.com/m-shames/portfolio/blob/main/projects/police-oversight/2_visualizations/Code_fig-crb-finding.R)).  

<figure id="fig1">
  <figcaption>Figure 1: Distribution of Recommended Case Outcomes</figcaption>
  <img src="2_visualizations/fig1_crb_finding.png" alt="CRB ITS">
</figure>

## Research Design
Multiple analyses have been conducted to answer various aspects of the research questions. These include:  

- Logistic Regression      
- Non-parametric Interrupted Time Series  
- Predictive Modeling Generated Counterfactual Outcomes (PMGCO)  

Code and results for each of these analyses is available upon request.  

## Research Findings  
In terms of the initial research questions guiding this project, this study finds: 

1. **Causal support** that the **increased sustain rate for CRB's recommended case outcomes**
may be attributable to the COPA reforms (see [Figure 2](#fig2)), but **no evidence that the longer-term increase in sustain rates for final case outcomes**
was directly caused by the reforms (see [Figure 3](#fig3)).    
2. Racial disparities in complaint substantiation rates persisted in both 
recommended and final case outcomes despite the COPA reforms (see [Figure 4](#figure-4)).     

Details about these findings and several other interesting results are currently 
being drafted into a manuscript, and are also available upon request.

<figure id="fig2">
  <figcaption>Figure 2: Predicted Probability of Recommended Outcome = Sustain</figcaption>
  <img src="2_visualizations/fig2.png" alt="CRB ITS">
</figure>

<figure id="fig3">
  <figcaption>Figure 3: Predicted Probability of Final Outcome = Sustain</figcaption>
  <img src="2_visualizations/fig3.png" alt="CPD ITS">
</figure>

<figure id="figure-4">
  <figcaption>Figure 4: Racial Disparities in Sustain Rates</figcaption>
  <img src="2_visualizations/fig4.png" alt="c-race">
</figure>


**⚠️Disclaimer**: This research is ongoing and the public repo may not represent current findings. 
Upon completion of the project, I hope to share the database of misconduct complaints and an executive summary of my research findings publicly. 