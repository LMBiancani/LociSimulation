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

# 3. Setup Results dataframe (Updated with Support Columns)
results <- data.frame(Dataset = character(),
                      RF = numeric(),
                      wRF = numeric(),
                      Quartet_Dist = numeric(),
                      Mean_SH = numeric(),
                      Mean_UF = numeric(),
                      Resolved_Nodes = numeric(),
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

    # --- Metric 1: Standard RF ---
    rf_val <- phangorn::RF.dist(truth_tree, test_tree)

    # --- Metric 2: Weighted RF ---
    wrf_val <- phangorn::wRF.dist(truth_tree, test_tree)

    # --- Metric 3: Quartet Distance ---
    q_status <- Quartet::QuartetStatus(truth_tree, test_tree)
    quart_val <- q_status[,'N'] - q_status[,'s']

    # --- Metric 4: Support Value Parsing (SH/UF) ---
    # Extract labels, ignoring empty strings (often the root)
    raw_supports <- test_tree$node.label[test_tree$node.label != ""]
    
    if (length(raw_supports) > 0) {
        # Split "98.5/100" into two columns
        sup_matrix <- do.call(rbind, strsplit(raw_supports, "/"))
        sh_vals <- as.numeric(sup_matrix[,1])
        uf_vals <- as.numeric(sup_matrix[,2])
        
        m_sh <- mean(sh_vals, na.rm = TRUE)
        m_uf <- mean(uf_vals, na.rm = TRUE)
        
        # Count nodes meeting both high-support thresholds
        res_nodes <- sum(sh_vals >= 80 & uf_vals >= 95, na.rm = TRUE)
    } else {
        m_sh <- m_uf <- res_nodes <- NA
    }

    # Append to results
    results <- rbind(results, data.frame(Dataset = label,
                                         RF = rf_val,
                                         wRF = wrf_val,
                                         Quartet_Dist = quart_val,
                                         Mean_SH = m_sh,
                                         Mean_UF = m_uf,
                                         Resolved_Nodes = res_nodes))

    cat("Analyzed:", label, "| Mean UF:", round(m_uf, 1), "\n")
  } else {
    cat("Warning: File not found -", tree_path, "\n")
  }
}

# 5. Write and Print Results
write.csv(results, out_csv, row.names = FALSE)

cat("\n==========================================================================================\n")
cat("                                TREE COMPARISON & SUPPORT REPORT                           \n")
cat("==========================================================================================\n")
cat(sprintf("%-25s %-5s %-8s %-10s %-8s %-8s %-10s\n", 
            "Dataset", "RF", "wRF", "Quart_D", "Avg_SH", "Avg_UF", "Resolved"))
cat("------------------------------------------------------------------------------------------\n")
for(i in 1:nrow(results)){
  cat(sprintf("%-25s %-5.0f %-8.3f %-10.0f %-8.1f %-8.1f %-10.0f\n",
              results$Dataset[i],
              results$RF[i],
              results$wRF[i],
              results$Quartet_Dist[i],
              results$Mean_SH[i],
              results$Mean_UF[i],
              results$Resolved_Nodes[i]))
}
cat("==========================================================================================\n")
cat("Note: Lower values indicate higher accuracy (closer to truth).\n")
cat("Resolved = Number of nodes with SH-aLRT >= 80 and UFBoot >= 95.\n")
cat("==========================================================================================\n")
