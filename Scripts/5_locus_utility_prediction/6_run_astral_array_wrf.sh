#!/bin/bash
#SBATCH --job-name="Astr_arr_wrf"
#SBATCH --time=20:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --array=1-7


module load R/4.0.3-foss-2020b
date

for i in ../simulations/*/*/1/
do
	cd ${i}
	pwd	
	gene_tree_path="inferred_gene_trees_Test.tre"
	gene_tree_names="inferred_gene_trees_Test.txt"
	astral_path="/home/aknyshov/alex_data/andromeda_tools/ASTRAL/Astral/astral.5.7.8.jar"
	collapser_path="../../../../3_feature_assessment/collapse_by.R"

	single_sample=$(sed -n ${SLURM_ARRAY_TASK_ID}p subsets/wRF_subsets/array_list.tx)
	sed_exp=$(cut -f1 -d, subsets/wRF_subsets/${single_sample} | grep -wnf - ${gene_tree_names} | awk -F: '{print $1"p"}' | paste -sd";")
	echo sed -n ${sed_exp} ${gene_tree_path} ">" subsets/wRF_subsets/trees_${single_sample}.tre
	sed -n ${sed_exp} ${gene_tree_path} > subsets/wRF_subsets/trees_${single_sample}.tre
	Rscript ${collapser_path} subsets/wRF_subsets/trees_${single_sample}.tre sh-alrt 0 subsets/wRF_subsets/collapsed_trees_${single_sample}.tre
	rm subsets/wRF_subsets/trees_${single_sample}.tre
	java -Xmx5000M -jar ${astral_path} -i subsets/wRF_subsets/collapsed_trees_${single_sample}.tre -o subsets/wRF_subsets/astral_${single_sample}.tre -t 4 2>subsets/wRF_subsets/astral_${single_sample}.log
	rm subsets/wRF_subsets/collapsed_trees_${single_sample}.tre
	cd ../../../../5_locus_utility_prediction
done
date
