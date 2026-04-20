# ==============================================================================
# Custom Theme & Helper Functions
# Project: COPA Evaluation
# Author: Michelle Shames
# Last Updated: 2026-02-19

# usage: source(here("visualizations/fig_helper.R")) at top of each figure script
# ==============================================================================

library(tidyverse)
library(colorBlindness)
library(showtext)

# 1. FIGURE THEME ---------------------------------------------------------

## color palettes ----
# color selection inspired by CPD's branding guide, available here
# <https://www.chicago.gov/content/dam/city/depts/dti/CDS/Chicago%20Design%20System%20Branding%20Guide-11-2023.pdf>

# case finding colors
colors.copa_finding <- c(
  "Not Investigated" = "#d6d7d9",
  "Not Sustained"    = "#a4d5ee",
  "Sustained"        = "#005899"
)

# sequential blues 
colors.copa_seq3 <- c("#08519C", "#0092d1", "#e1f3f8")

# validate palette for colorblind accessibility
# displayAllColors(colors.copa_finding)
# displayAllColors(colors.copa_seq3)

## custom theme ----

font_add_google("Inter", "inter")
showtext_auto()

theme.copa <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      # --- text ---
      text                  = element_text(family = "inter"),
      plot.title            = element_text(face = "bold", size = 15, hjust = 0.5),
      plot.subtitle         = element_text(color = "grey40", hjust = 0.5),
      plot.caption          = element_text(color = "grey55", size = 8, hjust = 0),
      plot.caption.position = "plot",
      # --- grid ---
      panel.grid            = element_blank(),
      # --- axes ---
      axis.text.x           = element_text(face = "bold", size = 12),
      # --- legend ---
      legend.margin         = margin(0, 0, 0, 0),
      legend.box.spacing    = unit(0, "pt"),
      legend.text           = element_text(size = 9),
      legend.title          = element_text(size = 10),
      # --- margins ---
      plot.margin           = margin(16, 16, 16, 16)
    )
}

# 2. FUNCTIONS ------------------------------------------------------------

# frequency table with proportions
# usage: f.freq_table(df, x, y)
f.freq_table <- function(data, ...) {
  data |>
    count(...) |>
    group_by(pick(1)) |>
    mutate(prop = scales::percent(n / sum(n), accuracy = 0.1))
}

# copyright helper
# usage: paste(f.ms_caption("~add fig-specific cap here~"))
f.ms_caption <- function(source_note) {
  paste0(source_note, "\n© Michelle Shames 2026")
}

# save plot
# usage: f.save_portfolio_fig("fig title", fig)
f.save_portfolio_fig <- function(filename, plot, width = 570, height = 375) {
  ggsave(
    filename   = here(paste0("visualizations/", filename, ".png")),
    plot       = plot,
    width      = width,
    height     = height,
    units      = "px",
    dpi        = 96,
    create.dir = TRUE
  )
}
