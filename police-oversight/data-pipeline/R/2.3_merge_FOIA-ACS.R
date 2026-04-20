# ==============================================================================
# Merge FOIA data + Complainant Attributes + ACS Data
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Aggregate complainant-level data to case-level attribute vectors
#   Merge misconduct data with complainant attributes
#   Merge combined FOIA data with ACS beat-level data

# Dependencies
#   Run after: 2.1 & 2.2
#   Output used by: 3

# Output
#   data/cleaning/df.foia_merged.rda
#   data/cleaning/df.foia_acs_merged.rda
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse)
library(here)

## load data ----
load(here("data/cleaning/df.misconduct_combined.rda"))
load(here("data/cleaning/df.complainants_combined.rda"))
load(here("data/raw/acs/df.acs_beats_post_2012.rda"))

# 1. CREATE COMPLAINANT ATTRIBUTE VECTORS ---------------------------------
#   pivots complainant-level data to wide format: one row per case,
#   → one column per category with counts of complainants in each category
#   → all complainant variables prefixed with "c_" for identification post-merge

pivot_complainant_att <- function(df, group_var) {
  df |>
    group_by(c_record_id) |>
    count({{ group_var }}) |>
    ungroup() |>
    pivot_wider(names_from = {{ group_var }}, values_from = n, values_fill = 0)
}

v.complainants_race <- pivot_complainant_att(df.complainants_combined, c_race_collapsed) |>
  rename_with(~ paste0("c_race_", .), -c_record_id)

v.complainants_sex <- pivot_complainant_att(df.complainants_combined, c_gender_collapsed) |>
  rename_with(~ paste0("c_gender_", .), -c_record_id)

v.complainants_role <- pivot_complainant_att(df.complainants_combined, c_role_collapsed) |>
  rename_with(~ paste0("c_role_", .), -c_record_id)

v.complainants_cpd <- pivot_complainant_att(df.complainants_combined, c_cpd) |>
  rename_with(~ paste0("c_cpd_", .), -c_record_id)

v.n_complainants <- df.complainants_combined |>
  count(c_record_id, name = "n_complainants")

# 2. MERGE MISCONDUCT & COMPLAINANT ATTs ----------------------------------

## 2.1 Merge complainant attribute vectors ----
df.complainant_atts <- v.complainants_race |>
  left_join(v.complainants_sex, by = "c_record_id") |>
  left_join(v.complainants_role, by = "c_record_id") |>
  left_join(v.complainants_cpd, by = "c_record_id") |>
  left_join(v.n_complainants, by = "c_record_id")
  
## 2.2 Merge misconduct data + complainant atts df ----
df.foia_merged <- df.misconduct_combined |>
  left_join(df.complainant_atts, by = c("record_id" = "c_record_id"))

stopifnot(
  "Merge Error: Row count changed after complainant join" =
    nrow(df.foia_merged) == nrow(df.misconduct_combined)
)

## 2.3 Investigate cases with missing complainant attributes ----

if (interactive()) {
  df.foia_merged |>
    filter(is.na(n_complainants)) |>
    summarise(
      n        = n(),
      all_open = all(investigation_status != "Closed"),
      pct_open = mean(investigation_status != "Closed") * 100
    )
}

# → n = 40; all open investigations; will be dropped in script 3

# intermediate save so ACS merge can be rerun independently
save(df.foia_merged, file = here("data/cleaning/df.foia_merged.rda"))

# 3. MERGE FOIA & ACS -----------------------------------------------------

## 3.1 Prep ACS data ----

df.cpd_beats_acs <- df.acs_beats_post_2012 |>
  rename_with(~ paste0("acs_", .)) 

## 3.2 Merge FOIA + ACS by *incident* beat & year ----
df.foia_acs_merged <- df.foia_merged |>  
  left_join(df.cpd_beats_acs, 
            by = c(
              "beat_clean" = "acs_beat_id", 
              "year_filed" = "acs_year"
              )
            )

stopifnot(
  "Merge Error: Row count changed after ACS join" =
    nrow(df.foia_acs_merged) == nrow(df.foia_merged)
)

## 3.3 Investigate missing ACS data ----
# df.foia_acs_merged |>
#   filter(is.na(acs_pct_bach_deg)) |>
#   filter(between(year_filed, 2013, 2021)) |>
#   count(beat_clean)

# → all NAs are (a) beats out of CPD jurisdiction, or (b) missing beat info

# SAVE --------------------------------------------------------------------
save(df.foia_acs_merged, 
     file = here("data/cleaning/df.foia_acs_merged.rda"))
