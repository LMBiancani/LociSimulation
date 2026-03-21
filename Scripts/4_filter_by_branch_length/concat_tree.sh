#!/bin/bash
#SBATCH --job-name="unfiltered_tree"
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=62G
#SBATCH -p uri-cpu
#SBATCH --constraint=avx512
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

# Input (final named alignments from 2.4)
Data="$out2_4/$dir_name"

# Output directory
OutDir="$out4_0/$dir_name"
mkdir -p ${OutDir}
cd ${OutDir}

module purge
module load uri/main Python/3.7.4-GCCcore-8.3.0

# 1. Run the AMAS script to produce concatenated loci and partitions files
python3 $run_amas ${Data} ${SLURM_CPUS_PER_TASK} ${AMAS}

# 2. Run IQ-TREE on the result

# Generate a starting tree:
${IQTREE} -nt AUTO -ntmax ${SLURM_CPUS_PER_TASK} \
    -s "concatenated.fasta" \
    -pre StartTree \
    -m GTR+G -fast

${IQTREE} -nt AUTO -ntmax ${SLURM_CPUS_PER_TASK} \
    -s "concatenated.fasta" \
    -spp "partitions.txt" \
    -pre Unfiltered_loci_ref_tree \
    -t StartTree.treefile \
    -m MFP -mset GTR -cmax 8 \
    -bb 1000 --alrt 1000
