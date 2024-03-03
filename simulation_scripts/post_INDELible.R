# A script to modify INDELible alignments
# introducing the crosscontamination and
# missing data
#
library(ape)

args = commandArgs(trailingOnly=TRUE)
alignment_folder_path <- args[1]
df_path <- args[2]
df <- read.csv(df_path)

nloci <- length(df[,1])

cmd0 <- "mkdir alignments2"
system(cmd0)

for (f in 1:nloci){
	remaining_taxa <- as.character(eval(parse(text=df$remaining_taxa[f])))
	seqpath <- paste0(alignment_folder_path, "/output_", df$loci[f], "_TRUE.phy")
	locus <- read.dna(seqpath, format="sequential", as.character = T)
	locus <- locus[rownames(locus) %in% remaining_taxa,]
	#contamination processing
	contaminant_tips <- eval(parse(text=df$cont_pairs[f]))
	lencon <- length (contaminant_tips)
	if (lencon > 0) {
		for (t in seq(2,lencon,2)) {
			locus[which(rownames(locus) == contaminant_tips[t]),] <- locus[which(rownames(locus) == contaminant_tips[t-1]),]
		}
	}
	# missing data
	loclen <- length(locus[1,])
	taxa_vector <- as.character(eval(parse(text=df$taxa_missing_segments[f])))
	missing_segments_prop_vector <- eval(parse(text=df$missing_segments_prop[f]))
	missing_segments_bias_vector <- eval(parse(text=df$missing_segments_bias[f]))
	for (t in 1:length(taxa_vector)) {
		taxon_name <- taxa_vector[t]
		taxon_index <- which(rownames(locus) == taxon_name)
		gapLen <- loclen*missing_segments_prop_vector[t]
		gapLen5 <- round(gapLen*missing_segments_bias_vector[t])
		gapLen3 <- round(gapLen-gapLen5)
		if (gapLen5 > 0){
			locus[taxon_index, 1:gapLen5] <- rep("-",gapLen5)
		}
		if (gapLen3 > 0){
			locus[taxon_index, (loclen-gapLen3+1):loclen] <- rep("-",gapLen3)
		}
	}
	#complete gap position removal
	badpos <- numeric()
	for (pos in 1:loclen) {
		posset <- unique(locus[,pos])
		if (length(posset) == 1 && posset == "-") {
			badpos <- c(badpos, pos)
		}
	}
	if (length(badpos) > 0) {
		locus <- locus[,-badpos]
	}
	#write out resulting alignment
	locus <- as.DNAbin(locus)
	write.FASTA(locus, paste0("alignments2/", df$loci[f],".fas"))
}