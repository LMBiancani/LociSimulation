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


ds_path_vector <- c(list.files(path="../simulations/empirical", pattern="", full.names=T, recursive=FALSE),
                    paste0("../simulations/random/ds_", 1:16))
ds_name_vector <- c(list.files(path="../simulations/empirical", pattern="", full.names=F, recursive=FALSE),
                    paste0("ds_", 1:16))

sptrees <- list()
branchdata <- data.frame()
for (f in 1:20) {
  sptrees[[f]] <- read.tree(paste0(ds_path_vector[f],"/1/s_tree.trees"))
  branchdata <- rbind(branchdata, data.frame(brdep = node.depth.edgelength(sptrees[[f]])[sptrees[[f]]$edge[,1]]/max(node.depth.edgelength(sptrees[[f]])),
                                             brlen = sptrees[[f]]$edge.length/max(node.depth.edgelength(sptrees[[f]]))))
}
class(sptrees) <- "multiPhylo"




#Check node height/branch length distributions across all datasets
library(ggExtra)
ggMarginal(ggplot(branchdata,aes(log(brlen), brdep)) + geom_point() + theme_bw())
ggMarginal(ggplot(branchdata,aes(brlen, brdep)) + geom_point() + theme_bw())

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

  #read assessed properties table for the training subsets
  ML_train_df <- read.table(paste0(ds_path_vector[f],"/1/ML_train.txt"), header = T)
  ML_train_df$MLset <- "train"

  #read assessed properties table for the testing subsets and merge with the previous
  ML_test_df <- read.table(paste0(ds_path_vector[f],"/1/ML_test.txt"), header = T)
  ML_test_df$MLset <- "test"
  ML_df <- rbind(ML_train_df, ML_test_df)
  
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


