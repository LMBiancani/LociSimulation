#!/bin/bash
#SBATCH --job-name="IQout"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=8G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE THIS to your user email address
#SBATCH --mail-type=ALL

## UPDATE as needed...
# path to Project Directory:
PROJECT=/data/schwartzlab/Biancani/FilterByKnownClades
# path to data directory:
DATA=$PROJECT/data
# Dataset name:
DATASET="Fong"
# Gene tree type (Constrained or Unconstrained)
GTT="Unconstrained"
# path to output folder:
OUTPUT=$PROJECT/output/$DATASET
# name of iqtree array work folder (will be created if doesn't exist):
array_work_folder=$OUTPUT/iqtree_assessment
# path to gene Trees
GTREES=$array_work_folder/GeneTrees$GTT

cd $GTREES

date
( > gtrees.txt; cat $array_work_folder/array_list.txt | while read line1; do cat $array_work_folder/${line1} >> gtrees.txt; done )
( > gtrees.tre; cat gtrees.txt | while read line; do cat ./inference_${line}.treefile >> gtrees.tre; done )
date

