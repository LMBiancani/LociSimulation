#!/bin/bash
#SBATCH --job-name="Astr"
#SBATCH --time=2:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR
module load R/4.0.3-foss-2020b
date

gene_tree_path="../inferred_gene_trees_Test.tre"
astral_path="/home/aknyshov/alex_data/andromeda_tools/ASTRAL/Astral/astral.5.7.8.jar"
collapser_path="/home/aknyshov/alex_data/andromeda_tools/PML/feature_assessment/collapse_by.R"

cd astral_tree
grep "/" ${gene_tree_path} > filtered.tre
Rscript ${collapser_path} filtered.tre sh-alrt 0 collapsed_trees.tre
rm filtered.tre
java -Xmx5000M -jar ${astral_path} -i collapsed_trees.tre -o astral.tre -t 4 2>astral.log
rm collapsed_trees.tre
date