allbranchdfbrl <- tibble()
logbreaks <- seq(min(log(branchdata$brlen)), max(log(branchdata$brlen)), length.out = 10)
allbranchdfbrd <- tibble()
depthbreaks <- c(0, 0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1)
for (f in 1:20) {
  dsname <- ds_name_vector[f]
  t0 <- read.tree(paste0(ds_path_vector[f], "/1/s_tree.trees"))
  t0$edge.length <- t0$edge.length/max(nodeHeights(t0)[,2])*1.0
  t1l <- read.tree(paste0(ds_path_vector[f], "/1/inferred_gene_trees_Train.tre"))
  t1n <- readLines(paste0(ds_path_vector[f], "/1/inferred_gene_trees_Train.txt"))
  for (t1i in 1:length(t1n)){
    locname <- t1n[t1i]
    #print(locname)
    locRFsim <- combo_simul_eval_df$robinson[combo_simul_eval_df$loci == paste0(dsname, "_", locname)]
    locwRFsim <- combo_simul_eval_df$wrobinson[combo_simul_eval_df$loci == paste0(dsname, "_", locname)]
    
    if (is.na(locRFsim)) {
      warning(paste("No match found for", locname))
      next 
    
    } else if (locRFsim > 0.75) {
      RFsim <- "max"
    } else if (locRFsim < 0.25) {
      RFsim <- "min"
    } else {
      RFsim <- "medium"
    }
    if (is.na(locwRFsim))  {
      warning(paste("No match found for", locname))
      next
    } else if (locwRFsim > 0.75) {
      wRFsim <- "max"
    } else if (locwRFsim < 0.25) {
      wRFsim <- "min"
    } else {
      wRFsim <- "medium"
    }
    locbranchdf <- tibble(dsname=character(),
                          locname=character(),
                          brl=numeric(),
                          brd=numeric(),
                          alrt=numeric(),
                          ufboot=numeric())
    t1 <- t1l[[t1i]]
    for (branch in 1:length(t0$edge.length)){
      brdata <- t0$edge[branch,]
      brdep = node.depth.edgelength(t0)[brdata[1]]/max(node.depth.edgelength(t0))
      brlen = t0$edge.length[branch]/max(node.depth.edgelength(t0))
      descN <- t0$edge[branch,2]
      if (descN>length(t0$tip.label)) {
        descN2 <- t0$edge[which(t0$edge[,1] == descN),2]
        tgroupD1 <- t0$tip.label[unlist(Descendants(t0, descN2[1], type="tips"))]
        tgroupD2 <- t0$tip.label[unlist(Descendants(t0, descN2[2], type="tips"))]
        ancN <- t0$edge[branch,1]
        ancNd <- t0$edge[which(t0$edge[,1] == ancN),2]
        ancNd <- ancNd[ancNd != descN]
        if (length(ancNd) > 1) {
          ancNd1 <- ancNd[1]
          ancNd2 <- ancNd[2]
          tgroupA1 <- t0$tip.label[unlist(Descendants(t0, ancNd1, type="tips"))]
          tgroupA2 <- t0$tip.label[unlist(Descendants(t0, ancNd2, type="tips"))]
        } else {
          ancNd1 <- ancNd
          tgroupA1 <- t0$tip.label[unlist(Descendants(t0, ancNd1, type="tips"))]
          ancNd2 <- "othertips"
          tgroupA2 <- t0$tip.label[!(t0$tip.label %in% c(tgroupD1, tgroupD2, tgroupA1))]
        }
        tgroupD1a <- tgroupD1[tgroupD1 %in% t1$tip.label]
        tgroupD2a <- tgroupD2[tgroupD2 %in% t1$tip.label]
        tgroupA1a <- tgroupA1[tgroupA1 %in% t1$tip.label]
        tgroupA2a <- tgroupA2[tgroupA2 %in% t1$tip.label]
        if (length(tgroupD1a) > 0 &
            length(tgroupD2a) > 0 &
            length(tgroupA1a) > 0 &
            length(tgroupA2a) > 0) {
          if (is.monophyletic(t1,tgroupD1a) &
              is.monophyletic(t1,tgroupD2a) &
              is.monophyletic(t1,tgroupA1a) &
              is.monophyletic(t1,tgroupA2a)) {
            sisters <- numeric()
            mrcaD1 <- getMRCA(t1,tgroupD1a)
            if (is.null(mrcaD1)){
              mrcaD1 <- which(t1$tip.label == tgroupD1a)
            }
            mrcaD2 <- getMRCA(t1,tgroupD2a)
            if (is.null(mrcaD2)){
              mrcaD2 <- which(t1$tip.label == tgroupD2a)
            }
            mrcaA1 <- getMRCA(t1,tgroupA1a)
            if (is.null(mrcaA1)){
              mrcaA1 <- which(t1$tip.label == tgroupA1a)
            }
            mrcaA2 <- getMRCA(t1,tgroupA2a)
            if (is.null(mrcaA2)){
              mrcaA2 <- which(t1$tip.label == tgroupA2a)
            }
            
            if (mrcaD1 != t1$edge[which(!(t1$edge[,1] %in% t1$edge[,2]))][1] && Siblings(t1, mrcaD1, include.self = FALSE) %in% c(mrcaD1,mrcaD2,mrcaA1,mrcaA2)) {
              sisters <- c(sisters, Ancestors(t1, mrcaD1, type="parent"))
            }
            if ((mrcaD2 != t1$edge[which(!(t1$edge[,1] %in% t1$edge[,2]))][1]) && Siblings(t1, mrcaD2, include.self = FALSE) %in% c(mrcaD1,mrcaD2,mrcaA1,mrcaA2)) {
              sisters <- c(sisters, Ancestors(t1, mrcaD2, type="parent"))
            }
            if ((mrcaA1 != t1$edge[which(!(t1$edge[,1] %in% t1$edge[,2]))][1]) && Siblings(t1, mrcaA1, include.self = FALSE) %in% c(mrcaD1,mrcaD2,mrcaA1,mrcaA2)) {
              sisters <- c(sisters, Ancestors(t1, mrcaA1, type="parent"))
            }
            if ((mrcaA2 != t1$edge[which(!(t1$edge[,1] %in% t1$edge[,2]))][1]) &&  Siblings(t1, mrcaA2, include.self = FALSE) %in% c(mrcaD1,mrcaD2,mrcaA1,mrcaA2)) {
              sisters <- c(sisters, Ancestors(t1, mrcaA2, type="parent"))
            }
            sisters <- unique(sisters)
            if (length(sisters) == 1) {
              corresponding_branch <- which(t1$edge[,2] == sisters)
              support <- as.numeric(unlist(strsplit(t1$node.label[t1$edge[corresponding_branch,2]-length(t1$tip.label)], "/")))
              locbranchdf <- add_row(locbranchdf, dsname=dsname, locname=locname, brl=brlen, brd=brdep,alrt=support[1], ufboot=support[2])
            }
          } else {
            locbranchdf <- add_row(locbranchdf, dsname=dsname, locname=locname, brl=brlen, brd=brdep,alrt=-1, ufboot=-1)
          }
        }
      }
    }
    locbranchdfbrd <- locbranchdf %>%
                        mutate( brdbin=cut(brd, breaks=depthbreaks,include.lowest = T)) %>%
                        group_by(dsname, locname, brdbin) %>%
                        dplyr::summarise(meanalrt = mean(alrt[alrt>-1]),
                                         meanufboot = mean(ufboot[ufboot>-1]),
                                         monophyProp = sum(alrt>-1)/length(alrt),
                                         .groups = "keep")
    locbranchdfbrd <- add_column(locbranchdfbrd, RFsim=RFsim, wRFsim=wRFsim)
    locbranchdfbrl <- locbranchdf %>%
                        mutate( brlbin=cut(log(brl), breaks = logbreaks,include.lowest = T)) %>%
                        group_by(dsname, locname, brlbin) %>%
                        dplyr::summarise(meanalrt = mean(alrt[alrt>-1]),
                                  meanufboot = mean(ufboot[ufboot>-1]),
                                  monophyProp = sum(alrt>-1)/length(alrt),
                                  .groups = "keep")
    locbranchdfbrl <- add_column(locbranchdfbrl, RFsim=RFsim, wRFsim=wRFsim)
    allbranchdfbrd <- rbind(allbranchdfbrd, locbranchdfbrd)
    allbranchdfbrl <- rbind(allbranchdfbrl, locbranchdfbrl)
  }
}

