#!/bin/bash
#SBATCH --job-name="amas"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=12   # processor core(s) per node
#SBATCH -p uri-cpu
#SBATCH --mail-user="molly.donnellan@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH --array=[0-48]%49

module purge
module load uri/main
module load Python/3.7.4-GCCcore-8.3.0
amas="../../../../../AMAS/amas/AMAS.py"
cores=12

pwd
date

SPP=(../simulations/*/*/1)
i=${SPP[$SLURM_ARRAY_TASK_ID]}

#for i in ../simulations/*/*/1
#	do
	cd ${i}
	pwd
	ls
	python ${amas} summary -c ${cores} -o amas_output2.txt -f fasta -d dna -i alignments2/*.fas 
	python ${amas} summary -c ${cores} -o amas_output3.txt -f fasta -d dna -i alignments3/*.fas
	cd ../../../../3_feature_assessment/
#done

date
