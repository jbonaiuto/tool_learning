#! /usr/bin/Rscript
args = commandArgs(trailingOnly=TRUE)
output_path=args[1]
model_fname=args[2]

# Install packages
#devtools::install_github("smildiner/mHMMbayes", ref = "develop")

# Set up working environment
library(tidyverse)
library(mHMMbayes)


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
source(paste0(pathName, "/get_pred_prob_long.R"))

load(paste0(output_path,'/',model_fname))

# Load data sets
data <- read_csv(paste0(output_path, '/hmm_data.csv'))

# Reshape to tidy wide format
data_wide <- data %>%
  spread(key = electrode, value = value)# %>%
#  filter(trial != 320) # last trial has missing values

# Get training data (don't need date, condition, timestep?)
train <- as.matrix(subset(data_wide,select=-c(date,condition,timestep)))
  
n_electrodes<-ncol(train)-1

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

out_r_long <- get_pred_prob_long(x = out, xx = xx, type = "gamma", cov_name = "right", cov_val = c(0,1))
out_l_long <- get_pred_prob_long(x = out, xx = xx, type = "gamma", cov_name = "left", cov_val = c(0,1))

out_r_long <- out_r_long %>%
    as.data.frame() %>%
    gather(key = to, value = value, -state, -cov_val) %>%
    mutate(state = paste0("S",state,to),
           cov_val = factor(cov_val,levels = c(0,1), labels = c("center","right"))) %>%
    dplyr::select(-to) %>%
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
    dplyr::select(-to) %>%
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

dev.new()
g<-ggplot(out_cov, aes(x = covariate, y = map_median, fill = covariate)) +
  geom_col() +
  geom_errorbar(aes(ymin = CCI_lwr, ymax = CCI_upr)) +
  facet_wrap(state~., ncol = out$input$m) +
  theme_minimal()
print(g)
ggsave(paste0(output_path,'/model_tv_plnorm_',out$input$m,'states_',1,'_trans_covar.eps'))

cov_df<-out$gamma_cov_bar %>%
    as.data.frame() %>%
    slice(2001:4000) %>% # change for the number of iterations after burn-in (i.e., 2001:4000)
    gather(key = variable, value = value) %>%
    group_by(variable) %>%
    summarise_all(funs(median_val = median(.), 
                       CCI_lwr = quantile(., probs = c(0.025)),
                       CCI_upr = quantile(., probs = c(0.975)))) %>%
    mutate(sig = case_when(CCI_upr < 0 | CCI_lwr > 0 ~ "*",
                           (CCI_upr >=0 & CCI_lwr <= 0) ~ "")) %>%
    as.data.frame()
write.csv(cov_df,paste0(output_path,'/model_tv_plnorm_',out$input$m,'states_',1,'_trans_covar.csv'))