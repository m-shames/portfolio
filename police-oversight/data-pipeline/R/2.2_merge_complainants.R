# ==============================================================================
# Merge & Clean Complainant Tables (CLEAR + CMS)
# Project: COPA Evaluation
# Author: Michelle Shames 

# About 
#   Merge FOIA-obtained complainant datasets (CLEAR + CMS)
#   All complainant variables prefixed with "c_" for identification post-merge
#   Collapse race, gender, and role categories

# Dependencies
#   Run after: 1 (bigquery extraction)
#   Output used by: 2.3 (merge FOIA-ACS)

# Output
#   data/cleaning/df.complainants_combined.rda
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse)
library(here)

## load data ----
load(here("data/raw/foia/df.complainants_clear.rda"))
load(here("data/raw/foia/df.complainants_cms.rda"))

# 1. PREP COMPLAINANT DFs -------------------------------------------------

# compare DF structures
# tbl.compare <- tibble(
#   clear_vars = names(df.complainants_clear),
#   clear_types = map_chr(df.complainants_clear, ~ class(.)[1])
# ) |>
#   full_join(
#     tibble(
#       cms_vars = names(df.complainants_cms),
#       cms_types = map_chr(df.complainants_cms, ~ class(.)[1])
#     ),
#     by = c("clear_vars" = "cms_vars")
#   ) |>
#   rename(variable = clear_vars) |>
#   mutate(types_match = clear_types == cms_types)
# 
# print(tbl.compare, n = Inf, width = Inf)
# # → only mismatch: CMS is missing investigation_status

# replace blank strings with NA 
df.complainants_clear <- df.complainants_clear |>
  mutate(across(where(is.character), ~ na_if(., "")))

df.complainants_cms <- df.complainants_cms |>
  mutate(across(where(is.character), ~ na_if(., "")))

# 2. MERGE STANDARDIZED DFS -----------------------------------------------

df.complainants_combined <- bind_rows(
  df.complainants_clear |> mutate(source_period = "clear"),
  df.complainants_cms |> mutate(source_period = "cms")
  )

stopifnot(
  "Merge Error: Row count mismatch after bind_rows" =
    nrow(df.complainants_combined) == nrow(df.complainants_clear) + nrow(df.complainants_cms)
)

# 3. CLEAN ----------------------------------------------------------------

## 3.1 Update variable names & types ----
df.complainants_combined <- df.complainants_combined |>
  mutate(across(c(
    race, gender, role, cpd, source_period
    ), 
    as.factor)) |> 
  rename_with(~ paste0("c_", .), everything())

## 3.2 Race collapses ----
# NOTE: single-character codes are legacy CLEAR abbreviations:
#   → "I" = Asian/Pacific Islander, "S" = Spanish/Hispanic, "U" = Unknown
#   Code reference found here <https://www.cpdwiki.org/wiki/quick_reference/race_codes>

df.complainants_combined <- df.complainants_combined |>
  mutate(c_race_collapsed = case_when(
    c_race %in% c("AMER IND/ALASKAN NATIVE", 
                  "American Indian or Alaska Native",
                  "API", 
                  "Asian",
                  "ASIAN / PACIFIC ISLANDER",
                  "ASIAN/PACIFIC ISLANDER",
                  "Native Hawaiian or Other Pacific Islander",
                  "I"
                  ) ~ "AAPI",
    
    c_race %in% c("Middle Eastern or North African",
                  "Some Other Race, Ethnicity, or Origin"
                  ) ~ "Other",
    
    c_race %in% c("BLACK", 
                  "Black or African American",
                  "BLK"
                  ) ~ "Black",
    
    c_race %in% c("Hispanic, Latino, or Spanish origin",
                  "Hispanic, Latino, or Spanish Origin", 
                  "BLACK HISPANIC",
                  "WHITE HISPANIC", 
                  "WWH",
                  "SPANISH", 
                  "S"
                  ) ~ "Hispanic",
    
    c_race %in% c("White", 
                  "WHITE", 
                  "WHI"
                  ) ~ "White",
    
    c_race %in% c("UNKNOWN", 
                  "UNKNOWN / REFUSED", 
                  "U", 
                  "Not listed", 
                  "Prefer Not to Say" 
                  ) ~ "Unknown",
    
    is.na(c_race) ~ "True_Missing",
    
    # catch-all to identify any unmapped values
    TRUE ~ "Check_race"  
  )) |>
  mutate(c_race_collapsed = as.factor(c_race_collapsed)) |> 
  relocate(c_race_collapsed, .after = c_race)

## 3.3 Gender collapsed ----
df.complainants_combined <- df.complainants_combined |>
  mutate(
    c_gender_collapsed = case_when(
      c_gender == "FEMALE" ~ "Female",
      
      c_gender == "MALE" ~ "Male",
      
      c_gender %in% c("NON-BINARY/THIRD GENDER", 
                      "PREFER TO SELF-DESCRIBE"
                      ) ~ "Other",
      
      c_gender %in% c("NOT LISTED",
                      "PREFER NOT TO SAY"
                      ) ~ "Unknown",
      
      is.na(c_gender) ~ "True_Missing",
      
      TRUE ~ "Check_gender"
      ),
    c_gender_collapsed = as.factor(c_gender_collapsed)
  ) |>
  relocate(c_gender_collapsed, .after = c_gender)

## 3.4 Role collapsed ----
df.complainants_combined <- df.complainants_combined |>
  mutate(
    c_role_collapsed = case_when(
      c_role %in% c("Complainant", 
                    "Complainant/Victim",
                    "Victim",
                    "Subject/Detainee",
                    "Reporting Party: Subject"
                    ) ~ "Subject",
      
      c_role %in% c("Reporting Party: Third Party", 
                    "Reporting Party: Witness"
                    ) ~ "Third_Party",
      
      is.na(c_role) ~ "True_Missing",
      
      TRUE ~ "Check_role"
      ),
    c_role_collapsed = as.factor(c_role_collapsed)
  ) |>
  relocate(c_role_collapsed, .after = c_role)

## 3.5 Validate recodes ----

# check crosswalks
# df.complainants_combined |>
#   count(c_race, c_race_collapsed) |>
#   arrange(c_race_collapsed, desc(n)) |> 
#   print(n = Inf)
# df.complainants_combined |>
#   count(c_gender, c_gender_collapsed) |>
#   arrange(c_gender_collapsed, desc(n))
# df.complainants_combined |>
#   count(c_role, c_role_collapsed) |>
#   arrange(c_role_collapsed, desc(n))

stopifnot(
  "Recode Error: Unmapped values in c_race_collapsed" =
    nrow(filter(df.complainants_combined, c_race_collapsed == "Check_race")) == 0,
  "Recode Error: Unmapped values in c_gender_collapsed" =
    nrow(filter(df.complainants_combined, c_gender_collapsed == "Check_gender")) == 0,
  "Recode Error: Unmapped values in c_role_collapsed" =
    nrow(filter(df.complainants_combined, c_role_collapsed == "Check_role")) == 0
)

# SAVE --------------------------------------------------------------------
save(df.complainants_combined, 
     file = here("data/cleaning/df.complainants_combined.rda"))
