#!/bin/bash
#SBATCH --job-name="IQTREE"
#SBATCH --time=96:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=250G
#SBATCH -p uri-cpu
#SBATCH --mail-user="biancani@uri.edu" #CHANGE THIS to your user email address
#SBATCH --mail-type=ALL

# --- Variables ---
# Path to project directory:
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
# Path to output directory
Output="$Project/output/mammals"
# Path to IQTREE executable:
IQTREE="/project/pi_rsschwartz_uri_edu/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"
# Path to output files from 0.0_amas_concat.sh
Input="$Output/0.0_concatenated"
# Number of cpus per task:
Threads=${SLURM_CPUS_PER_TASK}

module purge

date
mkdir -p ${Output}/0.1_empirical_tree
cd ${Output}/0.1_empirical_tree

# --- Check for input files produced by 0.0_amas_concat.sh---

if [[ ! -f "$Input/concatenated.fasta" || ! -f "$Input/partitions.txt" ]]; then
    echo "Error: concatenated.fasta or partitions.txt not found in ${Input}"
    exit 1
fi

# --- Run IQ-TREE ---
# Flags:
#   -nt: number of CPU threads
#   -spp: partition file allowing different evolutionary rates per partition
#   -pre: prefix for output files
#   -m MFP: ModelFinder Plus for best-fit model selection
#   -bb: ultrafast bootstrap replicates
#   -alrt: SH-like approximate likelihood test replicates

${IQTREE} -nt ${Threads} \
    -s $Input/concatenated.fasta \
    -spp $Input/partitions.txt \
    -pre inferenceEmpirical \
    -m MFP -bb 1000 -alrt 1000

date

