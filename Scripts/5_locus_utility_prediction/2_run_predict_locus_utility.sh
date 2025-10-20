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
module load treeinterpreter/0.2.3-foss-2022a

for i in ../simulations/*/*/1
do

	cd ${i}
	pwd
	#RF model
        rm -rf subsets	
	mkdir subsets
	cd subsets

	python3 ../../../../../5_locus_utility_prediction/predict_locus_utility.py -i ../RF_combined_ML.tsv -o RF_combined_predicted_ML.tsv -m ../../../../../4_model_training/RF_model/model_and_scaler.pkl

#wRF model

	python3 ../../../../../5_locus_utility_prediction/predict_locus_utility.py -i ../wRF_combined_ML.tsv -o wRF_combined_predicted_ML.tsv -m ../../../../../4_model_training/wRF_model/model_and_scaler.pkl
	


	cd ../../../../../5_locus_utility_prediction

done
date
