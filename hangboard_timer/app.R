#
# This is a Shiny web application for training climbing using a hangboard

#### Imports ####
library(shiny)
library(lubridate)
library(beepr)
library(tidyverse)

#### Make dataframe of exercises ####
exercise = c("Warm Up", rep(c("Front Lever", "Front Three", "Front Three", "Half Crimp", "Half Crimp", "Pinch Block",
                    "Pinch Block", "Half Crimp", "Half Crimp"), 2), "Face Pulls", "External Rotations", "Finished")

bh = 20 # Time between left and right hangs
hand = c("B", "B", rep(c("R", "L", "L", "R"), 2), "B", rep(c("L", "R", "R", "L"), 2), "B", "B", "B")
hand[hand == "B"] <- "Both"
hand[hand == "L"] <- "Left"
hand[hand == "R"] <- "Right"
                                           
df = tibble("exercise" = exercise, "hand" = hand,
            "timings" = NA, "cum_timings" = NA, "record_time" = NA, "record_weight" = NA,
            "date" = as.character(Sys.Date()))


ui <- fluidPage(
  titlePanel("Hangboard Timer"),
  hr(),
  numericInput('interval','Time between exercise / s:', value=240, min=0, max=99999, step=1),
  actionButton('start','Start'),
  actionButton('stop','Stop'),
  actionButton('reset','Reset'),
  textOutput('next_ex_title'),
  textOutput('next_ex'),
  textOutput('time_to_ex'),
  tags$head(tags$style("#next_ex_title{font-size: 20px;
                       }
                       #next_ex{font-size: 30px;
                                font-style: bold;
                       }
                       #time_to_ex{font-size: 40px;
                                font-style: bold;
                       }
                       "
                       )),

  #textOutput('time_remaining') # time  remaining
  
  selectInput("record_ex", label="Exercise",
              choices = c("Front Lever", "Front Three", "Front Three", "Half Crimp", "Half Crimp", "Pinch Block")),
  
  radioButtons("record_hand", label="Hand",
              choices = c("Left", "Right", "Both"), inline = TRUE),
  
  numericInput('record_time', 'Time / s:', value=0, min=0, max=10, step=0.5),
  
  numericInput('record_weight', 'Weight / kg:', value=0, min=-100, max=100, step=0.5),
  actionButton("submit", "Submit"),

  tableOutput('df'),
  tableOutput('results_df'),
)

server <- function(input, output, session) {
  
  
  # Use interval input to set up timings
  reactive_df = reactive({
    interval=input$interval
    timings = c(10, interval, interval, rep(c(bh, interval-bh), 4),
                            interval, rep(c(bh, interval-bh), 4), interval, 10)
    df$timings <<- timings
    df$cum_timings <<- cumsum(df$timings)
    df
  })
  
  # output$df <- renderTable({reactive_df()})
  
  
  # OG data
  results_df = tibble("exercise" = character(), "hand" = character(),
                      "time" = numeric(), "weight" = numeric(),
                      "date" = as.character(Sys.Date()))
  
  # New data
  reactive_results_df = eventReactive(input$submit,{
    row = data.frame("excercises"=input$record_ex, "hand"=input$record_hand, 
                     "time"=input$record_time, "weight"=input$record_weight)
    results_df <<- rbind(results_df, row)
    results_df
    })
  
  #results_df = rbind(results_df, reactive_results_df())
  output$results_df <- renderTable(reactive_results_df())

  # Initialize reactive values
  counter <- reactiveVal(1)  # Tracks which exercise we are on
  timer <- reactiveVal(10)
  active <- reactiveVal(FALSE)
  
  # Show exercise and time until the hang
  output$next_ex_title <- renderText({"Next exercise:"})
  output$next_ex <- renderText({exercise[counter()]})
  output$time_to_ex <- renderText({paste(seconds_to_period(timer()))}) #####
  
  # observer that invalidates every second. If timer is active, decrease by one.
  observe({
    invalidateLater(500, session)
    
    isolate({
      if(active()){
        
        timer(timer()-1)
        
        # Add 5 beep coundown to hang
        if (timer()<6 & timer()>0){
          beep(sound = 10)   # 5 beeps to countdown to hang.
        }
        
        # When timer is zero
        else if (timer()==0){
          beep(sound = 1)
          counter(counter()+1)
          timer(df$timings[counter()])
          
          if (counter()==length(exercise)){
            beep(sound = 4)
            Sys.sleep(1)
            beep(sound = 3)
            active(FALSE)
            showModal(modalDialog(
              title = "Workout Completed!",
              "Countdown completed!"))
          }
        } else if (counter()>6 & timer() > (df$timings[counter()]-11)){ 
            beep(sound = 2)  # Beeps to count hangtime
          }
        }
      }
    )
  })
  

  # observers for actionbuttons
  
  observeEvent(input$start, {active(TRUE)})
  observeEvent(input$stop, {active(FALSE)})
  observeEvent(input$reset, {timer(10)
    counter(1)})
  observeEvent(input$submit, {output$results_df <- renderTable({reactive_results_df()})})
  
  
}

colnames(results_df)


shinyApp(ui, server)
