#!/bin/bash
#SBATCH --job-name="6.4_RF_compare"
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
Scripts6="$Project/LociSimulation/Scripts/6_infer_and_compare_trees"

# 1. Paths to Truth
Truth="$Output/1.1_formatted_empirical_tree/s_tree.trees"
TaxonMap="$Output/1.1_formatted_empirical_tree/taxon_map.csv"
UltraDir="$Output/6.3_ultrametric_trees"
ResultsCSV="High_Sensitivity_Accuracy_Report.csv"
FinalOut="$Output/6.4_comparisons"

mkdir -p "$FinalOut"
cd "$FinalOut"

# --- 2. Safety Check for Required Files ---
echo "--- Initializing Safety Checks ---"
if [ ! -f "$Truth" ]; then echo "ERROR: Truth tree not found at $Truth"; exit 1; fi
if [ ! -f "$TaxonMap" ]; then echo "ERROR: Taxon map not found at $TaxonMap"; exit 1; fi
if [ ! -d "$UltraDir" ]; then echo "ERROR: Directory $UltraDir does not exist"; exit 1; fi

# --- Environment ---
module purge
module load uri/main
# Use the toolchain that R was built with (gfbf/2023a)
module load R/4.3.2-gfbf-2023a

# Maintain your library and library-path exports
export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH
export R_LIBS=~/R-packages

# --- 3. Dynamic Argument Builder (Bulletproof Version) ---
CMD_ARGS=("$Truth" "$TaxonMap" "$ResultsCSV")
found_count=0

# Define filenames
FILES=(
    "unfiltered_ultrametric.tre"
    "All_pass_ultrametric.tre"
    "All_fail_ultrametric.tre"
    "S3_Clades_pass_ultrametric.tre"
    "S3_Clades_fail_ultrametric.tre"
    "S4_BLC_pass_ultrametric.tre"
    "S4_BLC_fail_ultrametric.tre"
    "S3_pass_S4_fail_ultrametric.tre"
    "S4_pass_S3_fail_ultrametric.tre"
    "Fail_at_least_one_ultrametric.tre"
    "Pass_at_least_one_ultrametric.tre"
)

# Define labels in the EXACT same order
LABELS=(
    "Unfiltered_Baseline"
    "Elite_Both_Pass"
    "Noisy_Both_Fail"
    "S3_Clades_Pass"
    "S3_Clades_Fail"
    "S4_BLC_Pass"
    "S4_BLC_Fail"
    "S3p_S4f_Discordant"
    "S4p_S3f_Discordant"
    "Liberal_Filter"
    "Conservative_Filter"
)

# Iterate using an index
for i in "${!FILES[@]}"; do
    FILE="${FILES[$i]}"
    LABEL="${LABELS[$i]}"
    FULL_PATH="$UltraDir/$FILE"
    
    if [ -f "$FULL_PATH" ]; then
        echo "Adding to comparison: $LABEL"
        CMD_ARGS+=("$FULL_PATH" "$LABEL")
        ((found_count++))
    else
        echo "MISSING: $FILE"
    fi
done

if [ "$found_count" -eq 0 ]; then
    echo "FATAL ERROR: No trees found. Paths checked: $UltraDir"
    exit 1
fi

# --- 4. Execute Comparison ---
echo "--- Running R Comparison Script with $found_count trees ---"
Rscript "$Scripts6/compare_trees.R" "${CMD_ARGS[@]}"

echo "6.4 Comparison complete."
