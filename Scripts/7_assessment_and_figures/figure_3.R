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
library(ggplotify)

ds_path_vector <- c(list.files(path="../simulations/empirical", pattern="", full.names=T, recursive=FALSE),
                    paste0("../simulations/random/ds_", 1:16))
ds_name_vector <- c(list.files(path="../simulations/empirical", pattern="", full.names=F, recursive=FALSE),
                    paste0("ds_", 1:16))

#Read the properties of all loci of all datasets. These include both
#true values of simulated properties (not used in the machine learning model)
#and assessed values (used in the ML)
simul_df <- data.frame()
model_df <-data.frame()
#iterate over datasets
for (f in 1:length(ds_name_vector)){
  base_name <- ds_name_vector[f]

  #read main simulated properties
  temp_simul_df <- read.csv(paste0(ds_path_vector[f], "/1/df.csv"), header = TRUE)[, 2:21]
  temp_simul_df$loci <- paste0(base_name, '_', temp_simul_df$loci, ".fas")

  # Read simulated substitution model properties
  temp_model_df <- read.csv(paste0(ds_path_vector[f], "/1/df2.csv"), header = TRUE)[, 2:8]
  temp_model_df$loci <- paste0(base_name, '_', temp_model_df$loci, ".fas")

  # Merge and compute additional variables
  merged_df <- merge(temp_simul_df, temp_model_df, by = "loci")
  nmissing_taxa <- sapply(merged_df$taxa_missing, function(x) length(eval(parse(text = x))))
  nremaining_taxa <- sapply(merged_df$remaining_taxa, function(x) length(eval(parse(text = x))))
  merged_df$prop_missing_taxa <- nmissing_taxa / (nmissing_taxa + nremaining_taxa)
  merged_df$prop_contamination <- sapply(merged_df$cont_pair_cont, function(x) eval(parse(text = x))) / (nmissing_taxa + nremaining_taxa)

  # Append to the main data frames
  simul_df <- rbind(simul_df, merged_df)
  model_df <- rbind(model_df, temp_model_df)


}


#read assessed properties table for the training subsets

RF_train_df <- read.table("../5_locus_utility_prediction/RFtrain_tab.tsv", header = T)
RF_train_df$MLset <- "train"


wRF_train_df <- read.table("../5_locus_utility_prediction/wRFtrain_tab.tsv", header = T)
wRF_train_df$MLset <- "train"

RF_test_df <- read.table("../5_locus_utility_prediction/RFtest_tab.tsv", header = T)
RF_test_df$MLset <- "test"


wRF_test_df <- read.table("../5_locus_utility_prediction/wRFtest_tab.tsv", header = T)
wRF_test_df$MLset <- "test"


#read assessed properties table for the testing subsets and merge with the previous


RF_df <- rbind(RF_train_df, RF_test_df)
write_csv(RF_df, "RF_df.csv")

wRF_df <- rbind(wRF_train_df, wRF_test_df)
write_csv(wRF_df, "wRF_df.csv")


#create data frame to populate
combo_RF_simul_eval_df <- data.frame()
combo_wRF_simul_eval_df <-data.frame()

#merge all
combo_RF_df <- merge(simul_df, RF_df, by.x="loci", by.y="locname")
combo_RF_simul_eval_df <- rbind(combo_RF_simul_eval_df,combo_RF_df)

combo_wRF_df <- merge(simul_df, wRF_df, by.x="loci", by.y="locname")
combo_wRF_simul_eval_df <- rbind(combo_wRF_simul_eval_df,combo_wRF_df)



#read RF data
predictedRF_df<- read.csv("../5_locus_utility_prediction/RF_combined_predicted.tsv", header = T)


combo_simul_eval_df_predRF <- merge(combo_RF_simul_eval_df, predictedRF_df, by.x = "loci", by.y = "locname")
combo_simul_eval_df_predRF$MLset <- factor(combo_simul_eval_df_predRF$MLset,
                                           levels = c("train", "test"))

write_csv(combo_simul_eval_df_predRF, "combo_simul_eval_df_predRF.csv")

#Read wRF data

predictedwRF_df <-read.csv ("../5_locus_utility_prediction/wRF_combined_predicted.tsv", header=T)


