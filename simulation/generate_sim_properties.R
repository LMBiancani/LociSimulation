# A script to generate random simulation parameters
#
# Working dir is expected to be a specific 
# species tree dataset folder
#
# Adjust the path to modified.write.tree2.R func
#
# Comment/uncomment the rate params! (lines 37-41)
#
library(ape)
library(geiger)
library(MultiRNG)
library(EnvStats)
library(extraDistr)

sptree <- read.tree("1/s_tree.trees")
#convert species tree to an appropriate nexus format species tree file
source("/home/alex/tools/PML/simulation/modified.write.tree2.R")
assignInNamespace(".write.tree2", .write.tree2, "ape")
write("#NEXUS", file="sptree.nex")
write("begin trees;", file="sptree.nex", append=T)
write(paste0("\ttree tree_1 = [&R] ", write.tree(sptree, digits=8, file="")), file="sptree.nex", append=T)
write("end;", file="sptree.nex", append=T)

#settings
nloci <- 2000
params <- unlist(strsplit(readLines("generate_params.txt"), " "))
Ne <- as.numeric(params[2])
print(Ne)
random_seed <- as.numeric(params[1])
print(random_seed)
ntaxa <- length(sptree$tip.label)
df <- data.frame(loci=paste0("loc_",as.character(1:nloci)))
set.seed(random_seed)

#average branch length - rate
abl <- round(runif(nloci,min=-20,max=-18),3) #random trees 1-12
# abl <- round(runif(nloci,min=-19,max=-17),3) #random trees 13-16
# abl <- round(runif(nloci,min=-19,max=-18),3) #empir specific
# abl <- round(runif(nloci,min=-20,max=-19),3) #wickett specific
# abl <- round(runif(nloci,min=-19.5,max=-18.5),3) #fong specific
df <- cbind(df, abl)

#variance in branch length - variance in rate - heterotachy
vbl <- round(runif(nloci,min=0.5,max=2.5),3)
df <- cbind(df, vbl)

#CDS or NOT
proteinCoding <- sample(c(TRUE,FALSE), nloci, TRUE)
df <- cbind(df, proteinCoding)

#model seed
modelseed <- sample(10000:99999,nloci, replace=F)
df <- cbind(df, modelseed)

#locus length
loclen <- sample(200:2000,nloci, replace=T)
df <- cbind(df, loclen)

#proportion of phylogenetic signal on internal branches
lambdaPS <- round(runif(nloci,min=0.75,max=1.0),5)
df <- cbind(df, lambdaPS)

#amount of ILS - proportional to Ne
Ne <- rep(Ne, nloci)
df <- cbind(df, Ne)

#SimPhy seeds
seed1 <- sample(10000:99999,nloci, replace=F)
df <- cbind(df, seed1)

#INDELible seeds
seed2 <- rep(12345, nloci)
seed2[df$proteinCoding == T] <- 54321
df <- cbind(df, seed2)

#entirely missing taxa
ntaxa_missing <- sample(0:round(ntaxa/2),nloci, replace=T)
taxa_missing <- list()
remaining_taxa <- list()
for (f in ntaxa_missing){
	txm <- sample(c(1:ntaxa),f, replace=F)
	taxa_missing <- c(taxa_missing, list(txm))
	remaining_taxa <- c(remaining_taxa, list(setdiff(c(1:ntaxa), txm)))
}
df$remaining_taxa <- remaining_taxa
df$taxa_missing <- taxa_missing

#taxa with partially missing data
nremaining_taxa <- lapply(remaining_taxa, length )
taxa_missing_segments <- lapply(remaining_taxa, function(x) sample(x,round(length(x)/2)))
df$taxa_missing_segments <- taxa_missing_segments

#proportions of missing data per missing data taxon
missing_segments_prop <- lapply(taxa_missing_segments, function(x) round(runif(length(x),min=0.2,max=0.6),3))
df$missing_segments_prop <- missing_segments_prop
missing_segments_bias <- lapply(taxa_missing_segments, function(x) round(runif(length(x),min=0,max=1),2))
df$missing_segments_bias <- missing_segments_bias

#number of paralogs per gene
# zero-inflated poisson
paralog_cont <- rzip(nloci, unlist(nremaining_taxa)/(unlist(nremaining_taxa)/2), 0.5)
df <- cbind(df, paralog_cont)
#paralog clade branch length
paralog_branch_mod <- round(runif(nloci,min=1.0,max=10.0),2)
df <- cbind(df, paralog_branch_mod)
#taxa selected to be deep paralogs in each gene
paralog_taxa <- apply(df, 1, function(x) sample(x$remaining_taxa,x$paralog_cont) )
df$paralog_taxa <- paralog_taxa

#number of contaminant groups per gene
cont_pair_cont <- rzip(nloci, unlist(nremaining_taxa)/(unlist(nremaining_taxa)/2), 0.5)
df <- cbind(df, cont_pair_cont)
#taxa selected to be contaminants in each gene
cont_pairs <- apply(df, 1, function(x) sample(x$remaining_taxa,x$cont_pair_cont*2) )
df$cont_pairs <- cont_pairs

#write output
df <- apply(df,2,as.character)
write.csv(df,"df.csv")
