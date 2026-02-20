# ==============================================================================
# Clean & Recode Outcome Variables
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Drop 1 case with unrecorded finding (record 2021-0000702; see 6.2)
#   Recode missing outcomes to Admin Closure (see 6.2)
#   Collapse outcome variables & construct followthrough measures

# Dependencies
#   Run after: 5 (and review 6.2; findings inform outcome recoding decisions)
#   Output used by: 7

# Output
#   data/cleaning/df.foia_subsample_clean_outcomes.rda
# ==============================================================================

# SETUP -------------------------------------------------------------------

## load packages ----
library(tidyverse)
library(here)

## load data ----
load(here("data/cleaning/df.foia_subsample_deduped.rda"))

## drop case with unrecorded finding (see script 6.2, section 3.4) ----
df.foia_subsample_deduped <- df.foia_subsample_deduped |>
  filter(record_id != "2021-0000702")

# 1. FINDINGS -------------------------------------------------------------

## 1.1 Recommended ----

# recode & collapse
df.foia_subsample_clean_outcomes <- df.foia_subsample_deduped |>
  mutate(recommended_finding_c2 = case_when(
    is.na(recommended_finding_c1) | recommended_finding_c1 == "Admin Closure" ~ "Admin Closure",
    recommended_finding_c1 %in% c("Exonerated", "Not Sustained", "Unfounded") ~ "Not Sustained",
    recommended_finding_c1 == "Sustained" ~ "Sustained",
    TRUE ~ "Check rec finding c2"
  ) |>
    factor(levels = c("Admin Closure", "Not Sustained", "Sustained", "Check rec finding c2"))
  ) |>
  relocate(recommended_finding_c2, .after = recommended_finding_c1)

# validate
# df.foia_subsample_clean_outcomes |> 
#   count(recommended_finding_c1, recommended_finding_c2) |>
#   arrange(recommended_finding_c2, desc(n))

## 1.2 Final ----

# recode & collapse
df.foia_subsample_clean_outcomes <- df.foia_subsample_clean_outcomes |>
  mutate(final_finding_c2 = case_when(
    is.na(final_finding_c1) | final_finding_c1 == "Admin Closure" ~ "Admin Closure",
    final_finding_c1 %in% c("Exonerated", "Not Sustained", "Unfounded") ~ "Not Sustained",
    final_finding_c1 == "Sustained" ~ "Sustained",
    TRUE ~ "Check final finding c2"
  ) |>
    factor(levels = c("Admin Closure", "Not Sustained", "Sustained", "Check final finding c2"))
  ) |>
  relocate(final_finding_c2, .after = final_finding_c1)

# validate
# df.foia_subsample_clean_outcomes |> 
#   count(final_finding_c1, final_finding_c2) |>
#   arrange(final_finding_c2, desc(n))

# 2. DISCIPLINE ------------------------------------------------------------

## 2.1 Explore finding x discipline ----

if (interactive()) {
  
# n non-sustained allegations with substantive discipline (excl. violation noted)
df.foia_subsample_clean_outcomes |>
  filter(recommended_finding_c1 != "Sustained",
         recommended_discipline_c1 %in% c("Reprimand",
                                          "1-7 day suspension",
                                          "8-30 day suspension",
                                          "31-90 day suspension",
                                          "Termination/Separation")) |>
  count(source_period)
# → 502 rows, all CMS

# investigate whether this reflects case-level discipline recording in CMS

# step 1: rule out bleed from sustained co-allegations
df.foia_subsample_clean_outcomes |>
  filter(recommended_finding_c1 != "Sustained",
         !is.na(recommended_discipline_c1)) |>
  group_by(record_id, officer_id) |>
  mutate(has_sustained_allegation = any(recommended_finding_c1 == "Sustained")) |>
  ungroup() |>
  count(has_sustained_allegation)
# → all FALSE: discipline is not bleeding from sustained co-allegations

# step 2: confirm CMS records discipline at case level, not allegation level
df.foia_subsample_clean_outcomes |>
  filter(agency_end == "COPA", source_period == "cms") |>
  group_by(record_id, officer_id) |>
  filter(n() > 1) |>
  summarise(
    n_distinct_findings  = n_distinct(recommended_finding_c1, na.rm = TRUE),
    n_distinct_discipline = n_distinct(recommended_discipline_c1, na.rm = TRUE),
    .groups = "drop"
  ) |>
  count(n_distinct_findings, n_distinct_discipline)
# → findings vary across allegations but discipline is constant within officer-case;
#   CMS records discipline at case level, not allegation level
#   see codebook for implications for discipline and followthrough analyses

}

