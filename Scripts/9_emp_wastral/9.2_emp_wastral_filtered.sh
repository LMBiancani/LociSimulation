#!/bin/bash
#SBATCH --job-name="9.2_wastral_filt"
#SBATCH --time=12:00:00
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

mkdir -p "$out9_2"
cd "$out9_2" || exit 1

FILTERED_TREES="$out9_2/filtered_pass_gtrees_ufboot.tre"
: > "$FILTERED_TREES"

echo "Gathering 21,233 clades-passing UFBoot gene trees at $(date)..."
find "$in9_2_pass" -maxdepth 1 -type f \( -name "*.fas" -o -name "*.fasta" -o -name "*.fa" \) | sort | while read -r PASS_ALN; do
    BASE=$(basename "$PASS_ALN")
    LOCUS="${BASE%.*}"
    GTREE="$out9_0/${LOCUS}.treefile"
    if [ -s "$GTREE" ]; then
        cat "$GTREE" >> "$FILTERED_TREES"
    else
        echo "WARNING: Missing gene tree for passing locus $LOCUS"
    fi
done

TREE_COUNT=$(wc -l < "$FILTERED_TREES")
echo "Filtered gene tree count: $TREE_COUNT"
if [ "$TREE_COUNT" -ne 21233 ]; then
    echo "ERROR: Expected 21,233 gene trees, found $TREE_COUNT. Aborting."
    exit 1
fi

echo "Running Weighted ASTRAL (hybrid mode) on FILTERED dataset at $(date)..."
wastral -t "${SLURM_CPUS_PER_TASK}" \
        -i "$FILTERED_TREES" \
        -o "$out9_2/emp_filtered_wastral.tre" \
        2> "$out9_2/filtered_wastral.log"

echo "Step 9.2 complete at $(date). Output: $out9_2/emp_filtered_wastral.tre"
