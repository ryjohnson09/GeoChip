#############################################################
# Name: Functional_Category_Visit_Number.R
# Author: Ryan Johnson
# Date Created: 11 July 2018
# Purpose: Visualize differences in functional gene 
#          categories between the various visit numbers
#############################################################

library(tidyverse)

## Read in Merged Geochip Data --------------------------------------------------------------------------
geochip <- read_tsv("data/processed/Merged_Geochip_Tidy.tsv", 
                    col_types = "ccicccccccd", 
                    progress = TRUE)



## Convert to Relative abundance and summarize by Gene_Category and visit_number ------------------------
geochip_RA_visitnumber <- geochip %>%
  group_by(glomics_ID) %>%
  mutate(Signal_Relative_Abundance = Signal / sum(Signal, na.rm = TRUE)) %>% # Relative Abundance Calc
  group_by(Gene_category, glomics_ID, visit_number) %>%
  summarise(Gene_category_relative_abundance = sum(Signal_Relative_Abundance, na.rm = TRUE)) %>%
  group_by(Gene_category, visit_number) %>%
  summarise(mean_sig = mean(Gene_category_relative_abundance),
            sd_sig = sd(Gene_category_relative_abundance))


## Create Plot -------------------------------------------------------------------------------------------

geochip_plot <- ggplot(geochip_RA_visitnumber, aes(x = Gene_category, 
                                                   y = mean_sig, 
                                                   fill = factor(visit_number))) +
  geom_errorbar(aes(ymax = mean_sig + sd_sig,
                    ymin = mean_sig - (mean_sig/2)), 
                width=.2, 
                position=position_dodge(.9)) +
  geom_bar(stat = "identity", color = "black", position = position_dodge()) +
  scale_fill_manual(name = "Visit Number", values = c('#d7191c','#fdae61','#abd9e9')) +
  
  ylab("Relative Abundance") +
  xlab("Functional Category") +
  ggtitle("Relative Abundance of Functional Gene Categories") +
  theme_minimal() +
  theme(
    axis.title.x = element_text(size = 14), 
    axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
    axis.title.y = element_text(size = 14), 
    plot.title = element_text(size = 16, face = "bold"),
    plot.margin=unit(c(1,1,1.5,1.2),"cm")
  )

## Save Plot ----------------------------------------------------------------------------------------------
ggsave("results/figures/Geochip_Functional_Gene_Abundance_Visit_Number.png")