combo_simul_eval_df_predwRF <- merge(combo_wRF_simul_eval_df, predictedwRF_df, by.x = "loci", by.y = "locname")
combo_simul_eval_df_predwRF$MLset <- factor(combo_simul_eval_df_predwRF$MLset,
                                           levels = c("train", "test"))



#read RF data for SVM
predictedRF_df_SVM<- read.csv("../5_locus_utility_prediction/SVM_locus_utility_prediction/RF_combined_predicted_svm.tsv", header = T)


combo_simul_eval_df_predRF_SVM <- merge(combo_RF_simul_eval_df, predictedRF_df_SVM, by.x = "loci", by.y = "locname")
combo_simul_eval_df_predRF_SVM$MLset <- factor(combo_simul_eval_df_predRF_SVM$MLset,
                                           levels = c("train", "test"))



#Read wRF data for SVM

predictedwRF_df_SVM <-read.csv ("../5_locus_utility_prediction/SVM_locus_utility_prediction/wRF_combined_predicted_svm.tsv", header=T)


combo_simul_eval_df_predwRF_SVM <- merge(combo_wRF_simul_eval_df, predictedwRF_df_SVM, by.x = "loci", by.y = "locname")
combo_simul_eval_df_predwRF_SVM$MLset <- factor(combo_simul_eval_df_predwRF_SVM$MLset,
                                           levels = c("train", "test"))



#Linear regression for Random Forest RF model
regressions_RF=function(df){
  #setting the regression function. 
  reg_fun<-lm(formula=df$predicted_utility~df$robinson) #regression function
  #getting the slope, intercept, R square and adjusted R squared of 
  #the regression function (with 3 decimals).
  slope<-round(coef(reg_fun)[2],3)
  intercept<-round(coef(reg_fun)[1],3)
  R2<-round(as.numeric(summary(reg_fun)[8]),3)
  R2.Adj<-round(as.numeric(summary(reg_fun)[9]),3)
  c(slope,intercept,R2,R2.Adj)
}

regressions_RF_data<-ddply(combo_simul_eval_df_predRF,"MLset",regressions_RF)
colnames(regressions_RF_data)<-c ("MLset","slope","intercept","R2","R2.Adj")
print("Linear regression for Random Forest RF model:")
print(regressions_RF_data)



#Linear regression for SVM RF model
regressions_RF_SVM=function(df){
  #setting the regression function. 
  reg_fun<-lm(formula=df$predicted_utility~df$robinson) #regression function
  #getting the slope, intercept, R square and adjusted R squared of 
  #the regression function (with 3 decimals).
  slope<-round(coef(reg_fun)[2],3)
  intercept<-round(coef(reg_fun)[1],3)
  R2<-round(as.numeric(summary(reg_fun)[8]),3)
  R2.Adj<-round(as.numeric(summary(reg_fun)[9]),3)
  c(slope,intercept,R2,R2.Adj)
}


regressions_RF_data_SVM<-ddply(combo_simul_eval_df_predRF_SVM,"MLset",regressions_RF_SVM)
colnames(regressions_RF_data_SVM)<-c ("MLset","slope","intercept","R2","R2.Adj")
print("Linear regression for Support Vector Machine RF model:")
print(regressions_RF_data_SVM)




#plot RF data SVM

p3_1 <- ggplot(combo_simul_eval_df_predRF_SVM,
               aes(x=robinson, y=predicted_utility)) +
          geom_point() +
          geom_smooth(method = "lm") +
          geom_label(data=regressions_RF_data_SVM, inherit.aes=FALSE, parse = T,
                     aes(x = 0.25, y = 0.7,
                         label=paste("R^2:",R2)
                     )) +
          theme_bw() +
          facet_wrap(.~MLset) +
          ylab("predicted RF similarity") +
          xlab("True RF similarity") +
          labs(title="Support Vector Machine Regressor")+
          theme(plot.title = element_text(hjust = 0.5))




#plot RF data Random Forest

p3_3 <- ggplot(combo_simul_eval_df_predRF,
               aes(x=robinson, y=predicted_utility)) +
          geom_point() +
          geom_smooth(method = "lm") + 
          geom_label(data=regressions_RF_data, inherit.aes=FALSE, parse = T,
                     aes(x = 0.25, y = 0.7,
                         label=paste("R^2:",R2)
                     )) +
          theme_bw() +
          facet_wrap(.~MLset) +
          ylab("predicted RF similarity") +
          xlab("True RF similarity")+
          labs(title="Random Forest Regressor")+
          theme(plot.title = element_text(hjust = 0.5))

