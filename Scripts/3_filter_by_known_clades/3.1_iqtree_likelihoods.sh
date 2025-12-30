#!/bin/bash
#SBATCH --job-name=iqtree
#SBATCH --partition=uri-cpu
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=30
#SBATCH --cpus-per-task=1
#SBATCH --mem=30G
#SBATCH --constraint=avx512
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Alignments="$Project/output/mammals/2.4_final_named_alignments"
Constraints="$Project/output/mammals/3.0_constraint_trees"
# Path to IQTREE executable:
IQTREE="/project/pi_rsschwartz_uri_edu/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"

OutDir="$Project/output/mammals/3.1_likelihoods"
mkdir -p "$OutDir"

# --- Environment Setup ---
module purge
module load uri/main
module load foss/2024a
module load parallel/20240822

# --- Command Factory Logic ---
run_iqtree() {
    locus_fas=$1
    locus_id=$(basename "$locus_fas" .fas)
    out_path=$2
    const_path=$3
    iqtree_exe=$4  # Receive the path variable here
    
    # 1. Unconstrained Run
    $iqtree_exe -s "$locus_fas" -m GTR+G -pre "$out_path/${locus_id}_uncon" -nt 1 -redo
    
    # 2. Constrained Run
    $iqtree_exe -s "$locus_fas" -m GTR+G -g "$const_path/${locus_id}_constraint.newick" -pre "$out_path/${locus_id}_con" -nt 1 -redo
    
    # Cleanup auxiliary files
    rm -f "$out_path/${locus_id}_"*".ckp.gz" "$out_path/${locus_id}_"*".bionj" "$out_path/${locus_id}_"*".mldist"
}

export -f run_iqtree

# --- Execute with GNU Parallel ---
# We pass $IQTREE as the 4th argument to the function
ls "$Alignments"/*.fas | parallel -j 30 --progress run_iqtree {} "$OutDir" "$Constraints" "$IQTREE"

echo "IQ-TREE inferences complete. Likelihoods saved in $OutDir"
