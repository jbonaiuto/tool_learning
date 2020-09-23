#! /usr/bin/Rscript

# Install packages
# devtools::install_github("smildiner/mHMMbayes", ref = "develop")

# Set up working environment
library(tidyverse)
library(mHMMbayes)

# Load utility functions
#source("/home/bonaiuto/Projects/tool_learning/src/R/hmm/utils.R")

# Load data sets
data <- read_csv("/home/bonaiuto/Projects/tool_learning/src/matlab/hmm/mHMMBayes/hmm_data.csv")

# Data cleaning and reshaping to tidy long format
#data_long <- gather(data_1ms, key = timestep, value = value, -date, -trial, -electrode) %>%
#  mutate(timestep = as.numeric(timestep)) %>%
#  drop_na()
#filter(timestep < 259) %>%
  
# Save max value
max_val <- max(data$value)

# Reshape to tidy wide format
data_wide <- data %>%
  spread(key = electrode, value = value)

# Use first week
train <- data_wide %>%
  select(date, trial, `1`:`32`) %>%
  as.matrix()

# Add informative column names
colnames(train) <- c("date","trial",paste0("el",1:32))

# General parameters
n       <- length(unique(train[,1]))    # Number of subjects (days)
m       <- 8                            # Number of hidden states
n_dep   <- 32                           # Number of dependent variables

## Starting values
# Transition matrix (diagonal of high probability, and lower probabilities in the rest)
start_gamma <- diag(0.99, m)
start_gamma[lower.tri(start_gamma) | upper.tri(start_gamma)] <- (1 - diag(start_gamma)) / (m - 1)

# Conditional distributions (starting values for lambdas)
start_emiss <- vector("list",length = n_dep)
for(i in 1:n_dep) {
  start_emiss[[i]] <- matrix(runif(m, min=0, max=max_val),nrow=m)#matrix(seq(max_val, 0.001, -(max_val - 0.001)/(m-1)), nrow = m, byrow = TRUE)
}

# Specify hyper-prior for the poisson emission distribution
hyp_pr <- list(
  emiss_alpha_a0 = rep(list(rep(1, m)),n_dep),
  emiss_alpha_b0 = rep(list(rep(1, m)),n_dep),
  emiss_beta_a0 = rep(list(rep(1, m)),n_dep),
  emiss_beta_b0 = rep(list(rep(1, m)),n_dep)
)

# Fit model
out <- mHMM_pois_rm(s_data = train,
                    gen = list(m = m, n_dep = n_dep),
                    start_val = c(list(start_gamma), start_emiss),
                    emiss_hyp_prior = hyp_pr,
                    mcmc = list(J = 200, burn_in = 100),
                    show_progress = TRUE,
                    return_fw_prob = TRUE,
                    alpha_scale = 2)

# Get a glimpse of the fitted model
#summary(out)

# Get averaged AIC across subjects
#get_aic_pois(out)

# Visualize higher level transition probabilities
#plot_mHMM(out, level = "higher", burnIn = 0, q = 1, target = "trans", plotType = "trace")


# Visualize lower level transition probabilities
#plot_mHMM(out, level = "lower", burnIn = 0, q = 1, target = "trans", plotType = "trace")

forward_probs <- get_map_fw(out, burn_in = 100, target = "median")

#head(forward_probs)

forward_probs <- forward_probs %>%
  as.data.frame() %>%
  group_by(subj, rm) %>%
  mutate(t = row_number()) %>%
  as.matrix()

#head(forward_probs)

write.csv(forward_probs,'forward_probs.csv')