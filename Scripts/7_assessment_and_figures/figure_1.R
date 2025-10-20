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


#Plot the species tree of each dataset for the supplementary Figure
pS1 <- ggtree(sptrees) + theme_tree2() + facet_wrap(~.id, scales="free")
levels(pS1$data$.id) <- c("Fong et al.", "Liu et al.", "McGowen et al.", "Wickett et al.", paste0("Random ", 1:16))
pS1 +
  theme(axis.text.x = element_text(size=6.5),
        panel.spacing.x = unit(10, "mm"),
        panel.spacing.y = unit(5, "mm"),
        plot.margin = unit(c(5,5,5,5), "mm")) +
  scale_x_continuous(expand = c(0,0))

ggsave("20_species_trees_SUPPLEMENTS.png", plot=last_plot(), device=png, dpi=300)

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
  base_name <- ds_name_vector[f]

  #read main simulated properties
  simul_df <- read.csv(paste0(ds_path_vector[f],"/1/df.csv"), header = T)[,2:21]
  simul_df$loci <- paste0(base_name,'_',simul_df$loci, ".fas")

  #read simulated substitution model properties
  model_df <- read.csv(paste0(ds_path_vector[f],"/1/df2.csv"), header = T)[,2:8]
  model_df$loci <- paste0(base_name,'_',model_df$loci, ".fas")

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

#Finish figure 1

p2_1 <- ggplot(combo_simul_eval_df,aes(x=abl, y=robinson)) +
  	geom_density_2d_filled() +
  	theme_bw()+
  	theme(legend.position = "none",
		axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
		axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
		axis.title.x = element_text(size = 9), # Adjusts x-axis label size
		axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
	    ) +
		ylab("RF similarity") + xlab("Simulated gene tree substitution rate")
p2_2 <- ggplot(combo_simul_eval_df,aes(x=loclen, y=robinson)) +
        geom_density_2d_filled() +
        theme_bw()+
        theme(legend.position = "none",
                  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
                  axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
                  axis.title.x = element_text(size = 9), # Adjusts x-axis label size
                  axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
            ) +
	ylab("RF similarity") + xlab("Simulated locus length")
p2_3 <- ggplot(combo_simul_eval_df,aes(x=lambdaPS, y=robinson)) +
        geom_density_2d_filled() +
        theme_bw()+
	theme(legend.position = "none",
                  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
                  axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
                  axis.title.x = element_text(size = 9), # Adjusts x-axis label size
                  axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
            ) +
        ylab("RF similarity") + xlab("Simulated phylogenetic signal (Pagel's lambda)")
p2_4 <- combo_simul_eval_df %>%
        mutate( bin=cut_width(prop_contamination, width=0.01, boundary=0) ) %>%
        ggplot(aes(x=bin, y=robinson)) +
        geom_boxplot() +
        theme_bw()+
        theme(legend.position = "none",
                  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
                  axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
                  axis.title.x = element_text(size = 9), # Adjusts x-axis label size
                  axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
            ) +
	ylab("RF similarity") + xlab("Simulated cross-contamination proportion")
p2_5 <- combo_simul_eval_df %>%
        mutate( bin=cut_width(prop_paralogy, width=0.01, boundary=0) ) %>%
        ggplot(aes(x=bin, y=robinson)) +
        geom_boxplot() +
        theme_bw()+
        theme(legend.position = "none",
                  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
                  axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
                  axis.title.x = element_text(size = 9), # Adjusts x-axis label size
                  axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
            ) +
	ylab("RF similarity") + xlab("Simulated paralogy proportion")
p2_6 <- ggplot(combo_simul_eval_df,aes(x=abl, y=wrobinson)) +
        geom_density_2d_filled() +
        theme_bw()+
        theme(legend.position = "none",
                  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
                  axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
                  axis.title.x = element_text(size = 9), # Adjusts x-axis label size
                  axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
            ) +
	ylab("wRF similarity") + xlab("Simulated gene tree substitution rate")
p2_7 <- ggplot(combo_simul_eval_df,aes(x=loclen, y=wrobinson)) +
        geom_density_2d_filled() +
        theme_bw()+
        theme(legend.position = "none",
                  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
                  axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
                  axis.title.x = element_text(size = 9), # Adjusts x-axis label size
                  axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
            ) +
        ylab("wRF similarity") + xlab("Simulated locus length")
p2_8 <- ggplot(combo_simul_eval_df,aes(x=lambdaPS, y=wrobinson)) +
        geom_density_2d_filled() +
        theme_bw()+
        theme(legend.position = "none",
                  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
                  axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
                  axis.title.x = element_text(size = 9), # Adjusts x-axis label size
                  axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
            ) +        
	ylab("wRF similarity") + xlab("Simulated phylogenetic signal (Pagel's lambda)")
p2_9 <- combo_simul_eval_df %>%
        mutate( bin=cut_width(prop_contamination, width=0.01, boundary=0) ) %>%
        ggplot(aes(x=bin, y=wrobinson)) +
        geom_boxplot() +
        theme_bw()+
        theme(legend.position = "none",
                  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
                  axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
                  axis.title.x = element_text(size = 9), # Adjusts x-axis label size
                  axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
            ) +
        ylab("wRF similarity") + xlab("Simulated cross-contamination proportion")
