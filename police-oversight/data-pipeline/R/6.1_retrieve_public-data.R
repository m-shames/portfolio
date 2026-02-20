# ==============================================================================
# Download Public COPA Case Summaries
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Download COPA Case Summaries from City of Chicago Data Portal
#   Note: current project uses data retrieved 2026-02

# Dependencies
#   Output used by: 6.2 & 6.3

# Output
#   data/raw/public/df.copa_cases.rds
# ==============================================================================

# SETUP -------------------------------------------------------------------
library(here)
library(janitor)

# DOWNLOAD ----------------------------------------------------------------
df.copa_cases <- read.csv(
  "https://data.cityofchicago.org/api/views/mft5-nfa8/rows.csv?accessType=DOWNLOAD"
) |>
  clean_names()

stopifnot(
  "Download Error: COPA cases file is empty" = nrow(df.copa_cases) > 0
)

# SAVE --------------------------------------------------------------------
saveRDS(df.copa_cases, file = here("data/raw/public/df.copa_cases.rds"))
