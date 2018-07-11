#################################################
# Name: PCA_GeoChip.R
# Author: Ryan Johnson
# Date Created: 6 July 2018
# Purpose: Perform Principal Coordinate Analysis
#          on GeoChip Data.
#################################################

library(tidyverse)
library(vegan)


## Import and Clean -----------------------------------------------------

# Import the merged Geochip data set
geochip <- readr::read_tsv("../../data/processed/Merged_Geochip.tsv", progress = TRUE)

# Remove descriptive columns (leaving only samples)
geochip <- geochip %>%
  select(-Genbank.ID, -Gene, -Organism, -Gene_category, 
         -Subcategory1, -Subcategory2, -Lineage, -X10) # X10 was removed from study





## PCA Analysis -------------------------------------------------

# Perform PCA analysis using vegan
geochip_pca <- vegan::rda(geochip, na.action = na.exclude)

# Get the coordinated for the samples
geochip_pca_coords <- scores(geochip_pca, display = "species")

# Make tibble
geochip_pca_coords <- as.data.frame(geochip_pca_coords) %>%
  rownames_to_column(var = "glomics_ID")

# Merge subject ids into pca_coords
geochip_pca_coords <- geochip_pca_coords %>%
  full_join(., ID_list, by = "glomics_ID") %>%
  na.omit() %>%
  separate(study_ID, into = c("study_id", "visit_number"), "(?<=\\d{4})-")

# Add in metadata
geochip_pca_coords <- geochip_pca_coords %>%
  full_join(., treatment_groups, by = c("study_id" = "STUDY_ID")) %>%
  drop_na(glomics_ID) # remove any samples not in glomics data