## 2.2 Recommended ----
df.foia_subsample_clean_outcomes <- df.foia_subsample_clean_outcomes |>
  mutate(
    recommended_discipline_c2 = case_when(
      recommended_discipline_c1 == "Officer resigned/deceased" ~ NA_character_,
      recommended_discipline_c1 %in% c("No action", "Violation noted", "Reprimand") |
        is.na(recommended_discipline_c1) ~ "None/Minor",
      recommended_discipline_c1 %in% c("1-7 day suspension", "8-30 day suspension") ~ "Suspension (1-30 days)",
      recommended_discipline_c1 %in% c("31-90 day suspension", "90 day-2 year suspension") ~ "Suspension (31+ days)",
      recommended_discipline_c1 %in% c("Termination/Separation") ~ "Termination",
      TRUE ~ "Check rec discipline c2"
    ),
    recommended_discipline_c2 = factor(recommended_discipline_c2, 
                                       levels = c("None/Minor", 
                                                  "Suspension (1-30 days)", 
                                                  "Suspension (31+ days)", 
                                                  "Termination",
                                                  "Check rec discipline c2")
                                       )
  ) |> 
  relocate(recommended_discipline_c2, .after = recommended_discipline_c1)

# validate
# df.foia_subsample_clean_outcomes |> 
#   count(recommended_discipline_c1, recommended_discipline_c2) |>
#   arrange(recommended_discipline_c2, desc(n))

## 2.3 Final ----
df.foia_subsample_clean_outcomes <- df.foia_subsample_clean_outcomes |>
  mutate(
    final_discipline_c2 = case_when(
      final_discipline_c1 == "Officer resigned/deceased" ~ NA_character_,
      final_discipline_c1 %in% c("No action", "Violation noted", "Reprimand") |
        is.na(final_discipline_c1) ~ "None/Minor",
      final_discipline_c1 %in% c("1-7 day suspension", "8-30 day suspension") ~ "Suspension (1-30 days)",
      final_discipline_c1 %in% c("31-90 day suspension", "90 day-2 year suspension") ~ "Suspension (31+ days)",
      final_discipline_c1 %in% c("Termination/Separation") ~ "Termination",
      TRUE ~ "Check final discipline c2"
    ),
    final_discipline_c2 = factor(final_discipline_c2, 
                                       levels = c("None/Minor", 
                                                  "Suspension (1-30 days)", 
                                                  "Suspension (31+ days)", 
                                                  "Termination",
                                                  "Check final discipline c2")
                                 )
  ) |> 
  relocate(final_discipline_c2, .after = final_discipline_c1)

# validate
# df.foia_subsample_clean_outcomes |> 
#   count(final_discipline_c1, final_discipline_c2) |>
#   arrange(final_discipline_c2, desc(n))

# 3. OUTCOME FOLLOWTHROUGH ------------------------------------------------
# Measures whether CPD's final determination matched the CRB recommendation.
#   Downgrade = CPD reduced severity relative to CRB recommendation
#   Same      = CPD matched CRB recommendation exactly
#   Upgrade   = CPD increased severity relative to CRB recommendation
# Note: given the stopifnot() above confirming no unsustained rec → sustained final,
#   'Upgrade' is only possible for discipline, not findings.

## 3.1 Finding ----

# confirm no unsustained recommendations escalated to sustained final finding
stopifnot(
  "Logic Error: Unsustained recommended finding has sustained final finding" =
    df.foia_subsample_clean_outcomes |>
    filter(recommended_finding_c2 != "Sustained",
           final_finding_c2 == "Sustained") |>
    nrow() == 0
)

