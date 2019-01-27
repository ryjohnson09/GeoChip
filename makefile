
# List all targes by typing make list
.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs -n 1




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
	R -e "source('code/Merge_Geochip.R', echo=T)"



# Create Clinical Metadata Table Extracted from TrEAT DB
# Depends on:   data/processed/Merged_Geochip.tsv
#               data/raw/TrEAT_Merge_ESBL_2018.09.13_v2.XLSX
#               data/raw/TrEAT_Merge_DataDictionary_2018.06.27.XLSX
#               data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx
#               code/Create_Clin_Metadata.R
# Produces:     data/processed/TrEAT_Clinical_Metadata_tidy.csv
data/processed/TrEAT_Clinical_Metadata_tidy.csv : data/processed/Merged_Geochip.tsv\
                                                  data/raw/TrEAT_Merge_ESBL_2018.09.13_v2.XLSX\
                                                  data/raw/TrEAT_Merge_DataDictionary_2018.06.27.XLSX\
                                                  data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx\
                                                  code/Create_Clin_Metadata.R
	R -e "source('code/Create_Clin_Metadata.R', echo=T)"



# Create Geochip specific ID_Decoder that links subject IDs to glomics IDs
# Depends on:	data/processed/Merged_Geochip.tsv
#		data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx
#		code/ID_Decoder_Geochip.R
# Produces:	data/processed/ID_Decoder_Geochip.csv
data/processed/ID_Decoder_Geochip.csv : data/processed/Merged_Geochip.tsv\
					data/raw/IDCRP_Glomics_Subject_ID_List_11-21-17.xlsx\
					code/ID_Decoder_Geochip.R
	R -e "source('code/ID_Decoder_Geochip.R', echo=T)"
