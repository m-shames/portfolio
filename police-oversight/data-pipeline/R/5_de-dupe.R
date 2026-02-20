# ==============================================================================
# Deduplication of Allegation-Level Data
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Sections 1-3: Investigate allegation_keys (content; missing; duplicates)
#   Section 4: Document deduplication decisions
#   Section 5: Perform & validate deduplication   

# Findings Summary
#   allegation_key = unique identifier for allegation × officer × case  
#   duplicate keys indicates multiple incidents tied to same allegation
#   all outcome variables are constant within allegation_key → safe to deduplicate
#   keep row with most recent close date → preserves >99% of outcome distribution  

# Dependencies
#   Run after: 4.1 (and 4.2 once complete)
#   Output used by: 6.2 & 6.3
 
# Output
#   data/cleaning/df.foia_subsample_deduped.rda
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse)
library(here)

## load data ----
load(here("data/cleaning/df.foia_subsample_clean.rda"))

# ==============================================================================
# PART I: ESTABLISH DEDUPLICATION RATIONALE
# ==============================================================================

# 1. EXPLORE ALLEGATION_KEY (AK) ------------------------------------------

## 1.1 Confirm definition ---- 
# hypothesis: allegation_key = allegation-level identifier

if (interactive()) {
  df.foia_subsample_clean |>
    filter(!is.na(allegation_key)) |> 
    group_by(allegation_key) |>
    summarise(
      n_officers         = n_distinct(officer_id),
      n_record_ids       = n_distinct(record_id),
      n_rec_findings     = n_distinct(recommended_finding),
      n_final_findings   = n_distinct(final_finding),
      n_allegation_codes = n_distinct(allegation_category_cd)
    ) |>
    filter(if_any(starts_with("n_"), ~ . > 1))

}

# → confirmed: within keys, same case, officer allegation code, finding

# 2. EXPLORE MISSING ALLEGATION KEYS ------------------------------------------

if (interactive()) {
  
# → 6% of rows = missing 
df.foia_subsample_clean |>
  summarise(
    n_total = n(),
    n_missing_key = sum(is.na(allegation_key)),
    pct_missing = round(n_missing_key / n_total * 100, 1)
  ) 

## 2.1 by database ----

# → 5-8% of allegations in each database have missing keys
df.foia_subsample_clean |>
  group_by(source_period) |>
  summarise(
    n_total = n(),
    n_missing_key = sum(is.na(allegation_key)),
    pct_missing = round(n_missing_key / n_total * 100, 1)
  ) 

## 2.2 by outcome ----

# → all missing have no outcome (admin closures)
df.foia_subsample_clean |>
  filter(is.na(allegation_key)) |>
  summarise(
    pct_rec_finding_missing = mean(is.na(recommended_finding)) * 100,
    pct_final_finding_missing = mean(is.na(final_finding)) * 100,
    pct_rec_discipline_missing = mean(is.na(recommended_discipline)) * 100,
    pct_final_discipline_missing = mean(is.na(final_discipline)) * 100
  )

## 2.3 by IDs ----
df.foia_subsample_clean |>
  filter(is.na(allegation_key)) |>
  summarise(
    n_officer_IDs = n_distinct(officer_id),
    n_allegation_codes = n_distinct(allegation_category_cd),
    n_record_id = n_distinct(record_id)
  )

# → all missing AKs also have missing officer ID & allegation cat
df.foia_subsample_clean |>
  filter(is.na(allegation_key)) |>
  count(officer_id, allegation_category_cd)

# 98% of missing AKs have 1 record ID → max n of same record_id = 4
df.foia_subsample_clean |>
  filter(is.na(allegation_key)) |>
  count(record_id) |>
  count(n, name = "n_records") |>
  rename(n_rows_per_record = n) |>
  mutate(pct = round(n_records / sum(n_records) * 100, 1))

### variation within dupe record IDs  ----

# → all spatial except incident date & complaint type 
df.foia_subsample_clean |>
  filter(is.na(allegation_key)) |>
  group_by(record_id) |>
  summarise(across(everything(), n_distinct)) |>
  select(-record_id) |>
  summarise(across(everything(), max)) |>
  pivot_longer(everything(), names_to = "variable", values_to = "max_distinct") |>
  filter(max_distinct > 1) |>
  filter(!str_starts(variable, "acs_")) |>
  arrange(desc(max_distinct))

}