df.foia_subsample_clean_outcomes <- df.foia_subsample_clean_outcomes |>
  mutate(
    rec_num = as.numeric(factor(recommended_finding_c2, 
                                levels = c("Admin Closure", "Not Sustained", "Sustained"))),
    fin_num = as.numeric(factor(final_finding_c2, 
                                levels = c("Admin Closure", "Not Sustained", "Sustained"))),
    finding_followthrough = case_when(
      fin_num == rec_num ~ "Same",
      fin_num < rec_num ~ "Downgrade",
      fin_num > rec_num ~ "Upgrade",
      TRUE ~ "Check finding followthrough"
    ),
    finding_followthrough = factor(finding_followthrough, 
                            levels = c("Downgrade", "Same", "Upgrade", "Check finding followthrough"))
  ) |>
  select(-rec_num, -fin_num) |>
  relocate(finding_followthrough, .after = final_finding_c2)

# validate
# df.foia_subsample_clean_outcomes |>
#   count(recommended_finding_c2, final_finding_c2, finding_followthrough) |> 
#   arrange(finding_followthrough, desc(n))

## 3.2 Discipline ----
df.foia_subsample_clean_outcomes <- df.foia_subsample_clean_outcomes |>
  mutate(
    rec_disc_num = as.numeric(factor(recommended_discipline_c2, 
                                     levels = c("None/Minor", "Suspension (1-30 days)", 
                                                "Suspension (31+ days)", "Termination"))),
    fin_disc_num = as.numeric(factor(final_discipline_c2, 
                                     levels = c("None/Minor", "Suspension (1-30 days)", 
                                                "Suspension (31+ days)", "Termination"))),
    discipline_followthrough = case_when(
      is.na(recommended_discipline_c2) | is.na(final_discipline_c2) ~ NA_character_,
      fin_disc_num == rec_disc_num ~ "Same",
      fin_disc_num < rec_disc_num ~ "Downgrade",
      fin_disc_num > rec_disc_num ~ "Upgrade",
      TRUE ~ "Check D followthrough"
    ),
    discipline_followthrough = factor(discipline_followthrough, 
                                      levels = c("Downgrade", "Same", "Upgrade", "Check D followthrough"))
  ) |>
  select(-rec_disc_num, -fin_disc_num) |>
  relocate(discipline_followthrough, .after = final_discipline_c2)

# validate
# df.foia_subsample_clean_outcomes |>
#   count(recommended_discipline_c2, final_discipline_c2, discipline_followthrough) |> 
#   arrange(discipline_followthrough, desc(n))

# FINAL VALIDATION CHECK --------------------------------------------------

stopifnot(
  "Recode Error: Unmapped values in recommended_finding_c2" =
    nrow(filter(df.foia_subsample_clean_outcomes, 
                recommended_finding_c2 == "Check rec finding c2")) == 0,

  "Recode Error: Unmapped values in final_finding_c2" =
    nrow(filter(df.foia_subsample_clean_outcomes, 
                final_finding_c2 == "Check final finding c2")) == 0,
  
  "Recode Error: Unmapped values in finding_followthrough" =
    nrow(filter(df.foia_subsample_clean_outcomes, 
                finding_followthrough == "Check finding followthrough")) == 0,

  "Recode Error: Unmapped values in discipline_followthrough" =
    nrow(filter(df.foia_subsample_clean_outcomes, 
                discipline_followthrough == "Check discipline followthrough",
                !is.na(discipline_followthrough))) == 0,
  
  "Recode Error: Unmapped values in recommended_discipline_c2" =
    nrow(filter(df.foia_subsample_clean_outcomes,
                recommended_discipline_c2 == "Check rec discipline c2")) == 0,
  
  "Recode Error: Unmapped values in final_discipline_c2" =
    nrow(filter(df.foia_subsample_clean_outcomes,
                final_discipline_c2 == "Check final discipline c2")) == 0
)

# SAVE --------------------------------------------------------------------
save(df.foia_subsample_clean_outcomes, 
     file = here("data/cleaning/df.foia_subsample_clean_outcomes.rda"))
