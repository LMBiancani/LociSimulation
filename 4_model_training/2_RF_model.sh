#!/bin/bash
#SBATCH --job-name="rfmodel"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=2   # number of nodes
#SBATCH --ntasks-per-node=20   # processor core(s) per node
#SBATCH --mem-per-cpu=12G


cd $SLURM_SUBMIT_DIR

date

module load scikit-learn/1.1.2-foss-2022a
module load matplotlib/3.5.2-foss-2022a
module load SHAP/0.42.1-foss-2022a
module load treeinterpreter/0.2.3-foss-2022a

cd RF_model
pwd
#python3 ../train_random_forest.py -i RFtrain_tab.tsv -t 20 -f auto --msl 20 -e 5000 --mss 5 --tune 

python3 ../train_random_forest.py -i RFtrain_tab.tsv -t 20 -f auto --msl 20 -e 5000 --mss 5 -d 15000

date
