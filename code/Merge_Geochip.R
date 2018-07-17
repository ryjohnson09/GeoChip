###########################################################################
# Name: Merge_Geochip
# Purpose: Take all Geochip data sets and combine 
#          them into a single data frame
# Date Created: 5 July, 2018
# Examples:
#   merge_geochip("../data/raw/geochip1.txt")
#   merge_geochip("../data/raw/geochip1.txt", "../data/raw/geochip2.txt)
############################################################################

library(tidyverse)

# list vector of geochip files
geochip_files <- c(
  "data/raw/GeoChip_New/GeoChip-1-LTO.txt",
  "data/raw/GeoChip_New/GeoChip-2-LTO.txt",
  "data/raw/GeoChip_New/GeoChip-3-LTO.txt", 
  "data/raw/GeoChip_New/GeoChip-4-LTO.txt", 
  "data/raw/GeoChip_New/GeoChip-5-LTO.txt", 
  "data/raw/GeoChip_New/GeoChip-6-LTO.txt", 
  "data/raw/GeoChip_New/GeoChip-7-LTO.txt", 
  "data/raw/GeoChip_New/GeoChip-8-LTO.txt"
)

# Create empty data frame
geochip_data <- tibble()

# Start loop that will read in each geochip separately
for (gchip in geochip_files){
  
  # If tibble is empty (first occurence)
  if(is_empty(geochip_data)){
    
    # Read in gchip
    geochip_data <- read_tsv(gchip, guess_max = 100000) %>%
      select(`Genbank ID`, Gene, Organism, Gene_category, 
             Subcategory1, Subcategory2, Lineage, starts_with("X"))
  } else {
    
    # Read in gchip and merge into geochip_data
    geochip_temp <-  read_tsv(gchip, guess_max = 100000) %>%
      select(`Genbank ID`, Gene, Organism, Gene_category, 
             Subcategory1, Subcategory2, Lineage, starts_with("X"))
    
    geochip_data <- full_join(geochip_data, geochip_temp, 
                              by = c("Genbank ID", "Gene", "Organism", "Gene_category", 
                                     "Subcategory1", "Subcategory2", "Lineage"))
  }
}

# Clean
rm(geochip_temp, gchip, geochip_files)


# Remove any extraneous text at end of sample headers
colnames(geochip_data) <- str_replace(string = colnames(geochip_data), 
                                        pattern = "(^[Xx]\\d{1,3}).*", 
                                        replacement = "\\1")

# Capitalize "x" if lowercase
colnames(geochip_data) <- str_replace(string = colnames(geochip_data),
                                      pattern = "^x",
                                      replacement = "X")



## Make sample names Unique ---------------------------------------------------

# Check for duplicates and make unique
geochip_data <- geochip_data %>%
  setNames(make.names(names(.), unique = TRUE))


#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
# Remove Duplicates ****MAY NEED TO BE CHANGED******* 
geochip_data <- geochip_data %>%
  select(-X85, -X101, -X193)

colnames(geochip_data) <- str_replace(string = colnames(geochip_data), 
                                      pattern = "\\.1", 
                                      replacement = "")
#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#




## Remove samples that are excluded from the study ----------------------------
geochip_data <- geochip_data %>%
  select(-X10) # 48-2406




## Fixing Category names ------------------------------------------------------

# Fix Gene_Categories
geochip_data$Gene_category <- toupper(geochip_data$Gene_category)
geochip_data$Gene_category <- gsub(pattern = " ", replacement = "_", geochip_data$Gene_category)


# Fix Subcategory1
geochip_data$Subcategory1 <- toupper(geochip_data$Subcategory1)
geochip_data$Subcategory1 <- gsub(pattern = " ", replacement = "_", geochip_data$Subcategory1)

geochip_data <- geochip_data %>%
  mutate(Subcategory1 = ifelse(Subcategory1 == "EFFECTOR", "EFFECTOR_PROTEIN", Subcategory1))

# Fix Subcategory2
geochip_data$Subcategory2 <- toupper(geochip_data$Subcategory2)
geochip_data$Subcategory2 <- gsub(pattern = " ", replacement = "_", geochip_data$Subcategory2)

geochip_data <- geochip_data %>%
  mutate(Subcategory2 = ifelse(Subcategory2 == "OOMYCETES", "OOMYCETE", Subcategory2)) %>%
  mutate(Subcategory2 = ifelse(Subcategory2 == "TRANSPORTER", "TRANSPORT", Subcategory2))



# Return compiled data frame
write_tsv(geochip_data, "data/processed/Merged_Geochip.tsv")

