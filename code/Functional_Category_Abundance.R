#######################################################
# Name: Functional_Category_Abundance.R
# Author: Ryan Johnson
# Date Created: 10 July 2018
# Purpose: Plot the relative abundance of functional 
#           gene categories for all Geochip samples
#######################################################

library(tidyverse)

## Read in Merged Geochip Data -----------------------------
geochip <- read_tsv("data/processed/Merged_Geochip_Tidy.tsv", col_types = "ccicccccccd", progress = TRUE)




## Convert to Relative Abundance and group by Gene Category --------------------------------
geochip_RA <- geochip %>%
  group_by(glomics_ID) %>%
  mutate(Signal_Relative_Abundance = Signal / sum(Signal, na.rm = TRUE)) %>% # convert to relative abundance
  group_by(Gene_category, glomics_ID) %>%
  
  # Add all relative abundance values together per gene category
  summarise(Gene_category_relative_abundance = sum(Signal_Relative_Abundance, na.rm = TRUE)) %>%
  group_by(Gene_category) %>%
  
  # Report mean gene category relative abundance with standard deviation
  summarise(mean_sig = mean(Gene_category_relative_abundance),
            sd_sig = sd(Gene_category_relative_abundance))




## Creat Plot ---------------------------------------------------------
geochip_plot <- ggplot(geochip_RA, aes(x = Gene_category, 
                                             y = mean_sig,
                                             fill = Gene_category)) +
  
  # Bar Plot
  geom_bar(stat = "identity", color = "black") +
  
  # Error Bar
  geom_errorbar(aes(ymin = mean_sig - sd_sig, 
                    ymax = mean_sig + sd_sig), 
                width=.2, 
                position=position_dodge(.9)) +
  
  # Aesthetics
  scale_fill_discrete(name = "Glomics ID") +
  ylab("Relative Abundance") +
  xlab("Functional Category") +
  ggtitle("Relative Abundance of Functional Gene Categories") +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.title.x = element_text(size = 14), 
    axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 12),
    axis.title.y = element_text(size = 14), 
    plot.title = element_text(size = 16, face = "bold")
  )



## Save Plot ----------------------------------------------------------------------------------------------
ggsave("results/figures/Geochip_Functional_Gene_Abundance.png")