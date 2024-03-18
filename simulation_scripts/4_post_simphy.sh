#!/bin/bash
#SBATCH --job-name="post_simphy"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 2
#SBATCH --mem-per-cpu=6G

##This script generates simulation properties, runs SimPhy, and preps gene trees for INDELible

pwd
date


for i in ../simulations/*/*; do 
    echo $i; 
    while [[ $(ls ${i}/1/loc_*/1/g_trees1.trees | wc -l) -lt 2000 ]]; do
        for j in $(seq 1 2000); do # go through all loc_ (2000)
            if [ -s ${i}/1/loc_${j}/1/g_trees1.trees ]
                then echo "$i $j completed"
            else 
                echo "$i $j did not complete. Rerunning"
                $(grep -w ${i}/1/loc_${j} 3_run_simphy_command_list.txt)
            fi
        done
    done
   
    cat ${i}/1/loc_*/1/g_trees1.trees >> ${i}/1/gene_trees.tre
    rm -rf ${i}/1/loc_*
done


