# ==============================================================================
# Figure 1: Recommended Outcome by Agency
# Project: COPA Evaluation
# Author: Michelle Shames
# Last Updated: 2026-02-19

# fig.alt
#   Stacked bar chart comparing recommended findings for civilian
#   complaints adjudicated under IPRA (2013-2017) and COPA (2017-2021). 

# Summary
#   - COPA sustained a higher proportion of allegations (13%) than IPRA (3%)
#   - Exploratory chi-square test indicates significant diff 
#     (X² = 636.11, df = 2, p < .001)
#   - Effect size suggests agency alone explains limited variation in outcomes
#     (Cramér's V = 0.16) 
# ==============================================================================

# load packages
library(tidyverse)
library(here)
library(rcompanion)
library(showtext)

# load data
load(here("data/cleaning/df.foia_subsample_clean_outcome.rda"))
source(here("visualizations/fig_helper.R"))

# STATISTICAL TESTS -------------------------------------------------------

# chi-square: distribution of findings by agency
#   NB: allegations clustered within officers & complaints
#   -> independence assumption is violated - results are exploratory only
chisq.test(
  table(
    df.foia_subsample_clean$agency_end,
    df.foia_subsample_clean$recommended_finding_c2
  )
)
# X² = 636.11, df = 2, p < .001

# cramér's v: effect size for chi-square
cramerV(
  table(
    df.foia_subsample_clean$agency_end,
    df.foia_subsample_clean$recommended_finding_c2
  )
)
# V = 0.16 -> statistically significant but modest in practice

# FIGURE 1 ----------------------------------------------------------------

fig1 <- df.foia_subsample_clean |>
  filter(complainant_type == "CIVILIAN") |>
  
  # data prep
  count(agency_end, recommended_finding_c2) |>
  group_by(agency_end) |>
  mutate(
    prop  = n / sum(n),
    label = scales::percent(prop, accuracy = 1),
    # rename Admin Closure for cleaner display
    recommended_finding_c2 = fct_recode(
      recommended_finding_c2,
      "Not Investigated" = "Admin Closure"
    )
  ) |>
  arrange(agency_end, desc(recommended_finding_c2)) |>
  
  # base plot 
  ggplot(aes(agency_end, prop, fill = recommended_finding_c2)) +
  geom_col(width = 0.8) +
  
  # data labels
  geom_label(
    aes(label = label),
    position   = position_stack(vjust = 0.5),
    size       = 4.2,
    color      = "grey20",
    fill       = "white",
    label.size = 0.2
  ) +
  
  # color palette from fig_helper.R
  scale_fill_manual(
    name   = "Finding",
    values = colors.copa_finding
  ) +
  
  # axes
  scale_y_continuous(name = NULL, labels = NULL) +
  scale_x_discrete(name = NULL) +
  
  # labels
  labs(
    title    = "CRB-Recommended Finding by Agency",
    subtitle = "Allegation-Level Case Outcomes",
    caption  = f.ms_caption("IPRA: 09/2013 – 09/2017; COPA: 09/2017 – 09/2021")
  ) +
  
  # shared theme from fig_helper.R + figure-specific overrides
  theme.copa() +
  theme(
    axis.text.y     = element_blank(),
    axis.ticks.y    = element_blank(),
    legend.position = "right"
  )

# SAVE --------------------------------------------------------------------
f.save_portfolio_fig("fig1", fig1)
