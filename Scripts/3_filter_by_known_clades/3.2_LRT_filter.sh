#!/bin/bash
#SBATCH --job-name=3.2_LRT_filter
#SBATCH --partition=uri-cpu
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --constraint=avx512
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Scripts="$Project/LociSimulation/Scripts/3_filter_by_known_clades"
Output="$Project/output/mammals"

# input (generate by 3.1_iqtree_likelihoods.sh)
IQ_DIR="$Output/3.1_likelihoods"

OutDir="$Output/3.2_lrt_results"
mkdir -p "$OutDir"
OUT_FILE="$OutDir/lrt_results.csv"

# --- Environment Setup (Proven Unity Config) ---
module purge
module load uri/main
module load foss/2024a
module load R/4.3.2-gfbf-2023a

export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH
export R_LIBS=~/R-packages

# --- Execute ---
Rscript $Scripts/LRT_filter.R "$IQ_DIR" "$OUT_FILE"
