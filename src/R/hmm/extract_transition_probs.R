#! /usr/bin/Rscript

library(mHMMbayes)

args <- commandArgs(trailingOnly = TRUE)
model_fname<-args[1]
out_fname<-args[2]

load(model_fname)
transitions<-obtain_gamma_pois(out, level="group")

From<-c()
To<-c()
Prob<-c()
for(i in 1:nrow(transitions)) {
  for(j in 1:ncol(transitions)) {
    From<-c(From, i)
    To<-c(To, j)
    Prob<-c(Prob, transitions[i,j])
  }
}
df=data.frame(From, To, Prob)
write.csv(df, out_fname, row.names = FALSE)
