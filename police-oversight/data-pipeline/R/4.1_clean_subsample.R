# ==============================================================================
# Filter & Clean ITS Analysis Subsample
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Clean & recode IDs, incident and case-related variables
#   Construct Officer ID; grouping variables; and ITS assignment variables

# Dependencies
#   Run after: 3
#   Output used by: 5

# Output
#   data/cleaning/df.foia_subsample_clean.rda
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse)
library(here)

## load data & utils ----
load(here("data/cleaning/df.foia_subsample.rda"))
source(here("data-pipeline/utils.R"))

## explore & organize ----

# run integrity check from utils.R
if (interactive()) {
  check_coverage(df.foia_subsample)
}

# reorder df cols using utils vectors
df.foia_subsample <- df.foia_subsample |>
  select(
    all_of(v.id),
    all_of(v.cpd_geo),
    all_of(v.case),
    all_of(v.allegation),
    all_of(v.outcomes),
    all_of(v.officer),
    all_of(v.c_atts),
    all_of(v.investigator),
    all_of(v.spatial),
    all_of(v.acs_n),
    all_of(v.acs_pct)
  )

# 1. IDs ------------------------------------------------------------------
# skimr::skim_without_charts(df.foia_subsample[v.id])
#   allegation_key treated in script 5

## 1.1 Officer ID ----

df.foia_subsample <- df.foia_subsample |>
  mutate(
    
    # clean star number: replace junk values with NA
    accused_star_no = str_trim(accused_star_no),
    accused_star_no = str_remove(accused_star_no, "^#"),
    accused_star_no = if_else(accused_star_no %in% v.junk_stars, NA_character_, accused_star_no),
    
    # clean names: replace junk values with NA
    accused_first_name = str_trim(accused_first_name),
    accused_first_name = if_else(is_junk(accused_first_name), NA_character_, accused_first_name),
    
    accused_last_name = str_trim(accused_last_name),
    accused_last_name = if_else(is_junk(accused_last_name), NA_character_, accused_last_name)
  ) |>
  
  # concatenate into composite officer ID
  unite("officer_id", 
        accused_star_no, accused_last_name, accused_first_name, accused_birth_year,
        sep = "_", remove = FALSE) |> 
  relocate(officer_id, .after = record_id)

## 1.2 Clean types ----
df.foia_subsample <- df.foia_subsample |>
  mutate(source_period = as.factor(source_period))

# 2. CPD GEO --------------------------------------------------------------
# skimr::skim_without_charts(df.foia_subsample[v.cpd_geo])
#   beat_clean created & padded in script 2.1

## 2.1 CPD District ----

# remove leading zeros
df.foia_subsample <- df.foia_subsample |>
  mutate(
    district_of_incident = na_if(district_of_incident, "000"),
    district_of_incident = str_sub(district_of_incident, 2, 3)
  )

## 2.2 CPD Area ----

# assign post 2019 CPD district groupings
df.foia_subsample <- df.foia_subsample |>
  mutate(area = case_when(
    is.na(district_of_incident) ~ NA_character_,
    district_of_incident %in% c("02", "03", "07", "08", "09") ~ "South Side",
    district_of_incident %in% c("04", "05", "06", "22") ~ "Far South Side",
    district_of_incident %in% c("01", "12", "18", "19", "20", "24") ~ "DT & North",
    district_of_incident %in% c("10", "11", "15") ~ "West",
    district_of_incident %in% c("14", "16", "17", "25") ~ "Northwest",
    TRUE ~ "Check area" 
  )) |>
  mutate(area = as.factor(area),
         district_of_incident = as.factor(district_of_incident)
         ) |> 
  relocate(area, .after = district_of_incident)

# 3. CASE -----------------------------------------------------------------
# skimr::skim_without_charts(df.foia_subsample[(v.case)])
#   → allegation category variables treated in script 4.2

## 3.1 Incident date ----
df.foia_subsample <- df.foia_subsample |>
  mutate(incident_date = as.Date(incident_datetime)) |> 
  relocate(incident_date, .before = incident_datetime)

