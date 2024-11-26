#!/bin/bash
#SBATCH --job-name="SVM_Regressor"
#SBATCH --time=196:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH --cpus-per-task 20
#SBATCH --mem-per-cpu=12G
#SBATCH --mail-user=alexandra.walling@uri.edu
#SBATCH --mail-type=ALL

cd $SLURM_SUBMIT_DIR

date
module purge

module load scikit-learn/1.1.2-foss-2022a
module load matplotlib/3.5.2-foss-2022a
module load SHAP/0.42.1-foss-2022a 
module load SciPy-bundle/2022.05-foss-2022a

python3 SVM_regressor.py -i ../RF_model/RFtrain_tab.tsv -t 20 -o rf_svm_model.bin

python3 SVM_regressor.py -i ../wRF_model/wRFtrain_tab.tsv -t 20 -o wrf_svm_model.bin

date
