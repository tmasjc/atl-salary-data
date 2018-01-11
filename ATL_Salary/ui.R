library(shiny)
library(shinythemes)
library(plotly)

# Define UI for application 
shinyUI(fluidPage(
    theme = shinytheme("paper"),
  # Application title
  tags$h4("Atlanta City Employee Salaries 2015"),
  # Sidebar with instruction and input params
  fluidRow(
    column(4,
        wellPanel(includeMarkdown("about.md")),
        verbatimTextOutput("brushInfo")
    ),
    column(8,
        # Enable user to select points using cursor
        tags$p("SELECTOR \t (Click and drag to select points)"),
        plotOutput('main', brush = brushOpts(id = "main_brush"), height = 400),
        # Split horizontal space evenly
        tags$p("PLOT I & II"),
        splitLayout(
            plotlyOutput("age"),
            plotlyOutput("ethnic")
        ),
    hr() # Just a little more space
    )
  )
))