#Linear regression for Random Forest wRF model
regressions_wRF=function(df){
  #setting the regression function. 
  reg_fun<-lm(formula=df$predicted_utility~df$wrobinson) #regression function
  #getting the slope, intercept, R square and adjusted R squared of 
  #the regression function (with 3 decimals).
  slope<-round(coef(reg_fun)[2],3)  
  intercept<-round(coef(reg_fun)[1],3) 
  R2<-round(as.numeric(summary(reg_fun)[8]),3)
  R2.Adj<-round(as.numeric(summary(reg_fun)[9]),3)
  c(slope,intercept,R2,R2.Adj)
}


regressions_wRF_data<-ddply(combo_simul_eval_df_predwRF,"MLset",regressions_wRF)
colnames(regressions_wRF_data)<-c ("MLset","slope","intercept","R2","R2.Adj")
print("Linear regression for Random Forest wRF model:")
print(regressions_wRF_data)


#Regression function for Random Forest wRF data
#regressions_wRF_data <- combo_simul_eval_df_predwRF %>%
#  group_by(MLset) %>%
#  summarise(
#    slope = round(coef(lm(predicted_utility ~ wrobinson))[2], 3),
#    intercept = round(coef(lm(predicted_utility ~ wrobinson))[1], 3),
#    R2 = round(summary(lm(predicted_utility ~ wrobinson))$r.squared, 3),
#    R2.Adj = round(summary(lm(predicted_utility ~ wrobinson))$adj.r.squared, 3)
#  ) %>%
#  ungroup()  # Removes the grouping to return a regular data frame


#Linear regression for SVM wRF model

regressions_wRF_SVM=function(df){
  #setting the regression function. 
  reg_fun<-lm(formula=df$predicted_utility~df$wrobinson) #regression function
  #getting the slope, intercept, R square and adjusted R squared of 
  #the regression function (with 3 decimals).
  slope<-round(coef(reg_fun)[2],3)
  intercept<-round(coef(reg_fun)[1],3)
  R2<-round(as.numeric(summary(reg_fun)[8]),3)
  R2.Adj<-round(as.numeric(summary(reg_fun)[9]),3)
  c(slope,intercept,R2,R2.Adj)
}



regressions_wRF_data_SVM<-ddply(combo_simul_eval_df_predwRF_SVM,"MLset",regressions_wRF_SVM)
colnames(regressions_wRF_data_SVM)<-c ("MLset","slope","intercept","R2","R2.Adj")
print("Linear regression for SVM wRF model:")
print(regressions_wRF_data_SVM)

#plot wRF data SVM
p3_2 <- ggplot(combo_simul_eval_df_predwRF_SVM,
               aes(x=wrobinson, y=predicted_utility)) +
  geom_point() +
  geom_smooth(method = "lm") +
  geom_label(data=regressions_wRF_data_SVM, inherit.aes=FALSE, parse = T,
             aes(x = 0.25, y = 0.7,
                 label=paste("R^2:",R2)
             )) +
  theme_bw() +
  facet_wrap(.~MLset) +
  ylab("predicted wRF similarity") +
  xlab("True wRF similarity")+
  labs(title="Support Vector Machine Regressor")+
  theme(plot.title = element_text(hjust = 0.5))


p3_3


#plot wRF data Random Forest
p3_4 <- ggplot(combo_simul_eval_df_predwRF,
               aes(x=wrobinson, y=predicted_utility)) +
  geom_point() +
  geom_smooth(method = "lm") + 
  geom_label(data=regressions_wRF_data, inherit.aes=FALSE, parse = T,
             aes(x = 0.25, y = 0.7,
                 label=paste("R^2:",R2)
             )) +
  theme_bw() +
  facet_wrap(.~MLset) +
  ylab("predicted wRF similarity") +
  xlab("True wRF similarity")+
  labs(title="Random Forest Regressor")+
  theme(plot.title = element_text(hjust = 0.5))


p3_4

#plot final image
grob <- grid.arrange(p3_1,p3_2,p3_3,p3_4,
             ncol=2, nrow =2)
ggsave("figure_3.png", plot=as.ggplot(grob),dpi=300, width=10, height=8)

#400x800
