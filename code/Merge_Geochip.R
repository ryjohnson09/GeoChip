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

merge_geochip <- function(Geochip){
  
  # Create empty data frame
  geochip_data <- tibble()
  
  # Start loop that will read in each geochip separately
  for (gchip in Geochip){
    
    # If tibble is empty (first occurence)
    if(is_empty(geochip_data)){
      
      # Read in gchip
      geochip_data <- read_tsv(gchip, guess_max = 100000) %>%
        select(`Genbank ID`, Gene, Organism, Gene_category, 
               Subcategory1, Subcategory2, Lineage, contains("[Xx]\\d{1,3}"))
    } else {
      
      # Read in gchip and merge into geochip_data
      x <-  read_tsv(gchip, guess_max = 100000) %>%
        select(`Genbank ID`, Gene, Organism, Gene_category, 
               Subcategory1, Subcategory2, Lineage, contains("[Xx]\\d{1,3}"))
      
      geochip_data <- full_join(geochip_data, x, 
                                by = c("Genbank ID", "Gene", "Organism", "Gene_category", 
                                       "Subcategory1", "Subcategory2", "Lineage"))
    }
  }
  
  # Remove any extraneous text at end of sample headers
  colnames(geochip_data) <- str_replace(string = colnames(geochip_data), 
                                          pattern = "(^[Xx]\\d{1,3}).*", 
                                          replacement = "\\1")
  
  # Capitalize "x" if lowercase
  colnames(geochip_data) <- str_replace(string = colnames(geochip_data),
                                        pattern = "^x",
                                        replacement = "X")
  
  # Return compiled data frame
  write_tsv(geochip_data, "data/processed/Merged_Geochip.tsv")
}
