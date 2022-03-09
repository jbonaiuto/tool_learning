#! /usr/bin/Rscript
args = commandArgs(trailingOnly=TRUE)
output_path=args[1]

# Install packages
#devtools::install_github("smildiner/mHMMbayes", ref = "develop")

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

# Reshape to tidy wide format
data_wide <- data %>%
  spread(key = electrode, value = value)

# Get training data (don't need date, condition, timestep?)
train <- data_wide %>%
  select(-c(date, condition, timestep)) %>%
  as.matrix()

n_electrodes<-ncol(train)-1

# Add informative column names
colnames(train) <- c("trial",paste0("el",colnames(train)[1:n_electrodes+1]))

# Set matrix of covariates
gamma_xx_t <- data_wide %>%
  mutate(left = case_when(condition == 3 ~ 1,
                          condition != 3 ~ 0),
         right = case_when(condition == 2 ~ 1,
                           condition != 2 ~ 0)) %>%
  select(trial, left, right) %>%
  as.matrix()

head(gamma_xx_t)


# General parameters
n       <- length(unique(train[,1]))    # Number of subjects (days)
#n_runs<-10
n_runs<-1
n_iterations<-3000
burn_in<-1000
n_dep   <- 15                           # Number of dependent variables
#n_possible_states=c(3:8)
n_possible_states=c(4)

#plan(multiprocess, workers = 10)

#pois_states<-c()
#pois_run<-c()
#pois_aic<-c()
#pois_bic<-c()

pgamma_states<-c()
pgamma_run<-c()
pgamma_aic<-c()
pgamma_bic<-c()

plnorm_states<-c()
plnorm_run<-c()
plnorm_aic<-c()
plnorm_bic<-c()

