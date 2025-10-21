#!/bin/bash
#SBATCH --job-name="AMAS"
#SBATCH --time=2:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH -p uri-cpu
#SBATCH --mail-user="biancani@uri.edu" #CHANGE THIS to your user email address
#SBATCH --mail-type=ALL

# --- Variables ---
# Path to project directory:
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
# Path to scripts directory:
Scripts="$Project/LociSimulation/Scripts/0_data_prep"
# Path to output directory (will be created if necessary)
Output="$Project/output/mammals"
# Path to aligned loci in fasta format:
Data="$Project/mammal_loci/01_SISRS_loci_filtered"
# Path to AMAS executable:
AMAS="/project/pi_rsschwartz_uri_edu/Biancani/Software/AMAS/amas/AMAS.py"
# Number of processor cores per node:
Cores=$(echo $SLURM_TASKS_PER_NODE | sed 's/(x.*)//')

module purge
module load uri/main Python/3.7.4-GCCcore-8.3.0

date
mkdir -p ${Output}
cd ${Output}

#Concatenate input fasta files and prepare partitions ahead of IQTree run
python3 ${Scripts}/run_amas.py ${Data} ${Cores} ${AMAS}

date
