#!/bin/bash
#SBATCH --job-name="unfiltered_tree"
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=62G
#SBATCH -p uri-cpu
#SBATCH --constraint=avx512
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Scripts="$Project/LociSimulation/Scripts"
Output="$Project/output/mammals/"
# Path to AMAS executable:
AMAS="/project/pi_rsschwartz_uri_edu/Biancani/Software/AMAS/amas/AMAS.py"
# Path to run_amas.py (from step 0.0)
amas_py="$Scripts/0_data_prep/run_amas.py"
# Path to IQTREE executable:
IQTREE="/project/pi_rsschwartz_uri_edu/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"

# Input
Data="$Output/2.4_final_named_alignments"

# Output directory
OutDir="$Output/4.0_unfiltered_concat_tree"
mkdir -p ${OutDir}
cd ${OutDir}

module purge
module load uri/main Python/3.7.4-GCCcore-8.3.0

# 1. Run the universal AMAS script
python3 $amas_py ${Data} ${SLURM_CPUS_PER_TASK} ${AMAS}

# 2. Run IQ-TREE on the result
$IQTREE -s concatenated.fasta \
    -m MFP \
    -nt ${SLURM_CPUS_PER_TASK} \
    -pre 2000_loci_ref_tree
    -bb 1000 #remove if necessary for speed (bootstraps not needed for BLC filtering)

# 2. (Alt) Run IQ-TREE on the result (with model specified)
#$IQTREE -s concatenated.fasta \
#    -m GTR+F+R8 \
#    -nt ${SLURM_CPUS_PER_TASK} \
#    -pre 2000_loci_ref_tree
#    -bb 1000 #remove if necessary for speed (bootstraps not needed for BLC filtering)
