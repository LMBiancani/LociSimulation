#!/bin/bash
#SBATCH --job-name="RFR SHAP"
#SBATCH --time=120:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 20
#SBATCH --cpus-per-task 20
#SBATCH --mem-per-cpu=12G


cd $SLURM_SUBMIT_DIR

date
module purge

module load scikit-learn/1.1.2-foss-2022a
module load matplotlib/3.5.2-foss-2022a
module load SHAP/0.42.1-foss-2022a
module load SHAP/0.42.1-foss-2022a

cd RF_model
pwd
python3 ../SHAP_values.py -m model_file.bin -i RFtrain_tab.tsv -t 20
cd ..

cd wRF_model
pwd
python3 ../SHAP_values.py -m model_file.bin -i wRFtrain_tab.tsv -t 20

date
