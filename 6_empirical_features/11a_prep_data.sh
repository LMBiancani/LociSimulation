#!/bin/bash
#SBATCH --job-name="rtune"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 20
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR

date


featureslist=(Wickett_features Fong_features)

for i in ${featureslist[@]}
do
	cd $i
	echo ML_data.txt >> path_ML_all.txt
        


        #prepare final files for model training and locus utility prediction


        #RF Similarity
        #all 
        python3 ../prep_table.py ML_data.txt RF_tab.tsv 2 3
        #all woY
        python3 ../prep_table.py ML_data.txt RF_combined_ML.tsv 1 2 3

        #wRF similarity
        #train Y
        python3 ../prep_table.py ML_data.txt wRF_tab.tsv 1 3
        #all woY
        python3 ../prep_table.py ML_data.txt wRF_combined_ML.tsv 1 2 3


        mkdir RF_model

        mkdir wRF_model

        mv RF_tab.tsv RF_model
        mv RF_combined_ML.tsv RF_model
        mv wRF_tab.tsv wRF_model
        mv wRF_combined_ML.tsv wRF_model

	cd ..
done

date