## 3.2 On duty ----
df.foia_subsample <- df.foia_subsample |>
  mutate(
    accused_on_duty = case_when(
      accused_on_duty %in% c("No", "Off Duty") ~ "No",
      accused_on_duty %in% c("Yes", "On Duty") ~ "Yes",
      TRUE ~ NA_character_
    ),
    accused_on_duty = as.factor(accused_on_duty)
  )

## 3.3 Groupings ----

### n officers per case ----
df.foia_subsample <- df.foia_subsample |>
  group_by(record_id) |>
  mutate(n_OFs = n_distinct(officer_id[!is.na(officer_id)])) |>
  ungroup() |> 
  relocate(n_OFs, .after = officer_id)

### allegations ----

# confirm structure → each allegation_key is nested within a single record_id 
stopifnot(
  "Data Structure Error: allegation_key is not nested within a single record_id" = 
    df.foia_subsample |>
    filter(!is.na(allegation_key)) |>
    group_by(allegation_key) |>
    summarise(n_records = n_distinct(record_id), .groups = "drop") |>
    filter(n_records > 1) |>
    nrow() == 0
)

#### n incidents per allegation ----
df.foia_subsample <- df.foia_subsample |>
  group_by(allegation_key) |>
  mutate(n_AK_dupes = n()) |>
  ungroup() |> 
  relocate(n_AK_dupes, .after = n_OFs)

#### n allegations per officer ----
df.foia_subsample <- df.foia_subsample |>
  group_by(record_id, officer_id) |>
  mutate(n_OF_AKs = n_distinct(allegation_key)) |>
  ungroup() |> 
  relocate(n_OF_AKs, .after = n_OFs)

# 4. OFFICER DEMOGRAPHICS -------------------------------------------------
# skimr::skim_without_charts(df.foia_subsample[(v.officer)])

## 4.1 Gender collapsed ----
df.foia_subsample <- df.foia_subsample |>
  mutate(
    accused_gender_c = case_when(
      is_junk(accused_gender) | is.na(accused_gender) ~ "Missing",
      accused_gender %in% c("F", "FEMALE")            ~ "Female",
      accused_gender %in% c("M", "MALE")              ~ "Male",
      TRUE                                            ~ "Check OF gender"
    ) |> 
      factor(levels = c("Male", "Female", "Missing", "Check OF gender"))
  ) |> 
  relocate(accused_gender_c, .after = accused_gender)

# validate
# df.foia_subsample |> 
#   count(accused_gender, accused_gender_c) |> 
#   arrange(accused_gender_c, desc(n))

## 4.2 Race collapsed ----
df.foia_subsample <- df.foia_subsample |>
  mutate(
    accused_race_c = case_when(
      is_junk(accused_race) | is.na(accused_race)                 ~ "Missing",
      accused_race %in% c("Hispanic, Latino, or Spanish origin",
                          "Hispanic, Latino, or Spanish Origin",
                          "WWH", "WBH", "S")                      ~ "Hispanic",
      accused_race %in% c("American Indian or Alaska Native", 
                          "API", "Asian", "I")                    ~ "AAPI",
      accused_race %in% c("Black or African American", "BLK")     ~ "Black",
      accused_race %in% c("WHI", "White")                         ~ "White",
      TRUE                                                        ~ "Check OF race"
    ) |> 
      factor(levels = c("Black", "Hispanic", "White", "AAPI", "Missing", "Check OF race"))
  ) |> 
  relocate(accused_race_c, .after = accused_race)

# validate
# df.foia_subsample |> 
#   count(accused_race, accused_race_c) |> 
#   arrange(accused_race_c, desc(n))

## 4.3 Years on force ----
# days between CPD appointment & complaint date, floored to whole years
df.foia_subsample <- df.foia_subsample |>
  mutate(
    accused_years_cpd = as.numeric(
      difftime(complaint_date, accused_appointed_date, units = "days")
      ) / 365.25,
    accused_years_cpd = if_else(accused_years_cpd < 0, NA_real_, floor(accused_years_cpd))
  ) |>
  relocate(accused_years_cpd, .after = accused_appointed_date)

