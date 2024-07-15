#!/bin/bash
#SBATCH --job-name="IQarr_gtree"
#SBATCH --time=48:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE THIS to your user email address
#SBATCH --mail-type=ALL
#SBATCH --array=[1-40]%40

## UPDATE as needed...
# path to Project Directory:
PROJECT=/data/schwartzlab/Biancani/FilterByKnownClades
# path to data directory:
DATA=$PROJECT/data
# Dataset name:
DATASET="Fong"
# path to IQtree scripts:
scripts_dir=$PROJECT/01_iqtree
# path to aligned loci:
aligned_loci_path=$DATA/$DATASET/simulated_loci
# path to constraint trees
constraint_path=$DATA/$DATASET/constraint_trees
# path to output folder (will be created if doesn't exist):
OUTPUT=$PROJECT/output/$DATASET
# name of iqtree array work folder (will be created if doesn't exist):
array_work_folder=$OUTPUT/iqtree_assessment
# path to iqtree executable:
iqtree_exe="/data/schwartzlab/alex/andromeda_tools/iqtree-2.1.2-Linux/bin/iqtree2"

date
cd $array_work_folder
mkdir -p GeneTreesConstrained

fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p $array_work_folder/array_list.txt)
cat ${array_work_folder}/${fileline} | while read line
do
	echo $line
  locusID="${line%.fas}"
  CONSTRAINT="${constraint_path}/${locusID}_constraint.newick"
  cd $array_work_folder
	${iqtree_exe} -nt 1 -s ${aligned_loci_path}/${line} -pre GeneTreesConstrained/inference_${line} -alrt 1000 -m GTR+G -g $CONSTRAINT
	rm -f GeneTreesConstrained/inference_${line}.parstree GeneTreesConstrained/inference_${line}.ckp.gz GeneTreesConstrained/inference_${line}.iqtree GeneTreesConstrained/inference_${line}.log GeneTreesConstrained/inference_${line}.bionj GeneTreesConstrained/inference_${line}.mldist GeneTreesConstrained/inference_${line}.uniqueseq.phy
done
##########
sbatch -q schwartzlab 02_iqtree_array_constrained_gtree.sh
Submitted batch job 330035
Job ID: 330035
Array Job ID: 330035_40
Cluster: andromeda
User/Group: biancani/schwartzlab
State: COMPLETED (exit code 0)
Cores: 1
CPU Utilized: 01:17:50
CPU Efficiency: 99.07% of 01:18:34 core-walltime
Job Wall-clock time: 01:18:34
Memory Utilized: 33.93 MB
Memory Efficiency: 0.55% of 6.00 GB

########## Liu ##########
for file in $(ls 02*)
do
    sed -i 's/\bFong\b/Liu/g' "$file"
done

