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


featureslist=(Liu_features)

for i in ${featureslist[@]}
do
	cd ${i}
	pwd
	cd randomforest_subsets

	python3 ../../subset_generator.py -i ../RF_model/RF_predicted_ML.tsv -s i 
	
        sed -i 's/data.txt_//g' ML_best*
        rm array_list.txt
	ls ML*txt > array_list.txt
	


	mkdir wRF_subsets
        cd wRF_subsets	
	#sed -i 's/ML_data.txt_/ML_data_/g' wRF_predicted_ML.tsv
	python3 ../../../subset_generator.py -i ../../wRF_model/wRF_predicted_ML.tsv -s i
	sed -i 's/data.txt_//g' ML_best*
        rm array_list.txt
	ls ML*txt > array_list.txt
	cd ../../..

done

date 
