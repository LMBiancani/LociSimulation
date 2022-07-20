#!/bin/bash
#SBATCH --job-name="sptree"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G

module load R/4.0.3-foss-2020b
date

species_tree_file1="./iqtree_concattree/inferenceTrain.treefile"
species_tree_file2="./iqtree_concattree/inferenceTest.treefile"
gene_tree_file1="inferred_gene_trees_Train"
gene_tree_file2="inferred_gene_trees_Test"
pruned_output_file1="./pruned_species_trees_Train.tre"
pruned_output_file2="./pruned_species_trees_Test.tre"
prune_script_path="/home/aknyshov/alex_data/andromeda_tools/PML/feature_assessment/prune_tree.R"

cat $(sed -n 1,4p ./alignmentGroups/array_list.txt | awk '{print "./alignmentGroups/"$0}') > ${gene_tree_file1}".txt"
cat $(cat $(sed -n 1,4p ./alignmentGroups/array_list.txt | awk '{print "./alignmentGroups/"$0}') | awk '{print "./iqtree_genetrees3/inference_"$0".treefile"}') > ${gene_tree_file1}".tre"

cat $(sed -n 5,8p ./alignmentGroups/array_list.txt | awk '{print "./alignmentGroups/"$0}') > ${gene_tree_file2}".txt"
cat $(cat $(sed -n 5,8p ./alignmentGroups/array_list.txt | awk '{print "./alignmentGroups/"$0}') | awk '{print "./iqtree_genetrees3/inference_"$0".treefile"}') > ${gene_tree_file2}".tre"

Rscript ${prune_script_path} ${species_tree_file1} ${gene_tree_file1}".tre" ${pruned_output_file1}
Rscript ${prune_script_path} ${species_tree_file2} ${gene_tree_file2}".tre" ${pruned_output_file2}

date
