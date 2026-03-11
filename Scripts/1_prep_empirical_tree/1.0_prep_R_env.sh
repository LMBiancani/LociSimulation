#!/bin/bash
#SBATCH --job-name="R_pkgs"
#SBATCH --time=8:00:00                 # Walltime limit (HH:MM:SS)
#SBATCH --nodes=1                      # Number of nodes
#SBATCH --ntasks=1                     # Total number of tasks (processes)
#SBATCH --cpus-per-task=4              # Number of CPU cores per task
#SBATCH --mem-per-cpu=16G              # Memory per cpu
#SBATCH --mail-user="biancani@uri.edu" # CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH -p uri-cpu                     # Partition/queue to submit job to

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

module purge
module load uri/main
module load ImageMagick/7.1.1-15-GCCcore-12.3.0 # system dependency for the R 'magick' package
module load foss/2024a # Loads an updated toolchain to provide the required C++ library: GLIBCXX_3.4.32 (fixes GLIBCXX error)
module load R/4.3.2-gfbf-2023a # Loads updated R version
# This forces the linker to find the correct, newest C++ library that contains GLIBCXX_3.4.32.
# This must be done AFTER module loading to override potential downgrades.
export GLIBCXX_PATH="/modules/uri_apps/software/GCCcore/13.3.0/lib64"
export LD_LIBRARY_PATH=$GLIBCXX_PATH:$LD_LIBRARY_PATH

## Install R packages

# add local space for R packages (won't ask about install location):
mkdir -p ${R_package_DIR}
export R_LIBS=${R_package_DIR}

# install R packages
Rscript ${SCRIPTS}/1_prep_empirical_tree/install.packages.R $R_packages

date