for(m in n_possible_states) {  
  cat("\nCurrently fitting model with m =",m,"\n")
  
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
    hyp_pr_pgamma <- list(
      emiss_alpha_a0 = rep(list(rep(0.01, m)),n_dep),
      emiss_alpha_b0 = rep(list(rep(0.01, m)),n_dep),
      emiss_beta_a0 = rep(list(rep(0.01, m)),n_dep),
      emiss_beta_b0 = rep(list(rep(0.01, m)),n_dep)
    )
    
    # Set seed
    #set.seed(42)
    
    # Train models
    #out_tv_pois <- mHMM_pois_tv(s_data = train,
    #                            gen = list(m = m, n_dep = n_dep),
    #                            start_val = c(list(start_gamma), start_emiss),
    #                            emiss_hyp_prior = hyp_pr_pgamma,
    #                            xx_t = gamma_xx_t,
    #                            mcmc = list(J = n_iterations, burn_in = burn_in),
    #                            show_progress = TRUE,
    #                            force_ordering = FALSE,
    #                            return_fw_prob = TRUE,
    #                            alpha_scale = 1)
    
    
    ## Check emission convergence
    #emiss_data=data.frame()
    #for (elec in 1:n_dep) {
    #  e_data <- out_tv_pois$emiss_alpha_bar[[elec]] %>%
    #    as.data.frame()
    #  names(e_data) <- paste('S',rep(1:m),sep='')
    #  e_data <- e_data %>%
    #    mutate(iter = row_number()) %>%
    #    gather(key = 'variable', value = 'value', -iter)
    #  e_data$electrode<-elec
    #  e_data$parameter<-'alpha'
    #  emiss_data<-rbind(emiss_data,e_data)
    #  
    #  e_data <- out_tv_pois$emiss_beta_bar[[elec]] %>%
    #    as.data.frame()
    #  names(e_data) <- paste('S',rep(1:m),sep='')
    #  e_data <- e_data %>%
    #    mutate(iter = row_number()) %>%
    #    gather(key = 'variable', value = 'value', -iter)
    #  e_data$electrode<-elec
    #  e_data$parameter<-'beta'
    #  emiss_data<-rbind(emiss_data,e_data)
    #}
    #dev.new()
    #g<-ggplot(emiss_data[emiss_data$parameter=='alpha',])+
    #  geom_line(aes(x=iter,y=value, group=variable, color=variable))+
    #  facet_wrap(electrode ~., nrow = 8)
    #print(g)
    #ggsave(paste0('/home/bonaiuto/Projects/tool_learning/data/hmm/betta/F1/model_tv_pois_',run_idx,'_alpha.png'))
    #dev.off()
    
    
    #dev.new()
    #g<-ggplot(emiss_data[emiss_data$parameter=='beta',])+
    #  geom_line(aes(x=iter,y=value, group=variable, color=variable))+
    #  facet_wrap(electrode ~., nrow = 8)
    #print(g)
    #ggsave(paste0('/home/bonaiuto/Projects/tool_learning/data/hmm/betta/F1/model_tv_pois_',run_idx,'_beta.png'))
    #dev.off()
    
    ## Visualize higher level transition probabilities
    #dev.new()
    #plot_mHMM(out_tv_pois, level = "higher", burnIn = 0, q = 1, target = "trans", plotType = "trace")
    #ggsave(paste0(output_path,'/model_tv_pois_',run_idx,'_trans.png'))
    #dev.off()
    
    ## Get a glimpse of the fitted model
    ##summary(out)
    
    #forward_probs <- get_map_fw(out_tv_pois, burn_in = burn_in, target = "median") %>%
    #  as.data.frame() %>%
    #  group_by(subj) %>%
    #  mutate(t = row_number())
    
    #date1 <- data_wide %>%
    #  select(trial, condition) %>%
    #  rename("subj" = trial) %>%
    #  group_by(subj) %>%
    #  mutate(t = row_number())
    
    #merged_data <- inner_join(x = forward_probs, y = date1, by = c("subj","t"))
    
    #head(merged_data)
    
    #save(out_tv_pois, file=paste0(output_path, '/model_tv_pois_',run_idx,'.rda'))
    
    #write.csv(merged_data,paste0(output_path, '/forward_probs_tv_pois_',run_idx,'.csv'))
    
    # Get averaged AIC across subjects
    #run_aic<-get_aic_pois(out_tv_pois)
    #run_bic<-get_bic_pois(out_tv_pois)
    #pois_states<-c(pois_states,m)
    #pois_run<-c(pois_run,run_idx)
    #pois_aic<-c(pois_aic,run_aic)
    #pois_bic<-c(pois_bic,run_bic)
    
    # Write AIC-BIC every iteration
    #df<-data.frame(pois_states,pois_run,pois_aic,pois_bic)
    #write.csv(df,paste0(output_path,'/pois_aic_bic.csv'))
    
    out_tv_pgamma <- mHMM_pgamma_tv(s_data = train,
                                    gen = list(m = m, n_dep = n_dep),
                                    xx_t = gamma_xx_t,
                                    start_val = c(list(start_gamma), start_emiss),
                                    mcmc = list(J = n_iterations, burn_in = burn_in),
                                    emiss_hyp_prior = hyp_pr_pgamma,
                                    return_path = FALSE, show_progress = TRUE,
                                    gamma_hyp_prior = NULL, 
                                    gamma_sampler = NULL, emiss_sampler = NULL,
                                    return_fw_prob = TRUE)
    
    # Check emission convergence
    emiss_data=data.frame()
    for (elec in 1:n_dep) {
      e_data <- out_tv_pgamma$emiss_alpha_bar[[elec]] %>%
        as.data.frame()
      names(e_data) <- paste('S',rep(1:m),sep='')
      e_data <- e_data %>%
        mutate(iter = row_number()) %>%
        gather(key = 'variable', value = 'value', -iter)
      e_data$electrode<-elec
      e_data$parameter<-'alpha'
      emiss_data<-rbind(emiss_data,e_data)
      
      e_data <- out_tv_pgamma$emiss_beta_bar[[elec]] %>%
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
    ggsave(paste0(output_path,'/model_tv_pgamma_',m,'states_',run_idx,'_alpha.png'))
    dev.off()
    
    
    dev.new()
    g<-ggplot(emiss_data[emiss_data$parameter=='beta',])+
      geom_line(aes(x=iter,y=value, group=variable, color=variable))+
      facet_wrap(electrode ~., nrow = 8)
    print(g)
    ggsave(paste0(output_path,'/model_tv_pgamma_',m,'states_',run_idx,'_beta.png'))
    dev.off()
    
    # Visualize higher level transition probabilities
    dev.new()
    plot_mHMM(out_tv_pgamma, level = "higher", burnIn = 0, q = 1, target = "trans", plotType = "trace")
    ggsave(paste0(output_path,'/model_tv_pgamma_',m,'states_',run_idx,'_trans.png'))
    dev.off()
    
    # Get a glimpse of the fitted model
    #summary(out)
    
    forward_probs <- get_map_fw(out_tv_pgamma, burn_in = burn_in, target = "median") %>%
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
    
    save(out_tv_pgamma, file=paste0(output_path, '/model_tv_pgamma__',m,'states_',run_idx,'.rda'))
    
    write.csv(merged_data,paste0(output_path, '/forward_probs_tv_pgamma_',m,'states_',run_idx,'.csv'))
    
    # Get averaged AIC across subjects
    run_aic<-get_aic_pois(out_tv_pgamma)
    run_bic<-get_bic_pois(out_tv_pgamma)
    pgamma_states<-c(pgamma_states,m)
    pgamma_run<-c(pgamma_run,run_idx)
    pgamma_aic<-c(pgamma_aic,run_aic)
    pgamma_bic<-c(pgamma_bic,run_bic)
    
    # Write AIC-BIC every iteration
    df<-data.frame(pgamma_states,pgamma_run,pgamma_aic,pgamma_bic)
    write.csv(df,paste0(output_path,'/pgamma_aic_bic.csv'))
    
    hyp_pr_plnorm <- list(
      emiss_mu0 = rep(list(matrix(0, nrow = 1, ncol = m)), n_dep), # nrow = no. of (time-static) covariates + 1; ncol = no. of hidden states
      emiss_K0  = rep(list(1),n_dep),
      emiss_nu  = rep(list(1),n_dep),
      emiss_V   = rep(list(rep(5, m)),n_dep),
      emiss_a0  = rep(list(rep(0.001, m)),n_dep),
      emiss_b0  = rep(list(rep(0.001, m)),n_dep))
    
    
    out_tv_plnorm <- mHMM_plnorm_tv(s_data = train,
                                    gen = list(m = m, n_dep = n_dep),
                                    xx_t = gamma_xx_t,
                                    start_val = c(list(start_gamma), start_emiss),
                                    mcmc = list(J = n_iterations, burn_in = burn_in),
                                    return_path = FALSE, show_progress = TRUE,
                                    gamma_hyp_prior = NULL, emiss_hyp_prior = hyp_pr_plnorm,
                                    gamma_sampler = NULL, emiss_sampler = NULL,
                                    return_fw_prob = TRUE)
    
    # Check emission convergence
    emiss_data=data.frame()
    for (elec in 1:n_dep) {
      e_data <- out_tv_plnorm$emiss_mu_bar[[elec]] %>%
        as.data.frame()
      names(e_data) <- paste('S',rep(1:m),sep='')
      e_data <- e_data %>%
        mutate(iter = row_number()) %>%
        gather(key = 'variable', value = 'value', -iter)
      e_data$electrode<-elec
      e_data$parameter<-'mu'
      emiss_data<-rbind(emiss_data,e_data)
      
      e_data <- out_tv_plnorm$emiss_varmu_bar[[elec]] %>%
        as.data.frame()
      names(e_data) <- paste('S',rep(1:m),sep='')
      e_data <- e_data %>%
        mutate(iter = row_number()) %>%
        gather(key = 'variable', value = 'value', -iter)
      e_data$electrode<-elec
      e_data$parameter<-'varmu'
      emiss_data<-rbind(emiss_data,e_data)
    }
    dev.new()
    g<-ggplot(emiss_data[emiss_data$parameter=='mu',])+
      geom_line(aes(x=iter,y=value, group=variable, color=variable))+
      facet_wrap(electrode ~., nrow = 8)
    print(g)
    ggsave(paste0(output_path,'/model_tv_plnorm_',m,'states_',run_idx,'_mu.png'))
    dev.off()
    
    
    dev.new()
    g<-ggplot(emiss_data[emiss_data$parameter=='varmu',])+
      geom_line(aes(x=iter,y=value, group=variable, color=variable))+
      facet_wrap(electrode ~., nrow = 8)
    print(g)
    ggsave(paste0(output_path,'/model_tv_plnorm_',m,'states_',run_idx,'_varmu.png'))
    dev.off()
    
    # Visualize higher level transition probabilities
    dev.new()
    plot_mHMM(out_tv_plnorm, level = "higher", burnIn = 0, q = 1, target = "trans", plotType = "trace")
    ggsave(paste0(output_path,'/model_tv_pgamma_',m,'states_',run_idx,'_trans.png'))
    dev.off()
    
    # Get a glimpse of the fitted model
    #summary(out)
    
    forward_probs <- get_map_fw(out_tv_plnorm, burn_in = burn_in, target = "median") %>%
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
    
    save(out_tv_plnorm, file=paste0(output_path, '/model_tv_plnorm_',m,'states_',run_idx,'.rda'))
    
    write.csv(merged_data,paste0(output_path, '/forward_probs_tv_plnorm_',m,'states_',run_idx,'.csv'))
    
    # Get averaged AIC across subjects
    run_aic<-get_aic_pois(out_tv_plnorm)
    run_bic<-get_bic_pois(out_tv_plnorm)
    plnorm_states<-c(plnorm_states,m)
    plnorm_run<-c(plnorm_run,run_idx)
    plnorm_aic<-c(plnorm_aic,run_aic)
    plnorm_bic<-c(plnorm_bic,run_bic)
    
    # Write AIC-BIC every iteration
    df<-data.frame(plnorm_states,plnorm_run,plnorm_aic,plnorm_bic)
    write.csv(df,paste0(output_path,'/plnorm_aic_bic.csv'))
  }
}