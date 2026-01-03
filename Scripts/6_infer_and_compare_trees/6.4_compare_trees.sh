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
ResultsCSV="High_Sensitivity_Accuracy_Report.csv"
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

# --- Dynamic Argument Builder ---
CMD_ARGS=("$Truth" "$TaxonMap" "$ResultsCSV")

GROUPS=(
    "unfiltered_ultrametric.tre|Unfiltered_Baseline"
    "All_pass_ultrametric.tre|Elite_Both_Pass"
    "All_fail_ultrametric.tre|Noisy_Both_Fail"
    "S3_Clades_pass_ultrametric.tre|S3_Clades_Pass"
    "S3_Clades_fail_ultrametric.tre|S3_Clades_Fail"
    "S4_BLC_pass_ultrametric.tre|S4_BLC_Pass"
    "S4_BLC_fail_ultrametric.tre|S4_BLC_Fail"
    "S3_pass_S4_fail_ultrametric.tre|S3p_S4f_Discordant"
    "S4_pass_S3_fail_ultrametric.tre|S4p_S3f_Discordant"
    "Fail_at_least_one_ultrametric.tre|Liberal_Filter"
    "Pass_at_least_one_ultrametric.tre|Conservative_Filter"
)

for entry in "${GROUPS[@]}"; do
    FILE="${entry%%|*}"
    LABEL="${entry##*|}"
    if [ -f "$UltraDir/$FILE" ]; then
        CMD_ARGS+=("$UltraDir/$FILE" "$LABEL")
    fi
done

# --- Execute Comparison ---
Rscript "$Scripts6/compare_trees.R" "${CMD_ARGS[@]}"

echo "6.4 Comparison complete. Results in $FinalOut/$ResultsCSV"
