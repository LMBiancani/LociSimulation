#!/bin/bash
#SBATCH --job-name="empirical_tree_processor"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH --mail-user="molly.donnellan@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH -p uri-cpu
#SBATCH -c 2
#SBATCH --mem-per-cpu=6G

##This script runs empirical_tree_simulator.R


cd ..
pwd
date

module load uri/main
module load R-bundle-Bioconductor/3.15-foss-2021b-R-4.2.0

Rscript 1_empirical_tree_generation/empirical_tree_processor.R

date
