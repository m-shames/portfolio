# ==============================================================================
# Merge & Clean Misconduct Tables (CLEAR + CMS)
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Merge FOIA-obtained misconduct datasets (CLEAR + CMS)
#   Standardize variable names & types; clean dates & CPD beats 

# Dependencies
#   Run after: 1 (bigquery extraction)
#   Output used by: 2.3 (merge FOIA-ACS)

# Output
#   data/cleaning/df.misconduct_combined.rda
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse)
library(here)

## load data ----
load(here("data/raw/foia/df.misconduct_clear.rda"))
load(here("data/raw/foia/df.misconduct_cms.rda"))

# 1. PREP MISCONDUCT DFs --------------------------------------------------

# compare DF structures
# tbl.compare <- tibble(
#   variable = names(df.misconduct_clear),
#   clear_types = map_chr(df.misconduct_clear, ~ class(.)[1])
# ) |> 
#   full_join(
#     tibble(
#       variable = names(df.misconduct_cms),
#       cms_types = map_chr(df.misconduct_cms, ~ class(.)[1])
#     ),
#     by = "variable"
#   ) |>
#   mutate(types_match = clear_types == cms_types) |> 
#   arrange(variable)
# 
# print(tbl.compare, n = Inf, width = Inf)

# standardize: convert CMS types to match CLEAR 
df.misconduct_cms <- df.misconduct_cms |>
  mutate(
    cpdmember_complaint = case_when(
      cpdmember_complaint == TRUE ~ "CPD EMPLOYEE",
      cpdmember_complaint == FALSE ~ "CIVILIAN",
      TRUE ~ NA_character_
    ),
    closed_date = mdy(closed_date)
  )

# replace blank strings with NA 
df.misconduct_clear <- df.misconduct_clear |>
  mutate(across(where(is.character) & !geometry, ~ na_if(., "")))

df.misconduct_cms <- df.misconduct_cms |>
  mutate(across(where(is.character) & !geometry, ~ na_if(., "")))

# 2. MERGE STANDARDIZED DFS -----------------------------------------------

df.misconduct_combined <- bind_rows(
  # add tag for source system
  df.misconduct_clear |> 
    mutate(source_period = "clear"),
  # standardize variable names
  df.misconduct_cms |> 
    rename(
      accused_appointed_date = accused_apt_date,
      accused_gender = accused_sex,
      accused_position = accused_position_rank,
      accused_star_no = accused_star,
      allegation_category_cd = code,
      beat_of_incident = beat,
      complainant_type = cpdmember_complaint,
      district_of_incident = district,
      final_discipline = current_penalty,
      final_finding = current_finding,
      investigation_end_date = closed_date,
      investigation_status = status,
      investigator_gender = inv_gender,
      investigator_position = inv_rank,
      investigator_race = inv_race,
      investigator_star_no = inv_star,
      recommended_discipline = initial_penalty,
      recommended_finding = initial_finding,
      street_direction = direction,
      street_name = street,
      street_number = address,
      zip_cd = zip_postal_code
      ) |>
    # add cms tag
    mutate(source_period = "cms")
  )

stopifnot(
  "Merge Error: Row count mismatch after bind_rows" =
    nrow(df.misconduct_combined) == nrow(df.misconduct_clear) + nrow(df.misconduct_cms)
)

# check missing columns (all NA) by source
# tbl.missing <- df.misconduct_combined |>
#   group_by(source_period) |>
#   summarise(across(everything(), ~all(is.na(.)))) |>
#   pivot_longer(-source_period,
#                names_to = "column",
#                values_to = "all_missing"
#                ) |>
#   filter(all_missing == TRUE)
# print(tbl.missing, n = Inf, width = Inf)

# → missing to address in cleaning
#   CMS: allegation_category_desc
#   CLEAR: allegation/reporting category

# 3. CLEAN ----------------------------------------------------------------

## 3.1 Beats ----

df.misconduct_combined <- df.misconduct_combined |>
  mutate(
    # pad 3-digit beats to 4 digits
    beat_clean = if_else(
      nchar(as.character(beat_of_incident)) == 3,
      str_pad(beat_of_incident, width = 4, pad = "0"),
      as.character(beat_of_incident)
    ),
    # recode 0 and NA to "True Missing"
    beat_clean = case_when(
      is.na(beat_clean) | beat_clean == "0" ~ "True Missing",
      TRUE ~ beat_clean
    ) |> as.factor()
  )

stopifnot(
  "Clean Error: Non-4-character beat codes detected" =
    df.misconduct_combined |>
    filter(beat_clean != "True Missing") |>
    filter(nchar(as.character(beat_clean)) != 4) |>
    nrow() == 0
)

## 3.2 Extract year filed ----
df.misconduct_combined <- df.misconduct_combined |>
  mutate(year_filed = year(complaint_date))

## 3.3 Check missingness in beat_clean within analytic window ----

# df.misconduct_combined |>
#   filter(beat_clean == "True Missing") |>
#   filter(investigation_status == "Closed") |>
#   filter(between(year_filed, 2013, 2021)) |>
#   filter(!is.na(recommended_finding)) |>
#   filter(complainant_type == "CIVILIAN") |>
#   count(district_of_incident)

# → 271/274 cases with missing beats also have missing districts;
#   flagged for follow-up in EDA; not addressed in this pipeline

# SAVE --------------------------------------------------------------------
save(df.misconduct_combined,
     file = here("data/cleaning/df.misconduct_combined.rda"))
