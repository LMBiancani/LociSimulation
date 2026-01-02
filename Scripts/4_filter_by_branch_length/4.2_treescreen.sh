#!/bin/bash
#SBATCH --job-name=BLC_screen
#SBATCH --partition=uri-cpu
#SBATCH --time=00:20:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=8G
#SBATCH --constraint=avx512
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Scripts="$Project/LociSimulation/Scripts/"
Scripts4="$Scripts/4_filter_by_branch_length"
Output="$Project/output/mammals"

# Inputs
RefTree="$Output/4.0_unfiltered_concat_tree/2000_loci_ref_tree.treefile"
Gtrees="$Output/4.1_constrained_gtrees"
Alignments="$Output/2.4_final_named_alignments"

# Output subdirectories
OutDir="$Output/4.2_BLC_filtered"
mkdir -p "$OutDir/pass_loci"
mkdir -p "$OutDir/fail_loci"

# --- Environment ---
module purge
module load uri/main
module load foss/2024a
module load R/4.3.2-gfbf-2023a

export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH
export R_LIBS=~/R-packages

# --- Execute R Screening ---
echo "Calculating Branch Length Correlations..."
Rscript "$Scripts4/treescreen.R" "$RefTree" "$Gtrees" "$OutDir/blc_results.csv"

# --- Assemble Filtered Datasets ---
echo "Sorting alignments into pass/fail directories..."

# Use tail to skip CSV header, IFS to parse columns
while IFS=, read -r locus slope rsq status; do
    # Remove possible carriage returns or quotes
    locus=$(echo $locus | tr -d '"\r')
    status=$(echo $status | tr -d '"\r')
    
    if [ "$status" == "Pass" ]; then
        cp "$Alignments/${locus}.fas" "$OutDir/pass_loci/"
    elif [ "$status" == "Fail" ]; then
        cp "$Alignments/${locus}.fas" "$OutDir/fail_loci/"
    fi
done < <(tail -n +2 "$OutDir/blc_results.csv")

echo "Process complete. Final alignments are in $OutDir/pass_loci"
date
