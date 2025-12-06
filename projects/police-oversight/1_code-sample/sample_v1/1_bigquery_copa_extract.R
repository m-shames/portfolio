# ==============================================================================
# BigQuery ETL Pipeline for Police Misconduct Data Extraction
# Proj: COPA Eval

# Author: Michelle Shames
# ==============================================================================

# 1. SETUP ---------------------------------------------------------------------

## load packages ----
library(bigrquery) # BigQuery API interface
library(here) # Project-relative file paths

## authenticate  ----
bq_auth()

custom_scopes <- c(
  "https://www.googleapis.com/auth/bigquery",
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/drive.readonly"
)
bq_auth(scopes = custom_scopes)

# 2. VIEW TABLES ---------------------------------------------------------------

# retrieve all dataset references for n3-main project
n3_datasets_r = bq_project_datasets("n3-main") 

# list all dataset names
(ds_names = n3_datasets_r %>% sapply((function(x) x$dataset)))

# select a dataset to use
data_subset = bq_dataset("n3-main", "copa_anon")

# retrieve all table references for 
tables = bq_dataset_tables(data_subset)
# list all table names
(table_names = tables %>% sapply((function(x) x$table)))

# get table reference
misconduct_clear = bq_table("n3-main", "copa_anon", "misconduct_clear")
misconduct_cms = bq_table("n3-main", "copa_anon", "misconduct_cms")

complainants_clear = bq_table("n3-main", "copa_anon", "complainant_results_clear")
complainants_cms = bq_table("n3-main", "copa_anon", "complainant_results_cms")

# 3. PULL SAMPLE ---------------------------------------------------------------

# retrieve the first 50 observations from the table using a reference
cpd_anon_vr_vics_data_r = bq_table_download(cpd_demog_ascbeats_r, n_max = 50)

# verify the data
cpd_anon_vr_vics_data_r[1:5, 2:6]

# 3. PULL COMPLETE -------------------------------------------------------------

df.misconduct_clear = bq_table_download(misconduct_clear)
df.misconduct_cms = bq_table_download(misconduct_cms)

df.complainants_clear = bq_table_download(complainants_clear)
df.complainants_cms = bq_table_download(complainants_cms)

# 4. SAVE ----------------------------------------------------------------------

save(df.misconduct_clear, file = here("a_data/1_og_data/COPA_Corners/df.misconduct_clear.rds"))
save(df.misconduct_cms, file = here("a_data/1_og_data/COPA_Corners/df.misconduct_cms.rds"))

save(df.complainants_clear, file = here("a_data/1_og_data/COPA_Corners/df.complainants_clear.rds"))
save(df.complainants_cms, file = here("a_data/1_og_data/COPA_Corners/df.complainants_cms.rds"))