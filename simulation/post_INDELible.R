library(ape)

args = commandArgs(trailingOnly=TRUE)
alignment_folder_path <- args[1]
df_path <- args[2]
df <- read.csv(df_path)

nloci <- 2000

#mkdir alignments2

for (f in 1:nloci){
	remaining_taxa <- as.character(eval(parse(text=df$remaining_taxa[f])))
	seqpath <- paste0(alignment_folder_path, "/output_", df$loci[f], "_TRUE.phy")
	print(seqpath)
	locus <- read.dna(seqpath, format="sequential", as.character = T)
	locus <- locus[rownames(locus) %in% remaining_taxa,]
	taxa_vector <- as.character(eval(parse(text=df$taxa_missing_segments[f])))
	start_vector <- eval(parse(text=df$missing_segments_start[f]))
	end_vector <- eval(parse(text=df$missing_segments_end[f]))
	# print (length(taxa_vector))
	# print (length(start_vector))
	# print (start_vector)
	for (t in 1:length(taxa_vector)) {
		# print(t)
		taxon_name <- taxa_vector[t]
		taxon_index <- which(rownames(locus) == taxon_name)
		# print(start_vector[t])
		locus[taxon_index, 1:start_vector[t]] <- rep("-",start_vector[t])
		print (end_vector[t])
		print (df$loclen[f])
		print (length(locus[taxon_index, ]))
		locus[taxon_index, end_vector[t]:df$loclen[f]] <- rep("-",df$loclen[f]-end_vector[t]+1)
	}
	locus <- as.DNAbin(locus)
	write.FASTA(locus, paste0("alignments2/", df$loci[f],".fas"))
}