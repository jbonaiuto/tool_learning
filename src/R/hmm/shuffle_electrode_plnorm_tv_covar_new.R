#! /usr/bin/Rscript
args = commandArgs(trailingOnly=TRUE)
output_path=args[1]
m=args[2]
run_idx=args[3]

model_fname<-paste0('model_tv_plnorm_',m,'states_',run_idx,'.rda')

# Install packages
#devtools::install_github("smildiner/mHMMbayes", ref = "develop")

# Set up working environment
library(tidyverse)
library(mHMMbayes)

load(paste0(output_path,'/',model_fname))

# Load data sets
data <- read_csv(paste0(output_path, '/hmm_data.csv'))

# Reshape to tidy wide format
data_wide <- data %>%
  spread(key = electrode, value = value)
trials<-unique(data_wide$trial)

# Get training data (don't need date, condition, timestep?)
train <- as.matrix(subset(data_wide,select=-c(date,condition,timestep)))

n_shuffs<-100

for(s in 1:n_shuffs) {
    shuf_mat<-train
    for(trial in trials) {
	shuf_mat[train[,1]==trial,]<-train[train[,1]==trial,c(1,1+sample(ncol(train)-1))]
    }
    gdecoding <- mHMMbayes::vit_mHMM_pois(out, shuf_mat)

    forward_probs<-data.frame(subj=c(), t=c(), condition=c())
    for(i in 1:m) {
        forward_probs[[paste0('fw_prob_S',i)]]<-c()
    }
    
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
    write.csv(forward_probs,paste0(output_path, '/forward_probs_tv_plnorm_',m,'states_',run_idx,'_elec_shuf_',s,'.csv'))
}