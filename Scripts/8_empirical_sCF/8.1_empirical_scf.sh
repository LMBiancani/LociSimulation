#!/bin/bash
#SBATCH --job-name="8.0_emp_scf"
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=64G
#SBATCH -p uri-cpu
#SBATCH --constraint=avx512
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# Source master parameters script
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source "$vars"
echo "Variables sourced into current shell environment:"
cat "$vars"

# Environment Setup
module purge
module load uri/main
module load foss/2024a

# Output working directory
WorkDir="$out8_0"
mkdir -p "$WorkDir"
cd "$WorkDir" || exit 1

echo "Starting Empirical sCF calculations at $(date)"
echo "Working directory: $WorkDir"

# 1. Unfiltered Dataset sCF Calculation
echo "----------------------------------------------------------------"
echo "1. Calculating sCF for UNFILTERED empirical tree (Step 0.1)"
echo "Tree:      $Tree_Unfiltered"
echo "Alignment: $Aln_Unfiltered"
echo "----------------------------------------------------------------"

if [[ ! -f "$Tree_Unfiltered" || ! -f "$Aln_Unfiltered" ]]; then
    echo "ERROR: Unfiltered tree or alignment file not found!"
    exit 1
fi

"$IQTREE" -te "$Tree_Unfiltered" \
          -s "$Aln_Unfiltered" \
          --scf 100 \
          -nt "${SLURM_CPUS_PER_TASK}" \
          --prefix "unfiltered_scf" \
          -redo

# ------------------------------------------------------------------------------
# 2. Filtered Dataset sCF Calculation
# ------------------------------------------------------------------------------
echo "----------------------------------------------------------------"
echo "2. Calculating sCF for FILTERED empirical tree (Step 7.4)"
echo "Tree:      $Tree_Filtered"
echo "Alignment: $Aln_Filtered"
echo "----------------------------------------------------------------"

if [[ ! -f "$Tree_Filtered" || ! -f "$Aln_Filtered" ]]; then
    echo "ERROR: Filtered tree or alignment file not found!"
    exit 1
fi

"$IQTREE" -te "$Tree_Filtered" \
          -s "$Aln_Filtered" \
          --scf 100 \
          -nt "${SLURM_CPUS_PER_TASK}" \
          --prefix "filtered_scf" \
          -redo

echo "Step 8.0 complete at $(date)."
echo "Output files saved in: $WorkDir"
