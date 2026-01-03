#!/bin/bash
#SBATCH --job-name="6.2_trees"
#SBATCH --time=36:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=62G
#SBATCH -p uri-cpu
#SBATCH --constraint=avx512
#SBATCH --array=0-5
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Scripts="$Project/LociSimulation/Scripts"
Output="$Project/output/mammals"
AMAS="/project/pi_rsschwartz_uri_edu/Biancani/Software/AMAS/amas/AMAS.py"
amas_py="$Scripts/0_data_prep/run_amas.py"
IQTREE="/project/pi_rsschwartz_uri_edu/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"

# --- 1. Robust Mapping via Case Statement ---
case $SLURM_ARRAY_TASK_ID in
    0) current_name="All_pass";       current_input="$Output/6.1_intersection_data/all_pass" ;;
    1) current_name="All_fail";       current_input="$Output/6.1_intersection_data/all_fail" ;;
    2) current_name="S3_Clades_pass"; current_input="$Output/3.3_loci_filtered_by_known_clades/pass_0.05" ;;
    3) current_name="S3_Clades_fail"; current_input="$Output/3.3_loci_filtered_by_known_clades/fail_0.05" ;;
    4) current_name="S4_BLC_pass";    current_input="$Output/4.2_BLC_filtered/pass_loci" ;;
    5) current_name="S4_BLC_fail";    current_input="$Output/4.2_BLC_filtered/fail_loci" ;;
esac

WORK_DIR="$Output/6.2_subset_trees/$current_name"

# --- 2. Enhanced Safety Check ---
if [ -z "$current_name" ]; then
    echo "ERROR: current_name is empty for Task ID $SLURM_ARRAY_TASK_ID"
    exit 1
fi

if [ ! -d "$current_input" ]; then
    echo "ERROR: Input directory $current_input not found."
    exit 1
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit

module purge
module load uri/main Python/3.7.4-GCCcore-8.3.0

echo "Task ID $SLURM_ARRAY_TASK_ID: Processing $current_name"

# --- 3. Run AMAS with absolute pathing ---
# We use -f fasta -d dna to ensure AMAS knows what it's looking at
python3 "$amas_py" "$current_input" "${SLURM_CPUS_PER_TASK}" "${AMAS}" > amas_concat.log 2>&1

# Check if concatenation actually produced the file
if [ ! -f "concatenated.fasta" ]; then
    echo "ERROR: AMAS failed to create concatenated.fasta in $WORK_DIR"
    cat amas_concat.log
    exit 1
fi

# --- 4. Run IQ-TREE ---
"$IQTREE" -s concatenated.fasta \
          -m GTR+F+R8 \
          -nt "${SLURM_CPUS_PER_TASK}" \
          -pre "${current_name}_tree" \
          -bb 1000 \
          -redo

echo "Task $current_name complete."
