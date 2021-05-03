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

# Reshape to tidy wide format
data_wide <- data %>%
  spread(key = electrode, value = value)

# Use data from all days and all electrodes
train <- data_wide %>%
  select(date, trial, c(`1`,`2`,`3`,`5`,`6`,`7`,`9`,`10`,`13`,`14`,`17`,`18`,`21`,`25`,`26`,`27`,`28`,`29`,`30`,`31`,`32`)) %>%
  as.matrix()

n_electrodes<-ncol(train)-2

# Save max value
max_val <- max(train[,3:n_electrodes+2])

# Add informative column names
colnames(train) <- c("date","trial",paste0("el",1:n_electrodes))

n_possible_states=c(3:8)

n_runs<-10

n_iterations<-1000
burn_in<-750

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
    start_gamma <- diag(1, m)
    start_gamma[diag(start_gamma)] <- runif(m,min=0.95,max=0.99)
    start_gamma[lower.tri(start_gamma) | upper.tri(start_gamma)] <- runif((m-1)*m,min=0.0001, max=.05)
    start_gamma=start_gamma/rowSums(start_gamma)
    
    # Conditional distributions (starting values for lambdas)
    start_emiss <- vector("list",length = n_dep)
    for(i in 1:n_dep) {
      start_emiss[[i]]<-matrix(runif(m,min=0,max=max_val),nrow=m,byrow=TRUE)
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
                        mcmc = list(J = n_iterations, burn_in = burn_in),
                        show_progress = TRUE,
                        return_fw_prob = TRUE,
                        alpha_scale = 1,
                        force_ordering = FALSE)
    
    # Check emission convergence
    emiss_data=data.frame()
    for (elec in 1:n_dep) {
      e_data <- out$emiss_alpha_bar[[elec]] %>%
        as.data.frame()
      names(e_data) <- paste('S',rep(1:m),sep='')
      e_data <- e_data %>%
        mutate(iter = row_number()) %>%
        gather(key = 'variable', value = 'value', -iter)
      e_data$electrode<-elec
      e_data$parameter<-'alpha'
      emiss_data<-rbind(emiss_data,e_data)
      
      e_data <- out$emiss_beta_bar[[elec]] %>%
        as.data.frame()
      names(e_data) <- paste('S',rep(1:m),sep='')
      e_data <- e_data %>%
        mutate(iter = row_number()) %>%
        gather(key = 'variable', value = 'value', -iter)
      e_data$electrode<-elec
      e_data$parameter<-'beta'
      emiss_data<-rbind(emiss_data,e_data)
    }
    dev.new()
    g<-ggplot(emiss_data[emiss_data$parameter=='alpha',])+
      geom_line(aes(x=iter,y=value, group=variable, color=variable))+
      facet_wrap(electrode ~., nrow = 8)
    print(g)
    ggsave(paste0(output_path,'/model_',m,'states_',run_idx,'_alpha_group.png'))
    dev.off()
    
    dev.new()
    g<-ggplot(emiss_data[emiss_data$parameter=='beta',])+
      geom_line(aes(x=iter,y=value, group=variable, color=variable))+
      facet_wrap(electrode ~., nrow = 8)
    print(g)
    ggsave(paste0(output_path,'/model_',m,'states_',run_idx,'_beta_group.png'))
    dev.off()
    
    varNames <- paste("dep", rep(1:n_dep, m), "_lambda_S", rep(1:m, each = n_dep), sep = "")
    # Extract subject level data from the list and shpe it as a wide data frame
    data <- do.call(rbind, lapply(seq_along(out$PD_subj), function(e) {
      as.data.frame(out$PD_subj[e]) %>%
        dplyr::select(varNames) %>%
        mutate(iter = row_number(), id = e)
    }))
    # Reshape subj_data into long format
    data <- data %>% gather(key = 'variable', value = 'prob', -iter, -id)
    
    dev.new()
    g<-ggplot(data)+
      geom_line(aes(x=iter,y=prob, group=id))+
      facet_wrap(variable ~., nrow = 8)
    print(g)
    ggsave(paste0(output_path,'/model_',m,'states_',run_idx,'_lambda_day.png'))
    dev.off()
    
    
    # Visualize higher level transition probabilities
    dev.new()
    plot_mHMM(out, level = "higher", burnIn = 0, q = 1, target = "trans", plotType = "trace")
    ggsave(paste0(output_path,'/model_',m,'states_',run_idx,'_trans_group.png'))
    dev.off()
    
    # Visualize lower level transition probabilities
    dev.new()
    plot_mHMM(out, level = "lower", burnIn = 0, q = 1, target = "trans", plotType = "trace")
    ggsave(paste0(output_path,'/model_',m,'states_',run_idx,'_trans_day.png'))
    dev.off()
    
    # Get a glimpse of the fitted model
    #summary(out)
    
    # Get averaged AIC across subjects
    run_aic<-get_aic_pois(out)
    run_bic<-get_bic_pois(out)
    states<-c(states,m)
    run<-c(run,run_idx)
    aic<-c(aic,run_aic)
    bic<-c(bic,run_bic)
    
    forward_probs <- get_map_fw(out, burn_in = burn_in, target = "median")
    
    forward_probs <- forward_probs %>%
      as.data.frame() %>%
      group_by(subj,rm) %>%
      mutate(t = row_number()) %>%
      as.matrix()
    
    head(forward_probs)
    
    save(out, file=paste0(output_path, '/model_',m,'states_',run_idx,'.rda'))
    
    write.csv(forward_probs,paste0(output_path, '/forward_probs_',m,'states_',run_idx,'.csv'))
    
    # Write AIC-BIC every iteration
    df<-data.frame(states,run,aic,bic)
    write.csv(df,paste0(output_path,'/aic_bic.csv'))
  }
}