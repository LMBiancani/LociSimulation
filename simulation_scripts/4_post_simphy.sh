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




for j in ../simulations/empirical/fong/1/loc_*/1/s_tree.trees
	do echo $j
	if [ -s $j ]
	then echo "$j job completed"
	else echo "$j job did not complete. Rerunning"
	$(grep $(dirname $(dirname $j)) 3_run_simphy.sh)
	fi
	done

for j in ../simulations/empirical/liu/1/loc_*/1/s_tree.trees
        do echo $j
        if [ -s $j ]
        then echo "$j job completed"
        else echo "$j job did not complete. Rerunning"
        $(grep $(dirname $(dirname $j)) 3_run_simphy.sh)
        fi
        done

for j in ../simulations/empirical/wickett/1/loc_*/1/s_tree.trees
        do echo $j
        if [ -s $j ]
        then echo "$j job completed"
        else echo "$j job did not complete. Rerunning"
        $(grep $(dirname $(dirname $j)) 3_run_simphy.sh)
        fi
        done

for j in ../simulations/empirical/mcgowen/1/loc_*/1/s_tree.trees
        do echo $j
        if [ -s $j ]
        then echo "$j job completed"
        else echo "$j job did not complete. Rerunning"
        $(grep $(dirname $(dirname $j)) 3_run_simphy.sh)
        fi
        done
