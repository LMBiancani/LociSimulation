#!/bin/bash
#SBATCH --job-name="Predict"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR

date

module load scikit-learn/1.1.2-foss-2022a
module load matplotlib/3.5.2-foss-2022a
module load SHAP/0.42.1-foss-2022a 
module load SciPy-bundle/2022.05-foss-2022a



featureslist=(Wickett_features Fong_features)

for i in ${featureslist[@]}
do

	cd ${i}
	pwd
	#RF model
	
	mkdir randomforest_subsets
	cd randomforest_subsets

	python3 ../../predict_locus_utility.py -i ../RF_model/RF_combined_ML.tsv -o ../RF_model/RF_predicted_ML.tsv -m ../../../4_model_training/RF_model/model_file.bin

	#sed -i 's/ML_test\.txt_//g' RF_predicted_ML.tsv
#wRF model

	python3 ../../predict_locus_utility.py -i ../wRF_model/wRF_combined_ML.tsv -o ../wRF_model/wRF_predicted_ML.tsv -m ../../../4_model_training/wRF_model/model_file.bin
	
	#sed -i 's/ML_test\.txt_//g' wRF_predicted_ML.tsv


	cd ../../

done
date
