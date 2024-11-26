#!/bin/bash
#SBATCH --job-name="IQconcat"
#SBATCH --time=172:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=20   # processor core(s) per node
#SBATCH --mem=200G
#SBATCH


date

iqtree_exe="/home/aknyshov/alex_data/andromeda_tools/iqtree-2.1.2-Linux/bin/iqtree2"

amas="/home/aknyshov/alex_data/andromeda_tools/AMAS/amas/AMAS.py"


#featureslist=(Fong_features Liu_features Wickett_features)
#for i in  ${featureslist[@]}
for i in Liu_features
do
	cd ${i}/iqtree_concattree
	pwd
        files=$(cat $(sed -n p ../alignmentGroups/array_list.txt | awk '{print "../alignmentGroups/"$0}') | awk '{print "../alignments3/"$0}' | paste -sd" ")
        echo ${files} 
        echo "Running AMAS"
	python3 ${amas} concat -f fasta -d dna --out-format fasta --part-format raxml -i ${files} -t concatenated.fasta -p partitions.txt
	${iqtree_exe} -nt 20 -s concatenated.fasta -spp partitions.txt -pre inference -m MFP -bb 1000 -alrt 1000


	cd ../../
	
done
date
