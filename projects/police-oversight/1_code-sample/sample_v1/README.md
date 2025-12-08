# Navigation & Code Sample Files
This folder contains:  
A) Code sample cover letter (explainer) in various formats  
- `Sample-explainer_*.*`  
B) Code sample: ETL pipeline using R and Google BigQuery  
- **[`1_bigquery_copa_extract.R`](https://github.com/m-shames/portfolio/blob/main/projects/police-oversight/1_code-sample/sample_v1/1_bigquery_copa_extract.R)**:
  Extract FOIA data from BigQuery cloud data warehouse
- **[`2_copa_ETL.R`](https://github.com/m-shames/portfolio/blob/main/projects/police-oversight/1_code-sample/sample_v1/2_copa_ETL.R)**:
Prep & merge datasets for analysis

## About the Code Sample
For part of my dissertation, I evaluated Chicago Civilian Review Board (CRB) reforms and 
their impact on misconduct complaint investigation outcomes and officer discipline. 
The code sample provided consists of excerpts from various stages of this project. 
Further code will happily be provided upon request. *Please note: some outputs are suppressed or may not run due to private storage of confidential data.*    

----

# About the Larger Project
  
### Background & Research Objectives 
In 2017, Chicago implemented a series of reforms aimed at strengthening civilian 
review and independent oversight of the Chicago Police Department (CPD). 
The reforms centered around the launch of the Civilian Office of Police Accountability 
(COPA), which replaced Chicago's former CRB agency (IPRA). Both agencies investigated 
allegations of CPD misconduct, but COPA was given greater resources, jurisdiction, 
and independence from the CPD than its predecessor agency. While anecdotal evidence 
indicates that complaints are being sustained at a higher rate since COPA's launch, 
no empirical research has indicating whether this increase can be attributed to the 
reforms themselves. Even less research has been conducted on patterns of officer discipline.  

**Guided by these research gaps, this project answers two primary questions:**  
1. Did Chicago's civilian oversight reforms causally impact complaint substantiation rates, disciplinary recommendations, and CPD implementation of CRB recommendations?    
2. Did the reforms reduce racial disparities in police misconduct investigation outcomes?    

### Methods & Findings
This analysis uses a database of 26,000 misconduct complaints I built by acquiring 
and integrating public and FOIA data from law enforcement, civilian oversight agencies, 
and the U.S. Census Bureau. ***Further documentation related to research design, analyses, and findings can be found [here](https://github.com/m-shames/portfolio/tree/main/projects/police-oversight).*** 

**⚠️Disclaimer⚠**: This research is ongoing and the public repo may not represent current findings. 
Upon completion of the project, I hope to share the database of misconduct complaints and an executive summary of my research findings publicly. 