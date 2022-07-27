#!/bin/bash
#SBATCH --job-name="IQarr"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 20
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR

date

aligned_loci_path="../alignments3/"
iqtree_exe="/home/aknyshov/alex_data/andromeda_tools/iqtree-2.1.2-Linux/bin/iqtree2"
fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p array_list.txt)

infiles=$(cat $fileline | while read line; do newline=$(echo $line | sed 's/,.*/.fas/g'); echo ${aligned_loci_path}/${newline}; done | paste -sd" ")

python3 ~/alex_data/andromeda_tools/AMAS/amas/AMAS.py concat -f fasta -d dna --out-format fasta --part-format raxml -i $infiles -t concatenated_${fileline}.fasta -p partitions_${fileline}.txt

${iqtree_exe} -nt 20 -s concatenated_${fileline}.fasta -spp partitions_${fileline}.txt -pre inference_${fileline} -m MFP -bb 1000 -alrt 1000

date