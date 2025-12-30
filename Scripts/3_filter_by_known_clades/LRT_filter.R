#!/usr/bin/env Rscript

# --- Load Libraries ---
library(stringr)

# --- Argument Handling ---
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript 3.2_LRT_filter.R <IQ_DIR> <OUT_CSV>")
}

IQ_DIR  <- args[1]
OUT_CSV <- args[2]

# Get list of all unconstrained iqtree files
uncon_files <- list.files(IQ_DIR, pattern = "_uncon.iqtree", full.names = TRUE)

cat("Found", length(uncon_files), "loci to process...\n")

# --- Extraction Function ---
get_lnl <- function(filepath) {
  if(!file.exists(filepath)) return(NA)
  lines <- tryCatch(readLines(filepath), error = function(e) return(NULL))
  if(is.null(lines)) return(NA)
  
  # Search for the Likelihood line
  lnl_line <- lines[grep("Log-likelihood of the tree:", lines)]
  if(length(lnl_line) == 0) return(NA)
  
  # Extract numeric value using regex (matches number before the space/bracket)
  val <- str_extract(lnl_line, "-?[0-9.]+(?= \\()")
  return(as.numeric(val))
}

# --- Build Results Table ---
results <- data.frame(
  Locus = gsub("_uncon.iqtree", "", basename(uncon_files)),
  lnL_Uncon = sapply(uncon_files, get_lnl),
  stringsAsFactors = FALSE
)

cat("Extracting constrained likelihoods...\n")
results$lnL_Con <- sapply(results$Locus, function(x) {
  get_lnl(file.path(IQ_DIR, paste0(x, "_con.iqtree")))
})

# --- Statistics ---
# Calculate Delta lnL (Likelihood Penalty)
results$delta_lnL <- results$lnL_Uncon - results$lnL_Con

# Calculate LRT p-value (df=1 for a simple topological constraint)
results$LRT_stat <- 2 * results$delta_lnL
results$p_value <- pchisq(results$LRT_stat, df = 1, lower.tail = FALSE)

# Sort by delta_lnL (highest penalty at the top)
results <- results[order(results$delta_lnL, decreasing = TRUE), ]

# --- Save Output ---
write.csv(results, OUT_CSV, row.names = FALSE)

cat("\n--- Summary ---\n")
cat("Total loci processed:", nrow(results), "\n")
cat("Loci failing backbone (p < 0.05):", sum(results$p_value < 0.05, na.rm=TRUE), "\n")
cat("Results saved to:", OUT_CSV, "\n")
