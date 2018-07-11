geo1_trim <- read_tsv("../Input_for_IEG/Geochip1_input_trim.txt")

geo1_trim <- geo1_trim %>%
  select(-`Genbank ID`, -Gene_category)


#geo1_trim[is.na(geo1_trim)] <- 0


geochip_pca <- vegan::rda(geo1_trim)

# Get the coordinated for the samples
geochip_pca_coords <- scores(geochip_pca, display = "species")


ggplot(as.data.frame(geochip_pca_coords), aes(x = PC1, y = PC2)) +
  geom_point()
