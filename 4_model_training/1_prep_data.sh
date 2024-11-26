#!/bin/bash
#SBATCH --job-name="rtune"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 20
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR

date

for i in ../simulations/*/*/1
do
	echo ${i}/ML_train.txt >> path_ML_train.txt
	echo ${i}/ML_test.txt >> path_ML_test.txt
	echo ${i}/ML_train.txt >> path_ML_all.txt
	echo ${i}/ML_test.txt >> path_ML_all.txt
done

#prepare final files for model training and locus utility prediction


#RF Similarity
#train Y
python3 prep_train_table.py path_ML_train.txt RFtrain_tab.tsv 2 3
#all woY
python3 prep_train_table.py path_ML_all.txt RF_combined_ML.tsv 1 2 3

#wRF similarity
#train Y
python3 prep_train_table.py path_ML_train.txt wRFtrain_tab.tsv 1 3
#all woY
python3 prep_train_table.py path_ML_all.txt wRF_combined_ML.tsv 1 2 3


#mkdir RF_model

#mkdir wRF_model

mv RFtrain_tab.tsv RF_model
mv RF_combined_ML.tsv RF_model
mv wRFtrain_tab.tsv wRF_model
mv wRF_combined_ML.tsv wRF_model
date
