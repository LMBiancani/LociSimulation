#!/bin/bash
#SBATCH --job-name="prep"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G



date

cd ../datasets/McGowen_alignments

python3 /home/aknyshov/alex_data/andromeda_tools/AMAS/amas/AMAS.py split -d dna -f phylip -i DATASET_A.phylip -l partitions.txt -u fasta
