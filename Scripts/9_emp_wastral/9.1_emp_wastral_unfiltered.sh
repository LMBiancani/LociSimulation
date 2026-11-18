#!/bin/bash
#SBATCH --job-name="9.1_wastral_all"
#SBATCH --time=30:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=30G
#SBATCH -p uri-cpu
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source "$vars"
echo "Variables sourced into current shell environment:"
cat "$vars"

module purge
module load uri/main
module load conda/latest
eval "$(conda shell.bash hook)"
conda activate aster

mkdir -p "$out9_1"
cd "$out9_1" || exit 1

UNFILTERED_TREES="$out9_1/unfiltered_all_gtrees_ufboot.tre"

echo "Gathering all 109,799 UFBoot gene trees from $out9_0 at $(date)..."
find "$out9_0" -maxdepth 1 -name "*.treefile" | sort | xargs cat > "$UNFILTERED_TREES"

TREE_COUNT=$(wc -l < "$UNFILTERED_TREES")
echo "Unfiltered gene tree count: $TREE_COUNT"
if [ "$TREE_COUNT" -ne 109799 ]; then
    echo "ERROR: Expected 109,799 gene trees, found $TREE_COUNT. Aborting."
    exit 1
fi

echo "Running Weighted ASTRAL (hybrid mode) on UNFILTERED dataset at $(date)..."
wastral -t "${SLURM_CPUS_PER_TASK}" \
        -i "$UNFILTERED_TREES" \
        -o "$out9_1/emp_unfiltered_wastral.tre" \
        2> "$out9_1/unfiltered_wastral.log"

echo "Step 9.1 complete at $(date). Output: $out9_1/emp_unfiltered_wastral.tre"
