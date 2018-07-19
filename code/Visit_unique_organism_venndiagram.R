#########################################################
# Name: Visit_unique_organism_venndiagram.R
# Author: Ryan Johnson
# Date Created: 18 July 2018
# Purpose: Create a Venn Diagram showing the overlap in
#          gene presence between the various visits.
#          Only considering unique genes (can be the 
#          same gene from different species).
#########################################################

library(tidyverse)
library(VennDiagram)

geochip <- read_tsv("data/processed/Merged_Geochip_Tidy.tsv", 
                    col_types = "ccicccccccd",
                    progress = TRUE)

# If a signal is present, convert to 1, if it is NA convert to 0.
geochip1 <- geochip %>% 
  mutate(Signal = ifelse(is.na(Signal), 0, 1)) %>%
  group_by(glomics_ID, Organism, visit_number, study_id) %>%
  summarise(gene_presense = sum(Signal)) %>%
  ungroup() %>%
  
  # Remove genes not detected in samples, no organism
  filter(gene_presense != 0) %>%
  filter(!is.na(Organism))



# Merge in Clinical Metadata
treatment_groups <- read_csv("data/processed/TrEAT_Clinical_Metadata_tidy.csv")

geochip2 <- geochip1 %>%
  full_join(., treatment_groups, by = c("study_id" = "STUDY_ID")) %>%
  drop_na(glomics_ID) # remove any samples not in glomics data




# Get tibble of organisms within each visit
visit_organisms <- geochip2 %>%
  select(Organism, visit_number) %>%
  group_by(visit_number) %>%
  mutate(group_row = 1:n()) %>%
  spread(visit_number, Organism) %>%
  select(-group_row)


# Make three lists of unique genes at each visit.
Visit1 <- unique(na.omit(visit_organisms$`1`))
Visit4 <- unique(na.omit(visit_organisms$`4`))
Visit5 <- unique(na.omit(visit_organisms$`5`))


#Plot as Venn diagram
visit_gene_list <- list(
  Visit_1 = Visit1,
  Visit_4 = Visit4,
  Visit_5 = Visit5
)
futile.logger::flog.threshold(futile.logger::ERROR, name = "VennDiagramLogger") # no log file written

visit_venn <- venn.diagram(visit_gene_list,
                           filename = "results/figures/Visit_unique_organism_venndiagram.tiff",
                           fill = c(2:4),
                           alpha = 0.3,
                           cex = 2,
                           cat.cex = 2)