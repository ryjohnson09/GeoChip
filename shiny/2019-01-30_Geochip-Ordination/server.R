##################################
#### Geochip Shiny App Server ####
##################################

## Load Libraries -----------------------------------
library(shiny)
library(tidyverse)
library(vegan)
library(ggExtra)
library(ape)


# Define server -------------------------------------
shinyServer(function(input, output){
  
  
  
  ## Read in Raw Data with Progress Bar --------------------------------
  withProgress(message = "Reading in Data:", {
    
    # Geochip
    incProgress(amount = 1/3, detail = "Reading Geochip Data")
    geochip <- suppressWarnings(suppressMessages(read_tsv("Merged_Geochip.tsv")))
    
    
    # Treat
    incProgress(amount = 1/3, detail = "Reading Metadata Data")
    treat <- suppressWarnings(suppressMessages(read_csv("TrEAT_Clinical_Metadata_tidy.csv")))
    
    
    # ID Decoder
    incProgress(amount = 1/3, detail = "Reading Decoder")
    ID_decoder <- suppressWarnings(suppressMessages(read_csv("ID_Decoder_Geochip.csv")))
  })
  
  
  ## Filter Patients from Data -------------------------------------------------------
  
  ##############################
  ### Visit Number / Matched ###
  ##############################
  ID_v <- reactive({
    
    # Ensure that at least visit is selected
    validate(need(input$visit_number, 'Please select at least one visit number'))
    
    # If non-matched
    if (!input$matched){
      filter(ID_decoder, visit_number %in% as.numeric(input$visit_number))
      
      # if matched 
    } else if (input$matched){
      matched_samples <- ID_decoder %>%
        filter(visit_number %in% as.numeric(input$visit_number)) %>%
        count(study_id) %>%
        filter(n == length(as.numeric(input$visit_number))) %>%
        pull(study_id)
      
      # Get glomics ID's that correspond to the patients
      # with matched samples
      matched_glomics <- ID_decoder %>%
        filter(visit_number %in% as.numeric(input$visit_number)) %>%
        filter(study_id %in% matched_samples) %>%
        pull(glomics_ID)
      
      # Filter ID Decoder for only matched
      filter(ID_decoder, glomics_ID %in% matched_glomics)
    }
  })
  
  
  #########################
  ### Filter by Country ###
  #########################
  ID_v_c <- reactive({
    
    # Ensure that at least country is selected
    validate(need(input$country, 'Please select at least one country'))
    
    # Select patients by country from treat
    country_patients <- treat %>%
      filter(country %in% input$country) %>%
      pull(STUDY_ID)
    
    # Filter ID_Decoder
    ID_v() %>%
      filter(study_id %in% country_patients)
  })
  
  
  ##########################################
  ### Treatment Group / Remove LOP & PLA ###
  ##########################################
  ID_v_c_t <- reactive({
    
    # Ensure that at least treatment group is selected
    validate(need(input$treatment_groups, 'Please select at least one treatment group'))
    
    treat_studyIDs <- treat %>%
      # Remove LOP and PLA samples
      filter(!Treatment %in% c("LOP", "PLA")) %>%
      # Samples in select treatment groups
      filter(Treatment %in% input$treatment_groups) %>%
      pull(STUDY_ID)
    
    # Filter ID_decoder
    ID_v_c() %>%
      filter(study_id %in% treat_studyIDs)
  })
  
  
  
  ########################
  ### Disease Severity ###
  ########################
  ID_v_c_t_d <- reactive({
    
    # Ensure that at least disease severity is selected
    validate(need(input$disease_severity, 'Please select at least one disease severity group'))
    
    treat_disease <- treat %>%
      filter(LLS_severity %in% input$disease_severity) %>%
      pull(STUDY_ID)
    
    # Filter ID_decoder
    ID_v_c_t() %>%
      filter(study_id %in% treat_disease)
  })
  
  
  
  ##########################
  ### Pathogen Detection ###
  ##########################
  treat_pathogens <- reactive({
    treat_select <- treat %>%
      # Select columns with appropriate detection method
      select(STUDY_ID, ends_with(input$detection_method)) %>%
      # Determine if co-infection or not
      mutate(num_pathogens = rowSums(. == "yes", na.rm = TRUE))
    
    # Allow Coinfections?
    if (!input$allow_coinfections){
      treat_select_coinfections <- treat_select %>%
        filter(num_pathogens == 1)
    } else if (input$allow_coinfections){
      treat_select_coinfections <- treat_select
    }
    
    treat_new <- treat_select_coinfections %>%
      # Select for pathogens of interest
      select(STUDY_ID, paste(input$pathogens, input$detection_method, sep = "_")) %>%
      # Replace yes no with Pathogen
      mutate_at(vars(matches(input$detection_method)),
                funs(ifelse(. == "yes", gsub(x = deparse(substitute(.)), pattern = "_.*$", replacement = ""), ""))) %>%
      # If sample has an NA, remove it (wasn't tested)
      mutate(has_na = rowSums(is.na(.))) %>%
      filter(has_na == 0) %>%
      select(-has_na) %>%
      # If no pathogens of intereste detected, remove it
      mutate(path_present = rowSums(. == "")) %>%
      filter(path_present != length(input$pathogens)) %>%
      select(-path_present) %>%
      # Merge pathogens into one column
      unite(pathogens, paste(input$pathogens, input$detection_method, sep = "_"), sep = "_") %>%
      mutate(pathogens = str_replace_all(pathogens, "^_*", "")) %>%
      mutate(pathogens = str_replace_all(pathogens, "_*$", "")) %>%
      mutate(pathogens = str_replace_all(pathogens, "_+", "-"))
    
    treat_new
  })
  
  # Filter ID if selecting pathogens
  ID_v_c_t_d_p <- reactive({
    if (input$pathogen_select){
      
      # Ensure that at least one pathogen is selected
      validate(need(input$pathogens, 'Please select at least one Pathogen'))
      
      ID_v_c_t_d() %>%
        filter(study_id %in% treat_pathogens()$STUDY_ID)
    } else if (!input$pathogen_select){
      ID_v_c_t_d()
    }
  })
  
  
  
  ## Probe Filtering ---------------------------------------------------------
  geo_probes_filtered <- reactive({
    
    if(input$probe_type == "Gene Category"){
      # Ensure that at least one functional group is selected
      validate(need(input$geneCategory, 'Please select at least one Functional Group'))
      # Filter Geochip for Gene_category(s) of interest
      geochip %>%
        filter(Gene_category %in% input$geneCategory)
    } else if (input$probe_type == "All"){
      geochip
    }
  })
  
  
  
  
  
  
  
  
})