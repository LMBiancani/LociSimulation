#!/bin/bash
#SBATCH --job-name="FastSP"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node

module purge
module load Java

fastsp="/home/aknyshov/alex_data/andromeda_tools/FastSP/FastSP.jar"

> fastsp_output.csv

cat alignmentGroups/array_list.txt | while read fileline
do
	cat alignmentGroups/${fileline} | while read line
	do
		echo ${line}","$(java -jar ${fastsp} -r alignments2/${line} -e alignments3/${line} | grep "SP-Score" | cut -f2 -d" ") >> fastsp_output.csv
	done
done
