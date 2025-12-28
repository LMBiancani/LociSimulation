# ==============================================================================
# Script: Run_SimPhy.R
# Purpose: Generate a list of SimPhy commands based on generated parameters.
# ==============================================================================

library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)

# Check for the 5 arguments passed from the shell script
if (length(args) < 5) {
  stop("Usage: Rscript Run_SimPhy.R <sptree_path> <df_path> <output_list> <loci_dir> <simphy_path>", call. = FALSE)
}

species_tree_path <- args[1]
df_path           <- args[2]
output_list_path  <- args[3]
loci_dir          <- args[4]
simphy            <- args[5]


# Load the parameter blueprint generated in the previous step
df <- read.csv(df_path)
nloci <- nrow(df)

# Generate the command strings
# Using mutate and paste0 for a clean 'tidyverse' approach
df_cmds <- df %>%
  mutate(command = paste0(
    simphy, 
    " -rl f:1",                          # Replicates per locus
    " -sr ", species_tree_path,          # Input species tree
    " -sp f:", Ne,                       # Population size for ILS
    " -su ln:", abl, ",0.1",             # Subst. rate (ln scale)
    " -hs ln:", vbl, ",1",               # Heterotachy (vbl)
    " -cs ", seed1,                      # Random seed
    " -o ", loci_dir, loci               # Locus-specific output folder
  ))

# Write the command list to the text file
writeLines(df_cmds$command, con = output_list_path)

cat(paste("Successfully generated  ", nloci, "SimPhy commands in:", output_list_path, "\n"))
