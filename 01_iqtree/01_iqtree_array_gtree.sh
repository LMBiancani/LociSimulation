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
# path to output folder (will be created if doesn't exist):
OUTPUT=$PROJECT/output/$DATASET
# name of iqtree array work folder (will be created if doesn't exist):
array_work_folder=$OUTPUT/iqtree_assessment
# path to iqtree executable:
iqtree_exe="/data/schwartzlab/alex/andromeda_tools/iqtree-2.1.2-Linux/bin/iqtree2"

date
cd $array_work_folder
mkdir -p GeneTreesUnconstrained
cd GeneTreesUnconstrained

fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p $array_work_folder/array_list.txt)
cat ${array_work_folder}/${fileline} | while read line
do
	echo $line
	${iqtree_exe} -nt 1 -s ${aligned_loci_path}/${line} -pre inference_${line} -alrt 1000 -m GTR+G
	rm -f inference_${line}.ckp.gz inference_${line}.iqtree inference_${line}.log inference_${line}.bionj inference_${line}.mldist inference_${line}.uniqueseq.phy
done

