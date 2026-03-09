################################################
# variables.sh
# full path: /scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh
# variables are grouped by their first point of use but remain available for all subsequent scripts.

set -a  # Automatically export all variables defined after this line

## 0_data_prep

# Path to workspace:
WORK="/scratch4/workspace/biancani_uri_edu-LociSimulation"
# Path to empircial data (aligned loci in fasta format):
DATA="$WORK/mammal_loci/01_SISRS_loci_filtered"
# Path to parent output directory:
OUTPUT="$WORK/output"
# Path to dataset-specific output directory (named for empirical dataset):
Output="$OUTPUT/mammals"

# Path to simulation project directory:
PROJECT="$WORK/LociSimulation"
# Path to scripts directory:
SCRIPTS="$PROJECT/Scripts"

## 0.0_amas_concat.sh

# Path to script-specific output directory:
out0_0="$Output/0.0_concatenated"
# Path to AMAS executable:
AMAS="/project/pi_rsschwartz_uri_edu/Biancani/Software/AMAS/amas/AMAS.py"

## 0.1_iqtree_empirical.sh

# Path to script-specific output directory:
out0_1="$Output/0.1_empirical_tree"
# Path to IQTREE executable:
IQTREE="/project/pi_rsschwartz_uri_edu/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"


set +a  # Stop automatically exporting
################################################
