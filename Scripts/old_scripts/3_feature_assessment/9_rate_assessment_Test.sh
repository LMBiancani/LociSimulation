#!/bin/bash
#SBATCH --job-name="HParr"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G

module load R/4.0.3-foss-2020b
module load HyPhy/2.5.33-gompi-2020b
date

for i in ../simulations/*/*/1
do
        cd ${i}



	fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p alignmentGroups/array_list.txt)
	aligned_loci_path="../alignments3/"
	batch_script="/opt/software/HyPhy/2.5.33-gompi-2020b/share/hyphy/TemplateBatchFiles/LEISR.bf"
	iqtree_log_path="../iqtree_genetrees3/"
	pruned_trees_path="../pruned_species_trees_Test.tre"
	gene_tree_names="../inferred_gene_trees_Test.txt"

	cd rate_assessment
	cat ../alignmentGroups/${fileline} | while read line
	do
	
		echo $line #locus file
		best_model_param=$(grep "Bayesian Information Criterion:" ${iqtree_log_path}/inference_${line}.log | awk '{print $4}')
		best_model=$(echo ${best_model_param} | cut -f1 -d+)
		if [ "$best_model" = "HKY" ] || [ "$best_model" = "F81" ]; then useModel="HKY85"; else useModel="GTR"; fi
		if [[ "$best_model_param" == *"+"* ]]; then best_param=$(echo ${best_model_param} | cut -f2- -d+); else best_param=""; fi	
		if [[ "$best_param" == *"G"* ]] || [[ "$best_param" == *"R"* ]]; then useRVAS="Gamma"; else useRVAS="No"; fi
		treefile="temp_tree_${SLURM_ARRAY_TASK_ID}.tre"
		loc_name=$(echo ${line} | cut -f1 -d.)
		sed -n $(grep -wn ${loc_name} ${gene_tree_names} | cut -f1 -d:)p ${pruned_trees_path} > ${treefile}
		hyphy ${batch_script} ${aligned_loci_path}/${line} ${treefile} Nucleotide ${useModel} ${useRVAS} 	
		mv ${aligned_loci_path}/${line}.LEISR.json .
		rm ${treefile}
	done
	cd ../../../../../3_feature_assessment/
done
date
