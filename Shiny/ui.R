library(shiny)
library(shinythemes)
library(plotly)

# Define UI for application 
shinyUI(fluidPage(
    # Awesome Shiny theme 
    theme = shinytheme("paper"),
    # Custom CSS
    tags$head(
        tags$style(HTML(
            ".well .shiny-input-container{
                width: 90%;
                margin-left: auto;
                margin-right: auto;
            }"
        ))
    ),
  # Application title
  tags$h4("Atlanta City Employee Salaries 2015"),
  # Sidebar with instruction and input params
  fluidRow(
    column(4,
        wellPanel(
            includeMarkdown("about_pt1.md"),
            # Use NSE here to capture vatiable names. See ?aes_s
            radioButtons("col", label = NULL, choices = list("Gender" = quote(gender), "Ethnic Group" = quote(ethnic))),
            includeMarkdown("about_pt2.md")
            ),
        tags$h6("TABLE I "),
        tags$p("Count at each combination of factor level"),
        verbatimTextOutput("summ"),
        br(),
        span(icon("github"), a("Source Code", href = "https://github.com/tmasjc/ATL_Salary_Data"))
    ),
    column(8,
        # Enable user to select points using cursor
        tags$h6("SELECTOR"),
        tags$p("Click and drag to select points"),
        plotOutput('selector', brush = brushOpts(id = "selector_brush")),
        # Split horizontal space evenly
        tags$h6("PLOT I & II"),
        splitLayout(
            plotlyOutput("age"),
            plotlyOutput("ethnic")
        ),
    hr() # Just a little more space
    )
  )
))
