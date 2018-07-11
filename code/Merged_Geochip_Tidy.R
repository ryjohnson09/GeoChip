####################################################
# Name: Merged_Geochip_Tidy.R
# Author: Ryan Johnson
# Date Created: 8 July 2018
# Purpose: Take the merged Geochip data and convert
#          it to long/tidy format
####################################################

library(tidyverse)

# Read in merged Geochip Data
geochip <- read_tsv("data/processed/Merged_Geochip.tsv", guess_max = 100000)

# Make long/tidy
geochip_long <- geochip %>%
  gather(key = glomics_ID, 
         value = Signal, 
         colnames(.[8:ncol(.)]), -Genbank.ID, -Gene,
         -Organism, -Gene_category, -Subcategory1, 
         -Subcategory2, -Lineage)

rm(geochip) # Clean

# Read in decoder
ID_list <- read.csv("data/processed/ID_Decoder.csv")

# Join to geochip data
geochip_long <- geochip_long %>%
  full_join(., ID_list, by = c("glomics_ID")) %>%
  select(glomics_ID, study_id, visit_number, everything())

# Write to `data/processed`
write_tsv(geochip_long, "data/processed/Merged_Geochip_Tidy.tsv")