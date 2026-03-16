#!/bin/bash
#SBATCH --job-name="prep_simphy"
#SBATCH --time=00:20:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH -p uri-cpu
#SBATCH -c 1
#SBATCH --mem-per-cpu=2G

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

# --- Module Management ---
module purge
module load uri/main
module load foss/2024a
module load R/4.3.2-gfbf-2023a

# --- Critical Environment Fixes ---
# 1. Fix for the C++ library (GLIBCXX) errors
export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH

# 2. Point R to your custom package library
export R_LIBS=~/R-packages

# --- generate_sim_properties.R ---

# create output subdirectory:
mkdir -p $out2_0
cd $out2_0

# loop through random number $seeds and generate a set of simulation properties for each seed:

sets=$(echo $seeds | wc -w)
echo "Generating simulation properties for $sets set(s) of $nloci loci"
for random_seed in $seeds;
  do
  echo "Generating simulation properties for random seed: $random_seed";
  set_dir="set_$random_seed"
  mkdir -p "$set_dir"
  cd "$set_dir" || exit # Exit if directory change fails
  Rscript $GSP $input2_0 $mod_write_tree2 $random_seed $nloci $Ne $ABLmin $ABLmax $LLmin $LLmax $lambdaPSmin $lambdaPSmax $VBLmin $VBLmax $MissTaxa $PartLoss $MissPropMIN $MissPropMAX $PropCoding $NoParalogy $ParalogyIntensity $NoContaminant $ContaminantIntensity
  cd .. 
  echo "Simulation properties for $set_dir have been generated."
  done

date
