###########################################################
# Name: Geochip_ResRatio_Visit.R
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

# ID_Decoder
ID_decoder <- suppressWarnings(suppressMessages(read_csv("data/processed/ID_Decoder.csv")))
treat <- suppressWarnings(suppressMessages(read_csv("data/processed/TrEAT_Clinical_Metadata_tidy.csv")))

# Filter ID_decoder to only include samples in geochip
ID_decoder <- ID_decoder %>%
  filter(glomics_ID %in% geochip$glomics_ID)

treat <- treat %>%
  left_join(., ID_decoder, by = c("STUDY_ID" = "study_id"))


### Remove samples from geochip that 
### are in the LOP & PLA tx groups 

LOP_PLA_samples <- treat %>%
  filter(Treatment %in% c("LOP", "PLA")) %>%
  pull(glomics_ID)

geochip <- geochip %>%
  filter(!glomics_ID %in% LOP_PLA_samples)

rm(LOP_PLA_samples)


##############################################
### Only keep patients with matched visits ###
##############################################


# Get vector of patients that have matched visits
matched_samples <- ID_decoder %>%
  filter(visit_number %in% c(1,4,5)) %>%
  count(study_id) %>%
  filter(n == length(c(1,4,5))) %>%
  pull(study_id)

# Get glomics ID's that correspond to the patients
# with matched samples
matched_glomics <- ID_decoder %>%
  filter(study_id %in% matched_samples) %>%
  pull(glomics_ID)

# Subset the geochip data
geochip <- geochip %>%
  filter(glomics_ID %in% matched_glomics)
rm(matched_glomics, matched_samples)


# Calculate RRs
geochip_RR <- geochip %>%
  
  group_by(glomics_ID) %>%
  mutate(Signal_Relative_Abundance = (Signal / sum(Signal, na.rm = TRUE)* 100)) %>%
  
  # Remove columns not needed
  select(-Gene, -Genbank.ID, -Subcategory1,  
         -Signal, -Organism, -Subcategory2, -Lineage) %>%
  
  # Remove any rows with NA in the signal category or Gene_category
  filter(!is.na(Signal_Relative_Abundance)) %>%
  filter(!is.na(Gene_category)) %>%
  
  
  
  # Remove samples that are unmatched

  # Remove the PLA and   
  
  # Calculate mead, sd, and counts (n)
  group_by(Gene_category, glomics_ID, visit_number) %>%
  summarise(Gene_category_relative_abundance = sum(Signal_Relative_Abundance, na.rm = TRUE)) %>%
  group_by(Gene_category, visit_number) %>%
  summarise(mean_signal = mean(Gene_category_relative_abundance),
            sd_signal = sd(Gene_category_relative_abundance),
            n = sum(!is.na(Gene_category_relative_abundance))) %>%


  # Spread the signal mean by visit number
  group_by(Gene_category) %>%
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
  group_by(Gene_category) %>%
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

# Make Tidy for plotting
geochip_RR_tidy <- geochip_RR %>%
  select(Gene_category, RR_41, RR_51, CI95_41, CI95_51) %>%
  gather(key = RR_group, value = RR, -Gene_category, -CI95_41, -CI95_51) %>%
  gather(key = CI_group, value = CI95, -Gene_category, -RR_group, -RR) %>%
  mutate(keepers = ifelse(str_extract(RR_group, "..$") == str_extract(CI_group, "..$"), "yes", NA)) %>%
  filter(!is.na(keepers)) %>%
  select(-keepers, -CI_group)


# Plot
dodge <- position_dodge(width = 0.75)

geochip_RR_plot <- ggplot(data = geochip_RR_tidy) +
  geom_hline(yintercept = 0, linetype = "dashed", size = 1) +
  
  # points and error bar
  geom_point(aes(x = Gene_category, y = RR, color = RR_group), size = 4, position = dodge) +
  geom_errorbar(aes(ymin = RR - CI95, ymax = RR + CI95, x = Gene_category, color = RR_group), position = dodge) +
  
  scale_color_manual(values = c("black", "red"), labels = c("Visit 1 vs 4", "Visit 1 vs 5")) +

  labs(title = "Response Ratio",
       subtitle = "Gene Category by Visit",
       x = "Gene Category",
       y = "Response Ratio",
       color = "Visit Comparisons",
       caption = "Only considering samples from patients that provided samples at all 3 time points") +
  theme_minimal() +
  coord_flip() +
  theme(
    axis.title.x = element_text(size = 15),
    axis.title.y = element_text(size = 15),
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    plot.caption = element_text(hjust = 0.5)
  )



ggsave("results/figures/Geochip_RespRatio_Visit.png", height = 9, width = 8)
