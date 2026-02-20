# Data Pipeline: Police Misconduct Complaint Database

End-to-end pipeline for constructing a database of 26,525 allegation-level 
police misconduct complaint records for an interrupted time series (ITS) 
analysis of Chicago's 2017 civilian oversight reforms (IPRA → COPA).

The pipeline integrates FOIA-obtained complaint data from two legacy database 
systems (CLEAR and CMS), complainant demographic data, U.S. Census Bureau ACS 
beat-level data, and supplementary public complaint data from the City of 
Chicago Data Portal.

---

## Scripts

Scripts must be run sequentially. Each loads the saved output of the preceding 
step.

| Script | Description | Input | Output |
|--------|-------------|-------|--------|
| `utils.R` | Shared utility functions and lookup vectors | — | — |
| `1_bigquery_extraction.R` | Authenticate with Google Cloud and extract FOIA data from BigQuery | BigQuery (private) | `df.misconduct_clear`, `df.misconduct_cms`, `df.complainants_clear`, `df.complainants_cms`, `df.acs_beats_post_2012` |
| `2_1_merge_misconduct.R` | Harmonize and merge CLEAR and CMS misconduct records | Raw `.rda` files | `df.misconduct_combined` |
| `2_2_merge_complainants.R` | Harmonize and merge CLEAR and CMS complainant records; pivot to case-level attribute vectors | Raw `.rda` files | `df.complainants_combined` |
| `2_3_merge_foia_acs.R` | Merge misconduct, complainant, and ACS data into unified dataset | Merged `.rda` files | `df.foia_merged`, `df.foia_acs_merged` |
| `3_filter_subsample.R` | Filter to ITS analytic window (2013–2021); restrict to civilian complaints within CPD jurisdiction | `df.foia_acs_merged` | `df.foia_subsample` |
| `4_clean_sample.R` | Recode, collapse, and validate outcome and covariate variables | `df.foia_subsample` | `df.foia_subsample` (cleaned) |
| `4_2_dedupe.R` | Investigate and resolve duplicate records; validate deduplication impact on outcome distributions | `df.foia_subsample` | `df.foia_subsample_deduped` |
| `5_supplement_findings.R` | Fill missing findings using public COPA data from City of Chicago Data Portal | `df.foia_subsample_deduped` + public API | `df.foia_subsample_clean` |

---

## Data Sources

| Source | Description | Access |
|--------|-------------|--------|
| CLEAR (FOIA) | Legacy misconduct & complainant records, pre-2017 | Private GCP / BigQuery |
| CMS (FOIA) | Current misconduct & complainant records, 2017–2021 | Private GCP / BigQuery |
| ACS | Beat-level census demographics, 2013–2021 | Private GCP / BigQuery |
| COPA Summary | Case-level public complaint data | [City of Chicago Data Portal](https://data.cityofchicago.org/Public-Safety/COPA-Cases-Summary/mft5-nfa8) |

> The FOIA data were stored in a private Google Cloud BigQuery project 
> (`n3-main`) and are not publicly accessible. Extraction scripts are included 
> for transparency and reproducibility documentation. The FOIA request was 
> fulfilled June 22, 2022.

---

## Key Pipeline Decisions

**Two-system harmonization:** IPRA used the CLEAR database system; COPA uses 
CMS. The two systems have different variable names, coding schemes, and 
allegation category taxonomies. Scripts 2_1–2_3 harmonize these into a unified 
dataset with consistent variable names and recoded categories.

**Allegation-level structure:** The unit of analysis is the allegation — a 
specific charge against a specific officer within a complaint case. One 
complaint can contain multiple allegations against multiple officers.

**Deduplication:** A non-trivial share of records appeared as duplicates due to 
data entry artifacts. Script 4_2 investigates the sources of duplication and 
resolves them with documented decision rules, validating that deduplication did 
not systematically alter outcome distributions.

**Missing findings:** Approximately 40% of allegations in the analytic sample 
had missing `recommended_finding` values, concentrated in COPA-era cases filed 
close to the FOIA fulfillment date (June 2022). Script 5 supplements these 
using publicly available COPA data. Recoverable missing cases (n = 1,854, all 
CMS-era) were exclusively administrative closures (No Affidavit or No Finding). 
The remaining 1,869 missing cases are CLEAR-era records not present in the 
public portal and are treated as missing in the analysis.

---

## Final Dataset

**Unit of analysis:** Allegation (complaint × officer × charge)  
**N:** 26,525 unique allegations  
**Time period:** 2013–2021 (±4 years around September 15, 2017 intervention)  
**Variables:** 151 total; 35 selected for analytic models  

For a full narrative walkthrough of the pipeline including decision rationale, 
variable descriptions, and validation output, see 
[`data_construction_appendix.qmd`](./data_construction_appendix.qmd).

---

## Dependencies

**R** (≥ 4.3)  
Key packages: `tidyverse`, `here`, `bigrquery`, `skimr`, `janitor`, `lubridate`

**Python** (≥ 3.9) — for `sample_API/COPA_API.py` only  
Key packages: `requests`, `pandas`
