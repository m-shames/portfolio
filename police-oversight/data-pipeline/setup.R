# ==============================================================================
# Project Setup
# Project: COPA Evaluation
# Author: Michelle Shames

# About
#   Create required directory structure & install pipeline dependencies
#   → Run once before first pipeline execution on a new machine
#   → Not intended to be sourced by run_all.R or individual scripts

# Note
#   Script 1 (BigQuery extraction) requires additional credentials:
#     set BQ_EMAIL environment variable and request access to GCP project 'n3-main'.
#   Start from script 2.1 if running without BigQuery access; 
#     pre-extracted .rda files needed are available upon request
# ==============================================================================

# 1. CREATE DIRECTORIES ------------------------------------------------------
# if not yet existing, create directories & parent folders

dirs <- c(
  "data/raw/foia",
  "data/raw/acs",
  "data/raw/public",
  "data/cleaning",
  "data/final",
  "docs"
)

lapply(dirs, function(d) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    cat("Created:", d, "\n")
  } else {
    cat("Already exists:", d, "\n")
  }
})

# 2. PACKAGES -----------------------------------------------------------------
# install any missing packages; already-installed packages are skipped

packages <- c(
  "here",       # file paths
  "tidyverse",  # core data manipulation
  "bigrquery",  # BigQuery extraction (script 1 only)
  "skimr",      # data summaries (interactive use in scripts 4.1, 4.2)
  "janitor",    # clean variable names (script 6.1)
  "labelled",   # variable labels (script 7)
  "sjPlot"      # codebook rendering (script 7)
)

install.packages(packages[!packages %in% installed.packages()[, "Package"]])
