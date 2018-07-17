####################################################
# Name: Geochip_Visit_Gene_Diff.R
# Author: Ryan Johnson
# Date Created: 14 July 2018
# Purpose: Generate tibble with differences in 
#          normalized signal intensity between the
#          the various visits for genes.
####################################################

library(tidyverse)

# Read in merged Geochip data
geochip <- read_tsv("data/processed/Merged_Geochip_Tidy.tsv", 
                    col_types = "ccicccccccd",
                    progress = TRUE)

# Generate new gene difference tibble
geochip_visit_genediff <- geochip %>%
  
  # Remove the glomics ID
  select(-glomics_ID) %>%
  
  # Make visit numbers text
  mutate(visit_number = ifelse(visit_number == 1, "Visit_1_Signal", 
                               ifelse(visit_number == 4, "Visit_4_Signal",
                               ifelse(visit_number == 5, "Visit_5_Signal", NA)))) %>%
  
  # Compute differences in visit 1 from visit 4 and 5
  spread(visit_number, Signal) %>%
  mutate(Visit14_diff = Visit_1_Signal - Visit_4_Signal) %>%
  mutate(Visit15_diff = Visit_1_Signal - Visit_5_Signal) %>%
  
  group_by(Gene, Organism) %>%
  summarise(avg_14 = mean(Visit14_diff, na.rm = TRUE), 
            avg_15 = mean(Visit15_diff, na.rm = TRUE)) %>%
  arrange(desc(avg_14))

write_tsv(geochip_visit_genediff, "data/processed/Geochip_Visit_Gene_Diff.tsv")