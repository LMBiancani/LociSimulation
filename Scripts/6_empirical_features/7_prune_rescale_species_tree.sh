#!/bin/bash
#SBATCH --job-name="sptree"
#SBATCH --time=10:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=5   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=48G

module load R/4.0.3-foss-2020b
date

featureslist=(Liu_features)


for i in ${featureslist[@]}/
do	
	cd ${i}
	pwd
	
	species_tree_file="./iqtree_concattree/inference.treefile"
	gene_tree_file="inferred_gene_trees"
	pruned_output_file="./pruned_species_trees.tre"
	prune_script_path="../prune_tree.R"

	cat $(sed -n p ./alignmentGroups/array_list.txt | awk '{print "./alignmentGroups/"$0}') > ${gene_tree_file}".txt"
	cat $(cat $(sed -n p ./alignmentGroups/array_list.txt | awk '{print "./alignmentGroups/"$0}') | awk '{print "./iqtree_genetrees3/inference_"$0".treefile"}') > ${gene_tree_file}".tre"


	Rscript ${prune_script_path} ${species_tree_file} ${gene_tree_file}".tre" ${pruned_output_file}
	
	cd ..
done
date
