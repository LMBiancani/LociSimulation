#!/bin/bash
#SBATCH --job-name="align2"
#SBATCH --time=196:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -p uri-cpu
#SBATCH --mail-user="molly.donnellan@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL

### adjust/add sbatch flags as needed

module load uri/main
module load MAFFT/7.505-GCC-11.3.0-with-extensions 

for i in ../simulations/*/*/1/alignmentGroups
do
	cd ${i}
	pwd
	fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p array_list.txt)
	
	
	cat ${fileline} | while read line
	do
		mafft --auto --thread 4 ../alignments2/${line} > ../alignments3/${line}
	done
	cd ../../../../../3_feature_assessment
done
