#!/bin/bash
#SBATCH --job-name="FastSP"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=2   # processor core(s) per node
#SBATCH -p uri-cpu
#SBATCH --mail-user="molly.donnellan@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH --array=[0-10]%49

module purge
module load uri/main
module load all/Java/21.0.2 

fastsp="../../../../../FastSP/FastSP.jar"

SPP=(../simulations/*/*/1/)
i=${SPP[$SLURM_ARRAY_TASK_ID]}

#for i in ../simulations/*/*/1
#do	
	cd ${i}
	pwd
	rm fastsp_output.csv
	>fastsp_output.csv
	cat alignmentGroups/array_list.txt | while read fileline
	do
		#echo ${fileline}
		cat alignmentGroups/${fileline} | while read line
		do
		#	echo ${line}
		#	echo ${line}","$(java -jar ${fastsp} -r alignments2/${line} -e alignments3/${line} | grep "SP-Score" | cut -f2 -d" ")  >> fastsp_output.csv
			echo ${line}","$(java -jar ${fastsp} -r alignments2/${line} -e alignments3/${line} | grep "SP-Score" | sed 's/SP-Score //g')  >> fastsp_output.csv
		done
	done
cd ../../../../3_feature_assessment/
#done
