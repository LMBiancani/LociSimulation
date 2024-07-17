#!/bin/bash
#SBATCH --job-name="IQ_CatTree"
#SBATCH --time=96:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=24   # processor core(s) per node
#SBATCH --mem=100G
#SBATCH --exclusive
#SBATCH --mail-user="biancani@uri.edu" #CHANGE THIS to your user email address
#SBATCH --mail-type=ALL

## UPDATE as needed...
# path to Project Directory:
PROJECT=/data/schwartzlab/Biancani/FilterByKnownClades
# path to data directory:
DATA=$PROJECT/data
# Dataset name:
DATASET="Fong"
# path to aligned loci:
aligned_loci_path=$DATA/$DATASET/simulated_loci
# path to output folder (will be created if doesn't exits):
OUTPUT=$PROJECT/output/$DATASET/iqtree_assessment/CatTree_Unfiltered
# path to iqtree executable:
iqtree_exe="/data/schwartzlab/alex/andromeda_tools/iqtree-2.1.2-Linux/bin/iqtree2"
# path to AMAS.py
amas_py="/home/aknyshov/alex_data/andromeda_tools/AMAS/amas/AMAS.py"

mkdir -p $OUTPUT
cd $OUTPUT
date

#Concatenate input fasta files and prepare partitions ahead of IQTree run
python3 $amas_py concat -f fasta -d dna --out-format fasta --part-format raxml -i $aligned_loci_path/*fas -c 24 -t concatenated_loci.fasta -p partitions.txt

#Run IQtree. Flags: -nt: use 24 CPU cores -spp: specifies partition file but allows partitions to have different evolutionary speeds -pre: specifies prefix for output files -m: determine best fit model immediately followed by tree reconstruction -bb: sets 1000 bootstrap replicates  -alrt: sets 1000 replicates to perform SH-like approximate likelihood test (SH-aLRT)
${iqtree_exe} -nt 24 -s concatenated_loci.fasta -spp partitions.txt -pre unfiltered_loci -m MFP -bb 1000 -alrt 1000

date