p4_1 <- ggplot(allbranchdfbrl, aes(x=brlbin)) +
  geom_bar() + 
  scale_y_continuous(breaks=c(0, 20000)) +
  theme_bw() + 
  xlab("Branch length log bin") +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))
p4_2 <- ggplot(allbranchdfbrl, aes(x=brlbin)) +
  geom_boxplot(aes(y=meanalrt)) +
  theme_bw() +
  ylab("SH-aLRT, mean") +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_text(hjust = -0.8),
        legend.position = "none")
p4_3 <- ggplot(allbranchdfbrl, aes(x=brlbin, fill=RFsim)) +
  geom_boxplot(aes(y=meanalrt)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_4 <- ggplot(allbranchdfbrl, aes(x=brlbin)) +
  geom_boxplot(aes(y=meanufboot)) +
  theme_bw() +
  ylab("UFBoot, mean") +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_text(hjust = -1.5),
        legend.position = "none")
p4_5 <- ggplot(allbranchdfbrl, aes(x=brlbin, fill=RFsim)) +
  geom_boxplot(aes(y=meanufboot)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_6 <- ggplot(allbranchdfbrl, aes(x=brlbin)) +
  geom_boxplot(aes(y=monophyProp)) +
  theme_bw() +
  ylab("Correct nodes, prop.") +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_text(hjust = -0.5),
        legend.position = "none")
p4_7 <- ggplot(allbranchdfbrl, aes(x=brlbin, fill=RFsim)) +
  geom_boxplot(aes(y=monophyProp)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "top") +
  scale_fill_discrete(labels=c('high', 'medium', 'low'))
p4_8 <- ggplot(allbranchdfbrd, aes(x=brdbin)) +
  geom_bar() +
  scale_y_continuous(breaks=c(0, 20000)) +
  theme_bw() +
  xlab("Node height bin") +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),
        axis.title.y = element_blank())
