#! /usr/bin/Rscript
args = commandArgs(trailingOnly=TRUE)
output_path=args[1]

# Install packages
devtools::install_github("smildiner/mHMMbayes", ref = "develop")

# Set up working environment
library(tidyverse)
library(mHMMbayes)
# Preferred parallel library
#library(future.apply)

args = commandArgs()

scriptName = args[substr(args,1,7) == '--file=']

if (length(scriptName) == 0) {
  scriptName <- rstudioapi::getSourceEditorContext()$path
} else {
  scriptName <- substr(scriptName, 8, nchar(scriptName))
}

pathName = substr(
  scriptName, 
  1, 
  nchar(scriptName) - nchar(strsplit(scriptName, '.*[/|\\]')[[1]][2])
)

# Load utility functions
source(paste0(pathName, "/utils.R"))

# Load data sets
data <- read_csv(paste0(output_path, '/hmm_data.csv'))

# Save max value
max_val <- max(data$value)
max_date <- max(data$date)

# Reshape to tidy wide format
data_wide <- data %>%
  spread(key = electrode, value = value)

n_electrodes<-max(data$electrode)

# Use data from all days and all electrodes
train <- data_wide %>%
  select(date, trial, `1`:`32`) %>%
  as.matrix()


# Add informative column names
colnames(train) <- c("date","trial",paste0("el",1:32))

n_possible_states=c(2:8)
#n_possible_states=c(5)

#n_runs<-10
n_runs<-1

# Set up cluster
#plan(multiprocess, workers = 3)

states<-c()
run<-c()
aic<-c()
bic<-c()

# Fit models in parallel
#aics<-future_sapply(n_possible_states, function(m) {
for(m in n_possible_states) {  
  cat("\nCurrently fitting model with m =",m,"\n")
  
  # General parameters
  n_dep   <- n_electrodes                 # Number of dependent variables
  
  for(run_idx in 1:n_runs) {
    
    ## Starting values
    # Transition matrix (diagonal of high probability, and lower probabilities in the rest)
    start_gamma <- diag(0.9, m)
    start_gamma[lower.tri(start_gamma) | upper.tri(start_gamma)] <- (1 - diag(start_gamma)) / (m - 1)
    
    # Conditional distributions (starting values for lambdas)
    start_emiss <- vector("list",length = n_dep)
    for(i in 1:n_dep) {start_emiss[[i]] <- matrix(seq(max_val, 0.001, -(max_val - 0.001)/(m-1)), nrow = m, byrow = TRUE)}
      
    
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
                        #xx = xx,
                        mcmc = list(J = 250, burn_in = 150),
                        show_progress = TRUE,
                        return_fw_prob = TRUE,
                        alpha_scale = 10,
                        force_ordering = TRUE)
    
    # Get a glimpse of the fitted model
    #summary(out)
    
    # Get averaged AIC across subjects
    run_aic<-get_aic_pois(out)
    run_bic<-get_bic_pois(out)
    states<-c(states,m)
    run<-c(run,run_idx)
    aic<-c(aic,run_aic)
    bic<-c(bic,run_bic)
    
    # Visualize higher level transition probabilities
    #plot_mHMM(out, level = "higher", burnIn = 0, q = 1, target = "trans", plotType = "trace")
    
    
    # Visualize lower level transition probabilities
    #plot_mHMM(out, level = "lower", burnIn = 0, q = 1, target = "trans", plotType = "trace")
    
    forward_probs <- get_map_fw(out, burn_in = 150, target = "median")
    
    forward_probs <- forward_probs %>%
      as.data.frame() %>%
      group_by(subj,rm) %>%
      mutate(t = row_number()) %>%
      as.matrix()
    
    head(forward_probs)
    
    save(out, file=paste0(output_path, '/model_',m,'states_',run_idx,'.rda'))
    
    write.csv(forward_probs,paste0(output_path, '/forward_probs_',m,'states_',run_idx,'.csv'))
  }
  
  #return(aic)
}

#, future.seed = 42L)
# Close cluster
#plan(sequential)
#states<-c()
#run<-c()
#aic<-c()
#for(state_idx in 1:length(aics)){
#  state_aic<-aics[state_idx]
#  for(run_idx in 1:length(state_aic)) {
#    states<-c(states,n_possible_states[state_idx])
#    run<-c(run,run_idx)
#    aic<-c(aic,state_aic[run_idx])
#  }
#}
df<-data.frame(states,run,aic,bic)
write.csv(df,paste0(output_path,'/aic_bic.csv'))