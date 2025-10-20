#!/bin/bash
#SBATCH --job-name="Astr_arr"
#SBATCH --time=20:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --array=1-8


module load R/4.0.3-foss-2020b
date


featureslist=(Liu_features)

for i in ${featureslist[@]}
do
	cd ${i}
	pwd	
	gene_tree_path="inferred_gene_trees.tre"
	gene_tree_names="inferred_gene_trees.txt"
	astral_path="/home/aknyshov/alex_data/andromeda_tools/ASTRAL/Astral/astral.5.7.8.jar"
	collapser_path="../collapse_by.R"

	single_sample=$(sed -n ${SLURM_ARRAY_TASK_ID}p randomforest_subsets/array_list.txt)
	sed_exp=$(cut -f1 -d, randomforest_subsets/${single_sample} | grep -wnf - ${gene_tree_names} | awk -F: '{print $1"p"}' | paste -sd";")
	echo sed -n ${sed_exp} ${gene_tree_path} ">" randomforest_subsets/trees_${single_sample}.tre
	sed -n ${sed_exp} ${gene_tree_path} > randomforest_subsets/trees_${single_sample}.tre
	Rscript ${collapser_path} randomforest_subsets/trees_${single_sample}.tre sh-alrt 0 randomforest_subsets/collapsed_trees_${single_sample}.tre
	rm randomforest_subsets/trees_${single_sample}.tre
	java -Xmx5000M -jar ${astral_path} -i randomforest_subsets/collapsed_trees_${single_sample}.tre -o randomforest_subsets/astral_${single_sample}.tre -t 4 2>randomforest_subsets/astral_${single_sample}.log
	rm randomforest_subsets/collapsed_trees_${single_sample}.tre
	cd ..
done
date
