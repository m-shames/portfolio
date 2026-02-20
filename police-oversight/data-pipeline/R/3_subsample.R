# ==============================================================================
# Filter ITS Analysis Subsample
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Filter merged FOIA+ACS data to ITS analysis subsample:
#     Symmetric 4-year window around intervention (2013-09-15 to 2021-09-15)
#     Closed investigations only
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

# 1. FILTER FOR ITS WINDOW ------------------------------------------------

## 1.1 ITS window ----
# intervention_date defined in utils.R (2017-09-15)
start_date <- intervention_date - years(4)  
end_date <- intervention_date + years(4)    

## 1.2 Filter ----
df.foia_subsample <- df.foia_acs_merged |>
  filter(complaint_date >= start_date & complaint_date <= end_date)

stopifnot(
  "Filter Error: Cases outside complaint window detected" =
    df.foia_subsample |>
    filter(complaint_date < start_date | complaint_date > end_date) |>
    nrow() == 0 
)

# 2. FILTER CLOSED CASES --------------------------------------------------

## 2.1 Explore open cases ----
# df.foia_subsample |>
#   filter(investigation_status == "Open") |>
#   count(year = year(complaint_date)) |>
#   arrange(year)

# → note: FOIA fulfilled June 22, 2022; investigation_status reflects that date
#   open cases skew toward later years → dropping may bias results if
#   disproportionately serious; accepted tradeoff given small N of open cases

## 2.2 Filter closed only  ----
df.foia_subsample <- df.foia_subsample |> 
  filter(investigation_status == "Closed") 

# validate
stopifnot(
 "Filter Error: Open investigations remain in subsample" =
    nrow(filter(df.foia_subsample, investigation_status != "Closed")) == 0,
  
  "Filter Error: Closed cases missing end date" =
    nrow(filter(df.foia_subsample, is.na(investigation_end_date))) == 0
 )

# 3. FILTER JURISDICTION --------------------------------------------------

## 3.1 Explore beat jurisdictions ----
# df.foia_subsample |>
#   filter(beat_clean %in% c("3100", "4100")) |>
#   count(beat_clean, geometry)

# → beats 3100 (airports) and 4100 (outside Chicago) follow diff accountability 
#   processes; exclude both from analytical sample 

## 3.2 Drop 3100 & 4100 ----
df.foia_subsample <- df.foia_subsample |>
  filter(!beat_clean %in% c("3100", "4100")) |> 
  mutate(beat_clean = as.factor(beat_clean))

# SAVE --------------------------------------------------------------------
save(df.foia_subsample, 
     file = here("data/cleaning/df.foia_subsample.rda"))
