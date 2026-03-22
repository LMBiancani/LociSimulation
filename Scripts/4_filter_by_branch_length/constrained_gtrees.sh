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

random_seed=$1
echo "Random number seed = $random_seed"
dir_name="set_$random_seed"

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

# --- Variables ---
# Input (final named alignments from 2.4)
Alignments="$out2_4/$dir_name"
# The Reference Tree from Step 4.0:
RefTree="$out4_0/$dir_name/Unfiltered_loci_ref_tree.treefile"
MODEL_FILE="$out4_0/$dir_name/Unfiltered_loci_ref_tree.iqtree"

# Output
OutDir="$out4_1/$dir_name"
mkdir -p "$OutDir"

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
    trimconstraint_R=$5
    model_info_file=$6

    # Optional: add this right before the Rscript line to stagger starts (preventing library loading issues)
    sleep $(( (RANDOM % 5) + 1 ))

    # 1. Prune the reference tree to match this locus
    Rscript "$trimconstraint_R" "$locus_fas" "$ref_tree" "$out_path/${locus_id}.constraint.tre"

    # 2. Look up the specific model for this locus from the BIC summary block
        # We turn the comma-separated list into lines, find the locus, and grab the model part
        SPECIFIC_MODEL=$(grep -A 100 "Best-fit model according to BIC:" "$model_info_file" | \
                         grep -m 1 -v "BIC:" | \
                         tr ',' '\n' | \
                         grep -w "$locus_id" | \
                         cut -d ":" -f 1 | \
                         tr -d '[:space:]')

        # Fallback to GTR+G if the lookup fails for any reason
        if [ -z "$SPECIFIC_MODEL" ]; then SPECIFIC_MODEL="GTR+G"; fi

    # 3. Run IQ-TREE constrained to that pruned topology
    $iqtree_exe -s "$locus_fas" -m "$SPECIFIC_MODEL" -g "$out_path/${locus_id}.constraint.tre" -pre "$out_path/${locus_id}" -nt 1 -redo

    # Cleanup auxiliary files
    rm -f "$out_path/${locus_id}."{ckp.gz,bionj,mldist,log}
}

export -f run_constrained_inference

# --- Execute with GNU Parallel ---
echo "Starting constrained branch length estimation..."
find "$Alignments" -name "*.fas" | parallel -j 32 --progress run_constrained_inference {} "$OutDir" "$RefTree" "$IQTREE" "$TCT" "$MODEL_FILE"
echo "Step 4.1 complete. Constrained trees are in $OutDir"
