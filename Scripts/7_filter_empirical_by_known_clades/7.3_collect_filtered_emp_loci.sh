#!/bin/bash
#SBATCH --job-name=7.3_filter_emp
#SBATCH --partition=uri-cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
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

# Input & Output Paths

# Input LRT results CSV from Step 7.2:
LRT_CSV="$out7_2/emp_lrt_results.csv"

# Original empirical alignments directory:
Alignments="$DATA"

# Destination directory for partitioned pass/fail empirical alignments:
FinalDir="$out7_3"
mkdir -p "$FinalDir"

P_THRESH="${Pvalue7_3:-0.05}"

echo "Starting empirical locus collection at $(date)"
echo "Input CSV:      $LRT_CSV"
echo "Alignments:     $Alignments"
echo "Destination:    $FinalDir"
echo "Threshold:      p >= $P_THRESH"

# Execute Partitioning

# Reusing collect_filtered_loci.R directly from Step 3 via $CFL
Rscript "$CFL" "$LRT_CSV" "$Alignments" "$FinalDir" "$P_THRESH"

echo "Collection complete at $(date)"
echo "------------------------------------------------"
echo "Post-Processing Audit:"
echo "Pass count: $(find "$FinalDir/pass_${P_THRESH}" -maxdepth 1 -regextype posix-extended -regex '.*\.(fas|fa|fasta)$' | wc -l)"
echo "Fail count: $(find "$FinalDir/fail_${P_THRESH}" -maxdepth 1 -regextype posix-extended -regex '.*\.(fas|fa|fasta)$' | wc -l)"
echo "------------------------------------------------"
