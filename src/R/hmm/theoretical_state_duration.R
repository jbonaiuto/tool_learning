#! /usr/bin/Rscript
args = commandArgs(trailingOnly=TRUE)
output_path=args[1]
model_fname=args[2]

# Load libraries
library(tidyverse)
library(mHMMbayes)

# Define require functions:

# computes probabilities from intercepts
int_to_prob <- function(int1) {
    if(is.matrix(int1)){
        prob1 <- matrix(nrow = nrow(int1), ncol = ncol(int1) + 1)
        for(r in 1:nrow(int1)){
            exp_int1 	<- matrix(exp(c(0, int1[r,])), nrow  = 1)
            prob1[r,] <- exp_int1 / as.vector(exp_int1 %*% c(rep(1, (dim(exp_int1)[2]))))
        }
    } else {
        exp_int1 	<- matrix(exp(c(0, int1)), nrow  = 1)
        prob1 		<- exp_int1 / as.vector(exp_int1 %*% c(rep(1, (dim(exp_int1)[2]))))
    }
    return(round(prob1,4))
}

# computes intercepts from probabilities, per row of input matrix (first catagory is reference catagory)
prob_to_int <- function(prob1){
    prob1 <- prob1 + 0.00001
    b0 <- matrix(NA, nrow(prob1), ncol(prob1)-1)
    sum_exp <- numeric(nrow(prob1))
    for(r in 1:nrow(prob1)){
        sum_exp[r] <- (1/prob1[r,1]) - 1
        for(cr in 2:ncol(prob1)){
            #for every b0 except the first collumn (e.g. b012 <- log(y12/y11-y12))
            b0[r,(cr-1)] <- log(prob1[r,cr]*(1+sum_exp[r]))
        }
    }
    return(round(b0,4))
}


# Load data
load(paste0(output_path,'/',model_fname))


# Define parameters
m <- out$input$m
iter <- out$input$J
burnin <- out$input$burn_in

# Calculate expected durations for each state given model parameters: we use
#   formula of geometric distribution:

#   duration = 1/(1-SelfTransitionProbability)

# dummies = c(0,0): center?
c_df<-apply(out$gamma_int_bar,
      1,
      function(r) matrix(t(int_to_prob(matrix(r, nrow = m, byrow = TRUE))), nrow = 1)) %>%
    t() %>%
    as.data.frame() %>%
    purrr::set_names(paste0("S",rep(1:m,each = m),"toS",1:m)) %>%
    mutate(iter = row_number()) %>%
    gather(parameter, value, -iter) %>%
    mutate(value = 1/(1-value)) %>%
    filter(iter > burnin,
           parameter %in% paste0("S",1:m,"toS",1:m)) %>%
    group_by(parameter) %>%
    summarise(median_duration = median(value), CCI_lwr = quantile(value, 0.025), CCI_upr = quantile(value, 0.975))
print(c_df)

# dummies = c(1,0): right?
r_df<-apply(out$gamma_int_bar +
          out$gamma_cov_bar[,stringr::str_detect(colnames(out$gamma_cov_bar), pattern = "cov1")] * 1 +
          out$gamma_cov_bar[,stringr::str_detect(colnames(out$gamma_cov_bar), pattern = "cov2")] * 0,
      1,
      function(r) matrix(t(int_to_prob(matrix(r, nrow = m, byrow = TRUE))), nrow = 1)) %>%
    t() %>%
    as.data.frame() %>%
    purrr::set_names(paste0("S",rep(1:m,each = m),"toS",1:m)) %>%
    mutate(iter = row_number()) %>%
    gather(parameter, value, -iter) %>%
    mutate(value = 1/(1-value)) %>%
    filter(iter > burnin,
           parameter %in% paste0("S",1:m,"toS",1:m)) %>%
    group_by(parameter) %>%
    summarise(median_duration = median(value), CCI_lwr = quantile(value, 0.025), CCI_upr = quantile(value, 0.975))
print(r_df)

# dummies = c(0,1): left?
l_df<-apply(out$gamma_int_bar +
          out$gamma_cov_bar[,stringr::str_detect(colnames(out$gamma_cov_bar), pattern = "cov1")] * 0 +
          out$gamma_cov_bar[,stringr::str_detect(colnames(out$gamma_cov_bar), pattern = "cov2")] * 1,
      1,
      function(r) matrix(t(int_to_prob(matrix(r, nrow = m, byrow = TRUE))), nrow = 1)) %>%
    t() %>%
    as.data.frame() %>%
    purrr::set_names(paste0("S",rep(1:m,each = m),"toS",1:m)) %>%
    mutate(iter = row_number()) %>%
    gather(parameter, value, -iter) %>%
    mutate(value = 1/(1-value)) %>%
    filter(iter > burnin,
           parameter %in% paste0("S",1:m,"toS",1:m)) %>%
    group_by(parameter) %>%
    summarise(median_duration = median(value), CCI_lwr = quantile(value, 0.025), CCI_upr = quantile(value, 0.975))
print(r_df)