## 4.4 Validate dates ----
#   → 1 case where accused_appointed_date > complaint_date (record 2020-0002751,
#   appointed 2020-12-16 but complaint filed 2020-06-17; likely data entry error).
#   accused_years_cpd set to NA for this case by the if_else() above.
stopifnot(
  "Audit Failure: Unexpected NA in accused_years_cpd where both source dates are present" =
    df.foia_subsample |>
    filter(!is.na(accused_appointed_date), !is.na(complaint_date)) |>
    filter(accused_appointed_date <= complaint_date) |>  # exclude known bad case
    filter(is.na(accused_years_cpd)) |>
    nrow() == 0
)

# 5. COMPLAINANT AGGREGATION ----------------------------------------------
# skimr::skim_without_charts(df.foia_subsample[(v.c_atts)])

## 5.1 N Complainants collapsed ----
df.foia_subsample <- df.foia_subsample |>
  mutate(
    n_Cs_collapsed = case_when(
      n_complainants == 1 ~ "1",
      n_complainants %in% 2:3 ~ "2-3",
      n_complainants > 3 ~ "4+"
    ),
    n_Cs_collapsed = fct_relevel(as.factor(n_Cs_collapsed), "1", "2-3", "4+")
  ) |>
  relocate(n_Cs_collapsed, .after = n_complainants)

## 5.2 Gender tally----

# gender sum check
stopifnot(
  "Data Inconsistency: Sum of gender categories does not match total n_complainants" = 
    df.foia_subsample |>
    mutate(gender_sum = c_gender_Male + c_gender_Female + 
             c_gender_True_Missing + c_gender_Other + c_gender_Unknown) |>
    filter(gender_sum != n_complainants) |>
    nrow() == 0
)

### gender tally ----
df.foia_subsample <- df.foia_subsample |>
  mutate(
    # logic check
    n_genders = (c_gender_Male > 0) + (c_gender_Female > 0),
    n_gender_unk = c_gender_True_Missing + c_gender_Other + c_gender_Unknown,
    # recode
    c_gender_tally = case_when(
      n_gender_unk > 0                                     ~ "Other/Missing",
      n_genders == 1 & c_gender_Male >= 1                  ~ "All Male",
      n_genders == 1 & c_gender_Female >= 1                ~ "All Female",
      n_genders == 2                                       ~ "Male and Female",
      TRUE                                                 ~ "Check gender tally"
    ),
    c_gender_tally = factor(c_gender_tally,
                            levels = c("All Male", "All Female", 
                                       "Male and Female", "Other/Missing",
                                       "Check gender tally"))
  ) |>
  select(-n_genders, -n_gender_unk) |>
  relocate(c_gender_tally, .after = n_Cs_collapsed)

## 5.3 Race tally ----
df.foia_subsample <- df.foia_subsample |>
  mutate(
    # logic check
    n_races = rowSums(across(c(c_race_Black, c_race_Hispanic, c_race_White, c_race_AAPI, c_race_Other)) > 0),
    n_minority = rowSums(across(c(c_race_Black, c_race_Hispanic, c_race_AAPI, c_race_Other)) > 0),
    n_race_unk = c_race_True_Missing + c_race_Unknown,
    
    ### race tally ----
    c_race_tally = case_when(
      n_race_unk > 0 ~ "Missing",
      n_races == 1 & c_race_Black >= 1 ~ "All Black",
      n_races == 1 & c_race_Hispanic >= 1 ~ "All Hispanic",
      n_races == 1 & c_race_White >= 1 ~ "All White",
      n_races == 1 & (c_race_AAPI >= 1 | c_race_Other >= 1) ~ "Other",
      n_races > 1 ~ "Multiple Races",
      TRUE ~ "Check race tally"
    ),
    
    ### minority status tally ----
    c_race_tally_mino = case_when(
      n_race_unk > 0 ~ "Missing",
      c_race_White > 0 & n_minority == 0 ~ "All White",
      n_minority > 0 & c_race_White == 0 ~ "All Minority",
      c_race_White > 0 & n_minority > 0 ~ "Mixed",
      TRUE ~ "Check minority tally"
    )
  ) |> 
  mutate(across(c(c_race_tally, c_race_tally_mino), as.factor)) |> 
  select(-n_races, -n_minority, -n_race_unk) |>
  relocate(c(c_race_tally, c_race_tally_mino), .after = c_gender_tally)

