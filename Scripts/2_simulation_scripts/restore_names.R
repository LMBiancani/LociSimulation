library(ape)

# --- 1. Capture Arguments ---
args <- commandArgs(trailingOnly=TRUE)
input_dir  <- args[1]
output_dir <- args[2]
map_path   <- args[3]

# --- 2. Load Taxon Map ---
taxon_map <- read.csv(map_path)
# Ensure columns are treated as strings to avoid matching errors
taxon_map$number <- as.character(taxon_map$number)

# --- 3. Renaming Loop ---
fas_files <- list.files(input_dir, pattern = "\\.fas$", full.names = TRUE)
message(paste("Renaming taxa in", length(fas_files), "alignments..."))

for (f in fas_files) {
  # Read alignment (as character matrix for easy renaming)
  aln <- read.dna(f, format = "fasta", as.character = TRUE)
  
  # Map numerical rownames back to names using the CSV
  # match() finds the row index in taxon_map where 'number' matches the rowname
  new_names <- taxon_map$name[match(rownames(aln), taxon_map$number)]
  
  # Apply new names
  rownames(aln) <- new_names
  
  # Save output
  out_name <- file.path(output_dir, basename(f))
  write.FASTA(as.DNAbin(aln), out_name)
}

message("All names restored successfully.")
