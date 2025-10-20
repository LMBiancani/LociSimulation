#!/bin/bash
#SBATCH --job-name="prep"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G



date


pwd


cd McGowen_features
pwd     


cp ../../datasets/McGowen_alignments/*fas alignments2/

