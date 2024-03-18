#!/bin/sh

#SBATCH --job-name="align2"
#SBATCH --time=196:00:00  # walltime limit (HH:MM:SS)
#SBATCH -c 4

### adjust/add sbatch flags as needed


module load MAFFT/7.475-gompi-2020b-with-extensions

for i in ../simulations/random/*/1/alignmentGroups
do
	cd ${i}
	pwd
	fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p array_list.txt)
	
	
	cat ${fileline} | while read line
	do
		mafft --auto --thread 4 ../alignments2/${line} > ../alignments3/${line}
	done
	cd ../../../../../feature_assessment
done
