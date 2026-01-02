#!/usr/bin/env Rscript
# trimConstraintTree.R
# Purpose: Prune a reference species tree to match the taxa present in a specific locus alignment.

library(ape)

# Capture command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript trimConstraintTree.R <alignment.fas> <reference.treefile> <output.tre>")
}

# 1. Load the alignment to see which taxa are present
alignment <- read.dna(args[1], format="fasta")
taxapresent <- rownames(alignment)

# 2. Load the Reference Species Tree (from Step 4.0)
tree <- read.tree(args[2])
treetips <- tree$tip.label

# 3. Identify tips in the tree that are NOT in the alignment
tipstoremove <- treetips[!(treetips %in% taxapresent)]

# 4. Prune the tree and write to file
# drop.tip removes the missing taxa while maintaining the relative branch lengths of the rest
outtree <- drop.tip(tree, tipstoremove)
write.tree(outtree, args[3])

cat("Successfully pruned tree to", length(outtree$tip.label), "taxa.\n")
