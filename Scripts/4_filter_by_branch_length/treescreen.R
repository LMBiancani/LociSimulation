#!/usr/bin/env Rscript
# treescreen.R
# Purpose: Calculate Pearson correlation (R2) between gene trees and reference tree.

library(ape)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript treescreen.R <ref_tree.treefile> <gtrees_dir> <output.csv>")
}

ref_tree_path <- args[1]
gtrees_dir    <- args[2]
output_csv    <- args[3]

# 1. Extract reference terminal branch lengths
ref_tree <- read.tree(ref_tree_path)
ref_bl <- setNames(ref_tree$edge.length[sapply(1:length(ref_tree$tip.label), 
                  function(x,y) which(y==x), y=ref_tree$edge[,2])], 
                  ref_tree$tip.label)

# 2. Identify all constrained treefiles
tree_files <- list.files(gtrees_dir, pattern = "\\.treefile$", full.names = TRUE)

# 3. Process each locus
results_list <- list()

for (f in tree_files) {
    locus_id <- gsub("\\.treefile$", "", basename(f))
    gtree    <- read.tree(f)
    
    # Extract gene tree branch lengths
    gtree_bl <- setNames(gtree$edge.length[sapply(1:length(gtree$tip.label), 
                         function(x,y) which(y==x), y=gtree$edge[,2])], 
                         gtree$tip.label)
    
    # Align tips (handles cases where gene trees have fewer taxa)
    common_tips <- intersect(names(ref_bl), names(gtree_bl))
    
    if (length(common_tips) > 2) {
        # Regression: Reference Lengths ~ Gene Tree Lengths
        regress  <- lm(gtree_bl[common_tips] ~ ref_bl[common_tips])
        rsq      <- summary(regress)$r.squared
        slope    <- coef(regress)[2]
        results_list[[locus_id]] <- data.frame(Locus=locus_id, Slope=slope, Rsq=rsq)
    }
}

results <- do.call(rbind, results_list)

# 4. Calculate filtering thresholds (Simion et al. 2017: Mean +/- 1.96 * SD)
mean_rsq <- mean(results$Rsq, na.rm=TRUE)
sd_rsq   <- sd(results$Rsq, na.rm=TRUE)
lower_limit <- mean_rsq - (1.96 * sd_rsq)
upper_limit <- mean_rsq + (1.96 * sd_rsq)

results$Status <- ifelse(results$Rsq >= lower_limit & results$Rsq <= upper_limit, "Pass", "Fail")

# 5. Save output
write.csv(results, output_csv, row.names = FALSE)

cat("\n--- BLC Screening Summary ---\n")
cat("Mean Rsq:    ", round(mean_rsq, 4), "\n")
cat("SD Rsq:      ", round(sd_rsq, 4), "\n")
cat("Lower Limit: ", round(lower_limit, 4), "\n")
cat("Loci Passed: ", sum(results$Status == "Pass"), "\n")
cat("Loci Failed: ", sum(results$Status == "Fail"), "\n")
