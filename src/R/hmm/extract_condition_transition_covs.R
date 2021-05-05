#! /usr/bin/Rscript

library(mHMMbayes)
library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)
model_fname<-args[1]
out_fname<-args[2]
output_path=args[3]

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
train <- data_wide %>%
  select(trial, c(`1`,`2`,`3`,`5`,`6`,`7`,`9`,`10`,`13`,`14`,`17`,`18`,`21`,`25`,`26`,`27`,`28`,`29`,`30`,`31`,`32`)) %>%
  as.matrix()

n_electrodes<-ncol(train)-1

# Set matrix of covariates
gamma_cov <- data_wide %>%
  mutate(left = case_when(condition == 3 ~ 1,
                          condition != 3 ~ 0),
         right = case_when(condition == 2 ~ 1,
                           condition != 2 ~ 0)) %>%
  select(trial, left, right) %>%
  distinct(.keep_all = TRUE) %>%
  as.matrix()

xx      <- rep(list(matrix(1, nrow = nrow(gamma_cov))), n_electrodes+1)
xx[[1]] <- cbind(xx[[1]], gamma_cov[,-1])

load(model_fname)


out_r_long <- get_pred_prob_long(x = out, xx = xx, type = "gamma", cov_name = "right", cov_val = c(0,1))
out_l_long <- get_pred_prob_long(x = out, xx = xx, type = "gamma", cov_name = "left", cov_val = c(0,1))

out_r_long <- out_r_long %>%
    as.data.frame() %>%
    gather(key = to, value = value, -state, -cov_val) %>%
    mutate(state = paste0("S",state,to),
           cov_val = factor(cov_val,levels = c(0,1), labels = c("center","right"))) %>%
    select(-to) %>%
    group_by(state, cov_val) %>%
    summarise_all(funs(median, 
                      quantile = list(as_tibble(as.list(quantile(., 
                                                                 probs = c(0.025, 0.975))))))) %>%
    unnest(cols = c(quantile))

out_l_long <- out_l_long %>%
    as.data.frame() %>%
    gather(key = to, value = value, -state, -cov_val) %>%
    mutate(state = paste0("S",state,to),
           cov_val = factor(cov_val,levels = c(0,1), labels = c("center","left"))) %>%
    select(-to) %>%
    group_by(state, cov_val) %>%
    summarise_all(funs(median, 
                       quantile = list(as_tibble(as.list(quantile(., 
                                                                  probs = c(0.025, 0.975))))))) %>%
    unnest(cols = c(quantile)) %>%
    filter(cov_val != "center")

out_cov <- bind_rows(out_r_long,out_l_long) %>%
    rename("map_median" = median,
           "CCI_lwr" = `2.5%`,
           "CCI_upr" = `97.5%`,
           "covariate" = cov_val)

head(out_cov)

#out$gamma_cov_bar %>%
#    as.data.frame() %>%
#    slice(150:200) %>%
#    gather(key = variable, value = value) %>%
#    group_by(variable) %>%
#    summarise_all(funs(median_val = median(.), 
#                       CCI_lwr = quantile(., probs = c(0.025)),
#                       CCI_upr = quantile(., probs = c(0.975)))) %>%
#    mutate(sig = case_when(CCI_upr < 0 | CCI_lwr > 0 ~ "*",
#                           (CCI_upr >=0 & CCI_lwr <= 0) ~ "")) %>%
#    as.data.frame()
    
From<-c()
To<-c()
Cov<-c()
MedVal<-c()
CCI_lwr<-c()
CCI_upr<-c()
for(i in 1:nrow(out_cov)) {  
    From<-c(From, as.integer(substr(out_cov$state[i],2,2)))
    To<-c(To, as.integer(substr(out_cov$state[i],6,6)))
    Cov<-c(Cov, as.character(out_cov$covariate[i]))
    MedVal<-c(MedVal, out_cov$map_median[i])
    CCI_lwr<-c(CCI_lwr, out_cov$CCI_lwr[i])
    CCI_upr<-c(CCI_upr, out_cov$CCI_upr[i])
}
df=data.frame(From, To, Cov, MedVal, CCI_lwr, CCI_upr)
write.csv(df, out_fname, row.names = FALSE)
