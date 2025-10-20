# A script to plot species trees for all simulated and empirical datasets
#

#Read in the species trees for each dataset as a multiphylo object
library(ape)
library(ggtree)
library(phangorn)
library(tidyverse)
library(gridExtra)
library(ggplot2)
library(grid)



fong_directory <- "../6_empirical_features/Fong_features/randomforest_subsets/"

RF_trees <-list.files(path=fong_directory, pattern="^astral_ML_.*\\.(tre)$", full.names = TRUE)
RF_trees
RF_tree_list <- list()

for (file in RF_trees) {
    tree <-read.tree(file)
    print(tree)
    #tree1 <- root(tree, outgroup="Danio")
    if (is.rooted(tree)) {
        # Print the root node of the tree (this is not a tip)
        print(paste("Root node of tree in", file, ":", tree$root))
    }
    #root_tip <- tree1$tip.label[tree1$edge[, 2] == tree1$root]
    RF_tree_list [[file]] <-tree
    #print(root_tip)
}
cat("Number of trees loaded:", length(RF_tree_list), "\n")
#print(RF_tree_list[[1]]$tip.label)


fong_sp_tree_file <- "../datasets/Fong_alignments/inferenceEmpirical.treefile"
fong_sp_tree <-read.tree(fong_sp_tree_file)
fong_sp_tree <-root(fong_sp_tree, outgroup="Danio")


RF_distance <- list()
for (i in seq_along(RF_tree_list)) {
    tree <- RF_tree_list[[i]]
    RF_distance[[names(RF_tree_list)[i]]] <- RF.dist(tree, fong_sp_tree, normalize = FALSE, 
                                                     check.labels = FALSE, rooted = TRUE)

}


RF_distance

fong_directory <- "../6_empirical_features/Fong_features/randomforest_subsets/wRF_subsets/"

wRF_trees <-list.files(path=fong_directory, pattern="^astral_ML_.*\\.(tre)$", full.names = TRUE)
wRF_trees
wRF_tree_list <- list()

for (file in wRF_trees) {
    tree <-read.tree(file)
    tree1 <- root(tree, outgroup="Danio")
    root_tip <- tree1$tip.label[tree1$edge[, 2] == tree1$root]
    wRF_tree_list [[file]] <-tree1
    print(root_tip)
}
cat("Number of trees loaded:", length(wRF_tree_list), "\n")
print(wRF_tree_list[[1]])


fong_sp_tree_file <- "../datasets/Fong_alignments/inferenceEmpirical.treefile"
fong_sp_tree <-read.tree(fong_sp_tree_file)
fong_sp_tree <-root(fong_sp_tree, outgroup="Danio")

wRF_distance <- list()
for (i in seq_along(wRF_tree_list)) {
    tree <- wRF_tree_list[[i]]
    wRF_distance[[names(wRF_tree_list)[i]]] <- wRF.dist(tree, fong_sp_tree, normalize = FALSE,
                                                     check.labels = FALSE, rooted = TRUE)

}


wRF_distance

