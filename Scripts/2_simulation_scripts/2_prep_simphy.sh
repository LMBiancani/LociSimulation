#!/bin/bash
#SBATCH --job-name="run_simphy"
#SBATCH --time=6:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH --mail-user="molly.donnellan@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH -p uri-cpu
#SBATCH -c 2
#SBATCH --mem-per-cpu=6G

##This script generates simulation properties, runs SimPhy, and preps gene trees for INDELible

pwd
date

module load uri/main
module load R-bundle-Bioconductor/3.15-foss-2021b-R-4.2.0


#local space for R packages and it won't ask about install location
mkdir -p ~/R-packages
export R_LIBS=~/R-packages

for l in ../simulations/*/*
do
	if [[ -d "$l" ]]; then #check that each $l is a directory (prevents script from attempting work on dsdf.csv)
		echo $l
		cd $l/1/
		pwd
		Rscript ../../../../2_simulation_scripts/generate_sim_properties.R
		cd ../../../../2_simulation_scripts
		pwd
		Rscript run_SimPhy.R $l/1/sptree.nex $l/1/df.csv 3_run_simphy_command_list.txt $l/1/gene_trees.tre $l/1/
		grep "ds_" 3_run_simphy_command_list.txt | split -l 2000 - 3_run_simphy_list_
		ls 3_run_simphy_list_* >> array_list.txt
	else
		echo "$l is not a directory" 
	fi
done
	
