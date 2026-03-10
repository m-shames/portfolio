# ==============================================================================
# Filter ITS Analysis Subsample
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Filter merged FOIA+ACS data to ITS analysis subsample:
#     Cases filed & closed within symmetric 4-year window around intervention (2013-09-15 to 2021-09-15)
#     Drop beats outside CPD jurisdiction
#   Note: complainant type not filtered here; civilian restriction applied post cleaning 

# Dependencies
#   Run after: 2.3
#   Output used by: 4.1

# Output
#   data/cleaning/df.foia_subsample.rda
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse)
library(here)

## load data & utils ----
load(here("data/cleaning/df.foia_acs_merged.rda"))
source(here("data-pipeline/utils.R"))

## ITS window constants ----
# (intervention_date defined in utils.R)
start_date <- intervention_date - years(4)  
end_date <- intervention_date + years(4)   

# 1. FILTER COMPLAINT FILE DATE -------------------------------------------

track_sample(df.foia_acs_merged, "0. Merged dataset")

df.foia_subsample <- df.foia_acs_merged |>
  filter(complaint_date >= start_date & complaint_date <= end_date)

stopifnot(
  "Filter Error: Cases outside complaint file window detected" =
    df.foia_subsample |>
    filter(complaint_date < start_date | complaint_date > end_date) |>
    nrow() == 0 
)

track_sample(df.foia_subsample, "1. Complaint file-date within window")

# 2. FILTER INVESTIGATION END DATE ----------------------------------------

if (interactive()) {
  # ensure all closed cases have end-dates and all missing end-dates are open
  df.foia_subsample |> 
    filter(is.na(investigation_end_date)) |> 
    count(investigation_status)
  
  df.foia_subsample |>
    filter(investigation_status == "Closed",
           is.na(investigation_end_date)) |>
    summarise(n_cases = n_distinct(record_id))
}

# filter end date (implicitly drops all open cases)
df.foia_subsample <- df.foia_subsample |>
  filter(investigation_end_date >= start_date & investigation_end_date <= end_date)

stopifnot(
  "Filter Error: Cases outside investigation end window detected" =
    df.foia_subsample |>
    filter(investigation_end_date < start_date | investigation_end_date > end_date) |>
    nrow() == 0 
)

track_sample(df.foia_subsample, "2. Investigation end-date within window")

# 3. FILTER JURISDICTION --------------------------------------------------

# explore unknown beats 
if (interactive()) {
  df.foia_subsample |>
    filter(beat_clean %in% c("3100", "4100")) |>
    count(beat_clean, geometry)
  # → beats 3100 (airports) and 4100 (outside Chicago) follow diff accountability 
  #   processes; exclude both from analytical sample 
}

# drop 3100 & 4100
df.foia_subsample <- df.foia_subsample |>
  filter(!beat_clean %in% c("3100", "4100")) |> 
  mutate(beat_clean = as.factor(beat_clean))

track_sample(df.foia_subsample, "3. Within CPD Jurisdiction")

# SAVE --------------------------------------------------------------------
save(df.foia_subsample, 
     file = here("data/cleaning/df.foia_subsample.rda"))