# 6. OUTCOMES -------------------------------------------------------------
# skimr::skim_without_charts(df.foia_subsample[(v.outcomes)])

## 6.1 Findings ----

### rec finding collapsed ----
df.foia_subsample <- df.foia_subsample |> 
  mutate(
    recommended_finding_c1 = case_when(
      is.na(recommended_finding)                               ~ NA_character_,
      recommended_finding %in% c("Administratively Closed", 
                                 "Administratively Terminated", 
                                 "Closed/No Finding", 
                                 "No Affidavit")              ~ "Admin Closure",
      recommended_finding %in% c("Exonerated",
                                 "Within Policy Officer Involved Shooting") ~ "Exonerated",
      recommended_finding == "Not Sustained"                  ~ "Not Sustained",
      recommended_finding == "Sustained"                      ~ "Sustained", 
      recommended_finding == "Unfounded"                      ~ "Unfounded",
      TRUE                                                    ~ "Check rec finding"
    ) |> as.factor()
  ) |> 
  relocate(recommended_finding_c1, .after = recommended_finding)

# validate
# df.foia_subsample |>
#   count(recommended_finding, recommended_finding_c1) |>
#   arrange(recommended_finding_c1, desc(n))

### final finding collapsed ----
df.foia_subsample <- df.foia_subsample |> 
  mutate(
    final_finding_c1 = case_when(
      is.na(final_finding)                                    ~ NA_character_,
      final_finding %in% c("Administratively Closed", 
                           "Administratively Terminated", 
                           "No Affidavit")                    ~ "Admin Closure",
      final_finding %in% c("Exonerated",
                           "Within Policy Officer Involved Shooting") ~ "Exonerated",
      final_finding == "Not Sustained"                        ~ "Not Sustained",
      final_finding == "Sustained"                            ~ "Sustained", 
      final_finding == "Unfounded"                            ~ "Unfounded",
      TRUE                                                    ~ "Check final finding"
    ) |> as.factor()
  ) |> 
  relocate(final_finding_c1, .after = final_finding)

# validate
# df.foia_subsample |>
#   count(final_finding, final_finding_c1) |>
#   arrange(final_finding_c1, desc(n))

## 6.2 Discipline ----

# uppercase source variables to simplify pattern matching
df.foia_subsample <- df.foia_subsample |>
  mutate(
    recommended_discipline = toupper(recommended_discipline),
    final_discipline       = toupper(final_discipline)
  )

