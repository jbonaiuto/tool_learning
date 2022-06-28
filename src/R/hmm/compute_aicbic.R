output_path='/home/bonaiuto/tool_learning/output/HMM/betta/motor_grasp/tv_cov_new/F5hand/'
#output_path='/home/bonaiuto/tool_learning/output/HMM/betta/motor_grasp/tv_cov_new/F1/'

# Install packages
#devtools::install_github("smildiner/mHMMbayes", ref = "develop")

# Set up working environment
library(tidyverse)
library(mHMMbayes)
# Preferred parallel library
#library(future.apply)

# Load utility functions
source("utils.R")

n_possible_states=c(3:8)

n_runs<-5

# Set up cluster
#plan(multiprocess, workers = 3)

states<-c()
run<-c()
aic<-c()
bic<-c()
loadRData <- function(fileName){
#loads an RData file, and returns it
    load(fileName)
    get(ls()[ls() != "fileName"])
}

model_type<-'plnorm'
#model_type<-'pgamma'

# Fit models in parallel
#aics<-future_sapply(n_possible_states, function(m) {
for(m in n_possible_states) {  
  
  for(run_idx in 1:n_runs) {
    
    fname<-paste0(output_path, '/model_tv_',model_type,'_',m,'states_',run_idx,'.rda')
    if(file.exists(fname)) {
        print(paste0(m, ' states - ', run_idx))
        out<-loadRData(fname)
    
        # Get averaged AIC across subjects
        run_aic<-get_aic_pois(out)
        run_bic<-get_bic_pois(out)
        states<-c(states,m)
        run<-c(run,run_idx)
        aic<-c(aic,run_aic)
        bic<-c(bic,run_bic)
     }
  }
}
df<-data.frame(states,run,aic,bic)
write.csv(df,paste0(output_path,'/',model_type,'_aic_bic.csv'))
