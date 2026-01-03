#!/usr/bin/env Rscript
# Required libraries
library(ape)
library(phangorn)
library(Quartet)

# Capture arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 5) {
  stop("Usage: Rscript compare_trees.R <truth_tree> <taxon_map> <output_csv> <test_tree1> <label1> ...")
}

truth_path <- args[1]
map_path   <- args[2]
out_csv    <- args[3]

# 1. Load Truth Tree and Taxon Map
truth_tree <- read.tree(truth_path)
taxon_map  <- read.csv(map_path)

# 2. Rename Truth Tree tips from numbers to names
truth_tree$tip.label <- taxon_map$name[match(truth_tree$tip.label, taxon_map$number)]

# 3. Setup Results dataframe
# We are adding Path_Dist and Quartet_Dist for increased sensitivity
results <- data.frame(Dataset = character(),
                      RF = numeric(),
                      wRF = numeric(),
                      Path_Dist = numeric(),
                      Quartet_Dist = numeric(),
                      stringsAsFactors = FALSE)

# 4. Iterate through test trees
tree_args <- args[4:length(args)]
for (i in seq(1, length(tree_args), by = 2)) {
  tree_path <- tree_args[i]
  label     <- tree_args[i+1]

  if (file.exists(tree_path)) {
    test_tree <- read.tree(tree_path)

    # Ensure tip labels match exactly and are pruned to match truth
    test_tree <- keep.tip(test_tree, truth_tree$tip.label)
    
    # --- Metric 1: Standard RF (Topological mismatch count) ---
    rf_val <- phangorn::RF.dist(truth_tree, test_tree)

    # --- Metric 2: Weighted RF (Branch length + Topology) ---
    wrf_val <- phangorn::wRF.dist(truth_tree, test_tree)

    # --- Metric 3: Path Distance (Sensitive to relative positions) ---
    # Measures the difference in the number of edges between all pairs of taxa.
    path_val <- phangorn::path.dist(truth_tree, test_tree)

    # --- Metric 4: Quartet Distance (Highest sensitivity) ---
    # Calculates the number of four-taxon subtrees (quartets) that differ.
    # QuartetStatus returns a matrix; we subtract the 's' (same) from 'N' (total).
    q_status <- Quartet::QuartetStatus(truth_tree, test_tree)
    quart_val <- q_status[,'N'] - q_status[,'s']

    results <- rbind(results, data.frame(Dataset = label,
                                         RF = rf_val,
                                         wRF = wrf_val,
                                         Path_Dist = path_val,
                                         Quartet_Dist = quart_val))
    
    cat("Compared:", label, "\n")
  } else {
    cat("Warning: File not found -", tree_path, "\n")
  }
}

# 5. Write and Print Results
write.csv(results, out_csv, row.names = FALSE)

cat("\n====================================================================================\n")
cat("                PHYLOGENETIC ACCURACY HIGH-SENSITIVITY REPORT                \n")
cat("====================================================================================\n")
cat(sprintf("%-25s %-6s %-10s %-12s %-12s\n", "Dataset", "RF", "wRF", "Path_Dist", "Quartet_Dist"))
cat("------------------------------------------------------------------------------------\n")
for(i in 1:nrow(results)){
  cat(sprintf("%-25s %-6.1f %-10.4f %-12.2f %-12.0f\n",
              results$Dataset[i],
              results$RF[i],
              results$wRF[i],
              results$Path_Dist[i],
              results$Quartet_Dist[i]))
}
cat("====================================================================================\n")
cat("Note: Lower values indicate higher accuracy (closer to truth).\n")
cat("Path_Dist: Sensitive to taxon displacement | Quartet_Dist: Sensitive to local clades.\n")
cat("====================================================================================\n")