### rec discipline collapsed ----
df.foia_subsample <- df.foia_subsample |>
  mutate(
    # extract day count from suspension strings for numeric range bucketing
    # lookahead (?=-DAY| DAY) extracts suspension days, not leading numbers
    # greedy \\d+ captures full number (e.g. "25-DAY" → 25, not 5)
    suspension_days = as.numeric(str_extract(recommended_discipline, "\\d+(?=-DAY| DAY)")),
    
    recommended_discipline_c1 = case_when(
      is.na(recommended_discipline)                                   ~ NA_character_,
      str_detect(recommended_discipline, 
                 "NO ACTION|ADMINISTRATIVELY CLOSED")                 ~ "No action",
      str_detect(recommended_discipline, "VIOLATION NOTED")           ~ "Violation noted",
      str_detect(recommended_discipline, "REPRIMAND")                 ~ "Reprimand",
      str_detect(recommended_discipline, "SEPARATION|TERMINATION")    ~ "Termination/Separation",
      str_detect(recommended_discipline, "RESIGNED|DECEASED")         ~ "Officer resigned/deceased",
      str_detect(recommended_discipline, "OVER 30 DAYS")              ~ "31-90 day suspension",
      str_detect(recommended_discipline, "SUSPEND|DAY") &
        suspension_days <= 7                                          ~ "1-7 day suspension",
      str_detect(recommended_discipline, "SUSPEND|DAY") &
        between(suspension_days, 8, 30)                               ~ "8-30 day suspension",
      str_detect(recommended_discipline, "SUSPEND|DAY") &
        between(suspension_days, 31, 90)                              ~ "31-90 day suspension",
      str_detect(recommended_discipline, "SUSPEND|DAY") &
        suspension_days > 90                                          ~ "90 day-2 year suspension",
      TRUE                                                            ~ "Check rec discipline"
    ) |> factor(levels = c("No action", "Violation noted", "Reprimand",
                           "1-7 day suspension", "8-30 day suspension",
                           "31-90 day suspension", "90 day-2 year suspension",
                           "Termination/Separation", "Officer resigned/deceased",
                           "Check rec discipline")),
    
    suspension_days = NULL  # drop intermediate variable
  ) |> 
  relocate(recommended_discipline_c1, .after = recommended_discipline)

# validate
# df.foia_subsample |>
#   count(recommended_discipline, recommended_discipline_c1) |>
#   arrange(recommended_discipline_c1, desc(n)) |>
#   print(n = Inf)

### final discipline collapsed ----
df.foia_subsample <- df.foia_subsample |>
  mutate(
    # extract day count from suspension strings for numeric range bucketing
    # lookahead (?=-DAY| DAY) extracts suspension days, not leading numbers
    # greedy \\d+ captures full number (e.g. "25-DAY" → 25, not 5)
    suspension_days = as.numeric(str_extract(final_discipline, "\\d+(?=-DAY| DAY)")),
    
    final_discipline_c1 = case_when(
      is.na(final_discipline)                                         ~ NA_character_,
      str_detect(final_discipline, 
                 "NO ACTION|ADMINISTRATIVELY CLOSED")                 ~ "No action",
      str_detect(final_discipline, "VIOLATION NOTED")                 ~ "Violation noted",
      str_detect(final_discipline, "REPRIMAND")                       ~ "Reprimand",
      str_detect(final_discipline, "SEPARATION|TERMINATION")          ~ "Termination/Separation",
      str_detect(final_discipline, "RESIGNED|DECEASED")               ~ "Officer resigned/deceased",
      str_detect(final_discipline, "OVER 30 DAYS")                    ~ "31-90 day suspension",
      str_detect(final_discipline, "SUSPEND|DAY") &
        suspension_days <= 7                                          ~ "1-7 day suspension",
      str_detect(final_discipline, "SUSPEND|DAY") &
        between(suspension_days, 8, 30)                               ~ "8-30 day suspension",
      str_detect(final_discipline, "SUSPEND|DAY") &
        between(suspension_days, 31, 90)                              ~ "31-90 day suspension",
      str_detect(final_discipline, "SUSPEND|DAY") &
        suspension_days > 90                                          ~ "90 day-2 year suspension",
      TRUE                                                            ~ "Check final discipline"
    ) |> factor(levels = c("No action", "Violation noted", "Reprimand",
                           "1-7 day suspension", "8-30 day suspension",
                           "31-90 day suspension", "90 day-2 year suspension",
                           "Termination/Separation", "Officer resigned/deceased",
                           "Check final discipline")),
    
    suspension_days = NULL  # drop intermediate variable
  ) |>
  relocate(final_discipline_c1, .after = final_discipline)

# validate
# df.foia_subsample |>
#   count(final_discipline, final_discipline_c1) |>
#   arrange(final_discipline_c1, desc(n)) |>
#   print(n = Inf)

