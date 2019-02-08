##################################################################
# Name: PCA_Geochip.R
# Author: Ryan Johnson
# Date Created: 8 February 2019
# Purpose: Perform PCA on Geochip Data
##################################################################

library(tidyverse)
library(vegan)


## Read in data -----------------------------------------------------------------------------------------
geochip <- suppressWarnings(suppressMessages(read_tsv("data/processed/Merged_Geochip.tsv")))
treat <- suppressWarnings(suppressMessages(read_csv("data/processed/TrEAT_Clinical_Metadata_tidy.csv")))
ID_Decoder <- suppressWarnings(suppressMessages(read_csv("data/processed/ID_Decoder_Geochip.csv")))

# Only include matched isolate for visit 1 and visit 4 or 5
ID_Decoder_matched <- ID_Decoder %>%
  filter(visit_number %in% c(1,5)) %>%
  group_by(study_id) %>% 
  filter(n() == 2) 

rm(ID_Decoder)

# Merge treat to ID_Decoder
treat <- ID_Decoder_matched %>% 
  left_join(., treat, by = c("study_id" = "STUDY_ID"))


## Filter treat to include treat samples of interest -----------------------------------------------

treat_filter <- treat %>% 
  # Remove LOP and PLA
  filter(!Treatment %in% c("LOP", "PLA"))

rm(treat)

## Filter the geochip data to include only samples in treat_filter --------------------------------
geochip_filtered <- geochip %>% 
  select_if(colnames(.) %in% c("Genbank.ID", "Gene", "Organism", "Lineage",
                               "Gene_Category", "Subcategory1",
                               "Subcategory2", treat_filter$glomics_ID))

rm(geochip)

## Probe Filtering ---------------------------------------------------------

geo_probes_filtered <- geochip_filtered



## Prepare Data for Ordination Analysis ----------------------------------------
geo_matrix <- geo_probes_filtered %>% 
  
  # Set NA's to 0 and values not NA to original value
  select(starts_with("X")) %>%
  mutate_all(funs(ifelse(is.na(.), 0, .)))

# Remove rows that equal 0
geo_matrix <- geo_matrix[rowSums(geo_matrix) != 0,]

# Return matrix
geo_matrix <- as.matrix(geo_matrix)



## Ordination Analysis ----------------------------------------------------------
geo_PCA <- vegan::rda(t(geo_matrix))

# Extract coordinates as tibble
geo_coordinates <- as.data.frame(scores(geo_PCA, display = "sites")) %>%
  rownames_to_column(var = "glomics_ID")



# Get Proportion explained
ord_prop_expl <- summary(eigenvals(geo_PCA))[2,] * 100



## Merge Ordination Analysis with Metadata --------------------------------------
geo_PCA_metadata <- geo_coordinates %>%
  # Add study ID's
  full_join(., treat_filter, by = "glomics_ID")



## Plot ---------------------------------------------------------------------------------
# Factor Columns
geo_PCA_metadata <- geo_PCA_metadata %>% 
  mutate(visit_number = factor(visit_number)) %>%
  mutate(Impact_of_illness_on_activity_level = factor(Impact_of_illness_on_activity_level))


# Aesthetic sizes
axis_title_size <- 18
axis_text_size <- 16
title_size <- 20
legend_text_size <- 13
point_size <- 4


# Set up base plot
geo_PCA_base <- 
  ggplot(geo_PCA_metadata) +
  theme_minimal() +
  theme(
    axis.title.x = element_text(size = axis_title_size),
    axis.text.x = element_text(size = axis_text_size, hjust = 1),
    axis.text.y = element_text(size = axis_text_size),
    axis.title.y = element_text(size = axis_title_size),
    plot.title = element_text(size = title_size, face = "bold"),
    legend.text = element_text(size = legend_text_size),
    legend.title = element_blank()) +
  guides(fill = guide_legend(override.aes = list(size=7)))

# PCA Plot
geo_PCA_plot <- geo_PCA_base +
  xlab(paste0("PC1(", round(ord_prop_expl[[1]], 2), "%)")) +
  ylab(paste0("PC2(", round(ord_prop_expl[[2]], 2), "%)")) +
  geom_point(aes(x = PC1, 
                 y = PC2, 
                 shape = visit_number),
             alpha = 1, size = point_size) +
  geom_line(aes(x = PC1, 
                y = PC2, 
                group = study_id,
                color = Treatment), 
            linetype = 1, size = 0.8) +
  ggtitle("PCA Analysis - Geochip")

geo_PCA_plot

ggsave(plot = geo_PCA_plot, filename = "results/figures/PCA_Geochip_v15_tx.png", height = 8, width = 9)
