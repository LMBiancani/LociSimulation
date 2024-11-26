# A script to plot species trees for all simulated and empirical datasets
#

#Read in the species trees for each dataset as a multiphylo object
library(ape)
library(ggtree)
library(phangorn)
library(tidyverse)
library(gridExtra)
library(ggplot2)
library(grid)
library(phytools)
library(cowplot)
library(plyr)
library(dplyr)


ds_path_vector <- c(list.files(path="../simulations/empirical", pattern="", full.names=T, recursive=FALSE),
                    paste0("../simulations/random/ds_", 1:16))
ds_name_vector <- c(list.files(path="../simulations/empirical", pattern="", full.names=F, recursive=FALSE),
                    paste0("ds_", 1:16))

#Read the properties of all loci of all datasets. These include both
#true values of simulated properties (not used in the machine learning model)
#and assessed values (used in the ML)

#create data frame to populate
combo_simul_eval_df <- data.frame()
#iterate over datasets
for (f in 1:length(ds_name_vector)){
  #read main simulated properties
  simul_df <- read.csv(paste0(ds_path_vector[f],"/1/df.csv"), header = T)[,2:21]
  simul_df$loci <- paste0(simul_df$loci, ".fas")

  #read simulated substitution model properties
  model_df <- read.csv(paste0(ds_path_vector[f],"/1/df2.csv"), header = T)[,2:8]
  model_df$loci <- paste0(model_df$loci, ".fas")

  #merge and compute additional variables from existing
  simul_df <- merge(simul_df, model_df, by="loci")
  nmissing_taxa <- sapply(simul_df$taxa_missing, function(x) length(eval(parse(text=x))))
  nremaining_taxa <- sapply(simul_df$remaining_taxa, function(x) length(eval(parse(text=x))))
  simul_df$prop_missing_taxa <- nmissing_taxa/(nmissing_taxa+nremaining_taxa)
  simul_df$prop_paralogy <- sapply(simul_df$paralog_cont, function(x) eval(parse(text=x)))/(nmissing_taxa+nremaining_taxa)
  simul_df$prop_contamination <- sapply(simul_df$cont_pair_cont, function(x) eval(parse(text=x)))/(nmissing_taxa+nremaining_taxa)
  head(simul_df)
  #read assessed properties table for the training subsets
  ML_train_df <- read.table(paste0(ds_path_vector[f],"/1/ML_train.txt"), header = T)
  ML_train_df$MLset <- "train"
  
  #read assessed properties table for the testing subsets and merge with the previous
  ML_test_df <- read.table(paste0(ds_path_vector[f],"/1/ML_test.txt"), header = T)
  ML_test_df$MLset <- "test"
  ML_df <- rbind(ML_train_df, ML_test_df)
  #print("ML_df")
  #head(ML_df)
  #if assessed, read the gene tree distance btw aligned and unaligned input loci
  #this looks at how alignment error manisfested itself in gene trees
  #genetreedf <- read.csv(paste0(ds_path_vector[f],"/1/gtreedist.csv"), header = T)
  #colnames(genetreedf)[2:3] <- c("gtrRFsim", "gtrwRFsim")

  #merge all
  combo_df <- merge(simul_df, ML_df, by.x="loci", by.y="locname")
 #combo_df <- merge(combo_df, genetreedf, by.x="loci", by.y="locname")
  combo_df[,1] <- paste0(ds_name_vector[f], "_", combo_df[,1])
  combo_df$dataset <- ds_name_vector[f]
  combo_simul_eval_df <- rbind(combo_simul_eval_df,combo_df)
}
print("combo_simul_eval_df")
head(combo_simul_eval_df)



#read RF data
predictedRF_df <- read.csv("../4_model_training/RF_model/ML_predicted.csv", header = T)
print("predictedRF_df")
head(predictedRF_df)


combo_simul_eval_df_predRF <- merge(combo_simul_eval_df, predictedRF_df, by.x = "loci", by.y = "locname")
combo_simul_eval_df_predRF$MLset <- factor(combo_simul_eval_df_predRF$MLset,
                                           levels = c("train", "test"))

head(combo_simul_eval_df_predRF)
#print(combo_simul_eval_df_predRF$robinson)
print(combo_simul_eval_df_predRF$predicted_utility)
#apply the regression function and rename columns using dplyr
regressions_RF_data <- combo_simul_eval_df_predRF %>%
  group_by(MLset) %>%
  summarise(
    slope = round(coef(lm(predicted_utility ~ robinson))[2], 3),
    intercept = round(coef(lm(predicted_utility ~ robinson))[1], 3),
    R2 = round(summary(lm(predicted_utility ~ robinson))$r.squared, 3),
    R2.Adj = round(summary(lm(predicted_utility ~ robinson))$adj.r.squared, 3)
  ) %>%
  ungroup()  # Removes the grouping to return a regular data frame

print(regressions_RF_data)

#plot RF data

p3_2 <- ggplot(combo_simul_eval_df_predRF,
               aes(x=robinson, y=RFsimilarity)) +
          geom_point() +
          geom_smooth(method = "lm") + 
          geom_label(data=regressions_RF_data, inherit.aes=FALSE, parse = T,
                     aes(x = 0.25, y = 0.7,
                         label=paste("R^2:",R2)
                     )) +
          theme_bw() +
          facet_wrap(.~MLset) +
          ylab("predicted RF similarity") +
          xlab("True RF similarity")

#read wRF data
predictedwRF_df <- read.csv("../4_model_training/wRF_model/ML_predicted.csv", header = T)
combo_simul_eval_df_predwRF <- merge(combo_simul_eval_df, predictedwRF_df, by.x = "loci", by.y = "locname")
combo_simul_eval_df_predwRF$MLset <- factor(combo_simul_eval_df_predwRF$MLset,
                                            levels = c("train", "test"))
#print(combo_simul_eval_df_predwRF)
regressionwRF=function(df){
  #setting the regression function. 
  reg_fun<-lm(formula=df$RFsimilarity~df$wrobinson) #regression function
  #getting the slope, intercept, R square and adjusted R squared of 
  #the regression function (with 3 decimals).
  slope<-round(coef(reg_fun)[2],3)  
  intercept<-round(coef(reg_fun)[1],3) 
  R2<-round(as.numeric(summary(reg_fun)[8]),3)
  R2.Adj<-round(as.numeric(summary(reg_fun)[9]),3)
  c(slope,intercept,R2,R2.Adj)
}

#plot wRF data
regressions_wRF_data<-ddply(combo_simul_eval_df_predwRF,"MLset",regressionwRF)
colnames(regressions_wRF_data)<-c ("MLset","slope","intercept","R2","R2.Adj")
print(regressions_wRF_data)
p3_4 <- ggplot(combo_simul_eval_df_predwRF,
               aes(x=wrobinson, y=RFsimilarity)) +
  geom_point() +
  geom_smooth(method = "lm") + 
  geom_label(data=regressions_wRF_data, inherit.aes=FALSE, parse = T,
             aes(x = 0.25, y = 0.7,
                 label=paste("R^2:",R2)
             )) +
  theme_bw() +
  facet_wrap(.~MLset) +
  ylab("predicted wRF similarity") +
  xlab("True wRF similarity")
p3_4

#plot final image
grid.arrange(p3_1, p3_2, p3_3, p3_4,
             ncol=2, nrow =2)
#400x800
