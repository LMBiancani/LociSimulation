#!/usr/bin/env Rscript

# --- Setup ---
args <- commandArgs(trailingOnly = TRUE)
LRT_CSV    <- args[1]
IN_DIR     <- args[2]
OUT_BASE   <- args[3] # Base output path
P_THRESH   <- as.numeric(args[4])

# Load results
df <- read.csv(LRT_CSV)

# Define paths for both groups using paste0 to keep the name clean
PASS_DIR <- file.path(OUT_BASE, paste0("pass_", P_THRESH))
FAIL_DIR <- file.path(OUT_BASE, paste0("fail_", P_THRESH))

# Create directories
if(!dir.exists(PASS_DIR)) dir.create(PASS_DIR, recursive = TRUE)
if(!dir.exists(FAIL_DIR)) dir.create(FAIL_DIR, recursive = TRUE)

# Categorize loci
passing_loci <- df$Locus[df$p_value >= P_THRESH]
failing_loci <- df$Locus[df$p_value <  P_THRESH]

cat("Threshold:", P_THRESH, "\n")
cat("Loci to copy to PASS:", length(passing_loci), "\n")
cat("Loci to copy to FAIL:", length(failing_loci), "\n")

# Function to copy files
move_files <- function(locus_list, destination) {
  for(locus in locus_list) {
    file_name <- paste0(locus, ".fas")
    file.copy(from = file.path(IN_DIR, file_name),
              to   = destination)
  }
}

# Execute copies
move_files(passing_loci, PASS_DIR)
move_files(failing_loci, FAIL_DIR)

cat("Assembly complete.\n")
cat("  Pass folder:", PASS_DIR, "\n")
cat(length(passing_loci), " loci passed.\n")
cat("  Fail folder:", FAIL_DIR, "\n")
cat(length(failing_loci), " loci failed.\n")
