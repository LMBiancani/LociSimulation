#!/bin/bash
#SBATCH --job-name=submit_jobs
#SBATCH --ntasks=1
#SBATCH --mem=100M
#SBATCH -p uri-cpu
#SBATCH --time=00:05:00
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

for random_seed in $seeds;
  do
  echo "Submitting create intersections job for random seed: $random_seed";
  sbatch $Intersects $random_seed
done
