#################################################
# Name: Plot_DCA_GeoChip.R
# Author: Ryan Johnson
# Date Created: 6 July 2018
# Purpose: Plot the results of the DCA Analysis 
#          run on the GeoChip data with various
#          metadata added.
#################################################

library(tidyverse)
library(readxl)

## Read in GeoChip DCA Analysis Results -------------------------------
geochip_dca <- read_csv("data/processed/GeoChip_DCA.csv")


# Read in decoder
ID_list <- read.csv("data/processed/ID_Decoder.csv")


## Match glomics and subject ID's ----------------------------------------

# Merge subject ids into ord_DCcoords
geochip_dca <- geochip_dca %>%
  left_join(., ID_list, by = "glomics_ID") %>%
  na.omit()





## Add in Clinical Metadata -----------------------------------
treatment_groups <- read_csv("data/processed/TrEAT_Clinical_Metadata_tidy.csv")

geochip_dca <- geochip_dca %>%
  left_join(., treatment_groups, by = c("study_id" = "STUDY_ID")) %>%
  drop_na(glomics_ID)








## Plot and Save various DCA Graphs -----------------------------------

# Visit Number
plot_visit_number <- ggplot(geochip_dca, aes(x = DCA1, y = DCA2, fill = factor(visit_number))) +
  scale_fill_discrete(name = "Visit Number") +
  geom_point(pch = 21, size = 4, color = "black", alpha = 0.8) + 
  ggtitle("DCA Analysis: Visit Number")

ggsave("results/figures/DCA_GeoChip_VisitNumber.png")

# Treatment Group
plot_tx_group <- geochip_dca %>%
  filter(visit_number != 1) %>% # Select for only visit days 4 and 5 (post treatment)
  ggplot(aes(x = DCA1, y = DCA2, fill = Treatment)) +
  scale_fill_discrete(name = "Treatment") +
  geom_point(pch = 21, size = 4, color = "black", alpha = 0.8) + 
  ggtitle("DCA Analysis: Treatment (Visits 4 and 5 only)")

ggsave("results/figures/DCA_GeoChip_TreatmentGroup.png")


