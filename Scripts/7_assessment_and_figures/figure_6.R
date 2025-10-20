#Load relevant libraries

library(tidyverse)
library(gridExtra)
library(ggplot2)
library(grid)
library(cowplot)
library(plyr)
library(dplyr)
library(ggplotify)



Fong_RF_predicted <- read.csv("../6_empirical_features/Fong_features/RF_model/RF_predicted_ML.tsv")
Fong_wRF_predicted <-read.csv("../6_empirical_features/Fong_features/wRF_model/wRF_predicted_ML.tsv")


Fong_RF_sorted<-arrange(Fong_RF_predicted, desc(predicted_utility))
Fong_wRF_sorted<-arrange(Fong_wRF_predicted, desc(predicted_utility))

Fong_RF_data <- tibble::rowid_to_column(Fong_RF_sorted, "ID")
Fong_wRF_data <- tibble::rowid_to_column(Fong_wRF_sorted, "ID")



plt1 <-ggplot(Fong_RF_data, aes(y=predicted_utility, x=ID))+
  geom_point() +
  theme_bw()+
  labs(title="Fong et. al.",
       y = "Predicted phylogenetic utility: RF",
       x = "Locus ID")

plt1

plt2 <-ggplot(Fong_wRF_data, aes(y=predicted_utility, x=ID))+
  geom_point() +
  theme_bw()+
  labs(title="Fong et. al.",
       y = "Predicted phylogenetic utility: wRF",
       x = "Locus ID")

plt2



McGowen_RF_predicted <- read.csv("../6_empirical_features/McGowen_features/RF_model/RF_predicted_ML.tsv")
McGowen_wRF_predicted <-read.csv("../6_empirical_features/McGowen_features/wRF_model/wRF_predicted_ML.tsv")


McGowen_RF_sorted<-arrange(McGowen_RF_predicted, desc(predicted_utility))
McGowen_wRF_sorted<-arrange(McGowen_wRF_predicted, desc(predicted_utility))

McGowen_RF_data <- tibble::rowid_to_column(McGowen_RF_sorted, "ID")
McGowen_wRF_data <- tibble::rowid_to_column(McGowen_wRF_sorted, "ID")




plt3 <-ggplot(McGowen_RF_data, aes(y=predicted_utility, x=ID))+
  geom_point() +
  theme_bw()+
  labs(title="McGowen et. al.",
       y = "Predicted phylogenetic utility: RF",
       x = "Locus ID")

plt3


plt4 <-ggplot(McGowen_wRF_data, aes(y=predicted_utility, x=ID))+
  geom_point() +
  theme_bw()+
  labs(title="McGowen et. al.",
       y = "Predicted phylogenetic utility: wRF",
       x = "Locus ID")

plt4


Wickett_RF_predicted <- read.csv("../6_empirical_features/Wickett_features/RF_model/RF_predicted_ML.tsv")
Wickett_wRF_predicted <-read.csv("../6_empirical_features/Wickett_features/wRF_model/wRF_predicted_ML.tsv")


Wickett_RF_sorted<-arrange(Wickett_RF_predicted, desc(predicted_utility))
Wickett_wRF_sorted<-arrange(Wickett_wRF_predicted, desc(predicted_utility))

Wickett_RF_data <- tibble::rowid_to_column(Wickett_RF_sorted, "ID")
Wickett_wRF_data <- tibble::rowid_to_column(Wickett_wRF_sorted, "ID")




plt5 <-ggplot(Wickett_RF_data, aes(y=predicted_utility, x=ID))+
  geom_point() +
  theme_bw()+
  labs(title="Wickett et. al.",
       y = "Predicted phylogenetic utility: RF",
       x = "Locus ID")

plt5


plt6 <-ggplot(Wickett_RF_data, aes(y=predicted_utility, x=ID))+
  geom_point() +
  theme_bw()+
  labs(title="Wickett et. al.",
       y = "Predicted phylogenetic utility: wRF",
       x = "Locus ID")

plt6

Liu_RF_predicted <- read.csv("../6_empirical_features/Liu_features/RF_model/RF_predicted_ML.tsv")
Liu_wRF_predicted <-read.csv("../6_empirical_features/Liu_features/wRF_model/wRF_predicted_ML.tsv")


Liu_RF_sorted<-arrange(Liu_RF_predicted, desc(predicted_utility))
Liu_wRF_sorted<-arrange(Liu_wRF_predicted, desc(predicted_utility))

Liu_RF_data <- tibble::rowid_to_column(Liu_RF_sorted, "ID")
Liu_wRF_data <- tibble::rowid_to_column(Liu_wRF_sorted, "ID")




plt7 <-ggplot(Liu_RF_data, aes(y=predicted_utility, x=ID))+
  geom_point() +
  theme_bw()+
  labs(title="Liu et. al.",
       y = "Predicted phylogenetic utility: RF",
       x = "Locus ID")

plt7


plt8 <-ggplot(Liu_RF_data, aes(y=predicted_utility, x=ID))+
  geom_point() +
  theme_bw()+
  labs(title="Liu et. al.",
       y = "Predicted phylogenetic utility: wRF",
       x = "Locus ID")

plt8





#plot final image
grob <- grid.arrange(plt1, plt2, plt3, plt4, plt5, plt6,plt7,plt8,
             ncol=2, nrow =4)
ggsave("figure_6.png", plot=as.ggplot(grob),dpi=300, width=10, height=14)

#400x800
