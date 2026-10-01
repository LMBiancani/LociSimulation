#!/bin/bash
#SBATCH --job-name=constraints
#SBATCH --partition=uri-cpu
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --constraint=avx512
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

# Input empirical alignments (from 0_data_prep):
Alignments=$DATA

# Output subdirectory for the constraint tree:
out_dir="$out7_0"
mkdir -p "$out_dir"

# --- Environment Setup ---
module purge
module load uri/main
module load foss/2024a
module load R/4.3.2-gfbf-2023a

export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH
export R_LIBS=~/R-packages

# --- Execute ---
Rscript $GenConR "$Alignments" "$out_dir" "$clades"

# --- Audit & Confirmation ---
echo "------------------------------------------------"
echo "Post-Processing Audit:"
expected_count=$(find "$Alignments" -maxdepth 1 -regextype posix-extended -regex '.*\.(fas|fa|fasta)$' | wc -l)
actual_count=$(find "$out_dir" -maxdepth 1 -name "*_constraint.newick" | wc -l)

echo "Expected constraints: $expected_count"
echo "Generated constraints: $actual_count"

if [ "$expected_count" -eq "$actual_count" ]; then
    echo "SUCCESS: All constraint files were generated correctly."
else
    echo "NOTICE: Count mismatch! Some loci may not have enough taxa to form a constraint."
fi
echo "------------------------------------------------"
