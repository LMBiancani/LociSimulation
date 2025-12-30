#!/bin/bash
#SBATCH --job-name="prep"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G



date

module load R-bundle-Bioconductor/3.16-foss-2022b-R-4.2.2

Rscript figure_7.R 
