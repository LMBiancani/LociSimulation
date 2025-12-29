library(ape)

# --- 1. Capture Arguments ---
args = commandArgs(trailingOnly=TRUE)
alignment_folder_path <- args[1] # This is $indel_dir from the .sh
df_path <- args[2]
df <- read.csv(df_path)

nloci <- length(df[,1])

# Create output directory for modified fasta files
# We'll use file.path for safety
final_aln_dir <- file.path(alignment_folder_path, "alignments_final")
if (!dir.exists(final_aln_dir)) dir.create(final_aln_dir)

# --- 2. Modification Loop ---
for (f in 1:nloci){
    # Identify the simulated file from INDELible
    # Matches the 'mv' command in our bash script: locus_i.phy
    seqpath <- file.path(alignment_folder_path, paste0("locus_", f, ".phy"))
    
    if (!file.exists(seqpath)) {
        message(paste("Warning: File missing for Locus", f))
        next
    }

    # Read DNA (Sequential Phylip format)
    locus <- read.dna(seqpath, format="sequential", as.character = T)
    
    # Filter for remaining taxa
    remaining_taxa <- as.character(eval(parse(text=df$remaining_taxa[f])))
    locus <- locus[rownames(locus) %in% remaining_taxa,]
    
    # --- Contamination Processing ---
    # Swaps sequence data between pairs to simulate lab contamination
    contaminant_tips <- eval(parse(text=df$cont_pairs[f]))
    lencon <- length(contaminant_tips)
    if (lencon > 0) {
        for (t in seq(2, lencon, 2)) {
            # Taxon t gets the sequence of Taxon t-1
            locus[which(rownames(locus) == contaminant_tips[t]), ] <- 
                locus[which(rownames(locus) == contaminant_tips[t-1]), ]
        }
    }
    
    # --- Missing Data Simulation ---
    # Adds gaps (-) to the 5' or 3' ends based on prop and bias in df.csv
    loclen <- ncol(locus)
    taxa_vector <- as.character(eval(parse(text=df$taxa_missing_segments[f])))
    missing_segments_prop_vector <- eval(parse(text=df$missing_segments_prop[f]))
    missing_segments_bias_vector <- eval(parse(text=df$missing_segments_bias[f]))
    
    if (length(taxa_vector) > 0) {
        for (t in 1:length(taxa_vector)) {
            taxon_name <- taxa_vector[t]
            taxon_index <- which(rownames(locus) == taxon_name)
            
            if (length(taxon_index) > 0) {
                gapLen <- loclen * missing_segments_prop_vector[t]
                gapLen5 <- round(gapLen * missing_segments_bias_vector[t])
                gapLen3 <- round(gapLen - gapLen5)
                
                if (gapLen5 > 0) locus[taxon_index, 1:gapLen5] <- "-"
                if (gapLen3 > 0) locus[taxon_index, (loclen - gapLen3 + 1):loclen] <- "-"
            }
        }
    }
    
    # --- Cleanup: Remove empty columns ---
    # If all taxa have a gap at a site, delete the site
    badpos <- which(apply(locus, 2, function(col) all(col == "-")))
    if (length(badpos) > 0) {
        locus <- locus[, -badpos]
    }
    
    # --- Write Result ---
    # Save as FASTA in the new alignments_final folder
    locus_bin <- as.DNAbin(locus)
    write.FASTA(locus_bin, file.path(final_aln_dir, paste0("loc_", f, ".fas")))
}

message("Post-processing complete. Modified alignments are in: ", final_aln_dir)
