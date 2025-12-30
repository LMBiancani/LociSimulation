#!/bin/bash
#SBATCH --job-name="Assess"
#SBATCH --time=120:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=2   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=50G

module load R-bundle-Bioconductor/3.16-foss-2022b-R-4.2.2
date


for i in ../simulations/empirical/*/1/
do
	cd ${i}
	pwd
	Rscript ../../../../3_feature_assessment/assess_gene_properties.R ./alignments3/ inferred_gene_trees_Train.tre inferred_gene_trees_Train.txt pruned_species_trees_Train.tre amas_output3.txt ./rate_assessment/ ML_train.txt ./fastsp_output.csv
	Rscript ../../../../3_feature_assessment/assess_gene_properties.R ./alignments3/ inferred_gene_trees_Test.tre inferred_gene_trees_Test.txt pruned_species_trees_Test.tre amas_output3.txt ./rate_assessment/ ML_test.txt ./fastsp_output.csv
cd ../../../../3_feature_assessment/
done


for i in ../simulations/random/*/1
do
	cd ${i}
	pwd
	Rscript ../../../../3_feature_assessment/assess_gene_properties.R ./alignments3/ inferred_gene_trees_Train.tre inferred_gene_trees_Train.txt pruned_simul_trees_Train.tre amas_output3.txt ./rate_assessment/ ML_train.txt ./fastsp_output.csv
	Rscript ../../../../3_feature_assessment/assess_gene_properties.R ./alignments3/ inferred_gene_trees_Test.tre inferred_gene_trees_Test.txt pruned_simul_trees_Test.tre amas_output3.txt ./rate_assessment/ ML_test.txt ./fastsp_output.csv
cd ../../../../3_feature_assessment/
done

date
