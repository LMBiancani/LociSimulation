library(ape)
library(geiger)
library(MultiRNG)
library(EnvStats)
library(extraDistr)
#settings
nloci <- 2000
args <- commandArgs(trailingOnly=TRUE)
sptree <- read.tree(args[1])
Ne <- as.numeric(args[2])
random_seed <- as.numeric(args[3])
#write.nexus(sptree, file="sptree.nex", translate = F)
write("#NEXUS", file="sptree.nex")
write("begin trees;", file="sptree.nex", append=T)
write(paste0("\ttree tree_1 = [&R] ", write.tree(sptree,file="")), file="sptree.nex", append=T)
write("end;", file="sptree.nex", append=T)
ntaxa <- length(sptree$tip.label)
df <- data.frame(loci=paste0("loc_",as.character(1:nloci)))
set.seed(random_seed)

#average branch length - rate
abl <- round(runif(nloci,min=-17,max=-13),3)
df <- cbind(df, abl)

#variance in branch length - variance in rate - heterotachy
vbl <- round(runif(nloci,min=0.5,max=5.5),3)
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
lambdaPS <- round(runif(nloci,min=0.1,max=1.0),5)
df <- cbind(df, lambdaPS)

#amount of ILS - proportional to Ne
Ne <- rep(Ne, nloci)
df <- cbind(df, Ne)

#simphy seeds
seed1 <- sample(10000:99999,nloci, replace=F)
df <- cbind(df, seed1)

#indelible seeds
# seed2 <- sample(10000:99999,nloci, replace=F)
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
paralog_cont <- rzip(nloci, unlist(nremaining_taxa)/10, 0.5)
df <- cbind(df, paralog_cont)
#taxa selected to be deep paralogs in each gene
paralog_taxa <- apply(df, 1, function(x) sample(x$remaining_taxa,x$paralog_cont) )
df$paralog_taxa <- paralog_taxa

#number of contaminant groups per gene
cont_pair_cont <- rzip(nloci, unlist(nremaining_taxa)/50, 0.5)
df <- cbind(df, cont_pair_cont)
#taxa selected to be contaminants in each gene
cont_pairs <- apply(df, 1, function(x) sample(x$remaining_taxa,x$cont_pair_cont*2) )
df$cont_pairs <- cont_pairs

# print (df)
df <- apply(df,2,as.character)
write.csv(df,"df.csv")
