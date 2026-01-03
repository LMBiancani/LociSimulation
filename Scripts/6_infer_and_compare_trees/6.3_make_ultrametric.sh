#!/bin/bash
#SBATCH --job-name="6.3_ultrametric"
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH -p uri-cpu
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Output="$Project/output/mammals"
Scripts="$Project/LociSimulation/Scripts"
Scripts6="$Scripts/6_infer_and_compare_trees"

# Output directory
OutDir="$Output/6.3_ultrametric_trees"
mkdir -p ${OutDir}

# Outgroup (same as 1.1)
outgroup="Wallabia_bicolor,Potorous_gilbertii,Pseudochirops_corinnae,Gymnobelideus_leadbeateri,Phalanger_gymnotis,Vombatus_ursinus,Phascolarctos_cinereus,Thylacinus_cynocephalus,Sarcophilus_harrisii,Didelphis_virginiana"

# --- Environment ---
module purge
module load uri/main
module load foss/2024a
module load R/4.3.2-gfbf-2023a

export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH
export R_LIBS=~/R-packages

# --- Process all trees in 6.0 and 6.2 ---

# 1. Process Unfiltered Baseline
Rscript $Scripts6/make_ultrametric.R \
    "$Output/6.0_unfiltered_tree/2000_loci_ref_tree.treefile" \
    "$OutDir/unfiltered_ultrametric.tre" \
    "$outgroup"

# 2. Process Subset Trees from 6.2
SubsetGroups=("All_pass" "All_fail" "S3_Clades_pass" "S3_Clades_fail" "S4_BLC_pass" "S4_BLC_fail")

for TargetSubset in "${SubsetGroups[@]}"; do
    echo "DEBUG: TargetSubset is currently: $TargetSubset"
    # This path must match exactly where 6.2 is currently writing its output
    INPUT_TREE="$Output/6.2_subset_trees/$TargetSubset/${TargetSubset}_tree.treefile"
    OUTPUT_TREE="$OutDir/${TargetSubset}_ultrametric.tre"
        
    if [ -f "$INPUT_TREE" ]; then
        echo "Processing $TargetSubset..."
        Rscript $Scripts6/make_ultrametric.R "$INPUT_TREE" "$OUTPUT_TREE" "$outgroup"
    else
        echo "Warning: $INPUT_TREE not found. Check if 6.2 has finished for this group."
    fi
done

echo "6.3: All trees converted to ultrametric format."
