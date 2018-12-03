# Geochip Probe/Gene/Category Relative Abundance and Counts

library(shiny)
library(tidyverse)

#######################
#### Read in Files ####
#######################

ID_decoder <- suppressWarnings(suppressMessages(read_csv("ID_Decoder.csv")))
treat <- suppressWarnings(suppressMessages(read_csv("TrEAT_Clinical_Metadata_tidy.csv")))
geochip <- suppressWarnings(suppressMessages(read_tsv("Merged_Geochip.tsv")))



## UI ------------------------------------------------------------------------------------

ui <- fluidPage(
  
  titlePanel("GeoChip Relative Abundance/Counts"),
  sidebarLayout(
    sidebarPanel(
      
      # Matched or All samples
      radioButtons("matched", label = "Matched or All samples",
                   choices = matched_choices, inline = TRUE, selected = "matched_samples"),
      helpText("Matched = Only patients that provided samples for all selected visits"),
      
      ##########################################
      ### Inputs that Select Certain Samples ###
      ##########################################
      fluidRow(
        h3("Sample Selection:"),
        
        column(12, 
               wellPanel(
                 # Treatment Group
                 selectInput("tx_group", "Treatment Groups", choices = tx_choices, selected = "All"),
                 helpText("Select patients samples in specified treatment groups"),
                 
                 # Visit Number
                 checkboxGroupInput('Visit_Number', 'Visit:', choices = visit_choices, selected = c(1, 5), inline = TRUE),
                 helpText("Select patient samples from specified visit number"),
                 helpText("Only select two visit numbers"),
                 
                 # Pathogen Detection
                 selectInput("path_detection", "Pathogen Detection Method", choices = detection_choices, selected = "Both"),
                 helpText("How are samples determined to be positive for pathogen"),
                 # Pathogen Choices
                 uiOutput("secondSelection"),
                 helpText("If", code("All"), ", then all samples included.")))),
      
      
      #######################
      ### Probe Selection ###
      #######################
      fluidRow(
        h3("Probe Selection"),
        
        column(12, 
               wellPanel(
                 
                 # Select Phylum probes?
                 h5("Phylum Specific Probes"),
                 checkboxInput("select_phylum", label = "Select Phylum Probes?", value = FALSE),
                 helpText("If selected, only probes from selected bacterial phlya will be included in analysis"),
                 
                 # Phyla output
                 uiOutput("phyla"),
                 helpText("Select probes based on bacterial phyla")))),
      
      ########################
      ### Y axis categories ##
      ########################
      fluidRow(
        h3("Functional Group Selection"),
        
        column(12, 
               wellPanel(
                 # Gene_category vs Subcategory1 vs Subcategory2
                 selectInput("cat_choice", "Y-axis Categories", choices = cat_choices, selected = "Gene_category"),
                 helpText("Select Categories to Compare"),
                 
                 # Number of minimum samples that must have Category
                 sliderInput("cat_min_number", "Minimum Observation in Category:",
                             min = 1, max = 20,
                             value = 10)))),
      
      
      fluidRow(
        h3("Ordination and Aesthetics"),
        
        column(12, 
               wellPanel(
                 # Only keep significant RR's
                 checkboxInput("keeper", label = "Remove non-significant RR's", value = FALSE)
               )),
        
        
        downloadButton('downloadPlot','Download Plot')),
      
      
      #sidebar width
      width = 4),
    
    # Plot
    mainPanel(
      plotOutput("plot", width = "800px", height = "800px"),
      br()
      
      # Table to see patients (not needed, but useful for troubleshooting)
      #fluidRow(column(12,tableOutput('table')))
      
      ################################
      ### Notes Regarding Analysis ###
      ################################
      #helpText("")
    )))