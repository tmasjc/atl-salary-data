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

dat <- raw %>% 
    # Filter small sample size group for both 'age' and 'ethnic'
    filter(!age %in% x_agegrp &!ethnic %in% x_ethgrp) %>% 
    # and simplify ethnic group to first word only
    mutate(ethnic = factor(stringr::str_extract(ethnic, "^[A-Z]?[a-z]+")))

## Remove 61 rows of data
# nrow(raw) - nrow(dat)


# Server functions -------------------------------------------------------------


# Explore 'sex', "age", or 'ethnic' variables on 'salary'
shinyServer(function(input, output, session) {
    
    # Set ggplot2 theme
    old <- theme_set(theme_light() + theme(legend.position = "none"))
    
    # Main window - scatterplot (Age + Sex / Ethnic)
    output$main <- renderPlot({
        dat %>% 
            ggplot(aes(age, salary, col = sex)) + 
            geom_point(position = position_jitter(width = 0.3, height = 0.1)) + 
            scale_y_continuous(labels = scales::dollar) + 
            labs(x = "Age", y = "Median Salary", col = "Sex") + 
            theme(legend.position = c(0.1, 0.9), legend.text = element_text(size = 12)) # retrieve legend just for this plot
    })
    
    # All or User selected points
    brushPts <- reactive({
        if(is.null(input$main_brush)){
            dat
        }else{
            brushedPoints(dat, input$main_brush)
        }
    })
    
    # Find median salary by age
    grp_by_age <- reactive({
        brushPts() %>% group_by(sex, age) %>% summarise(salary = median(salary))
    })
    
    # Find median salary by ethnic
    grp_by_ethnic <- reactive({
        brushPts() %>% group_by(sex, ethnic) %>% summarise(salary = median(salary))
    })
    
    # So that our plots can share a common y-axis
    scaleY <- reactive({
        # Get range of y-axis value
        rng_y <- range(grp_by_age()$salary, grp_by_ethnic()$salary)
        scale_y_continuous(labels = scales::dollar, limits = rng_y)
    })
        
    # Plot 1 - lineplot (Sex + Age)
    output$age <- renderPlotly({
        p <- grp_by_age() %>%  
            ggplot(aes(age, salary, col = sex, group = sex,
                       # Custom tooltip
                       text = paste("Sex:", sex, "\nAge:", age, "\nSalary:", salary))) + 
            geom_line() + 
            geom_rug(sides = "l") +
            scaleY() + 
            labs(x = "Age", y = "", col = "Sex")
        
        # Convert to interactive plot
        ggplotly(p, tooltip = c("text")) 
    })
    
    # Get ethnic group salary range for geom_linerange
    linerange <- reactive({
        brushPts() %>% group_by(sex, ethnic) %>% summarise(salary = median(salary)) %>% 
            # Convert to long format so that we can do comparison
            tidyr::spread(sex, salary) %>% 
            mutate(ymax = ifelse(Female > Male, Female, Male), ymin = ifelse(Female < Male, Female, Male))
    })
    
    # Plot 2 - dumbbell plot (Sex + Ethnic)
    output$ethnic <- renderPlotly({
        p <- grp_by_ethnic() %>% 
            ggplot(aes(ethnic, salary, col = sex, 
                       text = paste("Sex:", sex, "\nEthnic:", ethnic, "\nSalary:", salary))) + 
            geom_linerange(aes(x = ethnic, ymin = ymin, ymax = ymax), data = linerange(), inherit.aes = FALSE, col = "darkgrey") + 
            # It is important to put geom_point last so that it overlaps the lines
            geom_point(size = 3) + 
            scaleY() +
            labs(x = "Ethnic", y = "", col = "Sex") + 
            # Hide this y-axis, we have one on the left already
            theme(axis.text.y = element_blank())
        
        ggplotly(p, tooltip = c("text"))
    })
    
    
})
