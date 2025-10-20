#!/bin/bash
#SBATCH --job-name="DNN Best Model"
#SBATCH --time=2:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH --cpus-per-task 5
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
module load torchvision/0.13.1-foss-2022a-CUDA-11.7.0


python3 load_best_model.py
date
