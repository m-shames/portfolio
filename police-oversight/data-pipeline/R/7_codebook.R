# ==============================================================================
# Finalize Dataset & Generate Codebook
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Select final variable subset for analysis & documentation
#   Attach variable labels & dataset metadata
#   Render HTML codebook via sjPlot::view_df()

# Dependencies
#   Run after: 6.3

# Output
#   data/final/df.foia_labeled.rda
#   data/final/codebook_crb-complaint-database.html
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse) 
library(here)
library(labelled)
library(sjPlot)

## load data -----
load(here("data/cleaning/df.foia_subsample_clean_outcomes.rda"))

## subset variable list ----
df.foia_labeled <- df.foia_subsample_clean_outcomes |>
  select(
    
    # redundant
    -investigation_status,   # all subset observations are closed by construction
    -incident_datetime,      # replaced by incident_date  
    -sector,                 # overlap with beat_clean
    -beat_of_incident,       # replaced by cleaned variable
    -accused_gender,         # replaced by cleaned variable
    -accused_race,           # replaced by cleaned variable
    -comm_area_num,          # 1:1 with comm_area_name; name retained
    
    # extractable from geometry 
    -lat,                    
    -long,          
    
    # extractable from full_address
    -street_number,    
    -street_name,            
    -street_direction,       

    # process artifacts
    -address_match,   
    -end_addr_range,  
    -partial_match,
    -error_geocoding,  
    
    # zero/near zero variance
    -city,                   
    -state,                 
    -street_side,
    
    # high missingness/not analytically useful
    -accused_assignment,     # 99.6% NA
    -accused_detailed_unit,  # 93.4% NA
    -apt_no,                 # 94.9% NA
    -address_type,           # 86.4% NA
    -investigator_star_no,   # 83.1% NA
    -investigator,           # 73.2% NA
    -investigator_position,  # 73.3% NA
    -data_group              # CMS only
  )

## rename variables ----
df.foia_labeled <- df.foia_labeled |>
  rename(
    cpd_beat         = beat_clean,
    cpd_district     = district_of_incident,
    cpd_area         = area,
    allegation_type  = alleg_gr_ms
  )

## drop levels with no values ----
df.foia_labeled <- df.foia_labeled |>
  mutate(across(where(is.factor), droplevels))

## fix types ----
df.foia_labeled <- df.foia_labeled |>
  mutate(
    geometry = as.character(geometry),
    geometry = sf::st_as_sfc(
      replace(geometry, is.na(geometry), "POINT EMPTY"),
      crs = 4326
    ),
    complainant_type = as.factor(complainant_type),
    allegation_type  = as.factor(allegation_type)
  )
  
## reorder ----
df.foia_labeled <- df.foia_labeled |>
  relocate(officer_id, allegation_key, source_period, .after = record_id) |>
  relocate(cpd_beat, .before = cpd_district) |> 
  relocate(n_OFs:n_AK_dupes, .after = incident_date) |>
  relocate(complaint_date, year_filed, investigation_end_date, .after = allegation) |>
  relocate(finding_followthrough, .before = discipline_followthrough) |>
  relocate(acs_t_pop, .after = full_address) |> 
  relocate(allegation_type, alleg_ipra, alleg_copa, alleg_j_change, .after = accused_on_duty) |> 
  relocate(accused_years_cpd, .before = accused_race_c) |> 
  relocate(geometry, .before = acs_t_pop)
  
# 1. VARIABLE LABELS -------------------------------------------------------

