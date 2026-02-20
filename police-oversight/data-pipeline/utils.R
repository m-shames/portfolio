# ==============================================================================
# Utility file: sourced by pipeline scripts
# Project: COPA Evaluation
# Author: Michelle Shames

# About: 
#   Reusable variable vectors, constants, and helper functions 
#   Not intended to be run directly; sourced in scripts 3, 4.1, 4.2 
# ==============================================================================

# 1. CONSTANTS ------------------------------------------------------------

# COPA launch date: primary intervention date for ITS analysis
intervention_date <- as.Date("2017-09-15")

# strings treated as missing across character variables
v.junk_strings <- c(
  "UNKNOWN", "UNK", "N/A", "NA", "TBD", "", " ", ".", "-", "?",
  "COVERED BY ELECTRICAL TAPE", "COVERED BY TAPE",
  "NOT LISTED", "PREFER NOT TO SAY", "U"
)

# star number values treated as missing
v.junk_stars <- c("", ".", "1", " ")

# 2. ORIGINAL VARIABLE VECTORS --------------------------------------------
# vectors group raw variables by type for use in column selection,
#   ordering (via select(all_of(...))), and coverage validation

## IDs ----
v.id <- c(
  "record_id",
  "source_period",
  "allegation_key"
)

## CPD geography ----
v.cpd_geo <- c(
  "district_of_incident",
  "beat_clean",
  "beat_of_incident",
  "sector"
)

## Allegations ----
v.allegation <- c(
  "reporting_category",
  "allegation_category_desc",
  "allegation_category_cd",
  "allegation"
)

## Case ----
v.case <- c(
  "incident_datetime",
  "accused_on_duty",
  "complaint_date",
  "year_filed",
  "investigation_end_date",
  "investigation_status", 
  "data_group"
)

## Outcomes ----
v.outcomes <- c(  
  "recommended_finding",
  "recommended_discipline",
  "final_finding",
  "final_discipline"
)

## Officer ----
v.officer <- c(
  "accused_race",
  "accused_gender",
  "accused_birth_year",
  "accused_position",
  "accused_appointed_date",
  "accused_unit_at_complaint",
  "accused_assigned_unit",
  "accused_assignment",
  "accused_detailed_unit",
  "accused_first_name",
  "accused_middle_initial",
  "accused_last_name",
  "accused_star_no"
)

## Complainant attributes ----
v.c_atts <- c(
  "complainant_type",
  "n_complainants",
  "c_race_Black",
  "c_race_Hispanic",
  "c_race_White",
  "c_race_AAPI",
  "c_race_True_Missing",
  "c_race_Unknown",
  "c_race_Other",
  "c_gender_Male",
  "c_gender_Female",
  "c_gender_True_Missing",
  "c_gender_Other",
  "c_gender_Unknown",
  "c_role_Subject",
  "c_role_True_Missing",
  "c_role_Third_Party",
  "c_cpd_FALSE",
  "c_cpd_TRUE",
  "c_cpd_NA" 
)

## Investigator ----
v.investigator <- c(
  "investigator_first_name",
  "investigator_last_name",
  "investigator",
  "investigator_star_no",
  "investigator_race",
  "investigator_gender",
  "investigator_position"
)

## Spatial ----
v.spatial <- c(
  "comm_area_name",
  "comm_area_num",
  "found_address",
  "street_number",
  "street_name",
  "partial_match",
  "geometry",
  "city",
  "apt_no",
  "zip_cd",
  "state",
  "end_addr_range",
  "street_direction",
  "error_geocoding",
  "street_side",
  "full_address",
  "lat",
  "long",
  "address_match",
  "address_type"
)

## ACS counts ----
v.acs_n <- c(
  "acs_t_h_hold",
  "acs_t_h_unit",
  "acs_t_hisp_nonhisp",
  "acs_t_labor_f",
  "acs_t_pop",
  "acs_n_adv_deg",
  "acs_n_af_am",
  "acs_n_af_am_nonhisp",
  "acs_n_asian",
  "acs_n_asian_nonhisp",
  "acs_n_bach_deg",
  "acs_n_diff_house",
  "acs_n_emp",
  "acs_n_fem_h_hold",
  "acs_n_frgn_born",
  "acs_n_hs_grad",
  "acs_n_hisp",
  "acs_n_less_hs_grad",
  "acs_n_out_labor_f",
  "acs_n_other_nonhisp",
  "acs_n_pov",
  "acs_n_pub_asst",
  "acs_n_rent_occ",
  "acs_n_res_more_1yr",
  "acs_n_some_coll",
  "acs_n_under_18",
  "acs_n_unemp",
  "acs_n_white",
  "acs_n_white_nonhisp"
)

## ACS percentages ----
v.acs_pct <- c(
  "acs_pct_adv_deg",
  "acs_pct_af_am",
  "acs_pct_af_am_nonhisp",
  "acs_pct_asian",
  "acs_pct_asian_nonhisp",
  "acs_pct_bach_deg",
  "acs_pct_diff_house",
  "acs_pct_emp",
  "acs_pct_fem_h_hold",
  "acs_pct_frgn_born",
  "acs_pct_hs_grad",
  "acs_pct_hisp",
  "acs_pct_less_hs_grad",
  "acs_pct_other_nonhisp",
  "acs_pct_out_labor_f",
  "acs_pct_pov",
  "acs_pct_pub_asst",
  "acs_pct_rent_occ",
  "acs_pct_some_coll",
  "acs_pct_unemp",
  "acs_pct_unemp_disc_workers",
  "acs_pct_white",
  "acs_pct_white_nonhisp",
  "acs_pct_under_18"
)

# 3. HELPERS --------------------------------------------------------------

# standardize strings and identify junk values in cleaning scripts
is_junk <- function(x) {
  toupper(trimws(as.character(x))) %in% v.junk_strings
}

# check that all variables are assigned to exactly one vector
# reports unassigned & duplicate variables 
check_coverage <- function(df) {
  all_vecs <- list(
    v.id = v.id, v.cpd_geo = v.cpd_geo, v.allegation = v.allegation,
    v.case = v.case, v.outcomes = v.outcomes, v.officer = v.officer,
    v.investigator = v.investigator, v.c_atts = v.c_atts,
    v.spatial = v.spatial, v.acs_n = v.acs_n, v.acs_pct = v.acs_pct
  )
  
  all_assigned <- unlist(all_vecs)
  df_names <- names(df)
  
  # variables in df but not assigned to any vector
  unassigned <- setdiff(df_names, all_assigned)
  if (length(unassigned) > 0) {
    cat("NOT in any vector:", paste(unassigned, collapse = ", "), "\n")
  }
  
  # variables assigned to multiple vectors
  dupes <- all_assigned[duplicated(all_assigned)]
  if (length(dupes) > 0) {
    cat("In MULTIPLE vectors:", paste(unique(dupes), collapse = ", "), "\n")
  }
  
  if (length(unassigned) == 0 && length(dupes) == 0) {
    cat("All variables assigned to exactly one vector\n")
  }
}
