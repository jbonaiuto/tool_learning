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

# Get training data (don't need date, condition, timestep?)
train <- data_wide %>%
  select(trial, c(`1`,`2`,`3`,`5`,`6`,`7`,`9`,`10`,`13`,`14`,`17`,`18`,`21`,`25`,`26`,`27`,`28`,`29`,`30`,`31`,`32`)) %>%
  as.matrix()

n_electrodes<-ncol(train)-1

# Save max value
max_val <- max(train[,2:n_electrodes+1])

# Add informative column names
colnames(train) <- c("trial",paste0("el",1:n_electrodes))

#n_possible_states=c(3:8)
n_possible_states=c(5:8)

n_runs<-10

n_iterations<-1000
burn_in<-750

# Set up cluster
#plan(multiprocess, workers = 3)

states<-c()
run<-c()
aic<-c()
bic<-c()

# Set matrix of covariates
gamma_cov <- data_wide %>%
  mutate(left = case_when(condition == 3 ~ 1,
                          condition != 3 ~ 0),
         right = case_when(condition == 2 ~ 1,
                           condition != 2 ~ 0)) %>%
  select(trial, left, right) %>%
  distinct(.keep_all = TRUE) %>%
  as.matrix()

head(gamma_cov)


# Fit models in parallel
#aics<-future_sapply(n_possible_states, function(m) {
for(m in n_possible_states) {  
  cat("\nCurrently fitting model with m =",m,"\n")
  
  # General parameters
  n_dep   <- n_electrodes                 # Number of dependent variables
  
  xx      <- rep(list(matrix(1, nrow = nrow(gamma_cov))), n_dep+1)
  xx[[1]] <- cbind(xx[[1]], gamma_cov[,-1])
  
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
    out <- mHMM_pois(s_data = train,
                     gen = list(m = m, n_dep = n_dep),
                     start_val = c(list(start_gamma), start_emiss),
                     emiss_hyp_prior = hyp_pr,
                     xx = xx,
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
    ggsave(paste0(output_path,'/model_',m,'states_',run_idx,'_alpha.png'))
    dev.off()
    
    
    dev.new()
    g<-ggplot(emiss_data[emiss_data$parameter=='beta',])+
      geom_line(aes(x=iter,y=value, group=variable, color=variable))+
      facet_wrap(electrode ~., nrow = 8)
    print(g)
    ggsave(paste0(output_path,'/model_',m,'states_',run_idx,'_beta.png'))
    dev.off()
    
    # Visualize higher level transition probabilities
    dev.new()
    plot_mHMM(out, level = "higher", burnIn = 0, q = 1, target = "trans", plotType = "trace")
    ggsave(paste0(output_path,'/model_',m,'states_',run_idx,'_trans.png'))
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
      group_by(subj) %>%
      mutate(t = row_number())
    
    
    date1 <- data_wide %>%
      select(trial, condition) %>%
      rename("subj" = trial) %>%
      group_by(subj) %>%
      mutate(t = row_number())
    
    merged_data <- inner_join(x = forward_probs, y = date1, by = c("subj","t"))
    
    head(merged_data)
    
    save(out, file=paste0(output_path, '/model_',m,'states_',run_idx,'.rda'))
    
    write.csv(merged_data,paste0(output_path, '/forward_probs_',m,'states_',run_idx,'.csv'))
    
    # Write AIC-BIC every iteration
    df<-data.frame(states,run,aic,bic)
    write.csv(df,paste0(output_path,'/aic_bic.csv'))
  }
}

