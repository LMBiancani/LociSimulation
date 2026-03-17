#!/bin/bash
#SBATCH --job-name=indelible_para
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32        # Number of INDELible instances to run at once
#SBATCH --mem=4G
#SBATCH -p uri-cpu
#SBATCH --constraint=avx512
#SBATCH --time=00:20:00
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

# Input from 2.2:
tree_file="$out2_2/$dir_name/gene_trees.tre"
# Input from 2.0
df_file="$out2_0/$dir_name/df.csv"

# Output subdirectory:
indel_dir="$out2_3/$dir_name"
mkdir -p "$indel_dir"

# --- Environment Setup ---
module purge
module load uri/main
module load foss/2024a
module load R/4.3.2-gfbf-2023a
module load parallel/20240822
# Fix for the C++ library (GLIBCXX) errors:
export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH
# Point R to your custom package library
export R_LIBS=~/R-packages

# --- 1. Prep Control Files ---
# Ensure your R script creates 'control_1.txt' through 'control_2000.txt' in $indel_dir
echo "Generating 2,000 INDELible control files..."
# Passing: [1]tree_file [2]df_file [3]output_dir [4]mod_write_tree2 [5]modify_gene_tree
Rscript "$prepIND" \
    "$tree_file" \
    "$df_file" \
    "$indel_dir" \
    "$mod_write_tree2" \
    "$modify_gene_tree"

# --- 2. Parallel Execution ---
echo "Running INDELible in parallel across $SLURM_CPUS_PER_TASK cores..."
cd "$indel_dir"

# Generate a list of tasks for parallel
# We create a unique temporary folder for each locus to prevent control.txt collisions
for i in {1..2000}; do
    echo "mkdir -p tmp_$i && cp control_$i.txt tmp_$i/control.txt && cd tmp_$i && $indel_exe > /dev/null && mv output_TRUE.phy ../locus_$i.phy && cd .. && rm -rf tmp_$i"
done > indelible_tasks.txt

# Run the tasks
parallel --jobs $SLURM_CPUS_PER_TASK < indelible_tasks.txt

# --- 3. Post-Processing ---
echo "Running post-simulation sequence modification..."
Rscript "$postIND" "$indel_dir" "$df_file"

date
