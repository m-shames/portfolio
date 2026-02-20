# ==============================================================================
# BigQuery Data Extraction
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Extract FOIA & ACS data from private Google Cloud BigQuery data warehouse
#   Saves 5 tables as local .rda files
#   Note: Not publicly runnable; pre-extracted files available upon request

# Dependencies
#   Credentials: BQ_EMAIL environment variable must be set
#   Access: Requires read permissions on GCP project 'n3-main' 

# Output
#   data/raw/foia/df.misconduct_clear.rda
#   data/raw/foia/df.misconduct_cms.rda
#   data/raw/foia/df.complainants_clear.rda
#   data/raw/foia/df.complainants_cms.rda
#   data/raw/acs/df.acs_beats_post_2012.rda 
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(bigrquery)
library(here)

## authenticate ----
custom_scopes <- c(
  "https://www.googleapis.com/auth/bigquery",
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/drive.readonly" 
)

bq_auth(email = Sys.getenv("BQ_EMAIL"), scopes = custom_scopes)

# 1. FOIA MISCONDUCT & COMPLAINANT DATA -----------------------------------

# check available tables
# data_subset <- bq_dataset("n3-main", "copa_anon")
# tables <- bq_dataset_tables(data_subset)
# table_names <- tables |> sapply(\(x) x$table)

## create paths ----
tbl.misconduct_clear   <- bq_table("n3-main", "copa_anon", "misconduct_clear")
tbl.misconduct_cms     <- bq_table("n3-main", "copa_anon", "misconduct_cms")
tbl.complainants_clear <- bq_table("n3-main", "copa_anon", "complainant_results_clear")
tbl.complainants_cms   <- bq_table("n3-main", "copa_anon", "complainant_results_cms")

## download tables ----
df.misconduct_clear   <- bq_table_download(tbl.misconduct_clear)
df.misconduct_cms     <- bq_table_download(tbl.misconduct_cms)
df.complainants_clear <- bq_table_download(tbl.complainants_clear)
df.complainants_cms   <- bq_table_download(tbl.complainants_cms)

## validate ----
stopifnot(
  "Download Error: df.misconduct_clear is empty"   = nrow(df.misconduct_clear)   > 0,
  "Download Error: df.misconduct_cms is empty"     = nrow(df.misconduct_cms)     > 0,
  "Download Error: df.complainants_clear is empty" = nrow(df.complainants_clear) > 0,
  "Download Error: df.complainants_cms is empty"   = nrow(df.complainants_cms)   > 0
)

## save ----
save(df.misconduct_clear,   file = here("data/raw/foia/df.misconduct_clear.rda"))
save(df.misconduct_cms,     file = here("data/raw/foia/df.misconduct_cms.rda"))
save(df.complainants_clear, file = here("data/raw/foia/df.complainants_clear.rda"))
save(df.complainants_cms,   file = here("data/raw/foia/df.complainants_cms.rda"))

# 2. ACS ------------------------------------------------------------------

# check available tables
# data_subset <- bq_dataset("n3-main", "demog_wh")
# tables <- bq_dataset_tables(data_subset)
# table_names <- tables |> sapply(\(x) x$table)

## create path ----
tbl.acs_beats_post_2012 <- bq_table("n3-main", "demog_wh", "acs_beats_post_2012")

# check structure
# df.acs_beats_post_2012 <- bq_table_download(tbl.acs_beats_post_2012, n_max = 50)
# dplyr::glimpse(df.acs_beats_post_2012)

## download ----
df.acs_beats_post_2012 <- bq_table_download(tbl.acs_beats_post_2012)

## validate ----
stopifnot(
  "Download Error: df.acs_beats_post_2012 is empty" = nrow(df.acs_beats_post_2012) > 0
)

## save ----
save(df.acs_beats_post_2012, file = here("data/raw/acs/df.acs_beats_post_2012.rda"))
