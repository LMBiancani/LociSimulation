#!/bin/bash
#SBATCH --job-name="IQloop"
#SBATCH --time=250:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=10G
#SBATCH --array=1-18

date

for i in Liu_features/alignmentGroups/

do
	
	cd ${i}
	pwd
	#path to first half of gene alignments for dataset
	aligned_loci_path2="../alignments2"
	#path to second half of gene alignments for dataset
	aligned_loci_path3="../alignments3"

	#path to iqtree executable; replace with your own path if not running on Andromeda
	iqtree_exe="/home/aknyshov/alex_data/andromeda_tools/iqtree-2.1.2-Linux/bin/iqtree2"

 
	#create a series of arrays corresponding to each line in the array_list.txt file
	fileline=$(sed -n "${SLURM_ARRAY_TASK_ID}"p array_list.txt)

	echo "File line:${fileline} "
       	cat ${fileline} | while read line
	do
		cd ../iqtree_genetrees2

		$iqtree_exe --keep-ident -nt 2 -s ${aligned_loci_path2}/${line} -pre inference_${line} -m MFP -bb 1000 -alrt 1000 #iqtree job. Flags instruct iqtree to keep sequence identifiers as they are in the input file; to set 2 threads for parallel processing; specifies a DNA aligment file; specifies a prefix for the output files; specifies the substitution model to be used, MFP, a mixture model of amino acid frequencies; sets 1000 ultrafast bootstraps; and ets the number of replicates for the non-parametric approximate likelihood ratio test (aLRT) to 1000 
		cd ../iqtree_genetrees3
		$iqtree_exe --keep-ident -nt 2 -s ${aligned_loci_path3}/${line} -pre inference_${line} -m MFP -bb 1000 -alrt 1000
		cd ../alignmentGroups
	done

	cd ../../
done
date
