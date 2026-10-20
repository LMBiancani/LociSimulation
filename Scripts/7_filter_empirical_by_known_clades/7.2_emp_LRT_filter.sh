#!/bin/bash
#SBATCH --job-name=7.2_emp_LRT
#SBATCH --partition=uri-cpu
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
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
module load R/4.3.2-gfbf-2023a

export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH
export R_LIBS=~/R-packages

# Input & Output Directories

# Input directory containing ~109k _uncon.iqtree and _con.iqtree files (from Step 7.1):
IQ_DIR="$out7_1"

# Output directory for the aggregated empirical LRT CSV:
OutDir="$out7_2"
mkdir -p "$OutDir"

OUT_FILE="$OutDir/emp_lrt_results.csv"

# Execute LRT Extraction

echo "Running Likelihood Ratio Test parsing on empirical loci in: $IQ_DIR"
date

Rscript "$LRTfilter" "$IQ_DIR" "$OUT_FILE"

date
echo "Empirical LRT filter complete. Output written to: $OUT_FILE"
