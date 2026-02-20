# ==============================================================================
# Investigate Cases with Missing Outcomes
# Project: COPA Evaluation
# Author: Michelle Shames

# About 
#   Exploratory script: run interactively, not sourced by run_all.R
#   Investigates missing findings in FOIA data using public COPA case summaries

# Findings Summary (documented in Section 5)
#   Match only successful for CMS cases (CLEAR used different record ID format)
#   Missing FOIA outcomes classified as administratively closed in public data
#   Pattern assumed to hold for unmatched CLEAR cases based on CMS consistency

# Dependencies
#   Run after: 6.1
#   Informs: 6.3 

# Output
#   None; findings documented in section 5 summary block
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse) 
library(here)

## load data ----
df.copa_cases <- readRDS(here("data/raw/public/df.copa_cases.rds"))
load(here("data/cleaning/df.foia_subsample_deduped.rda"))

# 1. CHECK CASE ID OVERLAP ------------------------------------------------

# head(df.copa_cases$log_no)
# head(df.foia_subsample_deduped$record_id)

# public data uses log_no format like "2020-0000007"
# FOIA data uses record_id without year prefix
# → create matching ID in FOIA data: yyyy-record_id
df.foia_subsample_deduped <- df.foia_subsample_deduped |>
  mutate(yyyy_recordid = paste(year(complaint_date), record_id, sep = "-"))

# check how many cases overlap between public and FOIA data → 4830
if (interactive()) {
  cat("Cases in public data found in FOIA:", 
      sum(df.copa_cases$log_no %in% df.foia_subsample_deduped$yyyy_recordid), "\n")
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
# → 45% of multi-allegation officer-cases have different findings
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
#   all_missing  7053
#   all_present  4901
#   mixed         192

# 3. MATCH MISSING CASES TO PUBLIC DATA -----------------------------------

## 3.1 Identify cases with all findings missing ----
cases_all_missing <- df.foia_subsample_deduped |>
  group_by(record_id) |>
  summarise(all_missing = all(is.na(recommended_finding_c1)), .groups = "drop") |>
  filter(all_missing)

## 3.2 Locate cases in public data ----
n_in_public <- sum(cases_all_missing$record_id %in% df.copa_cases$log_no)
cat("All-missing cases in FOIA:", nrow(cases_all_missing), "\n")
cat("Found in public data:", n_in_public, "\n") 
cat("Not found:", nrow(cases_all_missing) - n_in_public, "\n")

# → All-missing cases in FOIA: 5365
# → Found in public data: 2516
# → Not found: 2849

## 3.3 Determine findings for matched cases ----
# (public data has one row per case; findings pipe-delimited for multi-officer cases)

# check if finding_code contains pipes (multiple officers in one cell)
df.copa_cases |>
  filter(log_no %in% cases_all_missing$record_id) |>
  mutate(has_pipe = str_detect(finding_code, "\\|")) |>
  count(has_pipe) 
# → 1 case

# check piped case
df.copa_cases |>
  filter(log_no %in% cases_all_missing$record_id,
         str_detect(finding_code, "\\|")) |>
  select(log_no, finding_code)
# → all same outcome ("Sustained | Sustained | Sustained")

# distribution of findings for missing cases
df.copa_cases |>
  filter(log_no %in% cases_all_missing$record_id) |>
  distinct(log_no, finding_code) |>
  count(finding_code, sort = TRUE)

# →   No Finding 1500
# → No Affidavit 1015
# →    Sustained    1

## 3.4 Investigate single sustained case ----
df.foia_subsample_deduped |>
  filter(record_id == "2021-0000702" | yyyy_recordid == "2021-0000702") |>
  select(record_id, investigation_end_date, officer_id, allegation_key,
         recommended_finding, final_finding,
         n_OFs, n_OF_AKs) 
# → finding is unambiguously sustained
# → since no distinction between recommended or final, drop case in script 6.3

# 4. INVESTIGATE UNMATCHED CASES ------------------------------------------

# cases with missing findings NOT in public data
cases_not_in_public <- cases_all_missing |>
  filter(!(record_id %in% df.copa_cases$log_no))

# deduplicated to case-level for exploration
cases_not_found <- df.foia_subsample_deduped |>
  filter(record_id %in% cases_not_in_public$record_id) |>
  group_by(record_id) |>
  slice(1) |>
  ungroup()

# explore by time period
cases_not_found |> 
  summarise(
    n = n(),
    min_date = min(complaint_date, na.rm = TRUE),
    max_date = max(complaint_date, na.rm = TRUE),
    median_date = median(complaint_date, na.rm = TRUE)
  )

cases_not_found |> 
  count(agency_end)

# check year format
copa_not_found <- df.foia_subsample_deduped |>
  filter(record_id %in% cases_not_in_public$record_id, agency_end == "COPA") |>
  group_by(record_id) |>
  slice(1) |>
  ungroup() |>
  select(record_id, yyyy_recordid, complaint_date)

head(copa_not_found, 10)

# check if yyyy_recordid format matches log_no format
head(df.copa_cases$log_no, 10)

# check if non-matched cases use old ID format
copa_not_found |>
  mutate(old_format = !str_detect(record_id, "-")) |>
  count(old_format)

# compare to matched cases
df.foia_subsample_deduped |>
  filter(record_id %in% cases_all_missing$record_id,
         record_id %in% df.copa_cases$log_no) |>
  group_by(record_id) |>
  slice(1) |>
  ungroup() |>
  select(record_id) |>
  head(10)

# verify source period
df.foia_subsample_deduped |>
  filter(record_id %in% cases_all_missing$record_id) |>
  group_by(record_id) |>
  slice(1) |>
  ungroup() |>
  mutate(matched = record_id %in% df.copa_cases$log_no) |>
  count(matched, source_period)

}

# ==============================================================================
# 5. FINDINGS SUMMARY -----------------------------------------------------
#  
# GOAL: Fill missing investigation findings in FOIA data using publicly 
# available COPA Cases Summary data from City of Chicago Data Portal.
#
# MATCHING RESULTS
#   → 2,516 cases (all from CMS) matched to public data
#   → 2,849 cases (all from CLEAR) could NOT be matched
#
# MISMATCH EXPLANATION
#   → Match failure is entirely explained by source system:
#     - All cases in public were assigned IDs using new CMS format
#     - CLEAR-era cases retained CLEAR-ID format in FOIA data
#   → Matching these cases would require creating crosswalk between CLEAR & CMS,
#     likely only possible through additional FOIA
#
# FINDINGS FOR MATCHED CASES
#   → 2,515 administrative closures (all matched cases except 1)
#     - 1,015 No Affidavit (complainant did not sign sworn affidavit)
#     - 1,500 No Finding (closed without determination)
#   → 1 Sustained (record 2021-0000702; one officer, one allegation)
#     - Recommended vs final finding not recorded in FOIA system;
#       cannot construct followthrough measure
#     - Drop observation in script 6.3
#
# UNMATCHED CASES (2,849)
#   → All use legacy CLEAR ID format not present in public portal;
#     matching would require a CLEAR-to-CMS ID crosswalk or additional FOIA
#   → Assumption: same pattern holds as matched CMS cases (all admin closures);
#     supported by consistency of CMS findings and all-or-nothing missingness pattern
# ==============================================================================
