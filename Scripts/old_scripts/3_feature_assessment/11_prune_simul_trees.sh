#!/bin/bash
#SBATCH --job-name="Assess"
#SBATCH --time=120:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=2   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=50G

module load R/4.0.3-foss-2020b
date


for i in ../simulations/*/*/1/
do
	cd ${i}
	pwd
	Rscript ../../../../3_feature_assessment/prune_tree_simul.R s_tree.trees inferred_gene_trees_Train.tre pruned_simul_trees_Train.tre
	Rscript ../../../../3_feature_assessment/prune_tree_simul.R s_tree.trees inferred_gene_trees_Test.tre pruned_simul_trees_Test.tre
	cd ../../../../3_feature_assessment
done
