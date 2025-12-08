# ==============================================================================
# Figure of CRB Recommended Finding
# Proj: COPA Eval

# Author: Michelle Shames
# ==============================================================================

# Create bar graph ----
fig_crb_finding <- df.copa_subset %>% 
  mutate(finding_color = case_when(
    is.na(recommended_finding_c2) ~ "Not Investigated",
    recommended_finding_c2 == "Sustained" ~ "Sustained", 
    recommended_finding_c2 == "Not sustained" ~ "Not Sustained"
  )) %>%
  count(agency, finding_color) %>%
  group_by(agency) %>%
  mutate(
    prop = n / sum(n),
    label = scales::percent(prop, accuracy = 0.1),
    finding_color = factor(finding_color, 
                           levels = c("Not Investigated", "Not Sustained", "Sustained"))
  ) %>%
  arrange(agency, desc(finding_color)) %>%  
  ggplot(aes(x = agency, y = n, fill = finding_color)) +
  geom_col() +
  geom_label(
    aes(label = label),
    position = position_stack(vjust = 0.5),
    size = 4.6, 
    color = "black",
    fill = "white",
    label.size = 0.25
  ) + 
  scale_fill_manual(
    name = "Finding Status",
    values = c("Not Investigated" = "gray50", 
               "Not Sustained" = "lightblue", 
               "Sustained" = "darkblue")
  ) +
  scale_y_continuous(labels = scales::comma, breaks = seq(0, 15000, 2500)) +
  labs(
    y = " ",
    x = " ",
    title = "Count of Allegations by Agency"
  ) +
  theme_classic() +
  theme(
    axis.title = element_text(size = 7 * 3),
    axis.text = element_text(size = 4 * 3),
    plot.title = element_text(size = 6 * 3),
    legend.title = element_text(size = 5 * 3),
    legend.text = element_text(size = 4 * 3)
  )

# Save bar graph ----
ggsave("fig_crb_finding.png", 
       plot = fig_crb_finding, width = 10, height = 6, dpi = 150)