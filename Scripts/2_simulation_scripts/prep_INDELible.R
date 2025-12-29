library(ape)
library(geiger)
library(extraDistr)
library(MultiRNG)
library(EnvStats)
library(castor)
library(phangorn)
library(tidyverse)

# --- 1. Capture Arguments ---
args = commandArgs(trailingOnly=TRUE)
gene_trees_path <- args[1]
df_path         <- args[2]
out_dir         <- args[3]
script_dir      <- args[4] # This is the $Scripts/2_simulation_scripts path

# --- 2. Dynamic Sourcing ---
# Use file.path for cross-platform compatibility
source(file.path(script_dir, "modified.write.tree2.R"))
source(file.path(script_dir, "modify_gene_tree.R"))

# Apply the custom tree-writing function to the ape namespace
assignInNamespace(".write.tree2", .write.tree2, "ape")
options(scipen = 999)

# --- 3. Data Loading ---
gene_trees <- read.tree(gene_trees_path)
df <- read.csv(df_path)
nloci <- length(df[,1])

# --- 4. Main Processing Loop ---
# We loop through each locus and create a UNIQUE control file for it
df2_list <- list()

for (f in 1:nloci) {
  # Define the specific control file for this locus
  locus_control <- file.path(out_dir, paste0("control_", f, ".txt"))

  # Set seed for model parameters
  set.seed(df$modelseed[f])

  # --- Model Block Initialization ---
  if (df$proteinCoding[f] == "TRUE") {
    write("[TYPE] CODON 1", file=locus_control)
    write("[SETTINGS]", file=locus_control, append=T)
    write(paste("\t[randomseed]", df$seed2[f]), file=locus_control, append=T)
  } else {
    write("[TYPE] NUCLEOTIDE 1", file=locus_control)
    write("[SETTINGS]", file=locus_control, append=T)
    write(paste("\t[randomseed]", df$seed2[f]), file=locus_control, append=T)
  }

  # --- Tree Modification Logic (Paralogs/Shifts) ---
  # (Keeping your original logic for modifying the tree structure)
  new_tree <- modify_tree(gene_trees[[f]], df$lambdaPS[f], df$paralog_taxa[f], df$paralog_branch_mod[f])
  new_tree2 <- new_tree
  new_tree2$node.label <- rep("", new_tree2$Nnode)

  # Model shift logic...
  edges0 <- new_tree$edge.length
  names(edges0) <- 1:length(edges0)
  edges1 <- sort(edges0, decreasing = T)
  edges2 <- edges1[which(cumsum(edges1)<sum(edges1)/4)]
  edges3 <- as.numeric(names(edges2))
  nEdges <- rtpois(1, 0.5, -1,length(edges3))
  edges4 <- sample(edges3,nEdges)

  modelnames <- c()
  traversal <- get_tree_traversal_root_to_tips(new_tree2, T)

  for (x in traversal$queue){
    if (Ancestors(new_tree2,x,'parent') == 0) {
      current_model <- paste0("#mRoot")
      modelnames <- c(modelnames, current_model)
      new_tree2$node.label[x-length(new_tree2$tip.label)] <- current_model
    } else {
      current_branch <- which(new_tree2$edge[,2]==x)
      parent_model <- new_tree2$node.label[Ancestors(new_tree2,x,'parent')-length(new_tree2$tip.label)]
      if (current_branch %in% edges4) {
        current_model <- paste0("#m", x)
        modelnames <- c(modelnames, current_model)
      } else {
        if (current_model != parent_model) { current_model <- parent_model }
      }
      if (x <= length(new_tree2$tip.label)) {
        new_tree2$tip.label[x] <- paste0(new_tree2$tip.label[x], current_model)
      } else {
        new_tree2$node.label[x-length(new_tree2$tip.label)] <- current_model
      }
    }
  }

  # --- Write MODEL definitions to the file ---
  clean_modelnames <- gsub('#','', modelnames)

  if (df$proteinCoding[f] == "TRUE") {
    # Codon Model Parameters...
    pInv <- round(runif(1,0,0.25),3); pNeutral <- round(runif(1,0,1-pInv),3)
    for (m in clean_modelnames) {
      basefreqs <- draw.dirichlet(1,61,rep(10,61),1)[1,]
      basefreqs <- c(basefreqs[1:10], 0, 0, basefreqs[11:12], 0, basefreqs[13:61])
      kappa <- round(rlnormTrunc(1,log(4), log(2.5),max=14),3)
      omegaSelect <- round(runif(1,0,3),3)

      write(paste("[MODEL]", m), file=locus_control, append=T)
      write(paste("\t[statefreq]", paste(basefreqs, collapse=" ")), file=locus_control, append=T)
      write(paste("\t[submodel]", paste(kappa, pInv, pNeutral, 0, 1, omegaSelect, collapse=" ")), file=locus_control, append=T)
      write(paste("\t[indelmodel] POW", round(runif(1,1.5,2),3), "10"), file=locus_control, append=T)
      write(paste("\t[indelrate]", round(runif(1,0.001,0.002),5)), file=locus_control, append=T)
    }
    } else {
      # Nucleotide Model Parameters...
      pInv <- round(runif(1,0,0.25),5)
      ngamcat <- sample(c(0,1),1)
      alpha <- if(ngamcat==0) round(rlnormTrunc(1,log(0.3), log(2.5),max=1.4),5) else 0

      for (m in clean_modelnames) {
        modelType <- sample(c("GTR", "SYM", "TVM", "TVMef", "TIM", "TIMef", "K81uf", "K81", "TrN", "TrNef", "HKY", "K80", "F81", "JC"),1)
        paramvector <- get_param_vector(modelType)

        # Determine base frequencies for specific models
        basefreqs <- NA
        if (modelType %in% c("GTR", "TVM", "TIM", "K81uf", "TrN", "HKY", "F81")) {
          basefreqs <- draw.dirichlet(1,4,c(10,10,10,10),1)[1,]
        }

        # --- BUILD THE SUBMODEL STRING ---
        # This part is mandatory for INDELible to understand the modelType
        if (modelType %in% c("GTR", "SYM")) {
          modelstring <- paste(modelType, paste(paramvector[1:5], collapse=" "))
        } else if (modelType %in% c("TVM", "TVMef")) {
          modelstring <- paste(modelType, paste(paramvector[2:5], collapse=" "))
        } else if (modelType %in% c("TIM", "TIMef")) {
          modelstring <- paste(modelType, paste(paramvector[1:3], collapse=" "))
        } else if (modelType %in% c("K81uf", "K81")) {
          modelstring <- paste(modelType, paste(paramvector[2:3], collapse=" "))
        } else if (modelType %in% c("TrN", "TrNef")) {
          modelstring <- paste(modelType, paste(paramvector[c(1,6)], collapse=" "))
        } else if (modelType %in% c("HKY", "K80")) {
          modelstring <- paste(modelType, paramvector[1])
        } else {
          modelstring <- modelType # Covers JC and F81
        }

        # --- WRITE TO CONTROL FILE ---
        write(paste("[MODEL]", m), file=locus_control, append=T)
        write(paste("\t[submodel]", modelstring), file=locus_control, append=T)

        if (!all(is.na(basefreqs))) {
          write(paste("\t[statefreq]", paste(basefreqs, collapse=" ")), file=locus_control, append=T)
        }

        write(paste("\t[rates]", pInv, alpha, ngamcat), file=locus_control, append=T)
        write(paste("\t[indelmodel] POW", paramvector[7], "10"), file=locus_control, append=T)
        write(paste("\t[indelrate]", paramvector[8]), file=locus_control, append=T)
      }
    }

  # --- Write TREE, BRANCHES, and PARTITIONS to the file ---
  write(paste0("[TREE] t1 ", write.tree(new_tree, file="")), file=locus_control, append=T)

  new_tree2$edge.length <- NULL
  write(paste0("[BRANCHES] b1 ", write.tree(new_tree2, file="")), file=locus_control, append=T)

  seq_len <- if(df$proteinCoding[f]=="TRUE") round(df$loclen[f]/3) else df$loclen[f]
  write(paste0("[PARTITIONS] p1 [t1 b1 ", seq_len, "]"), file=locus_control, append=T)

  # --- Final EVOLVE block ---
  write("[EVOLVE] p1 1 output", file=locus_control, append = T)
}

# (Optional: df2.csv logging logic remains here) # logging simulated model params: the original script, was tracking things like modelkappasd and modelratesd.
# Since we are now using a loop, keeping that log would require initialize a data frame before the loop and fill it as you go.
# Not sure yet if we strictly need those specific standard deviation metrics for downstream analysis, so leaving it out for now to keep the script faster.
