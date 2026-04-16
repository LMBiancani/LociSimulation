#!/bin/bash
#SBATCH --job-name="6.4_RF_compare"
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=8G
#SBATCH -p uri-cpu
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL
  
random_seed=$1
echo "Random number seed = $random_seed"
dir_name="set_$random_seed"

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

# 1. Paths to Trees
SimTrees="$out6_3/$dir_name/"
ResultsCSV="Tree_Comparison_Report.csv"
FinalOut="$out6_4/$dir_name"

mkdir -p "$FinalOut"
cd "$FinalOut"

# --- 2. Safety Check for Required Files ---
echo "--- Initializing Safety Checks ---"
if [ ! -f "$Truth" ]; then echo "ERROR: Truth tree not found at $Truth"; exit 1; fi
if [ ! -f "$Taxon_Map" ]; then echo "ERROR: Taxon map not found at $Taxon_Map"; exit 1; fi
if [ ! -d "$SimTrees" ]; then echo "ERROR: Directory $SimTrees does not exist"; exit 1; fi

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
CMD_ARGS=("$Truth" "$Taxon_Map" "$ResultsCSV")
found_count=0

# Define filenames
FILES=(
    "Unfiltered_all_Loci.treefile"
    "all_PASS.treefile"
    "all_FAIL.treefile"
    "clades_PASS.treefile"
    "clades_FAIL.treefile"
    "blc_PASS.treefile"
    "blc_FAIL.treefile"
    "clades_PASS_blc_FAIL.treefile"
    "blc_PASS_clades_FAIL.treefile"
    "FAIL_at_least_one.treefile"
    "PASS_at_least_one.treefile"
)

# Define labels in the EXACT same order
LABELS=(
    "Unfiltered_Baseline"
    "Elite_all_PASS"
    "Noisy_all_FAIL"
    "clades_PASS"
    "clades_FAIL"
    "blc_PASS"
    "blc_FAIL"
    "clades_PASS_blc_FAIL"
    "blc_PASS_clades_FAIL"
    "FAIL_at_least_one"
    "PASS_at_least_one"
)

# Iterate using an index
for i in "${!FILES[@]}"; do
    FILE="${FILES[$i]}"
    LABEL="${LABELS[$i]}"
    FULL_PATH="$SimTrees/$FILE"

    if [ -f "$FULL_PATH" ]; then
        echo "Adding to comparison: $LABEL"
        CMD_ARGS+=("$FULL_PATH" "$LABEL")
        ((found_count++))
    else
        echo "MISSING: $FILE"
    fi
done

if [ "$found_count" -eq 0 ]; then
    echo "FATAL ERROR: No trees found. Paths checked: $SimTrees"
    exit 1
fi

# --- 4. Execute Comparison ---
echo "--- Running R Comparison Script with $found_count trees ---"
Rscript "$CompTreeR" "${CMD_ARGS[@]}"

echo "6.4 Comparison complete."
