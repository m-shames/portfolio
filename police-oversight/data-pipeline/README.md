# Chicago CRB Misconduct Complaint Database Pipeline  

**Dependencies**  
![](https://img.shields.io/badge/R-%3E%3D%204.1.0-blue) ![](https://img.shields.io/badge/BigQuery-Google%20Cloud-4285F4?logo=googlecloud&logoColor=white)    
Packages: `tidyverse` · `here` · `bigrquery` · `skimr` · `janitor` · `labelled` · `sjPlot`  

Constructs a database of 25,288 allegation-level police misconduct complaint 
records filed with Chicago's Civilian Review Board (CRB) for 
an interrupted time series (ITS) evaluation of 2017 civilian oversight reforms 
(IPRA → COPA transition). See the [project overview](https://github.com/m-shames/portfolio/blob/updated/police-oversight/README.md) for research 
context and findings.

The pipeline integrates FOIA-obtained complaint data from two database systems 
(CLEAR and CMS), complainant demographic data, ACS beat-level demographics, 
and supplementary public complaint data from the City of Chicago.

## How to Run

1. **Setup:** Run [`setup.R`](https://github.com/m-shames/portfolio/blob/updated/police-oversight/data-pipeline/setup.R) once on a new machine to install dependencies and create 
   directory structure.  
2. **Execution:** Run [`R/`](https://github.com/m-shames/portfolio/tree/updated/police-oversight/data-pipeline/R) pipeline scripts in numerical order starting from `1_bigquery_extraction.R` or use 
[`run_all.R`](https://github.com/m-shames/portfolio/blob/updated/police-oversight/data-pipeline/run_all.R) 
  to execute the full pipeline. 
  
>Note: Script `6.2` is exploratory and not sourced by `run_all.R` →  review before first run of `6.3`.

---

## Repository Structure

```
├── setup.R          # One-time setup (install dependencies, create directories)
├── run_all.R        # Full pipeline execution
├── utils.R          # Shared global objects (automatically sourced)
└── R/               # Pipeline scripts (run in order, scripts 1–7)
```

## [`R/`](https://github.com/m-shames/portfolio/tree/updated/police-oversight/data-pipeline/R): Pipeline Overview

| Stage | Script | Description |
|---|---|---|
| 1 | `1_bigquery_extraction.R` | Extract raw FOIA & ACS data from BigQuery |
| 2.1 | `2.1_merge_misconduct.R` | Join & clean CLEAR + CMS misconduct tables |
| 2.2 | `2.2_merge_complainants.R` | Join & clean CLEAR + CMS complainant tables |
| 2.3 | `2.3_merge_FOIA-ACS.R` | Join misconduct data + complainant group attributes + beat-level ACS demographics |
| 3 | `3_subsample.R` | Create analytic sample: 8-year window; closed cases; CPD jurisdiction only |
| 4.1 | `4.1_clean_subsample.R` | Clean & recode variables; construct Interrupted Time Series (ITS) exposure |
| 4.2 | `4.2_clean_allegations.R` | CMS-CLEAR Allegation crosswalk *(public release pending)* |
| 5 | `5_de-dupe.R` | Detect & resolve allegation-level duplicates |
| 6.1 | `6.1_retrieve_public-data.R` | Download public COPA case summaries |
| 6.2 | `6.2_investigate_NA-outcomes.R` | Diagnose missing FOIA outcomes using matched public COPA data (exploratory) |
| 6.3 | `6.3_clean_outcomes.R` | Recode & collapse outcome variables |
| 7 | `7_codebook.R` | Finalize dataset, attach labels & metadata, render codebook |

---

## Data Sources & Output

Some of the raw data used to build this database are not publicly available due 
to privacy considerations and are excluded from this repository via `.gitignore`. 
The final database (`data/final/df.foia_labeled.rda`) and a de-identified version 
will be shared publicly following dissertation defense.  

**Sources**  

| Source | Description | Access |
|---|---|---|
| CLEAR | FOIA-obtained complaint & complainant information (01/2001 – 02/2019)| Available upon request |
| CMS | FOIA-obtained complaint & complainant information (02/2019 – 07/2022)| Available upon request |
| Author-constructed | CPD beat-level crosswalk with annual ACS tract-level estimates (2013–2021) | Public release pending |
| COPA | Public complaint case summaries | [Chicago Data Portal](https://data.cityofchicago.org/Public-Safety/COPA-Cases-Summary/mft5-nfa8/about_data) |

**Output**  

- `data/final/df.foia_labeled.rda`: labeled allegation-level dataset (25,288 rows × 136 variables)
- `data/final/codebook_crb-complaint-database.html`: variable codebook (forthcoming as interactive document)

---

*Michelle Shames | PhD Candidate, Sociology & Applied Statistics*

*Code shared for portfolio and transparency purposes. Not licensed for reuse; open-access release planned following defense.*
