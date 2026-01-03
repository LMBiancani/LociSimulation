#!/usr/bin/env Rscript
library(ape)
library(phangorn)

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
results <- data.frame(Dataset = character(), 
                      RF_Distance = numeric(), 
                      Weighted_RF = numeric(),
                      stringsAsFactors = FALSE)

# 4. Iterate through test trees
tree_args <- args[4:length(args)]
for (i in seq(1, length(tree_args), by = 2)) {
  tree_path <- tree_args[i]
  label     <- tree_args[i+1]
  
  if (file.exists(tree_path)) {
    test_tree <- read.tree(tree_path)
    
    # Ensure tip labels match exactly
    test_tree <- keep.tip(test_tree, truth_tree$tip.label)
    
    # Standard RF (Topological mismatch count)
    rf_dist <- RF.dist(truth_tree, test_tree)
    
    # Weighted RF (Branch length + Topology)
    wrf_dist <- wRF.dist(truth_tree, test_tree)
    
    results <- rbind(results, data.frame(Dataset = label, 
                                         RF_Distance = rf_dist, 
                                         Weighted_RF = wrf_dist))
  }
}

# 5. Generate Quantitative Report Summary
# We assume the first tree passed (index 1) is the Unfiltered Baseline
baseline_rf  <- results$RF_Distance[1]
baseline_wrf <- results$Weighted_RF[1]

results$RF_Improvement_Pct <- round(((baseline_rf - results$RF_Distance) / baseline_rf) * 100, 2)
results$WRF_Improvement_Pct <- round(((baseline_wrf - results$Weighted_RF) / baseline_wrf) * 100, 2)

# Handle cases where baseline is 0 or NaN to avoid division by zero errors
results[is.na(results)] <- 0

# 6. Write and Print
write.csv(results, out_csv, row.names = FALSE)

cat("\n==========================================================================\n")
cat("            PHYLOGENETIC ACCURACY QUANTITATIVE REPORT             \n")
cat("==========================================================================\n")
# Updated Header to include wRF_Gain%
cat(sprintf("%-25s %-8s %-10s %-12s %-12s\n", "Dataset", "RF", "wRF", "RF_Gain%", "wRF_Gain%"))
cat("--------------------------------------------------------------------------\n")
for(i in 1:nrow(results)){
  cat(sprintf("%-25s %-8.1f %-10.4f %-12.2f%% %-12.2f%%\n", 
              results$Dataset[i], 
              results$RF_Distance[i], 
              results$Weighted_RF[i],
              results$RF_Improvement_Pct[i],
              results$WRF_Improvement_Pct[i]))
}
cat("==========================================================================\n")
cat("Note: Positive Gain% indicates higher accuracy than Unfiltered_Baseline.\n")
cat("RF = Topology only | wRF = Topology + Branch Lengths (Divergence Times)\n")
