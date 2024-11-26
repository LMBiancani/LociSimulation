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


#lr=(0.001 0.0001)
#bs=(16 8 4)
#lmbda=(1e-5 1e-4 )

#length=${#lr[@]}


#for i in "${lr[@]}"; do
#	for j in "${bs[@]}"; do
#		for k in "${lmbda[@]}"; do
			

#			python3 updated_train_DNN.py -i ../RF_model/RFtrain_tab.tsv -t 20 -lmbda $k -lr $i -bs $j  -epochs 100
#		done
#	done
#done

python3 updated_train_DNN.py -i ../RF_model/RFtrain_tab.tsv -t 20 -lmbda 1e-05 -bs 16 -lr 0.001 -epochs 100
date
