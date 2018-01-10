library(dplyr)

# Read data
df <- read.csv("https://query.data.world/s/yywEX8qoMLyYeV4BymnF1sMm3tvsKa", header=TRUE, stringsAsFactors=FALSE)

# Convert to tibble
df <- df %>% rename(ethnic = ethnic.origin, job = job.title, salary = annual.salary) %>% as_tibble()

# Preview 
glimpse(df)

# Filter ethnic group with a sample size of more than 30
eGrp <- df %>% group_by(ethnic) %>% summarise(n = n()) %>% filter(n >= 30) %>% pull(ethnic)

# Filtering and cleaning text (4 major groups: Asian, Black, Hispanic, White)
dat <- df %>% filter(ethnic %in% eGrp) %>% mutate(ethnic = stringr::str_extract(ethnic, "^[A-Z]?[a-z]+"))


### EDA ------------------------------------------------------------------

dat %>% ggplot(aes(age, salary, col = sex)) + geom_point(position = position_jitter(seed = 1234, width = 0.2, height = 0.1))

# Ethnic and Sex Group ----------------------------------------------------------

# How do they fare against each other?
dat %>% group_by(sex, ethnic) %>% summarise(median = median(salary)) %>% 
    ggplot(aes(reorder(ethnic, median), median, fill = sex)) +
    geom_bar(stat = "identity", position = "dodge", width = 0.4) +
    coord_flip()


# Age ---------------------------------------------------------------------

# How does age correlate to salary?
with(dat, cor(salary, age))

# 'Age' sample count distribution
dat %>% ggplot(aes(age)) + geom_bar() + geom_hline(yintercept = 10, lty = 3) + scale_x_discrete(limits = seq(20, 70, 5))

# Data vis
dat %>% group_by(age) %>% 
    summarise(n = n(), median = median(salary), average = mean(salary)) %>% 
    filter(n >= 10) %>% # remove sample count that is too few
    select(-n) %>% # drop 'n', no longer needed
    tidyr::gather(measure, salary, -age) %>% # convert to long format
    ggplot(aes(age, salary, col = measure)) + 
    geom_line()


# Organization ------------------------------------------------------

# Explore Female-to-Male ratio, and median salary
fmRatio <- dat %>% group_by(organization) %>% 
    summarise(n = n(), n_F = sum(sex == "Female"), n_M = sum(sex == "Male"), fmR = formatC(n_F/n_M, format = 'f'), median = median(salary)) %>% 
    filter(n >= 30) # discard small sample size group

# Data vis
fmRatio %>% mutate(fmR = as.numeric(fmR), dep = str_extract(organization, "^[A-Z]{3}")) %>% 
    ggplot(aes(median, fmR)) + 
    geom_point(size = 3) +
    geom_text(aes(label = dep), nudge_y = 0.05)