df.foia_labeled <- df.foia_labeled |>
  set_variable_labels(
    
    ## IDs ----------------------------------------------------------------
    record_id      = "Unique CRB complaint identifier",
    officer_id     = "Unique accused officer composite identifier",
    allegation_key = "Unique allegation × officer × case identifier",
    source_period  = "FOIA source database",
    
    ## Treatment group/ITS exposure ---------------------------------------
    complaint_date         = "Date complaint was filed",
    year_filed             = "Calendar year complaint was filed",
    investigation_end_date = "Date investigation was closed",
    agency_end             = "Investigating agency at case closure",
    treatment_group        = "ITS assignment based on complaint filing & closure dates",
    
    ## CPD jurisdiction ---------------------------------------------------
    cpd_beat         = "CPD beat of alleged incident [coded 'True Missing' if NA or invalid]",
    cpd_district     = "CPD district of alleged incident", 
    cpd_area         = "CPD area [post-2019 district boundaries]",
    
    ## Incident & case details --------------------------------------------
    incident_date    = "Date of most recent incident associated with allegation",
    complainant_type = "Complaint filed by civilian or CPD employee",
    accused_on_duty  = "Accused officer on duty during incident",
    n_AK_dupes       = "Number of incidents associated with allegation",
    n_OF_AKs         = "Number of unique allegations per officer within case",
    n_OFs            = "Number of officers named in case",
    
    ## Allegation ---------------------------------------------------------
    allegation               = "Allegation text-narrative",
    allegation_category_cd   = "Allegation code",
    allegation_category_desc = "Allegation description (CLEAR only)",
    reporting_category       = "Allegation category (CMS only)",
    allegation_type          = "Allegation category [harmonized grouping across CLEAR and CMS systems]",
    # pending crosswalk completion
    # alleg_ipra               = "Allegation falls under IPRA jurisdiction",
    # alleg_copa               = "Allegation falls under COPA jurisdiction",
    # alleg_j_change           = "Allegation jurisdiction changed between IPRA and COPA",
    
    ## Raw outcomes -------------------------------------------------------
    recommended_finding    = "CRB recommended finding",
    final_finding          = "CPD final finding",
    recommended_discipline = "CRB recommended discipline",
    final_discipline       = "CPD final discipline",
    
    ## Collapsed outcomes: level 1 (distributional) -----------------------
    recommended_finding_c1    = "CRB recommended finding [collapsed]",
    final_finding_c1          = "CPD final finding [collapsed]",
    recommended_discipline_c1 = "CRB recommended discipline [collapsed]",
    final_discipline_c1       = "CPD final discipline [collapsed]",
    
    ## Collapsed outcomes: level 2 (analytic) -----------------------------
    recommended_finding_c2    = "CRB recommended finding [analytic grouping]",
    final_finding_c2          = "CPD final finding [analytic grouping]",
    recommended_discipline_c2 = "CRB recommended discipline [analytic grouping]",
    final_discipline_c2       = "CPD final discipline [analytic grouping]",
    
    ## Outcome followthrough ----------------------------------------------
    finding_followthrough    = "Measure of CPD adoption of CRB recommended finding",
    discipline_followthrough = "Measure of CPD adoption of CRB recommended discipline",
    
    ## Accused officer attributes -----------------------------------------
    accused_race_c         = "Remaining accused_* = accused officer attributes",
    accused_years_cpd      = "Accused officer years on force at complaint date [derived from appointment date, rounded to full year]",
    
    ## Complainant attributes ---------------------------------------------
    n_complainants    = "Total number of complainants per complaint",
    n_Cs_collapsed    = "n_complainants, collapsed",
    c_gender_tally    = "Gender composition of complainants per case [derived]",
    c_race_tally      = "Racial composition of complainants per case [derived]",
    c_race_tally_mino = "Minority status composition of complainants per case [derived]",
    c_race_Black      = "Remaining c_* = count of complainants with demographic attribute per case",
    
    ## ACS ----------------------------------------------------------------
    # see Census ACS documentation for variable definitions
    acs_t_pop       = "Beat-level ACS estimates, matched on beat × year; acs_t_* = universe totals (denominators)",
    acs_n_adv_deg   = "Beat-level ACS estimates, matched on beat × year; acs_n_* = subgroup counts",
    acs_pct_adv_deg = "Beat-level ACS estimates, matched on beat × year; acs_pct_* = percentages",

    ## Spatial ------------------------------------------------------------
    comm_area_name = "Incident spatial variables retained from FOIA for spatial-level analyses",
    geometry = "Incident coordinates (longitude, latitude)",
    ## Investigator -------------------------------------------------------
    investigator_first_name = "Investigator variables retained from FOIA for investigator-level analyses"
  )

# 2. DATASET METADATA ------------------------------------------------------

attr(df.foia_labeled, "name")             <- "Chicago CRB Misconduct Complaint Database"
attr(df.foia_labeled, "description")      <- paste(
  "Allegation-level police misconduct complaint records for an interrupted",
  "time series analysis of Chicago's 2017 civilian oversight reforms.",
  "Integrates FOIA-obtained CLEAR and CMS records with ACS beat-level",
  "demographics and supplementary public COPA case information."
)
attr(df.foia_labeled, "temporal-coverage") <- "2013-09-15 to 2021-09-15 (±4 years around COPA launch)"
attr(df.foia_labeled, "unit")              <- "Allegation (charge × officer × case)"
attr(df.foia_labeled, "n")                 <- nrow(df.foia_labeled)
attr(df.foia_labeled, "creator")           <- "Michelle C. Shames"
attr(df.foia_labeled, "last-date-created") <- as.character(Sys.Date())
attr(df.foia_labeled, "FOIA-fulfilled")    <- "2022-06-22"

# SAVE & RENDER -----------------------------------------------------------

# temporarily remove jurisdiction variables until crosswalk complete
df.foia_labeled <- df.foia_labeled |>
  select(-alleg_ipra,
         -alleg_copa,
         -alleg_j_change)

save(df.foia_labeled, file = here("data/final/df.foia_labeled.rda"))

sjPlot::view_df(
  df.foia_labeled,
  show.labels      = TRUE,
  show.na          = TRUE,
  show.type        = TRUE,
  show.values      = TRUE,
  show.frq         = TRUE,
  show.prc         = TRUE,
  show.string.val  = FALSE,
  wrap.labels      = 50,
  max.len          = 10,
  file             = here("data/final/codebook_crb-complaint-database.html")
)