# 3. EXPLORE AK DUPES -----------------------------------------------------

# create df of duplicate allegation_keys for investigation
df.dupes <- df.foia_subsample_clean |>
  filter(!is.na(allegation_key)) |>
  group_by(allegation_key) |>
  filter(n() > 1) |>
  ungroup()

if (interactive()) {
  
# → n dupes = 1761
n_distinct(df.dupes$allegation_key)

# distribution of dupes → up to 7
df.dupes |> 
  count(allegation_key) |>
  count(n, name = "n_keys")

## 3.1 Which variable values vary within dupes ----

# → n = 26; all spatial except incident_date & investigation_end_date
df.dupes |>
  group_by(allegation_key) |>
  summarise(across(everything(), n_distinct)) |>
  select(-allegation_key) |>
  summarise(across(everything(), max)) |>
  pivot_longer(everything(), names_to = "variable", values_to = "max_distinct") |>
  filter(max_distinct > 1) |>
  filter(!str_starts(variable, "acs_")) |>
  arrange(desc(max_distinct))

## 3.2 diff incident_date ----
df.dupes |>
  group_by(allegation_key) |>
  filter(n_distinct(incident_date) > 1) |>
  count(allegation_key) |> 
  arrange(desc(n))
# → 682 AKs, max variation = 7

## 3.3 diff investigation_end_dates ----
df.dupes |>
  group_by(allegation_key) |>
  filter(n_distinct(investigation_end_date) > 1) |>
  count(allegation_key)
# → 9 AKs,  max variation = 2

## 3.4 diff spatial indicators ----
df.dupes |>
  group_by(allegation_key) |>
  summarise(n_beats = n_distinct(beat_clean)) |>
  filter(n_beats > 1) |>
  count(n_beats) |>
  mutate(pct = round(n / sum(n) * 100, 1))
# → 92% = 2 beats; max 4 beats

}

# 4. KEY FINDINGS ---------------------------------------------------------

# VARIABLES THAT DIFFER WITHIN UNIQUE ALLEGATION_KEYS
#   investigation_end_date (only 9 AKs)
#   incident date & location variables 
#   all other variables incl outcome are constant

# DUPLICATE STRUCTURE
#   some complaints allege a PATTERN of misconduct across multiple incidents
#   same allegation_key appears multiple times with different incident dates/locations

# CONCLUSION
#   safe to dedupe to one row per allegation_key for outcome analysis excl. spatial controls
#   for geographic patterns, use df.foia_subsample_clean (pre-dedup)

# TREATMENT OF ROWS W/ MISSING AKS 
#   simple AK deduplication would eliminate all rows with missing AKs
#   given that all rows with missing AKs were admin closed, and
#   98% have distinct record IDs →  treat these cases as distinct, 
#   simply closed before enough data was collected to parse out complaint by allegation

# ==============================================================================
# PART II: PERFORM & TEST DEDUPLICATION
# ==============================================================================

# 5. DEDUPE ---------------------------------------------------------------

## 5.1 Document pre-deduplication counts ----

n_before      <- nrow(df.foia_subsample_clean)
n_valid_aks   <- n_distinct(df.foia_subsample_clean$allegation_key, na.rm = TRUE)
n_missing_aks <- sum(is.na(df.foia_subsample_clean$allegation_key))

