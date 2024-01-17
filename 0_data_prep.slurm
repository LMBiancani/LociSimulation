#!/bin/bash
#SBATCH --job-name="data_prep"
#SBATCH --time=120:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=36   # CHANGE THIS to the number of processors
#SBATCH --mail-user=alexandra.walling@uri.edu #CHANGE THIS to your user email address
#SBATCH --mail-type=ALL
#SBATCH --exclusive

cd $SLURM_SUBMIT_DIR
#rm -rf datasets
#mkdir datasets

#cp -R /data/schwartzlab/alex/ML/datasets/Brown_Thomson/Fong/fasta_alignments/ datasets/

cp -R /data/schwartzlab/alex/ML/datasets/Cetacea/DATASET_A.phylip datasets/

#cp -R /data/schwartzlab/alex/ML/datasets/Liu/fasta_alignments/ datasets/
cp -R /data/schwartzlab/alex/ML/datasets/Liu/fasta_alignments/ datasets/
#cp -R /data/schwartzlab/alex/ML/datasets/Wickett.zip /datasets

#cp -R /data/schwartzlab/alex/ML/datasets/plant_dataset/c1c2_f25/ datasets/
