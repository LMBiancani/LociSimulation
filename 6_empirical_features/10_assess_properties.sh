#!/bin/bash
#SBATCH --job-name="Assess"
#SBATCH --time=120:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=2   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=50G

module load R-bundle-Bioconductor/3.16-foss-2022b-R-4.2.2
date



featureslist=(Liu_features)

for i in ${featureslist[@]}
do
	cd ${i}
	pwd
	Rscript ../assess_gene_properties.R ./alignments3/ inferred_gene_trees.tre inferred_gene_trees.txt pruned_species_trees.tre amas_output3.txt ./rate_assessment/ ML_data.txt ./fastsp_output.csv
cd ../
done

date
