library(shiny)
library(plotly)

# Define UI for application 
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Atlanta City Employee Salaries 2015"),
  
  # Sidebar with instruction and input params
  sidebarLayout(
    sidebarPanel(
        
    ),
    
    
    mainPanel(
        shiny::plotOutput('main')
    )
  )
))