# 7. ITS INTERVENTION -----------------------------------------------------
# agency_end: primary ITS exposure variable → assigns allegations to IPRA/COPA
#   based on investigation end date (i.e., which agency closed the case).
# treatment_group: three-way classification retained for robustness checks
#   → allows "Straddling" cases (opened under IPRA, closed under COPA) to be
#   analyzed separately/to test sensitivity of main ITS estimates.

# date integrity check
stopifnot(
  "Temporal Logic Error: investigation_end_date occurs before complaint_date" = 
    df.foia_subsample |>
    filter(investigation_end_date < complaint_date) |>
    nrow() == 0
)

# create variables
df.foia_subsample <- df.foia_subsample |>
  mutate(
    
    ## 7.1 Agency assignment ----
    agency_end = case_when(
      investigation_end_date < intervention_date ~ "IPRA",
      investigation_end_date >= intervention_date ~ "COPA",
      TRUE ~ "Check agency"  
    ),
    agency_end = fct_relevel(agency_end, "IPRA", "COPA", "Check agency"),
    
    ## 7.2 ITS treatment group ----
    treatment_group = case_when(
      complaint_date < intervention_date & investigation_end_date < intervention_date ~ "Pre",
      complaint_date >= intervention_date & investigation_end_date >= intervention_date ~ "Post",
      complaint_date < intervention_date & investigation_end_date >= intervention_date ~ "Straddling",
      TRUE ~ "Check treatment"
    ),
    treatment_group = fct_relevel(treatment_group, "Pre", "Straddling", "Post", "Check treatment")
  ) |> 
  relocate(c(agency_end, treatment_group), .after = record_id)

# FINAL INTEGRITY CHECK ---------------------------------------------------

stopifnot(
  
  "Audit Failure: District mapping contains 'Check area' values" = 
    nrow(filter(df.foia_subsample, area == "Check area")) == 0,
  
  "Audit Failure: Officer Gender contains 'Check' values" = 
    nrow(filter(df.foia_subsample, accused_gender_c == "Check OF gender")) == 0,
  
  "Audit Failure: Officer Race contains 'Check' values" = 
    nrow(filter(df.foia_subsample, accused_race_c == "Check OF race")) == 0,

  "Audit Failure: Complainant Gender Tally contains 'Check' values" = 
    nrow(filter(df.foia_subsample, c_gender_tally == "Check gender tally")) == 0,
  
  "Audit Failure: Complainant Race Tally contains 'Check' values" = 
    nrow(filter(df.foia_subsample, c_race_tally == "Check race tally")) == 0,
  
  "Audit Failure: Complainant Minority Tally contains 'Check' values" = 
    nrow(filter(df.foia_subsample, c_race_tally_mino == "Check minority tally")) == 0,
  
  "Audit Failure: Unmatched recommended_finding values" =
    nrow(filter(df.foia_subsample, recommended_finding_c1 == "Check rec finding")) == 0,
  
  "Audit Failure: Unmatched final_finding values" =
    nrow(filter(df.foia_subsample, final_finding_c1 == "Check final finding")) == 0,
  
  "Audit Failure: Unmatched recommended_discipline values" =
    nrow(filter(df.foia_subsample, recommended_discipline_c1 == "Check rec discipline")) == 0,
  
  "Audit Failure: Unmatched final_discipline values" =
    nrow(filter(df.foia_subsample, final_discipline_c1 == "Check final discipline")) == 0,
  
  "Audit Failure: Unmatched values in agency_end" =
    nrow(filter(df.foia_subsample, agency_end == "Check agency")) == 0,
  
  "Audit Failure: Unmatched values in treatment_group" =
    nrow(filter(df.foia_subsample, treatment_group == "Check treatment")) == 0
  
  )

# SAVE --------------------------------------------------------------------

# rename to distinguish from intermediate saves earlier in pipeline
df.foia_subsample_clean <- df.foia_subsample

save(df.foia_subsample_clean, 
     file = here("data/cleaning/df.foia_subsample_clean.rda"))
