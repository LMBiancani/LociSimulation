# A script to generate control files for INDELible
# and a parameter log file
# (model params are simulated at this step)
#
# Working dir is expected to be a specific 
# species tree dataset folder
#
# Adjust the path to modified.write.tree2.R func
#
#
library(ape)
library(geiger)
library(extraDistr)
library(MultiRNG)
library(EnvStats)
library(castor)
library(phangorn)

args = commandArgs(trailingOnly=TRUE)
gene_trees_path <- args[1]
gene_trees <- read.tree(gene_trees_path)
df_path <- args[2]
df <- read.csv(df_path)

nloci <- length(df[,1])

source("../../../../simulation_scripts/modified.write.tree2.R")
assignInNamespace(".write.tree2", .write.tree2, "ape")
options(scipen = 999)

modify_tree <- function(oldTree, lambdaVal, ParalogTaxa, ParalogBL) {
  
  #a function to add paralogy and phylogenetic signal modification

  #edit tip names
  oldTree[[1]]$tip.label <- as.character(oldTree[[1]]$tip.label)
  oldTree[[1]]$tip.label <- sapply(strsplit(oldTree[[1]]$tip.label, "_"), function(x) x[1])
  oldTree[[1]]$tip.label <-as.phylo(oldTree[[1]]$tip.label)
  #transform orthologs into paralogs
  paralog_tips <- eval(parse(text=ParalogTaxa))
  if (length (paralog_tips) == 0) {
    newTree <- oldTree[[1]]
  } else {
    paralog_tips <- as.character(paralog_tips)
    #split tree
    #pull out taxa selected to be paralogs as a subtree
    orthoTree <- drop.tip(oldTree[[1]],paralog_tips)
    paraTree <- drop.tip(oldTree[[1]],oldTree[[1]]$tip.label[!(oldTree[[1]]$tip.label %in% paralog_tips)])
    #regraft the paralog subtree
    newTree <- bind.tree(orthoTree, paraTree)
    newTree <- multi2di(newTree,random = F)
    #modify paralog clade branch length
    if (length(paralog_tips) == 1) {
      newTree$edge.length[which(newTree$edge[,2] == which(newTree$tip.label == paralog_tips))] <- newTree$edge.length[which(newTree$edge[,2] == which(newTree$tip.label == paralog_tips))] + max(newTree$edge.length)*ParalogBL
    } else {
      newTree$edge.length[which(newTree$edge[,2] == getMRCA(newTree,paralog_tips))] <- max(newTree$edge.length)*ParalogBL
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
write(paste("\t[randomseed]", df$seed2[df$proteinCoding == F][1]),
      file="control.txt", append=T)
#CDS
write("[TYPE] CODON 1",
      file="controlCDS.txt")
write("[SETTINGS]",
      file="controlCDS.txt", append=T)
write(paste("\t[randomseed]", df$seed2[df$proteinCoding == T][1]),
      file="controlCDS.txt", append=T)

treelist <- list()
branchlist <- list()
df2 <- data.frame(loci=paste0("loc_",as.character(1:nloci)))
modelnum <- numeric()
modelbfsd <- numeric()
modelratesd <- numeric()
modelkappasd <- numeric()
modelselectionmean <- numeric()
modelselectionsd <- numeric()

# writing out MODEL block
for (f in 1:nloci){
  set.seed(df$modelseed[f])
  #modify the gene tree by lambda and get paralogs
  new_tree <- modify_tree(gene_trees[f],df$lambdaPS[f], df$paralog_taxa[f], df$paralog_branch_mod[f])
  treelist[[f]] <- new_tree
  #clone the gene tree for model params
  new_tree2 <- new_tree
  new_tree2$node.label <- rep("", new_tree2$Nnode)
  edges0 <- new_tree$edge.length
  names(edges0) <- 1:length(edges0)
  edges1 <- sort(edges0, decreasing = T)
  #select top 25% longest branches
  edges2 <- edges1[which(cumsum(edges1)<sum(edges1)/4)]
  edges3 <- as.numeric(names(edges2))
  #draw a number of model shifts according to poisson process
  #truncated by the total number of selected branches
  nEdges <- rtpois(1, 0.5, -1,length(edges3))
  #sample random branches from selected according to
  #the drawn number of shifts
  edges4 <- sample(edges3,nEdges)
  #reconstruct model at each node and tip accordingly
  modelnames <- c()
  traversal <- get_tree_traversal_root_to_tips(new_tree2, T)
  for (x in traversal$queue){
    if (Ancestors(new_tree2,x,'parent') == 0) {
      #set root model
      current_model <- paste0("#",df$loci[f],"mRoot")
      modelnames <- c(modelnames, current_model)
      new_tree2$node.label[x-length(new_tree2$tip.label)] <- current_model
    } else {
      #model of other nodes/tips
      current_branch <- which(new_tree2$edge[,2]==x)
      parent_model <- new_tree2$node.label[Ancestors(new_tree2,x,'parent')-length(new_tree2$tip.label)]
      if (current_branch %in% edges4) {
        #current branch is shift branch, change current model
        current_model <- paste0("#",df$loci[f],"m", x)
        modelnames <- c(modelnames, current_model)
      } else {
        #this is switch to different part of the tree
        #set model to ancestral model
        if (current_model != parent_model) {
          current_model <- parent_model
        }
      }
      #now update node or tip label
      if (x <= length(new_tree2$tip.label)) {
        #tip update, append model to tip label
        new_tree2$tip.label[x] <- paste0(new_tree2$tip.label[x], current_model)
      } else {
        #node update, set node label to model
        new_tree2$node.label[x-length(new_tree2$tip.label)] <- current_model
      }
    }
  }
  modelnames <- gsub('#','', modelnames)
  modelnum[f] <- length(modelnames)
  modelbf <- numeric()
  new_tree2$edge.length <- NULL
  branchlist[[f]] <- new_tree2

  if (df$proteinCoding[f] == "TRUE") {

    #protein coding locus processing

    outfile = "controlCDS.txt"
    modelType <- "M2"
    #rate heterogeneity has to be same all over the tree
    pInv <- round(runif(1,min=0,max=0.25),3)
    pNeutral <- round(runif(1,min=0,max=1-pInv),3)
    omegaInv <- 0 #no change
    omegaNeut <- 1 #syn=nonsyn
    modelkappa <- numeric()
    modelselection <- numeric()
    #iterate over models
    for (model1 in modelnames) {
      basefreqs <- draw.dirichlet(1,61,rep(10,61),1)[1,]
      basefreqs <- c(basefreqs[1:10], 0, 0, basefreqs[11:12], 0, basefreqs[13:61])
      modelbf <- rbind(modelbf, basefreqs)
      kappa <- round(rlnormTrunc(1,log(4), log(2.5),max=14),3)
      modelkappa <- c(modelkappa, kappa)
      omegaSelect <- round(runif(1,min=0,max=3),3)
      modelselection <- c(modelselection, omegaSelect)
      paramvector <- c(kappa, pInv, pNeutral, omegaInv, omegaNeut, omegaSelect)
      paramvector[7] <- round(runif(1,min=1.5,max=2),3) #indel model
      paramvector[8] <- round(runif(1,min=0.001,max=0.002),5) #indel rate
      modelstring <- paste(paramvector[1:6], collapse=" ")

      #write out model params
      write(paste("[MODEL]", model1),
            file=outfile, append=T)
      write(paste("\t[statefreq]", paste(basefreqs, collapse=" ")),
            file=outfile, append=T)
      write(paste("\t[submodel]", modelstring),
            file=outfile, append=T)
      write(paste("\t[indelmodel] POW", paramvector[7], "10"),
            file=outfile, append=T)
      write(paste("\t[indelrate]", paramvector[8]),
            file=outfile, append=T)
    }
    modelratesd[f] <- NA
    modelkappasd[f] <- sd(modelkappa)
    modelselectionmean[f] <- mean(modelselection)
    modelselectionsd[f] <- sd(modelselection)
    
  } else {

    #nucleotide (NON-protein coding) locus processing

    outfile = "control.txt"
    #rate heterogeneity has to be same all over the tree
    #pinv
    pInv <- round(runif(1,min=0,max=0.25),5)
    #ngamcat, continuous, none
    ngamcat <- sample(c(0,1),1)
    if (ngamcat == 0) {
      #alpha
      alpha <- round(rlnormTrunc(1,log(0.3), log(2.5),max=1.4),5)
    } else {
      # if 1 category, set alpha to 0 to turn off RVAS
      alpha <- 0
    }
    modelrate <- numeric()
    #iterate over models
    for (model1 in modelnames) {
      modelType <- sample(c("GTR", "SYM", "TVM", "TVMef", "TIM",
                "TIMef", "K81uf", "K81", "TrN", "TrNef",
                "HKY", "K80", "F81", "JC"),1)

      #substitution model base freqs
      if (modelType %in% c("GTR", "TVM", "TIM", "K81uf", "TrN", "HKY", "F81")) {
        #T C A G
        basefreqs <- draw.dirichlet(1,4,c(10,10,10,10),1)[1,]
        modelbf <- rbind(modelbf, basefreqs)
      } else {
        basefreqs = NA
        modelbf <- rbind(modelbf, rep(0.25,4))
      }

      #substitution model exchangeabilities (1-6)
      paramvector <- rep(NA,6)
       #               a = TC;   b = TA;  c = TG;  
        # a1 = CT;             d = CA;  e = CG;  
        # b1 = AT;  d1 = AC;            f = AG;  
        # c1 = GT;  e1 = GC;  f1 = GA; 
      #set exA - TC
      if (modelType == "K80" | modelType == "HKY" | modelType == "TrN" | modelType == "TrNef" |
        modelType == "TIM" | modelType == "TIMef" | modelType == "GTR" | modelType == "SYM") {
        paramvector[1] = round(rlnormTrunc(1,log(4), log(2.5),max=16),3)
      }
      #set exB and exC - TA and TG
      if (modelType == "K81" | modelType == "K81uf" | modelType == "TIM" | modelType == "TIMef" | 
        modelType == "TVM" | modelType == "TVMef" | modelType == "GTR" | modelType == "SYM") {
        paramvector[2] = round(rlnormTrunc(1,log(1.25), log(2.5),max=3.5),3)
        paramvector[3] = round(rlnormTrunc(1,log(3), log(2.5),max=9),3)
      }
      #set exD and exE - CA and CG
      if (modelType == "TVM" | modelType == "TVMef" | modelType == "GTR" | modelType == "SYM") {
        paramvector[4] = round(rlnormTrunc(1,log(1), log(2.5),max=2.5),3)
        paramvector[5] = round(rlnormTrunc(1,log(0.8), log(2.5),max=2),3)
      }
      #set exF - AG
      if (modelType == "TrN" | modelType == "TrNef") {
        paramvector[6] = round(rlnormTrunc(1,log(3), log(2.5),max=9),3)
      }

      #produce model string
      if (modelType == "GTR" | modelType == "SYM") {
        modelstring <- paste(modelType, paste(paramvector[1:5], collapse=" "))
        modelrate <- rbind(modelrate, c(a=paramvector[1],b=paramvector[2],
                                        c=paramvector[3],d=paramvector[4],
                                        e=paramvector[5],f=1))
      }
      if (modelType == "TVM" | modelType == "TVMef" ) {
        modelstring <- paste(modelType, paste(paramvector[2:5], collapse=" "))
        modelrate <- rbind(modelrate, c(a=1,b=paramvector[2],
                                        c=paramvector[3],d=paramvector[4],
                                        e=paramvector[5],f=1))
      }
      if (modelType == "TIM" | modelType == "TIMef") {
        modelstring <- paste(modelType, paste(paramvector[1:3], collapse=" "))
        modelrate <- rbind(modelrate, c(a=paramvector[1],b=paramvector[2],
                                        c=paramvector[3],d=paramvector[3],
                                        e=paramvector[2],f=1))
      }
      if (modelType == "K81uf" | modelType == "K81") {
        modelstring <- paste(modelType, paste(paramvector[2:3], collapse=" "))
        modelrate <- rbind(modelrate, c(a=1,b=paramvector[2],
                                        c=paramvector[3],d=paramvector[3],
                                        e=paramvector[2],f=1))
      }
      if (modelType == "TrN" | modelType == "TrNef") {
        modelstring <- paste(modelType, paste(paramvector[c(1,6)], collapse=" "))
        modelrate <- rbind(modelrate, c(a=paramvector[1],b=1,
                                        c=1,d=1,
                                        e=1,f=paramvector[6]))
      }
      if (modelType == "HKY" | modelType == "K80") {
        modelstring <- paste(modelType, paramvector[1])
        modelrate <- rbind(modelrate, c(a=paramvector[1],b=1,
                                        c=1,d=1,
                                        e=1,f=paramvector[1]))
      }
      if (modelType == "F81" | modelType == "JC") {
        modelstring <- modelType
        modelrate <- rbind(modelrate, c(a=1,b=1,
                                        c=1,d=1,
                                        e=1,f=1))
      }

      #indel model
      paramvector[7] <- round(runif(1,min=1.5,max=2),3)
      #indel rate
      paramvector[8] <- round(runif(1,min=0.001,max=0.002),5)

      #write out model params
      write(paste("[MODEL]", model1),
            file=outfile, append=T)
      write(paste("\t[submodel]", modelstring),
            file=outfile, append=T)
      #write out basefreqs
      if (!is.na(basefreqs[1])){
        write(paste("\t[statefreq]", paste(basefreqs, collapse=" ")),
                file=outfile, append=T)
      }
      #write out RVAS rates
      write(paste("\t[rates]", pInv, alpha, ngamcat),
          file=outfile, append=T)
      #write out indel model
      write(paste("\t[indelmodel] POW", paramvector[7], "10"),
          file=outfile, append=T)
      write(paste("\t[indelrate]", paramvector[8]),
          file=outfile, append=T)
    }
    modelratesd[f] <- mean(apply(modelrate,2,sd))
    modelkappasd[f] <- NA
    modelselectionmean[f] <- NA
    modelselectionsd[f] <- NA
  }
  modelbfsd[f] <- mean(apply(modelbf,2,sd))
}

# writing out TREE block
for (f in 1:nloci){
  if (df$proteinCoding[f] == "TRUE") {
    outfile = "controlCDS.txt"
  } else {
    outfile = "control.txt"
  }
  
  write(paste0("[TREE] t_", df$loci[f], " ", write.tree(treelist[[f]],file="")),
        file=outfile, append=T)
}

# writing out BRANCHES block
for (f in 1:nloci){
  if (df$proteinCoding[f] == "TRUE") {
    outfile = "controlCDS.txt"
  } else {
    outfile = "control.txt"
  }
  
  write(paste0("[BRANCHES] b_", df$loci[f], " ", write.tree(branchlist[[f]],file="")),
        file=outfile, append=T)
}

# writing out PARTITIONS block
for (f in 1:nloci){
  if (df$proteinCoding[f] == "TRUE") {
    outfile = "controlCDS.txt"
    write(paste0("[PARTITIONS] p_", df$loci[f],
      " [t_", df$loci[f], " b_", df$loci[f],
      " ", round(df$loclen[f]/3), "]"), file=outfile, append=T)
  } else {
    outfile = "control.txt"
    write(paste0("[PARTITIONS] p_", df$loci[f],
      " [t_", df$loci[f], " b_", df$loci[f],
      " ", df$loclen[f], "]"), file=outfile, append=T)
  }

}

# writing out EVOLVE block
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

#logging simulated model params
df2 <- cbind(df2, modelnum, modelkappasd, modelselectionmean, modelselectionsd, modelratesd, modelbfsd)
write.csv(df2,"df2.csv")

#make dir for INDELible simulations
cmd0 <- "mkdir alignments1"
system(cmd0)
