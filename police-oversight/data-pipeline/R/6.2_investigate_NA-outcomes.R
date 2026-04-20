# ==============================================================================
# Investigate Cases with Missing Outcomes
# Project: COPA Evaluation
# Author: Michelle Shames

# About 
#   Exploratory script: run interactively, not sourced by run_all.R
#   Investigate findings missing in FOIA data using public COPA data

# Findings Summary (documented in Section 4)
#   Match successful for all cases
#   All missing FOIA outcomes listed as administratively closed in public data

# Dependencies
#   Run after: 6.1
#   Informs: 6.3 

# Output
#   None; findings documented in section 4 summary block
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse) 
library(here)

## load data ----
df.copa_cases <- readRDS(here("data/raw/public/df.copa_cases.rds"))
load(here("data/cleaning/df.foia_subsample_deduped.rda"))

# 1. CHECK CASE ID OVERLAP ------------------------------------------------

## 1.1 Explore format ----

if (interactive()) {
  
# foia
df.foia_subsample_deduped |>
  mutate(id_pattern = gsub("[0-9]", "N", record_id)) |>
  distinct(source_period, agency_end, id_pattern) |>
  arrange(source_period, agency_end)

clear <- df.foia_subsample_deduped[df.foia_subsample_deduped$source_period == "clear", ]
head(as.data.frame(table(clear$record_id)), 20)

cms <- df.foia_subsample_deduped[df.foia_subsample_deduped$source_period == "cms", ]
head(as.data.frame(table(cms$record_id)), 20)

# clear → NNNNNNN     
# cms → YYYY-NNNNNNN

# public
head(df.copa_cases$log_no)

df.copa_cases |>
  mutate(id_pattern = gsub("[0-9]", "N", log_no)) |>
  distinct(id_pattern)

# all → NNNN-NNNNNNN
}

## 1.2 Create matching ID ----

df.foia_subsample_deduped <- df.foia_subsample_deduped |>
  mutate(yyyy_record_id = if_else(
    source_period == "clear",
    paste(year(complaint_date), record_id, sep = "-"),
    record_id
  ))

# overlap → 7,434
if (interactive()) {
  cat("Cases in public data found in FOIA:", 
      sum(df.copa_cases$log_no %in% df.foia_subsample_deduped$yyyy_record_id), "\n")
}

# 2. ASSESS FOIA OUTCOME MISSINGNESS  -------------------------------------

if (interactive()) {
  
# within officer x cases that HAVE findings, do findings vary across allegations?
#   will indicate whether a single case-level finding can represent all allegations
df.foia_subsample_deduped |>
  filter(!is.na(recommended_finding_c1)) |>
  group_by(record_id, officer_id) |>
  summarise(
    n_allegations = n(),
    n_unique_findings = n_distinct(recommended_finding_c1),
    .groups = "drop"
  ) |>
  mutate(findings_vary = n_unique_findings > 1) |>
  summarise(
    total_officer_cases = n(),
    single_allegation = sum(n_allegations == 1),
    multi_same_finding = sum(n_allegations > 1 & !findings_vary),
    multi_diff_finding = sum(n_allegations > 1 & findings_vary),
    pct_diff = mean(findings_vary[n_allegations > 1]) * 100
  )
# → 44% of multi-allegation officer-cases have different findings
# → case-level finding_code cannot reliably be imputed to individual allegations

# check missingness pattern: are findings all present, all missing, or mixed?
#   "mixed" = some allegations for an officer-case have findings, others don't
df.foia_subsample_deduped |>
  group_by(record_id, officer_id) |>
  summarise(
    n_allegations = n(),
    n_missing = sum(is.na(recommended_finding_c1)),
    n_present = sum(!is.na(recommended_finding_c1)),
    .groups = "drop"
  ) |>
  mutate(status = case_when(
    n_missing == 0 ~ "all_present",
    n_present == 0 ~ "all_missing",
    TRUE ~ "mixed"
  )) |>
  count(status)
# → very few mixed cases (missingness is almost entirely all-or-nothing)
#   all_missing  6720
#   all_present  4134
#   mixed         180

# 3. MATCH MISSING CASES TO PUBLIC DATA -----------------------------------

## 3.1 Identify cases with all findings missing ----
cases_all_missing <- df.foia_subsample_deduped |>
  group_by(record_id, yyyy_record_id) |>
  summarise(all_missing = all(is.na(recommended_finding_c1)), .groups = "drop") |>
  filter(all_missing)

## 3.2 Locate cases in public data ----
n_in_public <- sum(cases_all_missing$yyyy_record_id %in% df.copa_cases$log_no)
cat("All-missing cases in FOIA:", nrow(cases_all_missing), "\n")
cat("Found in public data:", n_in_public, "\n") 
cat("Not found:", nrow(cases_all_missing) - n_in_public, "\n")

# → All-missing cases in FOIA: 5162
# → Found in public data: 5162
# → Not found: 0

## 3.3 Determine findings for matched cases ----
# (public data has one row per case; findings pipe-delimited for multi-officer cases)

# check if finding_code contains pipes (multiple officers in one cell)
df.copa_cases |>
  filter(log_no %in% cases_all_missing$yyyy_record_id) |>
  mutate(has_pipe = str_detect(finding_code, "\\|")) |>
  count(has_pipe) 
# → 1 case

# check piped case
df.copa_cases |>
  filter(log_no %in% cases_all_missing$yyyy_record_id,
         str_detect(finding_code, "\\|")) |>
  select(log_no, finding_code)
# → all same outcome ("Sustained | Sustained | Sustained")

# distribution of findings for missing cases
df.copa_cases |>
  filter(log_no %in% cases_all_missing$yyyy_record_id) |>
  distinct(log_no, finding_code) |>
  count(finding_code, sort = TRUE)

# →  No Affidavit   2803
# →   No Finding    2357
# →           NA    1
# →    Sustained    1

### investigate single sustained case ----
df.foia_subsample_deduped |>
  filter(yyyy_record_id == "2021-0000702") |>
  select(record_id, investigation_end_date, officer_id, allegation_key,
         recommended_finding, final_finding, n_OFs, n_OF_AKs) 
# → finding is unambiguously sustained
# → since no distinction between recommended or final, drop case in script 6.3

### investigate NA case ----
df.copa_cases |>
  filter(log_no == "2018-1090333")
# assignment = BIA → Not a COPA case → drop case in script 6.3

## 3.4. CHECK CASE ASSIGNMENT ----
df.copa_cases |>
  filter(log_no %in% cases_all_missing$yyyy_record_id) |>
  count(assignment)
# → log_no 2018-1090333 is only BIA case

}

# ==============================================================================
# 4. FINDINGS SUMMARY -----------------------------------------------------
#  
# GOAL: Fill missing investigation findings in FOIA data using publicly 
# available COPA Cases Summary data from City of Chicago Data Portal.
#
# RESULTS: all missing in FOIA were matched to public data with findings:
#   → All administrative closures except 2
#     - 2,803 No Affidavit (complainant did not sign sworn affidavit)
#     - 2,357 No Finding (closed without determination)
#   → 1 Sustained (record 2021-0000702)
#     - Recommended vs final finding not recorded in FOIA system;
#       cannot construct followthrough measure
#     - Drop observation in script 6.3
#   → 1 NA (record 2018-1090333)
#     - Case assigned to BIA; should not have been in FOIA data
#     - Drop observation in script 6.3
#
# → All NA findings can be updated to administrative closure
# ==============================================================================
