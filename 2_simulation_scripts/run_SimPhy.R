# A script to generate locus gene trees
#
# Working dir is expected to be a specific 
# species tree dataset folder
#
# Adjust the path to SimPhy (line 16)
#
library(tidyverse)
args = commandArgs(trailingOnly=TRUE)
species_tree_path <- args[1]
df_path <- args[2]
output_path <- args[3]
gene_tree <- args[4]
loci_path <-args[5]
df <- read.csv(df_path)
nloci <- length(df[,1])
cmd0 <- paste0(">", gene_tree)
system(cmd0)
for (f in 1:nloci){
        cmd1 <- paste0("/data/schwartzlab/awalling/tools/SimPhy_1.0.2/bin/simphy_lnx64 -rl f:1",
        " -sr ",species_tree_path,
        " -sp f:",df$Ne[f],
        " -su ln:",df$abl[f],",0.1",
        " -hs ln:",df$vbl[f],",1",
        " -cs ",df$seed1[f],
        " -o ",loci_path,df$loci[f])
        write(cmd1,file=output_path,append=TRUE)
}

