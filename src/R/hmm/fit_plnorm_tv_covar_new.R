#! /usr/bin/Rscript
args = commandArgs(trailingOnly=TRUE)
output_path=args[1]

# Install packages
#devtools::install_github("smildiner/mHMMbayes", ref = "develop")

# Set up working environment
library(tidyverse)
library(mHMMbayes)
library(depmixS4)

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
source(paste0(pathName, "/get_pred_prob_long.R"))

# Load data sets
data <- read_csv(paste0(output_path, '/hmm_data.csv'))

# Reshape to tidy wide format
data_wide <- data %>%
  spread(key = electrode, value = value)

# Get training data (don't need date, condition, timestep?)
train <- as.matrix(subset(data_wide,select=-c(date,condition,timestep)))
  
n_electrodes<-ncol(train)-1

# Add informative column names
colnames(train) <- c("trial",paste0("el",1:n_electrodes))

# Set matrix of covariates
gamma_cov <- data_wide %>%
  mutate(left = case_when(condition == 3 ~ 1,
                          condition != 3 ~ 0),
         right = case_when(condition == 2 ~ 1,
                           condition != 2 ~ 0)) %>%
  dplyr::select(trial, left, right) %>%
  distinct(.keep_all = TRUE) %>%
  as.matrix()

head(gamma_cov)

xx      <- rep(list(matrix(1, nrow = nrow(gamma_cov))), n_electrodes+1)
xx[[1]] <- cbind(xx[[1]], gamma_cov[,-1])



# General parameters
n       <- length(unique(train[,1]))    # Number of subjects (trials)
n_iterations<-4000
burn_in<-2000
n_possible_states=c(3:8)
n_runs<-1

states<-c()
run<-c()
aic<-c()

for(m in n_possible_states) {
  cat("\nCurrently fitting model with m =",m,"\n")

  for(run_idx in 1:n_runs) {
  
    # Find best EM fit
    
    # Gen
    # Specify model in depmixS4
    elec_f_list=list()
    family_list=list()
    for(e in 1:n_electrodes) {
        elec_f_list<-append(elec_f_list, as.formula(paste0('el',e,' ~ 1')))
        family_list<-append(family_list, list(poisson()))        
    }
    mod <- depmix(elec_f_list,
              data = as.data.frame(train[,-1]), nstates = m,
              family = family_list)

    # Fit model in depmixS4
    depmixs4_fit <- fit(mod, verbose = 0)

    # Extract model results (we have to take the exponent of lambdas in logscale)
    em_start_val_num <- as.numeric(exp(getpars(depmixs4_fit)[(m+m^2+1):(m+m^2+m*n_electrodes)]))

    summary(depmixs4_fit)

    # Starting values for the group level transition distribution
    gamma_start <- diag(runif(m, 0.7, 0.9), m)
    gamma_start[lower.tri(gamma_start) | upper.tri(gamma_start)] <- (1 - diag(gamma_start)) / (m - 1)

    # Starting values for the group level emission distribution
    em_start_val <- vector("list", n_electrodes)
    for(q in 1:n_electrodes){
        em_start_val[[q]] <- matrix(em_start_val_num[(1+m*(q-1)):(m+m*(q-1))], nrow = m, ncol = 1)
    }
    
    # Specify hyper-prior for the poisson emission distribution (here, non-informative hyper priors are used)
    hyp_pr <- list(
      emiss_mu0 = rep(list(matrix(rep(1,m), nrow = 1, ncol = m)),n_electrodes), # State means hyper priors (expected counts for each state and each electrode)
      emiss_K0  = rep(list(1),n_electrodes), # Theoretical number of subjects in which we base our priors: 1 puts a low weight compared to number of trials (319)
      emiss_nu  = rep(list(1),n_electrodes), # Degrees of freedom of the hyper priors: the larger the number the stronger the prior
      emiss_V   = rep(list(rep(1, m)),n_electrodes), # Variance of the hyper priors: the larger, the less informative
      emiss_a0  = rep(list(rep(0.001, m)),n_electrodes), # Hyper priors on the variance, the smoller the less informative
      emiss_b0  = rep(list(rep(0.001, m)),n_electrodes)) # Hyper priors on the variance, the smaller the less informative    

    # Set seed
    set.seed(42)
    
    # Fit PLN model
    out <- mHMM_plnorm(s_data = train,
                   gen = list(m = m, n_dep = n_electrodes),
                   xx = xx,
                   start_val = c(list(gamma_start), em_start_val),
                   emiss_hyp_prior = hyp_pr,
                   mcmc = list(J = n_iterations, burn_in = burn_in),
                   show_progress = TRUE)
    
    
    
    # Check emission convergence
    emiss_data=data.frame()
    for (elec in 1:n_electrodes) {
      e_data <- out$emiss_mu_bar[[elec]] %>%
        as.data.frame()
      names(e_data) <- paste('S',rep(1:m),sep='')
      e_data <- e_data %>%
        mutate(iter = row_number()) %>%
        gather(key = 'variable', value = 'value', -iter)
      e_data$electrode<-elec
      e_data$parameter<-'mu'
      emiss_data<-rbind(emiss_data,e_data)
      
      e_data <- out$emiss_varmu_bar[[elec]] %>%
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
    plot_mHMM(out, level = "higher", burnIn = 0, q = 1, target = "trans", plotType = "trace")
    ggsave(paste0(output_path,'/model_tv_plnorm_',m,'states_',run_idx,'_trans.png'))
    dev.off()
    
    # Get a glimpse of the fitted model
    #summary(out)
    
    gdecoding <- mHMMbayes::vit_mHMM_pois(out, train)

    forward_probs<-data.frame(subj=c(), t=c(), condition=c())
    for(i in 1:m) {
        forward_probs[[paste0('fw_prob_S',i)]]<-c()
    }
    trials<-unique(data_wide$trial)
    for(t in 1:length(gdecoding$state_probs)) {
        cond<-data_wide$condition[data_wide$trial==trials[t]][1]
        df<-gdecoding$state_probs[[t]] %>%
          as.data.frame() %>%
          mutate(tstep = row_number()) %>%
          gather(state, value, -tstep)
        new_df<-data.frame(subj=rep(trials[t],max(df$tstep)), t=seq(1,max(df$tstep)), condition=rep(cond,max(df$tstep)))
        for(i in 1:m) {
            new_df[[paste0('fw_prob_S',i)]]<-df$value[df$state==paste0('V',i)]
        }
        forward_probs<-rbind(forward_probs,new_df)
    }
    
    head(forward_probs)
    
    save(out, file=paste0(output_path, '/model_tv_plnorm_',m,'states_',run_idx,'.rda'))
    
    write.csv(forward_probs,paste0(output_path, '/forward_probs_tv_plnorm_',m,'states_',run_idx,'.csv'))
    
    # Get averaged AIC across subjects
    aic<-c(aic, get_aic_pois(out))
    states<-c(states,m)
    run<-c(run,run_idx)
    
  }
}

# Write AIC
df<-data.frame(states,run,aic)
write.csv(df,paste0(output_path,'/plnorm_aic_bic.csv'))
