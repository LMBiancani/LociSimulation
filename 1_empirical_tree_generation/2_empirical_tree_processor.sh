#!/bin/bash
#SBATCH --job-name="empirical_tree_processor"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 2
#SBATCH --mem-per-cpu=6G

##This script runs empirical_tree_simulator.R


cd ..
pwd
date

module load R-bundle-Bioconductor/3.16-foss-2022b-R-4.2.2

Rscript empirical_tree_generation/empirical_tree_processor.R
