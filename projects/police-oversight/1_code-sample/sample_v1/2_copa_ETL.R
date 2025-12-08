# ==============================================================================
# ETL - DF MERGING
# Proj: COPA Eval

# Author: Michelle Shames
# ==============================================================================

# CODE SAMPLE CONTEXT ----------------------------------------------------------

# This script is an excerpt of the ETL process that was used to create the database 
# of COPA complaints that was analyzed in this project. 

# A total of five files were merged. This process involved:
#   - loading & reviewing the original data
#   - selecting variables of interest & standardizing them across datasets
#   - joining datasets & performing quality checks to ensure merges were successful

# ETL phases in this script:
#  1) CPD misconduct data from 2 time periods/different databases were merged
#  2) COPA complaint data from 2 time periods/different databases were merged
#  3) Combined the merged misconduct & complaint dataframes (DFs) into single FOIA dataset
#  4) Appended ACS demographic data by incident year & beat

# SETUP ------------------------------------------------------------------------

## load packages ----
library(tidyverse)
library(here)
library(stringr)
library(janitor)

## load data ----
load(here("a_data/1_og_data/COPA_Corners/df.misconduct_clear.rds"))
load(here("a_data/1_og_data/COPA_Corners/df.misconduct_cms.rds"))

load(here("a_data/1_og_data/COPA_Corners/df.complainants_clear.rds"))
load(here("a_data/1_og_data/COPA_Corners/df.complainants_cms.rds"))

load(here("a_data/1_og_data/ACS/beats_acs_data.rds"))

# 1. MERGE 2 MISCONDUCT DFs ------------------------------------------------------

## 1.1 Compare Dataset Structures ----

# Create comparison table of variable names & types across sets
tbl.compare <- tibble(
  variable = names(df.misconduct_clear),
  clear_types = map_chr(df.misconduct_clear, ~ class(.)[1])
) %>% 
  full_join(
    tibble(
      variable = names(df.misconduct_cms),
      cms_types = map_chr(df.misconduct_cms, ~ class(.)[1])
    ),
    by = "variable"
  ) %>%
  mutate(types_match = clear_types == cms_types) %>% 
  arrange(variable)

# Display comparison
print(tbl.compare, n = Inf, width = Inf)

## 1.2 Standardize Data Types ----

# Convert for consistency between sets
df.misconduct_cms <- df.misconduct_cms %>%
  mutate(
    cpdmember_complaint = case_when(
      cpdmember_complaint == TRUE ~ "CPD EMPLOYEE",
      cpdmember_complaint == FALSE ~ "CIVILIAN",
      TRUE ~ NA_character_
    ),
    closed_date = mdy(closed_date)
  )

## 1.3 Merge Datasets w Standardized Column Names ----

df.misconduct_combined <- bind_rows(
  # Clear dataset (2017-present)
  df.misconduct_clear %>% 
    mutate(source_period = "clear"),
  # CMS dataset (pre-2017) - rename to match Clear 
  df.misconduct_cms %>% 
    rename(
      accused_appointed_date = accused_apt_date,
      accused_gender = accused_sex,
      accused_position = accused_position_rank,
      # [***18 additional fields omitted for brevity***]
      street_number = address,
      zip_cd = zip_postal_code
    ) %>%
    mutate(source_period = "cms")
)

## 1.4 Data Quality Check ----

# Verify expected row count (115,431 + 14,380 = 129,811)
nrow(df.misconduct_combined)

# Identify columns with missing data by source period
missing_data_summary <- df.misconduct_combined %>%
  group_by(source_period) %>%
  summarise(across(everything(), ~all(is.na(.)))) %>%
  pivot_longer(-source_period, names_to = "column", values_to = "all_missing") %>%
  filter(all_missing == TRUE)

print(missing_data_summary)

## 1.5 Basic Clean ----
# [***Excerpt of variable cleaning for sample brevity***]

### ✅️ ️CPD beats ----
# Add leading zeros to standardize beat IDs
df.misconduct_combined <- df.misconduct_combined %>%
  mutate(
    beat_clean = case_when(
      nchar(as.character(beat_of_incident)) == 3 ~ paste0("0", beat_of_incident),
      TRUE ~ as.character(beat_of_incident)
    ),
    beat_clean = as.factor(beat_clean)
  )

