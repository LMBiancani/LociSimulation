#!/bin/bash
#SBATCH --job-name="6.2_trees"
#SBATCH --time=36:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=62G
#SBATCH -p uri-cpu
#SBATCH --constraint=avx512
#SBATCH --array=0-9
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Scripts="$Project/LociSimulation/Scripts"
Output="$Project/output/mammals"
AMAS="/project/pi_rsschwartz_uri_edu/Biancani/Software/AMAS/amas/AMAS.py"
amas_py="$Scripts/0_data_prep/run_amas.py"
IQTREE="/project/pi_rsschwartz_uri_edu/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"

# --- 1. Mapping via Case Statement ---
case $SLURM_ARRAY_TASK_ID in
    0) name="All_pass";          in="$Output/6.1_intersection_data/all_pass" ;;
    1) name="All_fail";          in="$Output/6.1_intersection_data/all_fail" ;;
    2) name="S3_Clades_pass";    in="$Output/3.3_loci_filtered_by_known_clades/pass_0.05" ;;
    3) name="S3_Clades_fail";    in="$Output/3.3_loci_filtered_by_known_clades/fail_0.05" ;;
    4) name="S4_BLC_pass";       in="$Output/4.2_BLC_filtered/pass_loci" ;;
    5) name="S4_BLC_fail";       in="$Output/4.2_BLC_filtered/fail_loci" ;;
    # New Intersection Groups
    6) name="S3_pass_S4_fail";   in="$Output/6.1_intersection_data/S3_pass_S4_fail" ;;
    7) name="S4_pass_S3_fail";   in="$Output/6.1_intersection_data/S4_pass_S3_fail" ;;
    8) name="Fail_at_least_one"; in="$Output/6.1_intersection_data/fail_at_least_one" ;;
    9) name="Pass_at_least_one"; in="$Output/6.1_intersection_data/pass_at_least_one" ;;
esac

WORK_DIR="$Output/6.2_subset_trees/$name"
FINAL_TREE="$WORK_DIR/${name}_tree.treefile"

# --- 2. Check for Existing Output ---
if [ -f "$FINAL_TREE" ]; then
    echo "Task ID $SLURM_ARRAY_TASK_ID ($name): Final tree found at $FINAL_TREE."
    echo "Skipping to avoid re-running."
    exit 0
fi

# --- 3. Safety Checks ---
if [ ! -d "$in" ]; then
    echo "ERROR: Input directory $in not found."
    exit 1
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit

module purge
module load uri/main Python/3.7.4-GCCcore-8.3.0

echo "Task ID $SLURM_ARRAY_TASK_ID: Starting inference for $name"

# --- 4. Run AMAS ---
python3 "$amas_py" "$in" "${SLURM_CPUS_PER_TASK}" "${AMAS}" > amas_concat.log 2>&1

if [ ! -f "concatenated.fasta" ]; then
    echo "ERROR: AMAS failed to create concatenated.fasta in $WORK_DIR"
    exit 1
fi

# --- 5. Run IQ-TREE ---
"$IQTREE" -s concatenated.fasta \
          -m GTR+F+R8 \
          -nt "${SLURM_CPUS_PER_TASK}" \
          -pre "${name}_tree" \
          -bb 1000 \
          -redo

echo "Task $name complete."
