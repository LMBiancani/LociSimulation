#!/bin/bash
#SBATCH --job-name="IQprep"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --mail-user="biancani@uri.edu" #CHANGE THIS to your user email address
#SBATCH --mail-type=ALL
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G

## UPDATE as needed...
# path to Project Directory:
PROJECT=/data/schwartzlab/Biancani/FilterByKnownClades
# path to data directory:
DATA=$PROJECT/data
# path to IQtree scripts:
scripts_dir=$PROJECT/01_iqtree
# path to aligned loci:
aligned_loci_path=$DATA/Fong/simulated_loci
# path to output folder (will be created if doesn't exist):
OUTPUT=$PROJECT/output/Fong/
# name of iqtree array work folder (will be created if doesn't exist):
array_work_folder=iqtree_assessment

mkdir -p $OUTPUT
cd $OUTPUT
mkdir -p ${array_work_folder}
cd ${array_work_folder}
mkdir scf
ls ${aligned_loci_path} | rev | cut -f1 -d/ | rev | split - aligned_loci_list_
arrayN=$(ls aligned_loci_list_* | wc -l)
ls aligned_loci_list_* > array_list.txt
ARRAY="sbatch --array=1-${arrayN}%40 ${scripts_dir}iqtree_array.sh"
echo $ARRAY 
echo $ARRAY >> array_command.txt

