###########################################################
# Name: Geochip_ResRatio_Visit_subcategory2.R
# Author: Ryan Johnson
# Date Created: 16 July 2018
# Purpose: Determine which genes are significantly altered
#          from visit 1 to visit 4 and 5 by calculating
#          response ratios with 95% CI using relative
#          abundance.
###########################################################

library(tidyverse)

# Read in merged Geochip Data
geochip <- read_tsv("data/processed/Merged_Geochip_Tidy.tsv", 
                    col_types = "ccicccccccd",
                    progress = TRUE)

geochip_RR <- geochip %>%
  
  group_by(glomics_ID) %>%
  mutate(Signal_Relative_Abundance = (Signal / sum(Signal, na.rm = TRUE)* 100)) %>%
  
  # Remove columns not needed
  select(-Gene, -Genbank.ID, -Gene_category,  
         -Signal, -Organism, -Subcategory1, -Lineage) %>%
  
  # Remove any rows with NA in the signal category or Subcategory2
  filter(!is.na(Signal_Relative_Abundance)) %>%
  filter(!is.na(Subcategory2)) %>%
  
  # Calculate mead, sd, and counts (n)
  group_by(Subcategory2, glomics_ID, visit_number) %>%
  summarise(Subcategory2_relative_abundance = sum(Signal_Relative_Abundance, na.rm = TRUE)) %>%
  group_by(Subcategory2, visit_number) %>%
  summarise(mean_signal = mean(Subcategory2_relative_abundance),
            sd_signal = sd(Subcategory2_relative_abundance),
            n = sum(!is.na(Subcategory2_relative_abundance))) %>%
  
  
  # Spread the signal mean by visit number
  group_by(Subcategory2) %>%
  spread(visit_number, mean_signal) %>%
  
  # Rename visit mean columns
  rename(Visit1_mean = `1`,
         Visit4_mean = `4`,
         Visit5_mean = `5`) %>% 
  
  # Spread the sd and n columns by visit
  mutate(sd_visit1 = ifelse(!is.na(Visit1_mean), sd_signal, NA)) %>%
  mutate(sd_visit4 = ifelse(!is.na(Visit4_mean), sd_signal, NA)) %>%
  mutate(sd_visit5 = ifelse(!is.na(Visit5_mean), sd_signal, NA)) %>%
  mutate(n_visit1 = ifelse(!is.na(Visit1_mean), n, NA)) %>%
  mutate(n_visit4 = ifelse(!is.na(Visit4_mean), n, NA)) %>%
  mutate(n_visit5 = ifelse(!is.na(Visit5_mean), n, NA)) %>%
  select(-sd_signal, -n) %>%
  
  
  # Compress NAs
  group_by(Subcategory2) %>%
  summarise_all(funs(sum(., na.rm = T))) %>%
  
  # Must have at least 10 observations in each subcategory
  filter(n_visit1 >= 10) %>%
  filter(n_visit4 >= 10) %>%
  filter(n_visit5 >= 10) %>%
  
  # Calculate SEM for each mean
  mutate(SEM_visit1 = sd_visit1 / sqrt(n_visit1)) %>%
  mutate(SEM_visit4 = sd_visit4 / sqrt(n_visit4)) %>%
  mutate(SEM_visit5 = sd_visit5 / sqrt(n_visit5)) %>%
  
  # Calculate the Response Ratio (RR) for each gene (V4-V1, V5-V1)
  mutate(RR_41 = log(Visit4_mean / Visit1_mean)) %>%
  mutate(RR_51 = log(Visit5_mean / Visit1_mean)) %>%
  
  # Calculate the Standard error for the RR
  mutate(SE_RR_41 = sqrt((SEM_visit1**2 / Visit1_mean**2) + (SEM_visit4**2 / Visit4_mean**2))) %>%
  mutate(SE_RR_51 = sqrt((SEM_visit1**2 / Visit1_mean**2) + (SEM_visit5**2 / Visit5_mean**2))) %>%
  
  # Calcualte the 95% confidence interval for each RR
  mutate(CI95_41 = abs(1.96 * SE_RR_41)) %>%
  mutate(CI95_51 = abs(1.96 * SE_RR_51))

# Only include subcategories where the 95% CI does not overlap 0
geochip_RR <- geochip_RR %>%
  mutate(overlap_zero_41 = ifelse(0 > RR_41 - CI95_41 & 0 < RR_41 + CI95_41, TRUE, FALSE)) %>%
  mutate(overlap_zero_51 = ifelse(0 > RR_51 - CI95_51 & 0 < RR_51 + CI95_51, TRUE, FALSE)) %>%
  filter(overlap_zero_41 != TRUE | overlap_zero_51 != TRUE)


# Plot
geochip_RR_plot <- ggplot(data = arrange(geochip_RR, desc(RR_41))) +
  geom_vline(xintercept = 0, linetype = "dashed", size = 1) +
  # 1 v 4
  geom_point(aes(x = RR_41, y = Subcategory2), size = 4, color = "black") +
  geom_errorbarh(aes(xmin = RR_41 - CI95_41, xmax = RR_41 + CI95_41, y = Subcategory2), 
                 color = "black") +
  # 1 v 5
  geom_point(aes(x = RR_51, y = Subcategory2), size = 4, color = "red") +
  geom_errorbarh(aes(xmin = RR_51 - CI95_51, xmax = RR_51 + CI95_51, y = Subcategory2), 
                 color = "red") +
  ggtitle("Response Ratio: Subcategory2\nBlack = Visit 4 vs Visit 1\nRed = Visit 5 vs Visit 1") +
  ylab("Gene Category") +
  xlab("Response Ratio") +
  theme_minimal() +
  theme(
    axis.title.x = element_text(size = 15),
    axis.title.y = element_text(size = 15),
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12),
    plot.title = element_text(size = 16, face = "bold")
  )

ggsave("results/figures/Geochip_RespRatio_Visit_Subcategory2.png", height = 10, width = 7)
