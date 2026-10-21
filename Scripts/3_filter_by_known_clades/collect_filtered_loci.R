#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
LRT_CSV    <- args[1]
IN_DIR     <- args[2]
OUT_BASE   <- args[3]
P_THRESH   <- as.numeric(args[4])

df <- read.csv(LRT_CSV)

PASS_DIR <- file.path(OUT_BASE, paste0("pass_", P_THRESH))
FAIL_DIR <- file.path(OUT_BASE, paste0("fail_", P_THRESH))

if (!dir.exists(PASS_DIR)) dir.create(PASS_DIR, recursive = TRUE)
if (!dir.exists(FAIL_DIR)) dir.create(FAIL_DIR, recursive = TRUE)

# Index available alignment files in the source directory to handle any extension (.fas, .fasta, .fa)
available_files <- list.files(IN_DIR, pattern = "\\.fast?a?$", full.names = FALSE)
names_no_ext <- sub("\\.fast?a?$", "", available_files)
lookup_map <- setNames(available_files, names_no_ext)

passing_loci <- df$Locus[df$p_value >= P_THRESH]
failing_loci <- df$Locus[df$p_value <  P_THRESH]

cat("Threshold:", P_THRESH, "\n")
cat("Loci to copy to PASS:", length(passing_loci), "\n")
cat("Loci to copy to FAIL:", length(failing_loci), "\n")

move_files <- function(locus_list, destination) {
  actual_files <- lookup_map[locus_list]
  valid_files  <- actual_files[!is.na(actual_files)]

  if (length(valid_files) > 0) {
    file.copy(from = file.path(IN_DIR, valid_files),
              to   = destination,
              overwrite = TRUE)
  }
}

move_files(passing_loci, PASS_DIR)
move_files(failing_loci, FAIL_DIR)

cat("Assembly complete.\n")
cat("  Pass folder:", PASS_DIR, "\n")
cat("  Fail folder:", FAIL_DIR, "\n")
