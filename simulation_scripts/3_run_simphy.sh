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

fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p array_list.txt)

cat ${fileline} | while read line
	do
	${line}
	done
