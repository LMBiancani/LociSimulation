#!/bin/bash
#SBATCH --job-name="dataprep"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 20
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR

date

for i in ../simulations/*/*/1
do
	cd ${i}
	
	head -1001 ML_test.txt > ML_combined.txt; tail -1000 ML_train.txt >> ML_combined.txt
	rm path_ML_all.txt
	echo ML_train.txt > path_ML_train.txt
        echo ML_test.txt > path_ML_test.txt
        echo ML_train.txt > path_ML_all.txt
        echo ML_test.txt >> path_ML_all.txt	

 
	#prepare final files for model training and locus utility prediction


	#RF Similarity
	#train Y
	python3 ../../../../5_locus_utility_prediction/prep_train_table.py path_ML_train.txt RFtrain_tab.tsv 2 3
	#all woY
	python3 ../../../../5_locus_utility_prediction/prep_train_table.py path_ML_all.txt RF_combined_ML.tsv 1 2 3

	#wRF similarity
	#train Y
	python3 ../../../../5_locus_utility_prediction/prep_train_table.py path_ML_train.txt wRFtrain_tab.tsv 1 3
	#all woY
	python3 ../../../../5_locus_utility_prediction/prep_train_table.py path_ML_all.txt wRF_combined_ML.tsv 1 2 3
	

	cd ../../../../5_locus_utility_prediction
done

date