### ✅️ CPD ️districts ----
df.misconduct_combined <- df.misconduct_combined %>%
  mutate(district_clean = substr(beat_clean, 1, 2)) %>% 
  relocate(district_clean, .after = beat_clean) %>%
  mutate(district_clean = as.factor(district_clean))

df.misconduct_combined <- df.misconduct_combined %>%
  mutate(district_clean = case_when(
    district_clean %in% c("31", "41", "61") ~ NA_character_,
    TRUE ~ district_clean
  ))

###  ✅️ agency ----
df.misconduct_combined <- df.misconduct_combined %>%
  mutate(agency = case_when(
    investigation_end_date < as.Date("2017-09-15") ~ "IPRA",
    investigation_end_date >= as.Date("2017-09-15") ~ "COPA",
    TRUE ~ NA_character_  # Handle NA or other unexpected values
  )) %>%
  mutate(agency = factor(agency, levels = c("IPRA", "COPA"))) %>% 
  relocate(agency, .after = investigation_end_date)

### ✅️ gender ----
df.misconduct_combined %>% 
  count(accused_gender)

df.misconduct_combined <- df.misconduct_combined %>%
  mutate(
    accused_gender = case_when(
      accused_gender %in% c("F", "FEMALE") ~ "Female",
      accused_gender %in% c("M", "MALE") ~ "Male",
      accused_gender %in% c("NOT LISTED", "PREFER NOT TO SAY") ~ "Other",
      is.na(accused_gender) ~ NA_character_,
      TRUE ~ NA_character_  # catches any unexpected values
    )
  )

## 1.6 SAVE ----
save(df.misconduct_combined, file = here("a_data/2.2_cleaning_FOIA/V2/1_df.misconduct_combined.rds"))

# 2. MERGE 2 COMPLAINT DFs -------------------------------------------------------
## [*** Steps similar to section 1; omitted for sample brevity***]

# 3. MERGE MISCONDUCT & COMPLAINTS ---------------------------------------------

## 3.1 Prep complainant attributes ----
# [***Excerpt of variable cleaning for sample brevity***]

### create vector for number of complainants associated w a distinct complaint ----
v.n_complainants <- df.complainants_combined %>%
  count(c_record_id, name = "n_complainants")

### Merge cleaned vectors of complainant attributes ----
df.complainant_atts <- v.complainants_race %>%
  left_join(v.complainants_sex, by = "c_record_id") %>%
  left_join(v.complainants_role, by = "c_record_id") %>%
  left_join(v.n_complainants, by = "c_record_id")

## 3.2 Merge misconduct + complainant data = all FOIA data ----
df.foia_merged <- df.misconduct_combined %>%
  left_join(df.complainant_atts, by = c("record_id" = "c_record_id"))

## 3.3 Validate merge ----
# --> only 40 cases missing complainant info
df.foia_merged %>% 
  count(is.na(n_complainants))

# check distribution of missing info by year
df.foia_merged %>% 
  filter(is.na(n_complainants)) %>% 
  count(year_filed)

## 3.4 SAVE ----
save(df.foia_merge, file = here("a_data/2.2_cleaning_FOIA/V2/3_df.foia_merge.rds"))

# 4. MERGE FOIA & ACS ----------------------------------------------------------

## 4.1 Prep ACS data ----

beats_acs_data %>% 
  skimr::skim_without_charts()

# [***Excerpt for sample brevity***]

### Rename all columns to add "acs_" prefix ----
# (done to simplify selecting ACS variables in modeling process)
cpd_beats_acs <- beats_acs_data %>%
  rename_with(~ paste0("acs_", .)) %>% 
  mutate(acs_year = as.factor(acs_year))

## 4.2 Merge FOIA + ACS data by incident beat & year ----
df.foia_acs_merged <- df.foia_merged %>%  
  left_join(cpd_beats_acs, by = c("beat_clean" = "acs_beat_id", "year_filed" = "acs_year"))

## 4.3 Validate merge ----
df.foia_acs_merged %>% 
  count(is.na(acs_pct_bach_deg))

# check distribution of missing ACS info by beat
df.foia_acs_merged %>% 
  filter(is.na(acs_pct_bach_deg)) %>% 
  count(beat_clean)

## 4.4 SAVE ----
save(df.foia_acs_merged, file = here("a_data/2.2_cleaning_FOIA/V2/4_df.foia_acs_merged.rds"))
