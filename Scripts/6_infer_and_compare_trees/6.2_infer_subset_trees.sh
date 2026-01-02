#!/bin/bash
#SBATCH --job-name="6.2_trees"
#SBATCH --time=36:00:00         
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=62G
#SBATCH -p uri-cpu
#SBATCH --constraint=avx512
#SBATCH --array=0-5              # 6 jobs total (0, 1, 2, 3, 4, 5)
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Scripts="$Project/LociSimulation/Scripts"
Output="$Project/output/mammals"
AMAS="/project/pi_rsschwartz_uri_edu/Biancani/Software/AMAS/amas/AMAS.py"
amas_py="$Scripts/0_data_prep/run_amas.py"
IQTREE="/project/pi_rsschwartz_uri_edu/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"

# --- 1. Define Arrays (Indices must align) ---
GROUPS=("All_pass" "All_fail" "S3_Clades_pass" "S3_Clades_fail" "S4_BLC_pass" "S4_BLC_fail")

PATHS=(
    "$Output/6.1_intersection_data/all_pass"
    "$Output/6.1_intersection_data/all_fail"
    "$Output/3.3_loci_filtered_by_known_clades/pass_0.05"
    "$Output/3.3_loci_filtered_by_known_clades/fail_0.05"
    "$Output/4.2_BLC_filtered/pass_loci"
    "$Output/4.2_BLC_filtered/fail_loci"
)

# --- 2. Select the specific group and path for this Task ID ---
NAME=${GROUPS[$SLURM_ARRAY_TASK_ID]}
INPUT_DIR=${PATHS[$SLURM_ARRAY_TASK_ID]}
WORK_DIR="$Output/6.2_subset_trees/$NAME"

# --- 3. Safety Check ---
if [ ! -d "$INPUT_DIR" ] || [ -z "$(ls -A "$INPUT_DIR" 2>/dev/null)" ]; then
    echo "ERROR: Task $SLURM_ARRAY_TASK_ID ($NAME) failed. Input directory $INPUT_DIR is missing or empty."
    exit 1
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

module purge
module load uri/main Python/3.7.4-GCCcore-8.3.0

echo "Task ID $SLURM_ARRAY_TASK_ID: Processing $NAME from $INPUT_DIR"

# 4. Run Concatenation (using the wrapper script)
python3 "$amas_py" "$INPUT_DIR" "${SLURM_CPUS_PER_TASK}" "${AMAS}"

# 5. Run IQ-TREE (GTR+F+R8 + 1000 UFBs)
"$IQTREE" -s concatenated.fasta \
          -m GTR+F+R8 \
          -nt "${SLURM_CPUS_PER_TASK}" \
          -pre "${NAME}_tree" \
          -bb 1000 \
          -redo
