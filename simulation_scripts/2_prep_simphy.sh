#!/bin/bash
#SBATCH --job-name="run_simphy"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 2
#SBATCH --mem-per-cpu=6G

##This script generates simulation properties, runs SimPhy, and preps gene trees for INDELible

pwd
date


module load R-bundle-Bioconductor/3.16-foss-2022b-R-4.2.2

for l in ../simulations/empirical/*

do
	echo $l
	cd $l/1/
	pwd
	Rscript ../../../../simulation_scripts/generate_sim_properties.R
	cd ../../../../simulation_scripts
	pwd
	Rscript run_SimPhy.R $l/1/sptree.nex $l/1/df.csv 3_run_simphy.sh $l/1/gene_trees.tre $l/1/

	#Rscript ../../../../simulation_scripts/prep_INDELible.R ./gene_trees.tre ./df.csv

done

	
