#!/bin/bash
#SBATCH --job-name=BLC_gtrees
#SBATCH --partition=uri-cpu
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --constraint=avx512
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Scripts="$Project/LociSimulation/Scripts/"
Scripts4="$Scripts/4_filter_by_branch_length"
Output="$Project/output/mammals/"
# Path to IQTREE executable:
IQTREE="/project/pi_rsschwartz_uri_edu/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"

# Inputs
Alignments="$Output/2.4_final_named_alignments"
# The Reference Tree from Step 4.0:
RefTree="$Output/4.0_unfiltered_concat_tree/2000_loci_ref_tree.treefile"

# Output
OutDir="$Output/4.1_constrained_gtrees"
mkdir -p "$OutDir"

# --- Extract the Model Name from 4.0 output ---
MODEL_FILE="$Output/4.0_unfiltered_concat_tree/2000_loci_ref_tree.iqtree"
GEN_MODEL=$(grep "Model of substitution:" "$MODEL_FILE" | cut -d ":" -f 2 | tr -d '[:space:]')

# Verify we actually got a model string
if [ -z "$GEN_MODEL" ]; then echo "Error: Model extraction failed"; exit 1; fi

# --- Environment ---
module purge
module load uri/main
module load foss/2024a
module load R/4.3.2-gfbf-2023a
module load parallel/20240822

export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH
export R_LIBS=~/R-packages

# --- Command Factory Logic ---
run_constrained_inference() {
    locus_fas=$1
    locus_id=$(basename "$locus_fas" .fas)
    out_path=$2
    ref_tree=$3
    iqtree_exe=$4
    script_dir=$5
    model_name=$6

    # Optional: add this right before the Rscript line to stagger starts (preventing library loading issues)
    sleep $(( (RANDOM % 5) + 1 ))

    # 1. Prune the reference tree to match this locus
    Rscript "$script_dir/trimConstraintTree.R" "$locus_fas" "$ref_tree" "$out_path/${locus_id}.constraint.tre"

    # 2. Run IQ-TREE constrained to that pruned topology
    $iqtree_exe -s "$locus_fas" -m "$model_name" -g "$out_path/${locus_id}.constraint.tre" -pre "$out_path/${locus_id}" -nt 1 -redo

    # Cleanup auxiliary files
    rm -f "$out_path/${locus_id}."{ckp.gz,bionj,mldist,log}
}

export -f run_constrained_inference

# --- Execute with GNU Parallel ---
echo "Starting constrained branch length estimation..."
find "$Alignments" -name "*.fas" | parallel -j 32 --progress run_constrained_inference {} "$OutDir" "$RefTree" "$IQTREE" "$Scripts4" "$GEN_MODEL"
echo "Step 4.1 complete. Constrained trees are in $OutDir"
