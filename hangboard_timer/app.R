#
# This is a Shiny web application for training climbing using a hangboard

#### Imports ####
library(shiny)
library(lubridate)
library(beepr)
library(tidyverse)
library(googlesheets4)
library(googledrive)

theme_set(
  theme_bw(base_size = 25)
)
        
sheet_URL = "https://docs.google.com/spreadsheets/d/17qnd_BELvIaU-FIFs8tZSxY8Th0irG4Bw_CJk1Atxo8/edit?usp=sharing"

# Set up exercises
exercises = c("Warm Up", rep(c("Front Lever", "Front Three", "Front Three",
                               "Half Crimp", "Half Crimp", "Pinch Block",
                              "Pinch Block", "Half Crimp", "Half Crimp"), 2),
              "Face Pulls", "External Rotations", "Finished")

# Exercises we want to record data for
tracked_exercises = choices = c("Front Lever", "Front Three",
                                "Front Three", "Half Crimp",
                                "Half Crimp", "Pinch Block")

bh = 30 # Time between left and right hangs
hand = c("B", "B", rep(c("R", "L", "L", "R"), 2), "B", rep(c("L", "R", "R", "L"), 2), "B", "B", "B")
hand[hand == "B"] <- "Both"
hand[hand == "L"] <- "Left"
hand[hand == "R"] <- "Right"

#### UI ####
ui <- fluidPage(
  br(),
  includeCSS("styles.css"),
  sidebarLayout(
    sidebarPanel(width=4,
      h3("Next exercise:"),
      textOutput('next_ex'),
      textOutput('time_to_ex'),
      actionButton('start','Start'),
      actionButton('stop','Stop'),
      actionButton('reset','Reset'),
      actionButton('skip','Skip'),
      textOutput('completed')
    ), 
    
    mainPanel(
      tabsetPanel(type = "tabs",
                  tabPanel("Record results",
                           br(),
                           numericInput("bodyweight", "Bodyweight / kg", value=NA, min=0, max=200, step=0.5),
                           selectInput("record_ex", label="Exercise",
                                       choices = tracked_exercises, selected = "Front Lever"),
                           radioButtons("record_hand", label="Hand",
                                        choices = c("Left", "Right","Both"), selected = "Both",
                                        inline = TRUE),
                           numericInput('record_time', 'Time / s:',
                                        value=NA, min=0, step=0.5),
                           numericInput('record_weight', 'Weight / kg:',
                                        value=NA, step=0.5),
                           actionButton("submit", "Submit")
                  ),
                  
                  tabPanel("Graphs",
                           br(),
                           selectInput("ex_choice", label="Exercise",
                                       choices = tracked_exercises),
                           selectInput("metric_choice", label="Metric",
                                       choices = c("Time", "Weight")),
                           plotOutput("plot")
                  ),
                  
                  tabPanel("Table",
                           br(),
                           p("Table of your results so far:"),
                           DT::dataTableOutput('results_df')
                  ),
                  
                  tabPanel("Settings",
                           br(),
                           sliderInput('interval', label = "Time between exercises / s:",
                                        round = TRUE, value=240, min=40, max=440, step=10)
                           )
                  )
      )
  ) 
)

server <- function(input, output, session) {
  
  # Initialize reactive values
  counter <- reactiveVal(1)     # Tracks which exercise we are on
  timer <- reactiveVal(10)      # Tracks time to next exercise 
  active <- reactiveVal(FALSE)  # Tracks if timer is active or paused
  
  # observers for actionbuttons
  observeEvent(input$start, {active(TRUE)})
  observeEvent(input$stop, {active(FALSE)})
  observeEvent(input$reset, {
    timer(10)
    counter(1)
  })
  observeEvent(input$skip, {timer(1)})
  
  # Dataframe that contains excercises and timings
  rv = reactiveValues(
    ex_df = tibble("exercise" = exercises, "hand" = hand,
                   "date" = as.character(Sys.Date()),
                   "timings" = NA)
  )
  
  # Add timings as reactive (user can choose exercise interval)
  observe({
    i = input$interval
    rv$ex_df$timings <- c(10, i, i, rep(c(bh, i-bh), 4),
                          i, rep(c(bh, i-bh), 4), i, 10)})
  
  #### Handle Results ####
  # Initialise results table
  output$results_df <- DT::renderDataTable({read_sheet(sheet_URL)})
  
  observeEvent(input$submit, {
    # Add data to google sheets
    row = data.frame("exercise" = input$record_ex, "hand" = input$record_hand, 
                     "time"=input$record_time, "weight"=input$record_weight,
                     "bodyweight" = input$bodyweight, "date" = as.character(Sys.Date()))
    sheet_append(sheet_URL, row)
    
    # After submission automatically add next exercise as defualt inputs
    updateSelectInput(session, "record_ex",
                      selected = rv$ex_df$exercise[counter()])
    updateRadioButtons(session, "record_hand",
                       selected = rv$ex_df$hand[counter()])
    output$results_df <- DT::renderDataTable({read_sheet(sheet_URL)})
  })
  
  
  #### Plot results ####
  output$plot = renderPlot({
    df = read_sheet(sheet_URL)
    df$date = ymd(df$date)
    df$hand <- as.factor(df$hand)
    colours = c("black", "goldenrod3", "darkslategray4")
      
    if (input$metric_choice == "Time"){
      p = df %>%
        filter(exercise == input$ex_choice) %>%
        ggplot(aes(date, time, color = hand, size=weight)) +
        geom_point(alpha=0.6) +
        scale_color_manual(values=colours) +
        scale_size("weight", range = c(1,5))
    }
    
    if (input$metric_choice == "Weight"){
      p = df %>%
        filter(exercise == input$ex_choice) %>%
        ggplot(aes(date, weight, color = hand, size=time)) +
        geom_point(alpha=0.6) +
        scale_color_manual(values=colours) +
        scale_size("time", range = c(1,5))
    }
    p
  })
  
  # Show exercise and time until the hang
  output$next_ex <- renderText({
    hand_or_hands <- if (rv$ex_df$hand[counter()] == "Both") "hands" else "hand"
    text = sprintf("%s (%s %s)", rv$ex_df$exercise[counter()], rv$ex_df$hand[counter()], hand_or_hands)})
  output$time_to_ex <- renderText({paste(seconds_to_period(timer()))}) #####
  
  # Show proportion of exercises completed
  output$completed <- renderText(sprintf("Completed %s/%s", counter()-1, length(exercises)-1))
  
  #### Timer (observer that invalidates every second) ####
  observe({
    invalidateLater(1000, session)
    isolate({
      if(active()){
        timer(timer()-1) # Countdown
        
        # Add 5 beep coundown to hang
        if (timer()<=5 & timer()>0){
          beep(sound = 10)   # 5 beeps to countdown to hang.
        }        
        # When timer is zero
        if (timer()==0){
          beep(sound = 1)
          counter(counter()+1)
          timer(rv$ex_df$timings[counter()])
          
          # Check if workout finished
          if (counter()==length(exercises)){
            beep(sound = 4)
            Sys.sleep(1)
            beep(sound = 3)
            active(FALSE)
            showModal(modalDialog(
              title = "Workout Completed!",
              "Workout completed!"))
          }
        } 
        else if (counter() > 1 & timer() > (rv$ex_df$timings[counter()]-11)){ 
          beep(sound = 2)  # Beeps to count hangtime
        }
        
      }
    })

    
        }
  )
  
}

shinyApp(ui, server)

