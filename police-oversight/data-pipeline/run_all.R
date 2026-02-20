# ==============================================================================
# Run All: Full Pipeline for Chicago CRB Complaint Database Pipeline
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Source all data pipeline scripts in order
#   Each script loads output of preceding step and saves its own
#     output as an .rda file in subdirectory created in script 0

# Dependencies
#   Run setup.R once on a new machine before executing this script.

# Final Pipeline Output
#   data/final/df.foia_labeled.rda
#   docs/codebook_copa_misconduct.html
# ==============================================================================

library(here)

# 1. EXTRACT --------------------------------------------------------------
# Requires BigQuery credentials
# → skip if using pre-extracted data (available upon request)
# source(here("data-pipeline/R/1_bigquery_extraction.R"))

# 2. MERGE ----------------------------------------------------------------
source(here("data-pipeline/R/2.1_merge_misconduct.R"))
source(here("data-pipeline/R/2.2_merge_complainants.R"))
source(here("data-pipeline/R/2.3_merge_FOIA-ACS.R"))

# 3. SUBSAMPLE ------------------------------------------------------------
source(here("data-pipeline/R/3_subsample.R"))

# 4. CLEAN ----------------------------------------------------------------
source(here("data-pipeline/R/4.1_clean_subsample.R"))
# 4.2_clean_allegations.R excluded pending completion of 
#   CLEAR/CMS allegation category crosswalk. Allegation variables
#   are retained in raw form in the current final dataset.

# 5. DEDUPLICATE ----------------------------------------------------------
source(here("data-pipeline/R/5_de-dupe.R"))

# 6. INVESTIGATE & RECODE OUTCOMES ---------------------------------------- 
source(here("data-pipeline/R/6.1_retrieve_public-data.R"))
# Script 6.2_investigate_NA-outcomes.R excluded (exploratory only)
source(here("data-pipeline/R/6.3_clean_outcomes.R"))

# 7. CODEBOOK -------------------------------------------------------------
source(here("data-pipeline/R/7_codebook.R"))
