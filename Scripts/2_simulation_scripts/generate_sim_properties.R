# generate_sim_properties.R
# Purpose: Generate stochastic evolutionary parameters for 2000 simulated loci
# based on an empirical species tree and mammalian rate ranges.
# The resulting df.csv will serve as the master "blueprint" for Run_SimPhy.R
# df.csv contains every stochastic variable needed to generate gene trees

# --- 1. Capture Command Line Arguments ---
# Arguments must be passed in the following order:
# [1] treefile         (Path to ultrametric species tree rescaled in generations)
# [2] params           (Path to generate_params.txt containing reproducibility seed and Ne)
# [3] mod_write_tree2  (Path to modified.write.tree2.R - custom ape patch for NEXUS output)

args <- commandArgs(trailingOnly = TRUE)

# Check if the correct number of arguments was provided
if (length(args) < 3) {
  stop("Error: Missing arguments. Expected: [1] treefile [2] params [3] mod_write_tree2", call. = FALSE)
}

# Assign arguments to variables
tree_path       <- args[1]
params_path     <- args[2]
mod_write_tree2 <- args[3]

# --- 2. Load Simulation Libraries ---
library(ape)        # Phylogenetics core
library(geiger)     # Tree transformation
library(MultiRNG)   # Multivariate random number generation
library(EnvStats)   # Statistical distributions
library(extraDistr) # Zero-inflated Poisson (rzip) for paralogs/contaminants

# --- 3. Setup and Data Loading ---

# Load the scaled, ultrametric species tree
sptree <- read.tree(tree_path)
ntaxa <- length(sptree$tip.label)

# Apply ape patch to ensure SimPhy-compatible NEXUS formatting
source(mod_write_tree2)
assignInNamespace(".write.tree2", .write.tree2, "ape")

# Extract simulation-wide constants from parameter input file (Seed and Population Size)
params_vals <- unlist(strsplit(readLines(params_path), " "))
random_seed <- as.numeric(params_vals[1])
Ne          <- as.numeric(params_vals[2])

# Set global seed for exact replication of the 2000-locus parameter set
set.seed(random_seed)

# --- 4. Parameter Generation ---
## Parameters:              Value/Range:     Scientific Context:
## Ave Branch Length (abl)  -20 to -18       natural log range estimated for mammals
## Loci Count (nloci)       2000             Standard for the PML training/testing datasets.
## Locus Length	            200–2000 bp      Longer loci are identified as a top feature for higher RF similarity.
## Heterotachy (vbl)        0.5–2.5          Introduces substitution rate variance, a key interaction factor in wRF models.
## ILS Level (Ne)           in params file   Scales discordance based on the effective population size of the empirical group.
## random seed              in params file   For reproducibility

nloci <- 2000
df <- data.frame(loci = paste0("loc_", as.character(1:nloci)))

# [ABL] Average Branch Length (Substitution Rate)
# Using natural log range -20 to -18 as identified for mammals 
abl <- round(runif(nloci, min = -20, max = -18), 3) 
df$abl <- abl

# Write Species Tree to NEXUS with the [&R] Rooted tag required by SimPhy
write("#NEXUS", file="sptree.nex")
write("begin trees;", file="sptree.nex", append=T)
write(paste0("\ttree tree_1 = [&R] ", write.tree(sptree, digits=8, file="")), file="sptree.nex", append=T)
write("end;", file="sptree.nex", append=T)

# [VBL] Variance in branch length: Heterotachy (Rate Variance)
# Models rate variation across the tree
vbl <- round(runif(nloci,min=0.5,max=2.5),3)
df <- cbind(df, vbl)

# [Coding Status] CDS? Determines if locus evolves under NUCLEOTIDE or CODON models
proteinCoding <- sample(c(TRUE,FALSE), nloci, TRUE)
df <- cbind(df, proteinCoding)

# [Model Seed] Unique seed for individual locus evolution models
modelseed <- sample(10000:99999,nloci, replace=F)
df <- cbind(df, modelseed)

# [Locus Length] 200-2000 bp.
# Longer loci strongly correlate with improved RF similarity/utility
loclen <- sample(200:2000,nloci, replace=T)
df <- cbind(df, loclen)

# [LambdaPS] Pagel's Lambda 
# Scales proportion of phylogenetic signal on internal branches
lambdaPS <- round(runif(nloci,min=0.75,max=1.0),5)
df <- cbind(df, lambdaPS)

# [ILS] Proportional to Effective Population Size (Ne)
# Dictates the level of Incomplete Lineage Sorting
Ne <- rep(Ne, nloci)
df <- cbind(df, Ne)

# [Seeds] Specific seeds for downstream software execution
df$seed1 <- sample(10000:99999, nloci, replace = FALSE) # SimPhy seed
df$seed2 <- ifelse(df$proteinCoding, 54321, 12345)      # INDELible seed

# --- 5. Missing Data Simulation ---
# Simulates stochastic and systematic data loss

# Entirely missing taxa (up to 50% of total taxa)
ntaxa_missing <- sample(0:round(ntaxa/2), nloci, replace = TRUE)
taxa_missing <- list()
remaining_taxa <- list()

for (f in ntaxa_missing){
  txm <- sample(c(1:ntaxa), f, replace = FALSE)
	taxa_missing <- c(taxa_missing, list(txm))
	remaining_taxa <- c(remaining_taxa, list(setdiff(c(1:ntaxa), txm)))
}
df$remaining_taxa <- remaining_taxa
df$taxa_missing <- taxa_missing

# Partially missing segments within remaining taxa
taxa_missing_segments <- lapply(remaining_taxa, function(x) sample(x, round(length(x)/2)))
df$taxa_missing_segments <- taxa_missing_segments
df$missing_segments_prop <- lapply(taxa_missing_segments, function(x) round(runif(length(x), 0.2, 0.6), 3))
df$missing_segments_bias <- lapply(taxa_missing_segments, function(x) round(runif(length(x), 0, 1), 2))

# --- 6. Paralogy and Contamination ---
# Simulates non-orthologous signal that can confound species tree error[cite: 35, 36, 556].

# Deep paralogs via Zero-Inflated Poisson distribution
nremaining_taxa <- lapply(remaining_taxa, length)
df$paralog_cont <- rzip(nloci, unlist(nremaining_taxa)/(unlist(nremaining_taxa)/2), 0.5)
df$paralog_branch_mod <- round(runif(nloci, 1.0, 10.0), 2)
df$paralog_taxa <- apply(df, 1, function(x) sample(x$remaining_taxa, x$paralog_cont))

# Contaminant groups
df$cont_pair_cont <- rzip(nloci, unlist(nremaining_taxa)/(unlist(nremaining_taxa)/2), 0.5)
df$cont_pairs <- apply(df, 1, function(x) sample(x$remaining_taxa, x$cont_pair_cont * 2))

# --- 7. Save Blueprint ---
# Convert lists to character strings to prevent CSV formatting errors
df <- as.data.frame(df)
df$remaining_taxa <- gsub("\n", " ", as.character(df$remaining_taxa))
df_out <- apply(df, 2, as.character)

write.csv(df_out, "df.csv", row.names = FALSE)
