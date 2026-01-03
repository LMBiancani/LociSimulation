#!/bin/bash
#SBATCH --job-name="RF_compare"
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=8G
#SBATCH -p uri-cpu
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Output="$Project/output/mammals"
Scripts="$Project/LociSimulation/Scripts"
Scripts6="$Scripts/6_infer_and_compare_trees"

# 1. Paths to Truth (The formatted backbone from 1.1)
Truth="$Output/1.1_formatted_empirical_tree/s_tree.trees"
TaxonMap="$Output/1.1_formatted_empirical_tree/taxon_map.csv"

# 2. Path to the Ultrametric test trees from 6.3
UltraDir="$Output/6.3_ultrametric_trees"

# Output
ResultsCSV="RF_WeightedRF_Results.csv"
FinalOut="$Output/6.4_comparisons"
mkdir -p "$FinalOut"
cd "$FinalOut"

# --- Environment ---
module purge
module load uri/main
module load foss/2024a
module load R/4.3.2-gfbf-2023a

export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH
export R_LIBS=~/R-packages

# --- Execute Comparison ---
Rscript "$Scripts6/compare_trees.R" "$Truth" "$TaxonMap" "$ResultsCSV" \
    "$UltraDir/unfiltered_ultrametric.tre" "Unfiltered_Baseline" \
    "$UltraDir/All_pass_ultrametric.tre"    "All_Pass" \
    "$UltraDir/All_fail_ultrametric.tre"    "All_Fail" \
    "$UltraDir/S3_Clades_pass_ultrametric.tre" "S3_Clades_Pass" \
    "$UltraDir/S3_Clades_fail_ultrametric.tre" "S3_Clades_Fail" \
    "$UltraDir/S4_BLC_pass_ultrametric.tre"    "S4_BLC_Pass" \
    "$UltraDir/S4_BLC_fail_ultrametric.tre"    "S4_BLC_Fail"

echo "6.4 Comparison complete. Results located in $FinalOut/$ResultsCSV"
