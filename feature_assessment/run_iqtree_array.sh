#!/bin/bash
#SBATCH --job-name="IQloop"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 2
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR

date

aligned_loci_path2="../alignments2/"
aligned_loci_path3="../alignments3/"
iqtree_exe="/home/aknyshov/alex_data/andromeda_tools/iqtree-2.1.2-Linux/bin/iqtree2"

fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p alignmentGroups/array_list.txt)

cat alignmentGroups/${fileline} | while read line
do
	cd iqtree_genetrees2
	${iqtree_exe} --keep-ident -nt 2 -s ${aligned_loci_path2}/${line} -pre inference_${line} -m MFP -bb 1000 -alrt 1000
	cd ../iqtree_genetrees3
	${iqtree_exe} --keep-ident -nt 2 -s ${aligned_loci_path3}/${line} -pre inference_${line} -m MFP -bb 1000 -alrt 1000
	cd ../
done
date
