#!/bin/bash
#SBATCH --job-name="post_simphy"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -p uri-cpu
#SBATCH --mail-user="molly.donnellan@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH -c 2
#SBATCH --mem-per-cpu=6G
#SBATCH --array=[0-48]%48

##This script prepares directories and control files for INDELible, runs INDELible for all four empirical datasets, and modifies INDELible alignments to introduce crosscontamination and missing data 

#Adjust paths to R (version 4.2.2) and INDELible (version 1.03)i


pwd
date

module load uri/main
module load R-bundle-Bioconductor/3.15-foss-2021b-R-4.2.0

SPP=(../simulations/*/*/1/)
i=${SPP[$SLURM_ARRAY_TASK_ID]}
INDEL=(../../../../../../INDELibleV1.03/src/indelible)

#for i in ../simulations/*/*/1/
#	do
	cd $i
	pwd
	Rscript ../../../../2_simulation_scripts/prep_INDELible.R gene_trees.tre df.csv
	cd alignments1
	cp ../control.txt .
	$INDEL
	cp ../controlCDS.txt ./control.txt
        $INDEL
	cd ../
	Rscript ../../../../2_simulation_scripts/post_INDELible.R alignments1 df.csv
	cd ../../../../2_simulation_scripts/
	pwd
#done

