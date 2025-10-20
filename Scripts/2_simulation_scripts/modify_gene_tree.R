#A function to add paralogy and phylogenetic signal modification to 
#simulated gene trees


modify_tree <- function(oldTree, lambdaVal, ParalogTaxa, ParalogBL) {
  
  #a function to add paralogy and phylogenetic signal modification
  
  #edit tip names
  oldTree$tip.label <- sapply(strsplit(oldTree$tip.label, "_"), function(x) x[1])
  #oldTree$tip.label <- oldTree %>%
    #mutate(tip.label = str_split(tip.label, "_") %>% sapply(`[[`, 1))
  
  #transform orthologs into paralogs
  paralog_tips <- eval(parse(text=ParalogTaxa))
  if (length (paralog_tips) == 0) {
    newTree <- oldTree
  } else {
    paralog_tips <- as.character(paralog_tips)
    #split tree
    #pull out taxa selected to be paralogs as a subtree
    orthoTree <- drop.tip(oldTree,paralog_tips)
    paraTree <- drop.tip(oldTree,oldTree$tip.label[!(oldTree$tip.label %in% paralog_tips)])
    #regraft the paralog subtree
    newTree <- bind.tree(orthoTree, paraTree)
    newTree <- multi2di(newTree,random = F)
    #modify paralog clade branch length
    if (length(paralog_tips) == 1) {
      newTree$edge.length[which(newTree$edge[,2] == which(newTree$tip.label == paralog_tips))] <- 
        newTree$edge.length[which(newTree$edge[,2] == which(newTree$tip.label == paralog_tips))] + 
        max(newTree$edge.length)*ParalogBL
    } else {
      newTree$edge.length[which(newTree$edge[,2] == getMRCA(newTree,paralog_tips))] <- 
        max(newTree$edge.length)*ParalogBL
    }
  }
  
  #modify tree by lambda
  newTree <- rescale(newTree, model = "lambda",lambdaVal)
  
  return(newTree)
}




get_param_vector <- function(modelType){
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
  #indel model
  paramvector[7] <- round(runif(1,min=1.5,max=2),3)
  #indel rate
  paramvector[8] <- round(runif(1,min=0.001,max=0.002),5)
  
  return(paramvector)
}
