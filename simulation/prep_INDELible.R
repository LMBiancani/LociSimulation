library(ape)
library(geiger)

args = commandArgs(trailingOnly=TRUE)
gene_trees_path <- args[1]
gene_trees <- read.tree(gene_trees_path)
df_path <- args[2]
df <- read.csv(df_path)

nloci <- length(df[,1])

source("/home/alex/tools/PML/simulation/modified.write.tree2.R")
assignInNamespace(".write.tree2", .write.tree2, "ape")
options(scipen = 999)
modify_tree <- function(oldTree, lambdaVal, ParalogTaxa) {
  #edit tip names
  oldTree[[1]]$tip.label <- sapply(strsplit(oldTree[[1]]$tip.label, "_"), function(x) x[1])

  #drop out paralogs
  paralog_tips <- eval(parse(text=ParalogTaxa))
  if (length (paralog_tips) == 0) {
    newTree <- oldTree[[1]]
  } else {
    paralog_tips <- as.character(paralog_tips)
    orthoTree <- drop.tip(oldTree[[1]],paralog_tips)
    paraTree <- drop.tip(oldTree[[1]],oldTree[[1]]$tip.label[!(oldTree[[1]]$tip.label %in% paralog_tips)])
    newTree <- bind.tree(orthoTree, paraTree)
    newTree <- multi2di(newTree,random = F)
    if (length(paralog_tips) == 1) {
      newTree$edge.length[which(newTree$edge[,2] == which(newTree$tip.label == paralog_tips))] <- newTree$edge.length[which(newTree$edge[,2] == which(newTree$tip.label == paralog_tips))] + max(newTree$edge.length)*10
    } else {
      newTree$edge.length[which(newTree$edge[,2] == getMRCA(newTree,paralog_tips))] <- max(newTree$edge.length)*10
    }
  }
  
  #modify tree by lambda
  newTree <- rescale(newTree, model = "lambda",lambdaVal)
  
  return(newTree)
}
#non CDS
write("[TYPE] NUCLEOTIDE 1",
      file="control.txt")
write("[SETTINGS]",
      file="control.txt", append=T)
write(paste0("\t[randomseed] ", df$seed2[df$proteinCoding == F][1]),
      file="control.txt", append=T)
#CDS
write("[TYPE] CODON 1",
      file="controlCDS.txt")
write("[SETTINGS]",
      file="controlCDS.txt", append=T)
write(paste0("\t[randomseed] ", df$seed2[df$proteinCoding == T][1]),
      file="controlCDS.txt", append=T)

for (f in 1:nloci){
  paramVector <- eval(parse(text=df$paramVector[f]))
  if (df$proteinCoding[f] == "TRUE") {
    outfile = "controlCDS.txt"
    modelstring <- paste(paramVector[1:6], collapse=" ")
  } else {
    outfile = "control.txt"
    if (df$modelType[f] == "GTR" | df$modelType[f] == "SYM") {
      modelstring <- paste0(df$modelType[f], " ", paste(paramVector[1:5], collapse=" "))
    }
    if (df$modelType[f] == "TVM" | df$modelType[f] == "TVMef" ) {
      modelstring <- paste0(df$modelType[f], " ", paste(paramVector[2:5], collapse=" "))
    }
    if (df$modelType[f] == "TIM" | df$modelType[f] == "TIMef") {
      modelstring <- paste0(df$modelType[f], " ", paste(paramVector[1:3], collapse=" "))
    }
    if (df$modelType[f] == "K81uf" | df$modelType[f] == "K81") {
      modelstring <- paste0(df$modelType[f], " ", paste(paramVector[2:3], collapse=" "))
    }
    if (df$modelType[f] == "TrN" | df$modelType[f] == "TrNef") {
      modelstring <- paste0(df$modelType[f], " ", paste(paramVector[c(1,6)], collapse=" "))
    }
    if (df$modelType[f] == "HKY" | df$modelType[f] == "K80") {
      modelstring <- paste0(df$modelType[f], " ", paramVector[1])
    }
    if (df$modelType[f] == "F81" | df$modelType[f] == "JC") {
      modelstring <- df$modelType[f]
    }
  }
  write(paste0("[MODEL] model_", df$loci[f]),
      file=outfile, append=T)
  write(paste0("\t[submodel] ", modelstring),
        file=outfile, append=T)
  if (df$proteinCoding[f] == "FALSE") {
    if (!is.na(df$baseFreq[f])){
      write(paste0("\t[statefreq] ", paste(eval(parse(text=df$baseFreq[f])), collapse=" ")),
              file=outfile, append=T)
    }
    write(paste0("\t[rates] ", paste(paramVector[7:9], collapse=" ")),
        file=outfile, append=T)
    write(paste0("\t[indelmodel] POW ", paramVector[10], " 10"),
        file=outfile, append=T)
    write(paste0("\t[indelrate] ", paramVector[11]),
        file=outfile, append=T)
  } else {
    write(paste0("\t[indelmodel] POW ", paramVector[7], " 10"),
        file=outfile, append=T)
    write(paste0("\t[indelrate] ", paramVector[8]),
        file=outfile, append=T)
  }
}

for (f in 1:nloci){
  if (df$proteinCoding[f] == "TRUE") {
    outfile = "controlCDS.txt"
  } else {
    outfile = "control.txt"
  }
  new_tree <- modify_tree(gene_trees[f],df$lambdaPS[f], df$paralog_taxa[f])
  write(paste0("[TREE] t_", df$loci[f], " ", write.tree(new_tree,file="")),
        file=outfile, append=T)
}

for (f in 1:nloci){
  if (df$proteinCoding[f] == "TRUE") {
    outfile = "controlCDS.txt"
    write(paste0("[PARTITIONS] p_", df$loci[f],
      " [t_", df$loci[f], " model_", df$loci[f],
      " ", round(df$loclen[f]/3), "]"), file=outfile, append=T)
  } else {
    outfile = "control.txt"
    write(paste0("[PARTITIONS] p_", df$loci[f],
      " [t_", df$loci[f], " model_", df$loci[f],
      " ", df$loclen[f], "]"), file=outfile, append=T)
  }

}

write("[EVOLVE]", file="control.txt", append = T)
write("[EVOLVE]", file="controlCDS.txt", append = T)
for (f in 1:nloci){
  if (df$proteinCoding[f] == "TRUE") {
    outfile = "controlCDS.txt"
  } else {
    outfile = "control.txt"
  }
  write(paste(paste0("\tp_", df$loci[f]), 1, paste0("output_", df$loci[f])),
        file=outfile, append = T)
}
cmd0 <- "mkdir alignments1"
system(cmd0)

# cmd <- "~/tools/INDELibleV1.03/src/indelible"
# system(cmd)
