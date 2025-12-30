library(ape)

# Capture arguments from shell
args <- commandArgs(trailingOnly = TRUE)
ALN_DIR     <- args[1]
OUTPUT_DIR  <- args[2]
CLADE_FILE  <- args[3]

dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Load Clade Definitions (Group, Taxa)
clade_df <- read.csv(CLADE_FILE, header = TRUE)
all_clades <- split(clade_df$Taxa, clade_df$Group)

# Process all alignments
loci_files <- list.files(ALN_DIR, pattern = "\\.fas$")

for (f in loci_files) {
  locus_path <- file.path(ALN_DIR, f)
  fasta <- read.FASTA(locus_path)
  present_taxa <- names(fasta)
  
  # Intersect defined clades with what is actually in this locus
  pruned_clades <- lapply(all_clades, function(x) intersect(x, present_taxa))
  valid_clades <- pruned_clades[sapply(pruned_clades, length) > 1]
  
  if (length(valid_clades) > 0) {
    # Create the constraint string
    clade_strings <- sapply(valid_clades, function(x) paste0("(", paste(x, collapse = ","), ")"))
    final_constraint <- paste0("(", paste(clade_strings, collapse = ","), ");")
    
    # Save as locus_i_constraint.newick
    out_name <- gsub("\\.fas$", "_constraint.newick", f)
    write(final_constraint, file = file.path(OUTPUT_DIR, out_name))
  }
}
cat(paste("Generated", length(list.files(OUTPUT_DIR)), "constraint files.\n"))
