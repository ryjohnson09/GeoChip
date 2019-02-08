#############################################################
# Name: GeoChip_Superheat_All.R
# Author: Ryan Johnson
# Date Created: 12 July 2018
# Purpose: Visualize the normalized signal intensities for
#          for all probes detected in merged Geochip data
#############################################################

#!#!##!#!#!#!#!#!#!#!#!#!!#
# ISSUES:
#  1. Data structure is too large, running out of memory.
#     Should try AWS, or data.table to compute dist manually
#!#!#!#!#!#!#!#!#!#!#!#!#!#

library(tidyverse)
library(superheat)

# Read in merged Geochip data (not tidy version)
geochip <- read_tsv("data/processed/Merged_Geochip.tsv", n_max = 50,
                    col_types = cols(Genbank.ID = col_character()), 
                    progress = TRUE) %>%
  select(Genbank.ID, starts_with("X"))

# Convert to data frame (with rownames)
geochip_df <- as.data.frame(geochip)
rownames(geochip_df) <- geochip_df$Genbank.ID
geochip_df[,1] <- NULL

rm(geochip)


# Set NA's to 0
geochip_df[is.na(geochip_df)] <- 0


# Create Superheat heatmap
png("results/figures/GeoChip_Superheat_all.png", height = 900, width = 800)

superheat(geochip_df,
         #row.dendrogram = TRUE,
         col.dendrogram = TRUE,
         # heat.lim encompasses all values in merged geochip data, 
         # and sets the 0 values to black
         heat.lim = c(2, 17),
         legend.breaks = c(2, 5, 8, 11, 14, 17))

dev.off()