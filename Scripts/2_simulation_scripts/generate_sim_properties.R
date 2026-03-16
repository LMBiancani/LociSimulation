# ==============================================================================
# Script: generate_sim_properties.R
# Description: Generates a stochastic "blueprint" (df.csv) for Run_SimPhy.R
#              containing evolutionary parameters for simulated loci.
#              Simulates biological realism including substitution rates (ABL),
#              heterotachy (VBL), ILS (Ne), and complex data loss patterns.
# Usage: Rscript generate_sim_properties.R <22 parameters>
# ==============================================================================
# --- 1. Capture Command Line Arguments ---
# Arguments must be passed in the following order:
# [1] treefile         (Path to ultrametric species tree rescaled in generations)
# [2] mod_write_tree2  (Path to modified.write.tree2.R - custom ape patch for NEXUS output)
# [3] random_seed      (Random number seed for reproducibility)
#                      Loci Simulation Parameters:
# [4] nloci            (number of loci to simulate)
# [5] Ne               (Effective Population Size - ILS level Scales discordance based on Ne of the empirical group)
# [6] ABLmin           (minimum (natural log) for Average Branch Length range (ABL))
# [7] ABLmax           (maximum (natural log) for Average Branch Length range (ABL))
# [8] LLmin            (minimum locus length (bp))
# [9] LLmax            (maximum locus length (bp))
# [10] lambdaPSmin     (minimum for Pagel's Lambda)
# [11] lambdaPSmax     (maximum for Pagel's Lambda)
# [12] VBLmin          (minimum Variance in Branch Length (VBL) - models heterotachy)
# [13] VBLmax          (maximum Variance in Branch Length (VBL) - models heterotachy)
# [14] MissTaxa        (maximum proportion of missing taxa per locus)
# [15] PartLoss        (proportion of non-missing taxa exhibiting partial data loss per locus)
# [16] MissPropMIN     (minimum proportion of locus sequence removed (for taxa exhibiting partial loss))
# [17] MissPropMAX     (maximum proportion of locus sequence removed (for taxa exhibiting partial loss))
# [18] PropCoding      (proportion of loci to be protein coding - CODON model (vs. NUCLEOTIDE))
# [19] NoParalogy      (proportion of loci exhibiting no paralogy (clean))
# [20] ParalogyIntensity  (average proportion of taxa exhibiting paralogous signal in a given non-orthologous locus)
# [21] NoContaminant   (proportion of loci exhibiting no contamination (clean))
# [22] ContaminantIntensity   (average proportion of taxa exhibiting contamination (swaps) in a given contaminated locus)


args <- commandArgs(trailingOnly = TRUE)

# Check if the correct number of arguments was provided
if (length(args) < 22) {
  stop("Error: Missing arguments. Expected: [1] treefile [2] mod_write_tree2 [3] random_seed [4] n_loci [5] Ne [6] ABLmin [7] ABLmax [8] LLmin [9] LLmax [10] lambdaPSmin [11] lambdaPSmax [12] VBLmin [13] VBLmax [14] MissTaxa [15] PartLoss [16] MissPropMIN [17] MissPropMAX [18] PropCoding [19] NoParalogy [20] ParalogyIntensity [21] NoContaminant [22] ContaminantIntensity", call. = FALSE)
}

# Assign arguments to variables
tree_path       <- args[1]
mod_write_tree2 <- args[2]
random_seed     <- args[3]
nloci           <- as.numeric(args[4])
Ne              <- as.numeric(args[5])
ABLmin          <- as.numeric(args[6])
ABLmax          <- as.numeric(args[7])
LLmin           <- as.numeric(args[8])
LLmax           <- as.numeric(args[9])
lambdaPSmin     <- as.numeric(args[10])
lambdaPSmax     <- as.numeric(args[11])
VBLmin          <- as.numeric(args[12])
VBLmax          <- as.numeric(args[13])
MissTaxa        <- as.numeric(args[14])
PartLoss        <- as.numeric(args[15])
MissPropMIN     <- as.numeric(args[16])
MissPropMAX     <- as.numeric(args[17])
PropCoding      <- as.numeric(args[18])
NoParalogy      <- as.numeric(args[19])
ParalogyIntensity <- as.numeric(args[20])
NoContaminant   <- as.numeric(args[21])
ContaminantIntensity  <- as.numeric(args[22])

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