p2_10 <- combo_simul_eval_df %>%
        mutate( bin=cut_width(prop_paralogy, width=0.01, boundary=0) ) %>%
        ggplot(aes(x=bin, y=wrobinson)) +
        geom_boxplot() +
        theme_bw()+
	theme(legend.position = "none",
        	  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 9),
        	  axis.text.y = element_text(size = 9),  # Adjusts y-axis tick label size
        	  axis.title.x = element_text(size = 9), # Adjusts x-axis label size
        	  axis.title.y = element_text(size = 9)  # Adjusts y-axis label size
	    ) +
        ylab("wRF similarity") + xlab("Simulated paralogy proportion")
grob <- grid.arrange(p2_1, p2_2, p2_3, p2_4, p2_5,
             p2_6, p2_7, p2_8, p2_9, p2_10,
             ncol=2, nrow =5, layout_matrix=cbind(c(1,2,3,5,4),
                                                  c(6,7,8,10,9)))
xyMin=0.005
xyMax=0.995
xyOneHalf=0.5
xB = c(xyMin, xyMax, xyMin)
yV = c(xyOneHalf,xyOneHalf, xyOneHalf)
grid.polygon(yV,xB,gp=gpar(fill="transparent",lex=2))
#700x800

ggsave("figure_1.png", grob)


#Perform correlation analyses for the figure 1 data

p2_1_reg1 <- cor.test(combo_simul_eval_df$abl[!(is.na(combo_simul_eval_df$abl) | is.na(combo_simul_eval_df$robinson))],
    combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$abl) | is.na(combo_simul_eval_df$robinson))],
    method="spearman")
p2_1_reg1$estimate
p2_1_reg1$p.value
p2_2_reg1 <- cor.test(combo_simul_eval_df$loclen[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$robinson))],
                      combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$robinson))],
                      method="spearman")
p2_2_reg1$estimate
p2_2_reg1$p.value
p2_3_reg1 <- cor.test(combo_simul_eval_df$lambdaPS[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$robinson))],
                      combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$robinson))],
                      method="spearman")
p2_3_reg1$estimate
p2_3_reg1$p.value
p2_4_reg1 <- cor.test(combo_simul_eval_df$prop_contamination[!(is.na(combo_simul_eval_df$prop_contamination) | is.na(combo_simul_eval_df$robinson))],
                      combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$prop_contamination) | is.na(combo_simul_eval_df$robinson))],
                      method="spearman")
p2_4_reg1$estimate
p2_4_reg1$p.value
p2_5_reg1 <- cor.test(combo_simul_eval_df$prop_paralogy[!(is.na(combo_simul_eval_df$prop_paralogy) | is.na(combo_simul_eval_df$robinson))],
                      combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$prop_paralogy) | is.na(combo_simul_eval_df$robinson))],
                      method="spearman")
p2_5_reg1$estimate
p2_5_reg1$p.value
p2_6_reg1 <- cor.test(combo_simul_eval_df$abl[!(is.na(combo_simul_eval_df$abl) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$abl) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_6_reg1$estimate
p2_6_reg1$p.value
p2_7_reg1 <- cor.test(combo_simul_eval_df$loclen[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_7_reg1$estimate
p2_7_reg1$p.value
p2_7_reg1a <- cor.test(combo_simul_eval_df$loclen[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$wrobinson)) & combo_simul_eval_df$prop_paralogy == 0],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$wrobinson)) & combo_simul_eval_df$prop_paralogy == 0],
                      method="spearman")
p2_7_reg1a$estimate
p2_7_reg1a$p.value
p2_8_reg1 <- cor.test(combo_simul_eval_df$lambdaPS[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_8_reg1$estimate
p2_8_reg1$p.value
p2_8_reg1a <- cor.test(combo_simul_eval_df$lambdaPS[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))  & combo_simul_eval_df$prop_paralogy == 0],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))  & combo_simul_eval_df$prop_paralogy == 0],
                      method="spearman")
p2_8_reg1a$estimate
p2_8_reg1a$p.value
p2_8_reg1b <- cor.test(combo_simul_eval_df$lambdaPS[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))  & combo_simul_eval_df$prop_paralogy > 0],
                       combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))  & combo_simul_eval_df$prop_paralogy > 0],
                       method="spearman")
p2_8_reg1b$estimate
p2_8_reg1b$p.value
p2_9_reg1 <- cor.test(combo_simul_eval_df$prop_contamination[!(is.na(combo_simul_eval_df$prop_contamination) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$prop_contamination) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_9_reg1$estimate
p2_9_reg1$p.value
p2_10_reg1 <- cor.test(combo_simul_eval_df$prop_paralogy[!(is.na(combo_simul_eval_df$prop_paralogy) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$prop_paralogy) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_10_reg1$estimate
p2_10_reg1$p.value

stats_df <- tibble(spearmans.rho<-c(p2_1_reg1$estimate, p2_2_reg1$estimate, p2_3_reg1$estimate,p2_4_reg1$estimate,p2_5_reg1$estimate,p2_6_reg1$estimate,p2_7_reg1$estimate,p2_8_reg1$estimate,p2_9_reg1$estimate,p2_10_reg1$estimate), p.value<-c(p2_1_reg1$p.value,p2_2_reg1$p.value,p2_3_reg1$p.value,p2_4_reg1$p.value,p2_5_reg1$p.value,p2_6_reg1$p.value,p2_7_reg1$p.value,p2_8_reg1$p.value,p2_9_reg1$p.value, p2_10_reg1$p.value))

stats_df

write_csv(stats_df, file="correlations_fig1.csv")
