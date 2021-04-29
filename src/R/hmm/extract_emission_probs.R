#! /usr/bin/Rscript

library(mHMMbayes)

args <- commandArgs(trailingOnly = TRUE)
model_fname<-args[1]
out_fname<-args[2]

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
source(paste0(pathName, "/obtain_emiss_pois.R"))

load(model_fname)
emissions<-obtain_emiss_pois(out, level="group")

State<-c()
Electrode<-c()
Alpha<-c()
Beta<-c()
for(j in 1:nrow(emissions[1]$el1)) {
  for(i in 1:length(emissions)) {
    State<-c(State, j)
    Electrode<-c(Electrode, i)
    Alpha<-c(Alpha, emissions[i][[paste0('el',i)]][j,1])
    Beta<-c(Beta, emissions[i][[paste0('el',i)]][j,2])
  }
}
df=data.frame(State, Electrode, Alpha, Beta)
write.csv(df, out_fname, row.names = FALSE)
