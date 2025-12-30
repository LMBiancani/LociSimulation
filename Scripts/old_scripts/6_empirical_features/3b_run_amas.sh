#!/bin/bash
#SBATCH --job-name="amas"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=20   # processor core(s) per node

all/Biopython/1.83-foss-2023b 
date
pwd
python3 trim_empty_alignments.py 
