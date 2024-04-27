#!/bin/bash
#SBATCH --job-name="IQconcat"
#SBATCH --time=172:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=2   # processor core(s) per node
#SBATCH -c 20
#SBATCH --mem=120G


cd $SLURM_SUBMIT_DIR

date

iqtree_exe="/home/aknyshov/alex_data/andromeda_tools/iqtree-2.1.2-Linux/bin/iqtree2"

amas="/home/aknyshov/alex_data/andromeda_tools/AMAS/amas/AMAS.py"

for i in  ../simulations/*/*/1/iqtree_concattree
do
	cd ${i}
	pwd
	filesTrain=$(cat $(sed -n 1,4p ../alignmentGroups/array_list.txt | awk '{print "../alignmentGroups/"$0}') | awk '{print "../alignments3/"$0}' | paste -sd" ")
	python3 ${amas} concat -f fasta -d dna --out-format fasta --part-format raxml -i ${filesTrain} -t concatenatedTrain.fasta -p partitionsTrain.txt
	${iqtree_exe} -nt 20 -s concatenatedTrain.fasta -spp partitionsTrain.txt -pre inferenceTrain -m MFP -bb 1000 -alrt 1000

	filesTest=$(cat $(sed -n 5,8p ../alignmentGroups/array_list.txt | awk '{print "../alignmentGroups/"$0}') | awk '{print "../alignments3/"$0}' | paste -sd" ")
	python3 ${amas} concat -f fasta -d dna --out-format fasta --part-format raxml -i ${filesTrain} -t concatenatedTest.fasta -p partitionsTest.txt
${iqtree_exe} -nt 20 -s concatenatedTest.fasta -spp partitionsTest.txt -pre inferenceTest -m MFP -bb 1000 -alrt 1000

	cd ../../../../../3_feature_assessment
	
done
date