if (interactive()) {
  cat("=== PRE-DEDUPLICATION ===\n")
  cat("Total rows:", n_before, "\n")
  cat("Rows with valid allegation_keys:", n_valid_aks, "\n")
  cat("Missing allegation_key rows:", sum(is.na(df.foia_subsample_clean$allegation_key)), "\n")
  cat("Duplicate rows to remove:", n_before - n_valid_aks - sum(is.na(df.foia_subsample_clean$allegation_key)), "\n")
}

# === PRE-DEDUPLICATION ===
# Total rows: 27528 
# Rows with valid allegation_keys: 23599 
# Missing allegation_key rows: 1691 
# Duplicate rows to remove: 2238

## 5.2 Deduplicate (keep latest close date) ----
# selection priority for duplicate allegation_keys:
#   1. most recent investigation_end_date → keeps final administrative record
#   2. for AKs with identical close dates → most recent incident_date
#   NB: this discards spatial variation, but was the least arbitrary way to select entry to keep

# dedupe rows with valid allegation_keys
df.deduped_aks <- df.foia_subsample_clean |>
  filter(!is.na(allegation_key)) |>
  arrange(allegation_key, desc(investigation_end_date), desc(incident_date)) |>
  distinct(allegation_key, .keep_all = TRUE)

# keep missing-key rows as-is → 98% have distinct record_ids,
# treated as distinct cases closed before allegation-level data was recorded
df.missing_aks <- df.foia_subsample_clean |>
  filter(is.na(allegation_key))

# recombine
df.foia_subsample_deduped <- bind_rows(df.deduped_aks, df.missing_aks)

## 5.3 Verify deduplication ----

n_after        <- nrow(df.foia_subsample_deduped)
n_after_valid  <- n_distinct(df.foia_subsample_deduped$allegation_key, na.rm = TRUE)
n_after_missing <- sum(is.na(df.foia_subsample_deduped$allegation_key))

if (interactive()) {
  cat("\n=== POST-DEDUPLICATION ===\n")
  cat("Total rows after:", n_after, "\n")
  cat("Valid allegation_key rows:", n_after_valid, "\n")
  cat("Missing allegation_key rows:", n_after_missing, "\n")
  cat("Rows removed:", n_before - n_after, 
      "(", round((n_before - n_after) / n_before * 100, 1), "%)\n")
}

# === POST-DEDUPLICATION === 
# Total rows after: 25289 
# Valid allegation_key rows: 23598 
# Missing allegation_key rows: 1691 
# Rows removed: 2239 ( 8.1 %)

stopifnot(
  "Dedup Error: Duplicate allegation_keys remain after deduplication" =
    df.foia_subsample_deduped |>
    filter(!is.na(allegation_key)) |>
    summarise(n_distinct(allegation_key) == n()) |>
    pull()
)

# 6. DOCUMENT IMPACT ------------------------------------------------------

# confirm deduplication does not shift outcome proportions
df.finding_comparison <- bind_rows(
  df.foia_subsample_clean |> count(recommended_finding, name = "n_pre") |> 
    mutate(pct_pre = n_pre / sum(n_pre)),
  df.foia_subsample_deduped |> count(recommended_finding, name = "n_post") |> 
    mutate(pct_post = n_post / sum(n_post))
) |>
  group_by(recommended_finding) |>
  summarise(across(everything(), ~ sum(.x, na.rm = TRUE)), .groups = "drop") |>
  mutate(delta_pct = (pct_post - pct_pre) * 100)

stopifnot(
  "Bias Warning: Deduplication shifted outcome proportions by > 1.5pp" = 
    df.finding_comparison |> 
    filter(!is.na(recommended_finding)) |> 
    summarise(max_delta = max(abs(delta_pct))) |> 
    # negligible threshold for ITS estimates
    pull(max_delta) < 1.5
)

# SAVE --------------------------------------------------------------------
save(df.foia_subsample_deduped, 
     file = here("data/cleaning/df.foia_subsample_deduped.rda"))
