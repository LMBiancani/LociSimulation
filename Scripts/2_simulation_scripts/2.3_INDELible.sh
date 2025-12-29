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

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Scripts="$Project/LociSimulation/Scripts"
Output="$Project/output/mammals"
# Path to INDELible executable
indel_exe="/project/pi_rsschwartz_uri_edu/Biancani/Software/indelible/src/indelible"

# Input from 2.0 and 2.2
tree_file="$Output/2.2_simulated_loci/gene_trees.tre"
df_file="$Output/2.0_simphy_prep/df.csv"

# Output subdirectory:
indel_dir="$Output/2.3_indelible"
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
# Passing: [1]tree_file [2]df_file [3]output_dir [4]sim_script_dir
Rscript "$Scripts/2_simulation_scripts/prep_INDELible.R" \
    "$tree_file" \
    "$df_file" \
    "$indel_dir" \
    "$Scripts/2_simulation_scripts"

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
Rscript "$Scripts/2_simulation_scripts/post_INDELible.R" "$indel_dir" "$df_file"

date
