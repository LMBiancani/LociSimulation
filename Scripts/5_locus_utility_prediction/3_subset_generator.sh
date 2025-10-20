#!/bin/bash
#SBATCH --job-name="Subsets"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 20
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR

date

module load scikit-learn/0.23.1-foss-2020a-Python-3.8.2
module load treeinterpreter/0.2.3-foss-2020a


for i in ../simulations/*/*/1
do
	cd ${i}/subsets
        rm *txt	

        python3 ../../../../../5_locus_utility_prediction/subset_generator.py -i RF_combined_predicted_ML.tsv -s bwr
	rm array_list.txt
	ls *txt > array_list.txt
        
        rm -rf wRF_subsets
	mkdir wRF_subsets
	
	cp wRF_combined_predicted_ML.tsv wRF_subsets/wRF_combined_predicted_ML.tsv
	cd wRF_subsets
        python3 ../../../../../../5_locus_utility_prediction/subset_generator.py -i wRF_combined_predicted_ML.tsv -s bwr
	ls *txt > array_list.tx
	cd ../../../../../../5_locus_utility_prediction

done

date
