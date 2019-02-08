#############################################################
# Name: GeoChip_heatmap2_All.R
# Author: Ryan Johnson
# Date Created: 13 July 2018
# Purpose: Visualize the normalized signal intensities for
#          for all probes detected in merged Geochip data
#############################################################

#!#!##!#!#!#!#!#!#!#!#!#!!#
# ISSUES:
#  1. Data structure is too large, running out of memory.
#     Should try AWS, or data.table to compute dist manually
#  2. Think about splitting up the number of samples in each/
#     number of genes included.
#!#!#!#!#!#!#!#!#!#!#!#!#!#

library(tidyverse)
library(gplots)
library(viridis)


# Read in Merged Geochip data
geochip <- read_tsv("data/processed/Merged_Geochip.tsv", 
                    col_types = cols(Genbank.ID = col_character()), 
                    progress = TRUE) %>%
  select(Genbank.ID, starts_with("X"))


# Ensure columns are numeric
geochip <- geochip %>%
  mutate_at(vars(starts_with("X")), funs(as.numeric))


# Set rownames
geochip_df <- as.data.frame(geochip)
rownames(geochip_df) <- geochip_df$Genbank.ID
geochip_df[,1] <- NULL

# Set NA's to 0
geochip_df[is.na(geochip_df)] <- 0

# Set up color scale
colors = c(
  seq(0, 2.6, length = 10), # Black
  seq(2.61, 5, length = 10), # Viridis (purple)
  seq(5.01, 7, length = 10), # Viridis
  seq(7.01, 9, length = 10), # Viridis
  seq(9.01, 11, length = 10), # Viridis (yellow)
  seq(11.01, 17, length = 10)) # Yellow

my_palette <- colorRampPalette(c("black", viridis(5), "#FDE725FF"))(n = 59)


# Plot heatmap and save
png("results/figures/Geochip_heatmap2_all.png", height = 10, width = 8, units = "in", res = 300)

heatmap.2(as.matrix(geochip_df),
          trace = "none",
          density.info = "none",
          col = my_palette, 
          breaks = colors, 
          labRow = FALSE,
          labCol = FALSE,
          dendrogram = "none",
          Rowv = FALSE,
          Colv = FALSE,
          key = FALSE)

dev.off()

