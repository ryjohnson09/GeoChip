###################################################
# Name: DCA_Geochip.R
# Author: Ryan Johnson
# Date Created: 6 July 2018
# Purpose: Perform Detrended Coordinate Analysis
#          on GeoChip Data. Merge with releavant
#          metadata
# Example:
#
###################################################

library(tidyverse)
library(vegan)

## Import and Clean --------------------------------

# Import the merged Geochip data set
geochip1 <- readr::read_tsv("data/processed/Merged_Geochip.tsv", progress = TRUE)

# Remove descriptive columns (leaving only samples)
geochip1 <- geochip1 %>%
  select(-`Genbank ID`, -Gene, -Organism, -Gene_category, 
         -Subcategory1, -Subcategory2, -Lineage, -X10) # X10 was removed from study

# Set NA's to 0
geochip1[is.na(geochip1)] <- 0

# Remove rows that equal 0
geochip1 <- geochip1[rowSums(geochip1) != 0,]







## Perform DCA ----------------------------------------

# Detrended correspondence analysis!!!!!!!!!!
geochip_dca <- vegan::decorana(veg = geochip1)

# Get the coordinated for the samples
geochip_dca_coords <- scores(geochip_dca, display = "species")

# Make rownames into first column
geochip_dca_coords <- as.data.frame(geochip_dca_coords) %>%
  rownames_to_column(var = "glomics_ID")




## Write DCA coordinates -------------------------------
write_csv(geochip_dca_coords, "data/processed/GeoChip_DCA.csv")
