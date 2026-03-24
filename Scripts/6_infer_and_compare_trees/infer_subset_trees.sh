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

random_seed=$1
echo "Random number seed = $random_seed"
dir_name="set_$random_seed"

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

# --- 1. Mapping via Case Statement ---
case $SLURM_ARRAY_TASK_ID in
    0) name="all_PASS";          in="$out6_1/$dir_name/all_PASS" ;;
    1) name="all_FAIL";          in="$out6_1/$dir_name/all_FAIL" ;;
    2) name="clades_PASS";       in="$out3_3/$dir_name/pass_0.05" ;;
    3) name="clades_FAIL";       in="$out3_3/$dir_name/fail_0.05" ;;
    4) name="blc_PASS";          in="$out4_2/$dir_name/pass_loci" ;;
    5) name="blc_FAIL";          in="$out4_2/$dir_name/fail_loci" ;;
    # Intersection Groups
    6) name="clades_PASS_blc_FAIL";   in="$out6_1/$dir_name/clades_PASS_blc_FAIL" ;;
    7) name="blc_PASS_clades_FAIL";   in="$out6_1/$dir_name/blc_PASS_clades_FAIL" ;;
    8) name="FAIL_at_least_one";      in="$out6_1/$dir_name/FAIL_at_least_one" ;;
    9) name="PASS_at_least_one";      in="$out6_1/$dir_name/PASS_at_least_one" ;;
esac

WORK_DIR="$out6_2/$dir_name/$name"
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
# Get the RELATIVE path from WORK_DIR to the input alignments
# This makes the paths in the command much shorter
REL_IN=$(realpath --relative-to="." "$in")

python3 "$run_amas" "$REL_IN" "${SLURM_CPUS_PER_TASK}" "${AMAS}" > amas_concat.log 2>&1

if [ ! -f "concatenated.fasta" ]; then
    echo "ERROR: AMAS FAILed to create concatenated.fasta in $WORK_DIR"
    exit 1
fi

# --- 5. Run IQ-TREE ---

# Generate a starting tree:
${IQTREE} -nt AUTO -ntmax ${SLURM_CPUS_PER_TASK} \
    -s "concatenated.fasta" \
    -pre StartTree \
    -m GTR+G -fast

${IQTREE} -nt AUTO -ntmax ${SLURM_CPUS_PER_TASK} \
    -s "concatenated.fasta" \
    -spp "partitions.txt" \
    -pre ${name}_tree \
    -t StartTree.treefile \
    -m MFP -mset GTR -cmax 8 \
    -bb 1000 --alrt 1000 

echo "Task $name complete."
