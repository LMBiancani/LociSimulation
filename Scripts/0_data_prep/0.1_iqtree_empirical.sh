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

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

# Number of cpus per task:
Threads=${SLURM_CPUS_PER_TASK}

module purge

date
mkdir -p $out0_1
cd $out0_1

# --- Check for input files produced by 0.0_amas_concat.sh---

if [[ ! -f "$out0_0/concatenated.fasta" || ! -f "$out0_0/partitions.txt" ]]; then
    echo "Error: concatenated.fasta or partitions.txt not found in ${out0_0}"
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

${IQTREE} -nt AUTO -ntmax ${Threads} \
    -s "$out0_0/concatenated.fasta" \
    -spp "$out0_0/partitions.txt" \
    -pre inferenceEmpirical \
    -m MFP -mset GTR -cmax 8 \
    -bb 1000 -alrt 1000

date
