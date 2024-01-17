#!/bin/bash
#SBATCH --job-name="IQloop"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 2
#SBATCH --mem-per-cpu=6G

##This script organizes data for empirical simulations.


cd $SLURM_SUBMIT_DIR
pwd
date

mkdir -p simulations/empirical/fong/1/
mkdir -p simulations/empirical/wickett/1/
mkdir -p simulations/empirical/mcgowen/1/
mkdir -p simulations/empirical/liu/1/

cp datasets/clean/fong/iqtree_genetrees2/*treefile simulations/empirical/fong/1/
cp datasets/clean/fong/iqtree_genetrees3/*treefile simulations/empirical/fong/1/

cp datasets/clean/wickett/iqtree_genetrees2/*treefile simulations/empirical/wickett/1/
cp datasets/clean/wickett/iqtree_genetrees3/*treefile simulations/empirical/wickett/1/

cp datasets/clean/mcgowen/iqtree_genetrees2/*treefile simulations/empirical/mcgowen/1/
cp datasets/clean/mcgowen/iqtree_genetrees3/*treefile simulations/empirical/mcgowen/1/

cp datasets/clean/liu/iqtree_genetrees2/*treefile simulations/empirical/liu/1/
cp datasets/clean/liu/iqtree_genetrees3/*treefile simulations/empirical/liu/1/

