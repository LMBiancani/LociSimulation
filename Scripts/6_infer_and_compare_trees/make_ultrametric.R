#!/usr/bin/env Rscript
library(ape)
library(geiger)

# Arguments: [1] input_tree [2] output_tree [3] outgroup_string
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Usage: Rscript make_ultrametric.R <input_tree> <output_tree> <outgroup_taxa_comma_sep>")
}

input_path  <- args[1]
output_path <- args[2]
outgroup    <- args[3]

# 1. Load Tree
tree <- read.tree(input_path)

# 2. Root Tree
outgroup_taxa <- unlist(strsplit(outgroup, ","))
if (!all(outgroup_taxa %in% tree$tip.label)) {
    missing <- setdiff(outgroup_taxa, tree$tip.label)
    stop(paste("Outgroup taxa missing from tree:", paste(missing, collapse=", ")))
}

outgroup_node <- getMRCA(phy = tree, tip = outgroup_taxa)
tree <- root(tree, node = outgroup_node, resolve.root = TRUE)

# 3. Transform to Ultrametric
# chronos uses penalized likelihood to make the tree ultrametric
tree_um <- chronos(tree)
class(tree_um) <- "phylo" 

# 4. Write Output (keeping original tip labels)
write.tree(tree_um, file = output_path)

cat("Ultrametric transformation complete for:", basename(input_path), "\n")