# Set global seed for exact replication of the 2000-locus parameter set
set.seed(random_seed)

# Initialize dataframe
df <- data.frame(loci = paste0("loc_", as.character(1:nloci)))

# [ABL] Average Branch Length (Substitution Rate)
abl <- round(runif(nloci, min = ABLmin, max = ABLmax), 3)
df$abl <- abl

# Write Species Tree to NEXUS with the [&R] Rooted tag required by SimPhy
write("#NEXUS", file="sptree.nex")
write("begin trees;", file="sptree.nex", append=T)
write(paste0("\ttree tree_1 = [&R] ", write.tree(sptree, digits=8, file="")), file="sptree.nex", append=T)
write("end;", file="sptree.nex", append=T)

# [VBL] Variance in branch length: Heterotachy (Rate Variance)
# Models rate variation across the tree
vbl <- round(runif(nloci,min=VBLmin,max=VBLmax),3)
df <- cbind(df, vbl)

# [Coding Status] CDS? Determines if locus evolves under NUCLEOTIDE or CODON models
proteinCoding <- sample(c(TRUE, FALSE), nloci, replace = TRUE, prob = c(PropCoding, 1-PropCoding))
df <- cbind(df, proteinCoding)

# [Model Seed] Unique seed for individual locus evolution models
modelseed <- sample(100000:999999,nloci, replace=F)
df <- cbind(df, modelseed)

# [Locus Length]
# Longer loci strongly correlate with improved RF similarity/utility
loclen <- sample(LLmin:LLmax,nloci, replace=T)
df <- cbind(df, loclen)

# [LambdaPS] Pagel's Lambda
# Scales proportion of phylogenetic signal on internal branches
lambdaPS <- round(runif(nloci,min=lambdaPSmin,max=lambdaPSmax),5)
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

# Entirely missing taxa (up to specified proportion (MissTaxa) of total taxa)
ntaxa_missing <- sample(0:round(ntaxa*MissTaxa), nloci, replace = TRUE)
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
taxa_missing_segments <- lapply(remaining_taxa, function(x) sample(x, round(length(x)*PartLoss)))
df$taxa_missing_segments <- taxa_missing_segments
df$missing_segments_prop <- lapply(taxa_missing_segments, function(x) round(runif(length(x), MissPropMIN, MissPropMAX), 3))
df$missing_segments_bias <- lapply(taxa_missing_segments, function(x) round(runif(length(x), 0, 1), 2))

# --- 6. Paralogy and Contamination ---
# Simulates non-orthologous signal that can confound species tree error[cite: 35, 36, 556].
nremaining_taxa <- lapply(remaining_taxa, length)

# Deep paralogs via Zero-Inflated Poisson distribution

# here lambda is the average number of taxa exhibiting paralogous signal in a given non-orthologous locus
lambda <- pmax(1, unlist(nremaining_taxa)*ParalogyIntensity)
df$paralog_cont <- extraDistr::rzip(nloci, lambda, NoParalogy)
df$paralog_branch_mod <- round(runif(nloci, 1.0, 10.0), 2)
df$paralog_taxa <- apply(df, 1, function(x) sample(x$remaining_taxa, x$paralog_cont))

# Contaminant groups

# here lambda is the average number of taxa exhibiting contamination (swaps) in a given contaminated locus
lambda <- pmax(1, unlist(nremaining_taxa)*ContaminantIntensity/2) #ContaminantIntensity is divided by 2 because one swap will impact 2 taxa
df$cont_pair_cont <- extraDistr::rzip(nloci, lambda, NoContaminant)
df$cont_pairs <- apply(df, 1, function(x) sample(x$remaining_taxa, x$cont_pair_cont * 2))

# --- 7. Save Blueprint ---
# Convert lists to character strings to prevent CSV formatting errors
df <- as.data.frame(df)
df$remaining_taxa <- gsub("\n", " ", as.character(df$remaining_taxa))
df_out <- apply(df, 2, as.character)

write.csv(df_out, "df.csv", row.names = FALSE)
