library(shiny)
library(tidyverse)
library(plotly)


# Data pre-processing -----------------------------------------------------

# Read data from file
raw <- readRDS("Data/atl_2015.RDS") %>% 
    rename(ethnic = ethnic.origin, 
           job = job.title, 
           salary = annual.salary) %>% 
    mutate(gender = factor(sex), 
           ethnic = factor(ethnic)) %>% 
    as_tibble()

# A count helper
which_less_than <- function(vec, n) {
    x <- table(vec) < n
    sort(unique(vec))[x]
} 

# Id age group that has a sample size smaller than 10
sub_age <- with(raw, age %>% which_less_than(10))
# Id ethnic group that has a sample size smaller than 30
sub_ethnic <- with(raw, ethnic %>% which_less_than(30))

# Filter small sample size group for both 'age' and 'ethnic'
dat <- raw %>% 
    filter(!(age %in% sub_age), !(ethnic %in% sub_ethnic)) %>% 
    # and simplify ethnic group to first word only
    mutate(ethnic = factor(stringr::str_extract(ethnic, "^[A-Z]?[a-z]+")))


# Server functions -------------------------------------------------------------

# Explore 'gender', "age", or 'ethnic' variables on 'salary'
shinyServer(function(input, output, session) {
    
    # Set ggplot2 theme 
    old <- theme_set(theme_light() + theme(plot.title = element_text(size = 11), legend.position = "none"))
    
    # Selector window (Age + Gender / Ethnic)
    output$selector <- renderPlot({
        dat %>% 
            ggplot(aes(age, salary)) +
            # enable toggle of input button
            aes_string(col = input$col) +
            geom_point(position = position_jitter(width = 0.3, height = 0.1)) + 
            scale_y_continuous(labels = scales::dollar, 
                               # a little buffer to make it looks nicer
                               limits = c(min(dat$salary), max(dat$salary) + 5e4)) + 
            labs(x = "Age", 
                 y = "Salary (USD)", 
                 col = toupper(as.character(input$col))) + 
            # retrieve legend for this plot only
            theme(
                legend.position = c(0.1, 0.8), 
                legend.title = element_text(size = 16, family = "mono"), 
                legend.text = element_text(size = 15, family = "mono"), 
                # legend.key = element_rect(colour = 'gray', linetype = 'dashed'),
                legend.key.width = unit(1, "cm")
            )
    })
    
    # User selected points
    brushPts <- reactive({
        # when none selected, return all rows
        if(is.null(input$selector_brush)) {
            return(dat)
        }
        # using Shiny default brush selector
        subs <- brushedPoints(dat, input$selector_brush)
        # defensive: make sure user selects some mininum points
        if(nrow(subs) > 10) {
            subs
        } else{
            dat
        }
    })
    
    # Find median salary by age
    # to pass to plot 1
    grp_by_age <- reactive({
        brushPts() %>% 
            group_by(gender, age) %>% 
            summarise(salary = median(salary)) %>% 
            ungroup()
    })
    
    # Find median salary by ethnic
    # to pass to plot 2
    grp_by_ethnic <- reactive({
        brushPts() %>% 
            group_by(gender, ethnic) %>% 
            summarise(salary = median(salary)) %>% 
            ungroup()
    })
    
    # So that our plots can share a common y-axis
    axisy <- reactive({
        # get range of y-axis value
        range_y <- range(grp_by_age()$salary, grp_by_ethnic()$salary)
        scale_y_continuous(labels = scales::dollar, limits = range_y)
    })
        
    # Plot 1 - lineplot (Gender + Age)
    output$age <- renderPlotly({
        p <- grp_by_age() %>%
            ggplot(aes(
                age,
                salary,
                col = gender,
                group = gender,
                # custom tooltip
                text = paste("Gender:", gender,
                             "\nAge:", age,
                             "\nSalary:", salary)
            )) +
            geom_line() +
            geom_rug(sides = "l") +
            axisy() +
            labs(
                x = "",
                y = "",
                col = "Gender",
                title  = "Plot I: Salary by Age Group"
            )
        
        # convert to interactive
        ggplotly(p, tooltip = c("text"))
    })
    
    # Get ethnic group salary range for geom_linerange
    linerange <- reactive({
        
        ## defence against too few samples
        if(length(unique(grp_by_ethnic()$gender)) < 2){
            return(NULL)
        }
        
        # First we compute the median salary 
        # and determine the range
        brushPts() %>% 
            group_by(gender, ethnic) %>% 
            summarise(salary = median(salary)) %>% 
            # convert to long format so that we can do comparison
            tidyr::spread(gender, salary, fill = 0) %>% 
            # pick maximum and maximum rowwise (female vs male)
            rowwise() %>% 
            mutate(ymax = max(Female, Male),
                   ymin = min(Female, Male))
    })
    
    # Plot 2 - dumbbell plot (Gender + Ethnic)
    output$ethnic <- renderPlotly({
        ## defensive: If only single gender is selected
        if (length(unique(grp_by_ethnic()$gender)) < 2) {
            # return a base object, not plotting anything meaningful
            p <- ggplot(aes(ethnic, salary), data = brushPts())
            return(ggplotly(p))
        }
        
        p <- grp_by_ethnic() %>%
            ggplot(aes(
                ethnic,
                salary,
                col = gender,
                text = paste("Gender:", gender,
                             "\nEthnic:", ethnic,
                             "\nSalary:", salary)
            )) +
            geom_linerange(
                aes(x = ethnic, ymin = ymin, ymax = ymax),
                # a reactive func passed down from above
                data = linerange(),
                inherit.aes = FALSE,
                col = "darkgrey"
            ) +
            # It is important to put geom_point last so that it overlaps the lines
            geom_point(size = 3) +
            axisy() +
            labs(
                x = "",
                y = "",
                col = "Gender",
                title = "Plot II: Salary By Ethnic Group"
            ) +
            # Hide this y-axis, we have one on the left already
            theme(axis.text.y = element_blank())
        
        ggplotly(p, tooltip = c("text"))
    })
    
    # Summary table
    output$summ <- renderPrint({
        # a simple contingency table
        with(brushPts(), table("Gender" = gender, "Ethnic" = ethnic))
    })
    
    ### The End ###
})


