#!/bin/bash
#SBATCH --job-name="Astr_arr"
#SBATCH --time=2:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR
module load R/4.0.3-foss-2020b
date

gene_tree_path="../inferred_gene_trees_Test.tre"
gene_tree_names="../inferred_gene_trees_Test.txt"
astral_path="/home/aknyshov/alex_data/andromeda_tools/ASTRAL/Astral/astral.5.7.8.jar"
collapser_path="/home/aknyshov/alex_data/ML/init_tests/collapse_by.R"

single_sample=$(sed -n ${SLURM_ARRAY_TASK_ID}p array_list.txt)
sed_exp=$(cut -f1 -d, ${single_sample} | grep -wnf - ${gene_tree_names} | awk -F: '{print $1"p"}' | paste -sd";")
echo sed -n ${sed_exp} ${gene_tree_path} ">" trees_${single_sample}.tre
sed -n ${sed_exp} ${gene_tree_path} > trees_${single_sample}.tre
Rscript ${collapser_path} trees_${single_sample}.tre sh-alrt 0 collapsed_trees_${single_sample}.tre
rm trees_${single_sample}.tre
java -Xmx5000M -jar ${astral_path} -i collapsed_trees_${single_sample}.tre -o astral_${single_sample}.tre -t 4 2>astral_${single_sample}.log
rm collapsed_trees_${single_sample}.tre
date
