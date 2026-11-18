#!/bin/bash
#SBATCH --job-name="9.0_ufboot"
#SBATCH --partition=uri-cpu,cpu,cpu-preempt
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH --array=1-20
#SBATCH --requeue
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source "$vars"

Alignments="$DATA"
OutDir="$out9_0"
mkdir -p "$OutDir"

module purge
module load uri/main
module load foss/2024a
module load parallel/20240822

# Thread-safe master alignment list creation (whichever task starts first builds it)
LOCUS_LIST="$OutDir/all_alignments.txt"
flock -x "${LOCUS_LIST}.lock" bash -c "
    if [ ! -s \"$LOCUS_LIST\" ]; then
        find \"$Alignments\" -maxdepth 1 -regextype posix-extended -regex '.*\.(fas|fa|fasta)$' | sort > \"${LOCUS_LIST}.tmp\"
        mv \"${LOCUS_LIST}.tmp\" \"$LOCUS_LIST\"
    fi
"

TOTAL_FILES=$(wc -l < "$LOCUS_LIST")
NUM_CHUNKS=20
CHUNK_SIZE=$(( (TOTAL_FILES + NUM_CHUNKS - 1) / NUM_CHUNKS ))
START_LINE=$(( (SLURM_ARRAY_TASK_ID - 1) * CHUNK_SIZE + 1 ))
END_LINE=$(( SLURM_ARRAY_TASK_ID * CHUNK_SIZE ))

calc_ufboot() {
    locus_path="$1"
    filename=$(basename "$locus_path")
    locus_id="${filename%.*}"

    out_prefix="$OutDir/${locus_id}"
    final_tree="${out_prefix}.treefile"

    # Resume logic: skip if non-empty bootstrap-annotated treefile already exists
    if [ -s "$final_tree" ]; then
        return 0
    fi

    "$IQTREE" -s "$locus_path" \
              -m GTR+G \
              -bb 1000 \
              -pre "$out_prefix" \
              -nt 1 \
              -redo \
              -quiet

    # Clean up auxiliary files to conserve scratch inodes
    rm -f "${out_prefix}.ckp.gz" \
          "${out_prefix}.bionj" \
          "${out_prefix}.mldist" \
          "${out_prefix}.ufboot" \
          "${out_prefix}.contree" \
          "${out_prefix}.splits.nex" \
          "${out_prefix}.iqtree" \
          "${out_prefix}.log"
}

export -f calc_ufboot
export IQTREE OutDir

echo "Task $SLURM_ARRAY_TASK_ID processing lines $START_LINE to $END_LINE at $(date)"

sed -n "${START_LINE},${END_LINE}p" "$LOCUS_LIST" | \
    parallel --env IQTREE \
             --env OutDir \
             -j "${SLURM_CPUS_PER_TASK}" \
             --no-notice \
             calc_ufboot {}

echo "Task $SLURM_ARRAY_TASK_ID complete at $(date)."
