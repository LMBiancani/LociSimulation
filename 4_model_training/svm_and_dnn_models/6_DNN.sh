#!/bin/bash
#SBATCH --job-name="DNN"
#SBATCH --time=120:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 20
#SBATCH --mem-per-cpu=12G


cd $SLURM_SUBMIT_DIR

date
module purge

module load scikit-learn/1.1.2-foss-2022a
module load matplotlib/3.5.2-foss-2022a
module load SHAP/0.42.1-foss-2022a
module load torchvision/0.13.1-foss-2022a-CUDA-11.7.0



python3 updated_train_DNN.py -i ../RF_model/RFtrain_tab.tsv -t 20 -lmbda 1e-05 -bs 16 -lr 0.001 -epochs 100 --name RF_model.pt --scaler RF_model_scaler.pt

python updated_train_DNN.py -i ../wRF_model/wRFtrain_tab.tsv -t 20 lmbda 1e-05 bs 16 lr 0.001 -epochs 100 --name wRF_model.pt --scaler wRF_model_scaler.pt
date
