
# List all targes by typing make list
.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs -n 1




# Create decoder that links Glomics ID's to TrEAT Subject IDs
# Depends on:	data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx
#		code/ID_Decoder.R
# Produces:	data/processed/ID_Decoder.csv
data/processed/ID_Decoder.csv : data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx\
				code/ID_Decoder.R
	R -e "source('code/ID_Decoder.R')"




# Merge all of the Geochip datasets into one
# Depends on:	data/raw/GeoChip_New/GeoChip-1-LTO.txt
#		data/raw/GeoChip_New/GeoChip-2-LTO.txt
#		data/raw/GeoChip_New/GeoChip-3-LTO.txt
#		data/raw/GeoChip_New/GeoChip-4-LTO.txt
#		data/raw/GeoChip_New/GeoChip-5-LTO.txt
#               data/raw/GeoChip_New/GeoChip-6-LTO.txt
#               data/raw/GeoChip_New/GeoChip-7-LTO.txt
#               data/raw/GeoChip_New/GeoChip-8-LTO.txt
#		code/Merge_Geochip.R
# Produces:	data/processed/Merged_Geochip.tsv
data/processed/Merged_Geochip.tsv : data/raw/GeoChip_New/GeoChip-1-LTO.txt\
				    data/raw/GeoChip_New/GeoChip-2-LTO.txt\
				    data/raw/GeoChip_New/GeoChip-3-LTO.txt\
                                    data/raw/GeoChip_New/GeoChip-4-LTO.txt\
                                    data/raw/GeoChip_New/GeoChip-5-LTO.txt\
                                    data/raw/GeoChip_New/GeoChip-6-LTO.txt\
				    data/raw/GeoChip_New/GeoChip-7-LTO.txt\
				    data/raw/GeoChip_New/GeoChip-8-LTO.txt\
				    code/Merge_Geochip.R
	R -e "source('code/Merge_Geochip.R'); merge_geochip(c('data/raw/GeoChip_New/GeoChip-1-LTO.txt','data/raw/GeoChip_New/GeoChip-2-LTO.txt','data/raw/GeoChip_New/GeoChip-3-LTO.txt','data/raw/GeoChip_New/GeoChip-4-LTO.txt','data/raw/GeoChip_New/GeoChip-5-LTO.txt','data/raw/GeoChip_New/GeoChip-6-LTO.txt','data/raw/GeoChip_New/GeoChip-7-LTO.txt','data/raw/GeoChip_New/GeoChip-8-LTO.txt'))"



# Make the Merged Geochip data long/tidy
# Depends on:	data/processed/Merged_Geochip.tsv
#		data/processed/ID_Decoder.csv
#		code/Merged_Geochip_Tidy.R
# Produces:	data/processed/Merged_Geochip_Tidy.tsv
data/processed/Merged_Geochip_Tidy.tsv : data/processed/Merged_Geochip.tsv\
			                 data/processed/ID_Decoder.csv\
			                 code/Merged_Geochip_Tidy.R
	R -e "source('code/Merged_Geochip_Tidy.R', echo=T)"





# Visualize the Geochip Signal Distribution
# Depends on:	data/processed/Merged_Geochip_Tidy.tsv
#		code/Geochip_Signal_Distribution.R
# Produces:	results/figures/Geochip_Signal_Distribution.png
results/figures/Geochip_Signal_Distribution.png : data/processed/Merged_Geochip_Tidy.tsv\
				                  code/Geochip_Signal_Distribution.R
	R -e "source('code/Geochip_Signal_Distribution.R', echo=T)"








# Plot the Relative Abundance of all Functional Gene Categories for all samples
# Depends on:	data/processed/Merged_Geochip_Tidy.tsv
#		code/Functional_Category_Abundance.R
# Produces:	results/figures/Geochip_Functional_Gene_Abundance.png
results/figures/Geochip_Functional_Gene_Abundance.png : data/processed/Merged_Geochip_Tidy.tsv\
							code/Functional_Category_Abundance.R
	R -e "source('code/Functional_Category_Abundance.R', echo=T)"





# Plot the Relative Abundance of Functional Gene Categories by visit number
# Depends on:	data/processed/Merged_Geochip_Tidy.tsv
#               code/Functional_Category_Visit_Number.R
# Produces:	results/figures/Geochip_Functional_Gene_Abundance_Visit_Number.png
results/figures/Geochip_Functional_Gene_Abundance_Visit_Number.png : data/processed/Merged_Geochip_Tidy.tsv\
								     code/Functional_Category_Visit_Number.R
	R -e "source('code/Functional_Category_Visit_Number.R', echo=T)"





# Create Clinical Metadata Table Extracted from TrEAT DB
# Depends on:	data/processed/Merged_Geochip.tsv
#		data/raw/TrEAT_Merge_2018.06.27.XLSX
#		data/raw/TrEAT_Merge_DataDictionary_2018.06.27.XLSX
#		data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx
#		code/Create_Clin_Metadata.R
# Produces:	data/processed/TrEAT_Clinical_Metadata_tidy.csv
data/processed/TrEAT_Clinical_Metadata_tidy.csv : data/processed/Merged_Geochip.tsv\
				                  data/raw/TrEAT_Merge_2018.06.27.XLSX\
				                  data/raw/TrEAT_Merge_DataDictionary_2018.06.27.XLSX\
				                  data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx\
				                  code/Create_Clin_Metadata.R
	R -e "source('code/Create_Clin_Metadata.R', echo=T)"


##################
### Ordination ###
##################

# Run Detrended Coordinate Analysis on Merged GeoChip Data
# Depends on:	data/processed/Merged_Geochip.tsv
#		code/DCA_Geochip.R
# Produces:	data/processed/GeoChip_DCA.csv
data/processed/GeoChip_DCA.csv : data/processed/Merged_Geochip.tsv\
				 code/DCA_Geochip.R
	R -e "source('code/DCA_Geochip.R', echo=T)"


# Plot DCA Analysis on Merged GeoChip Data
# Depends on:	data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx
#		data/processed/GeoChip_DCA.csv
#		data/processed/TrEAT_Clinical_Metadata_tidy.csv
#		code/Plot_DCA_GeoChip.R
# Produces: 	results/figures/DCA_GeoChip_TreatmentGroup.png
#		results/figures/DCA_GeoChip_VisitNumber.png
results/figures/DCA_GeoChip_TreatmentGroup.png results/figures/DCA_GeoChip_VisitNumber.png : data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx\
											     data/processed/GeoChip_DCA.csv\
											     data/processed/TrEAT_Clinical_Metadata_tidy.csv\
											     code/Plot_DCA_GeoChip.R
	R -e "source('code/Plot_DCA_GeoChip.R', echo=T)"
