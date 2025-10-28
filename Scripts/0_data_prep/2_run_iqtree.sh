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
# Path to scripts directory:
Scripts="$Project/LociSimulation/Scripts"
# Path to output directory
Output="$Project/output/mammals"
# Path to IQTREE executable:
IQTREE="/project/pi_rsschwartz_uri_edu/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"

module purge
Threads=${SLURM_CPUS_PER_TASK}

date
cd ${Output}

# --- Check input files ---
if [[ ! -f "concatenated.fasta" || ! -f "partitions.txt" ]]; then
    echo "Error: concatenated.fasta or partitions.txt not found in ${Output}"
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
    -s concatenated.fasta \
    -spp partitions.txt \
    -pre inferenceEmpirical \
    -m MFP -bb 1000 -alrt 1000

date
