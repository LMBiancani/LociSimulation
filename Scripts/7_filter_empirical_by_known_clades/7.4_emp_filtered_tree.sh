#!/bin/bash
#SBATCH --job-name="7.4_emp_tree"
#SBATCH --time=96:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=115G
#SBATCH -p uri-cpu
#SBATCH --constraint=avx512
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# Source master parameters script

vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source "$vars"
echo "Variables sourced into current shell environment:"
cat "$vars"

# Output directory:
WorkDir="$out7_4"
FinalTree="$WorkDir/emp_filtered_tree.treefile"

# Check if target tree already exists
if [ -f "$FinalTree" ]; then
    echo "Final tree already exists at: $FinalTree"
    echo "Exiting to avoid overwriting."
    exit 0
fi

# Validation: Verify input directory contains files
if [ ! -d "$in7_4" ]; then
    echo "ERROR: Input directory $in7_4 not found."
    exit 1
fi

mkdir -p "$WorkDir"
cd "$WorkDir" || exit 1

# Environment Setup

module purge
module load uri/main Python/3.7.4-GCCcore-8.3.0

echo "Starting AMAS concatenation for empirical passing loci at $(date)"
echo "Input alignments directory: $in7_4"
echo "Working directory: $WorkDir"

# 1. Run AMAS Concatenation

# Calculate relative path to prevent ARG_MAX buffer overflows
REL_IN=$(realpath --relative-to="." "$in7_4")

python3 "$run_amas" "$REL_IN" "${SLURM_CPUS_PER_TASK}" "${AMAS}" > amas_concat.log 2>&1

if [ ! -f "concatenated.fasta" ] || [ ! -f "partitions.txt" ]; then
    echo "ERROR: AMAS failed to create concatenated.fasta or partitions.txt in $WorkDir"
    cat amas_concat.log
    exit 1
fi

echo "Concatenation complete at $(date). Clean partitions created."

# 2. Run IQ-TREE Inferences

# Phase 1: Fast starting tree generation
echo "Phase 1: Inferring starting guide tree..."
"$IQTREE" -nt AUTO -ntmax "${SLURM_CPUS_PER_TASK}" \
          -s "concatenated.fasta" \
          -pre StartTree \
          -m GTR+G -fast

if [ ! -f "StartTree.treefile" ]; then
    echo "ERROR: Phase 1 failed. StartTree.treefile was not created."
    exit 1
fi

# Phase 2: Full partitioned analysis using guide tree
echo "Phase 2: Running partitioned inference with MFP and support metrics..."
"$IQTREE" -nt AUTO -ntmax "${SLURM_CPUS_PER_TASK}" \
          -s "concatenated.fasta" \
          -spp "partitions.txt" \
          -pre emp_filtered_tree \
          -t StartTree.treefile \
          -m MFP -mset GTR -cmax 8 \
          -bb 1000 -alrt 1000

echo "Step 7.4 complete at $(date). Final tree saved to: $FinalTree"
