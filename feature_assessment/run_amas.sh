#!/bin/bash
#SBATCH --job-name="amas"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=12   # processor core(s) per node

module purge
module load Python/3.7.4-GCCcore-8.3.0
amas="/home/aknyshov/alex_data/andromeda_tools/AMAS/amas/AMAS.py"
cores=12

cd $SLURM_SUBMIT_DIR
date

python ${amas} summary -c ${cores} -o amas_output2.txt -f fasta -d dna -i alignments2/*.fas 
python ${amas} summary -c ${cores} -o amas_output3.txt -f fasta -d dna -i alignments3/*.fas 

date