p4_9 <- ggplot(allbranchdfbrd, aes(x=brdbin)) +
  geom_boxplot(aes(y=meanalrt)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_10 <- ggplot(allbranchdfbrd, aes(x=brdbin, fill=RFsim)) +
  geom_boxplot(aes(y=meanalrt)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_11 <- ggplot(allbranchdfbrd, aes(x=brdbin)) +
  geom_boxplot(aes(y=meanufboot)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_12 <- ggplot(allbranchdfbrd, aes(x=brdbin, fill=RFsim)) +
  geom_boxplot(aes(y=meanufboot)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_13 <- ggplot(allbranchdfbrd, aes(x=brdbin)) +
  geom_boxplot(aes(y=monophyProp)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_14 <- ggplot(allbranchdfbrd, aes(x=brdbin, fill=RFsim)) +
  geom_boxplot(aes(y=monophyProp)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "top") +
  scale_fill_discrete(labels=c('high', 'medium', 'low'))

grob <-plot_grid(
  p4_7, p4_6, p4_5, p4_4, p4_3, p4_2, p4_1,
  p4_14, p4_13, p4_12, p4_11, p4_10, p4_9, p4_8,
  align = 'v',
  ncol = 2,
  nrow=7,
  byrow = F,
  rel_heights = c(1.75,1,1,1,1,1,2),
  rel_widths = c(1,1)
)

ggsave("figure_2.png", grob)
#700x800

# stats on branch length
library(rstatix)
statsbranchdfbrl <- as.data.frame(allbranchdfbrl[,c(3:8)])
#all bins combined
print(wilcox_test(data=statsbranchdfbrl, meanalrt~RFsim, paired = F, p.adjust.method = "bonferroni"))
print(wilcox_test(data=statsbranchdfbrl, meanufboot~RFsim, paired = F, p.adjust.method = "bonferroni"))
print(wilcox_test(data=statsbranchdfbrl, monophyProp~RFsim, paired = F, p.adjust.method = "bonferroni"))
#per bin tests
for (l in levels(statsbranchdfbrl$brlbin)) {
  print (l)
  print("meanalrt vs RF")
  print(wilcox_test(data=statsbranchdfbrl[statsbranchdfbrl$brlbin == l,], meanalrt~RFsim, paired = F, p.adjust.method = "bonferroni"))
  print("meanufboot vs RF")
  print(wilcox_test(data=statsbranchdfbrl[statsbranchdfbrl$brlbin == l,], meanufboot~RFsim, paired = F, p.adjust.method = "bonferroni"))
  print("monophyProp vs RF")
  print(wilcox_test(data=statsbranchdfbrl[statsbranchdfbrl$brlbin == l,], monophyProp~RFsim, paired = F, p.adjust.method = "bonferroni"))
}

# stats on node depth
statsbranchdfbrd <- as.data.frame(allbranchdfbrd[,c(3:8)])
#all bins combined
print(wilcox_test(data=statsbranchdfbrd, meanalrt~RFsim, paired = F, p.adjust.method = "bonferroni"))
print(wilcox_test(data=statsbranchdfbrd, meanufboot~RFsim, paired = F, p.adjust.method = "bonferroni"))
print(wilcox_test(data=statsbranchdfbrd, monophyProp~RFsim, paired = F, p.adjust.method = "bonferroni"))
#per bin tests
for (l in levels(statsbranchdfbrd$brdbin)) {
  print (l)
  print("meanalrt vs RF")
  print(wilcox_test(data=statsbranchdfbrd[statsbranchdfbrd$brdbin == l,], meanalrt~RFsim, paired = F, p.adjust.method = "bonferroni"))
  print("meanufboot vs RF")
  print(wilcox_test(data=statsbranchdfbrd[statsbranchdfbrd$brdbin == l,], meanufboot~RFsim, paired = F, p.adjust.method = "bonferroni"))
  print("monophyProp vs RF")
  print(wilcox_test(data=statsbranchdfbrd[statsbranchdfbrd$brdbin == l,], monophyProp~RFsim, paired = F, p.adjust.method = "bonferroni"))
}
