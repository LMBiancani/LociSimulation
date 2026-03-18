#!/bin/bash
#SBATCH --job-name="AMAS"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH -p uri-cpu
#SBATCH --mail-user="biancani@uri.edu" #CHANGE THIS to your user email address
#SBATCH --mail-type=ALL

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

# Number of processor cores per node:
Cores=$SLURM_CPUS_ON_NODE

module purge
module load uri/main Python/3.7.4-GCCcore-8.3.0

date
mkdir -p $out0_0
cd $out0_0

#Concatenate input fasta files and prepare partitions ahead of IQTree run
python3 $run_amas $DATA $Cores $AMAS

date
