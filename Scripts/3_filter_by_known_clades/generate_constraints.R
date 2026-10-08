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

# Process all alignments (.fas, .fa, or .fasta)
loci_files <- list.files(ALN_DIR, pattern = "\\.fast?a?$")

for (f in loci_files) {
  locus_path <- file.path(ALN_DIR, f)
  fasta <- read.FASTA(locus_path)
  present_taxa <- names(fasta)

  # Intersect defined clades with what is actually present in this locus
  pruned_clades <- lapply(all_clades, function(x) intersect(x, present_taxa))
  
  # Multi-taxon clades that can be constrained
  multi_clades <- pruned_clades[sapply(pruned_clades, length) > 1]
  
  # Singleton taxa (only 1 representative of the group present in this locus)
  single_taxa <- unlist(pruned_clades[sapply(pruned_clades, length) == 1])

  # A constraint is only meaningful if at least one multi-taxon clade exists
  if (length(multi_clades) > 0) {
    clade_strings <- sapply(multi_clades, function(x) paste0("(", paste(x, collapse = ","), ")"))
    
    # Combine multi-taxon constrained groups and any singleton tips
    all_elements <- c(clade_strings, single_taxa)
    final_constraint <- paste0("(", paste(all_elements, collapse = ","), ");")

    out_name <- gsub("\\.fast?a?$", "_constraint.newick", f)
    write(final_constraint, file = file.path(OUTPUT_DIR, out_name))
  }
}
cat(paste("Generated", length(list.files(OUTPUT_DIR)), "constraint files.\n"))
