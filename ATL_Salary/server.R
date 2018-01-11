library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)


# Data pre-processing -----------------------------------------------------

raw <- readRDS("atl_2015.RDS") %>% 
    rename(ethnic = ethnic.origin, job = job.title, salary = annual.salary) %>% 
    mutate(sex = factor(sex), ethnic = factor(ethnic)) %>% 
    as_tibble()

# Age group that has a sample size smaller than 10
x_agegrp <- raw %>% group_by(age) %>% summarise(n = n()) %>% filter(n < 10) %>% pull(age) 

# Ethnic group that has a sample size smaller than 30
x_ethgrp <- raw %>% group_by(ethnic) %>% summarise(n = n()) %>% filter(n < 30) %>% droplevels() %>% pull(ethnic) 

# Filter small sample size group for both 'age' and 'ethnic'
dat <- raw %>% filter(!age %in% x_agegrp &!ethnic %in% x_ethgrp)

## Remove 61 rows of data
# nrow(raw) - nrow(dat)


# Server functions -------------------------------------------------------------

# Set ggplot2 theme
old <- theme_set(theme_light() + theme(legend.position = "bottom"))

# Explore various variables' effects on Salary
shinyServer(function(input, output, session) {
    
    # Main Panel - Scatterplot (Age + Sex / Ethnic)
    # Enable user to select points using cursor
    output$main <- renderPlot({
        dat %>% 
            ggplot(aes(age, salary, col = sex)) + 
            geom_point(position = position_jitter(width = 0.3, height = 0.1)) + 
            scale_y_continuous(labels = scales::dollar) + 
            labs(x = "Age", y = "Salary", col = "Sex")
    })
    
    # Sideplot 1 - Lineplot (Age)
    
    
    # Sideplot 2 - Dumbellplot (Sex + Ethnic)
    
    # Sideplot 3 - Pointplot (Department)
  
})
