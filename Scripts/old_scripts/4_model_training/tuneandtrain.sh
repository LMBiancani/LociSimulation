#!/bin/bash
#SBATCH --job-name="rtune"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 20
#SBATCH --mem-per-cpu=6G


cd $SLURM_SUBMIT_DIR

date

module load scikit-learn/1.0.1-foss-2021b
python train_random_forest.py -i aknyshov_data/RFtrain_tab.tsv -t 1 -e 5000 --msl 20 --mss 5 --tune --train-test-split 0.25

date
