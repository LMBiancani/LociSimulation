# FilterByKnownClades
Scripts associated with "Improving Phylogenetic Marker Selection Using Support for Established Clades" Poster at Evolution Conference 2024

## 00. Simulated Loci

## 01. IQ-TREE

Scripts are located in the 01_iqtree directory.

### 00. Prep Script

Slurm submission script: 00_iqtree_prep.sh

* sets up the folders and lists of files to process
* generates batch fasta files for aligned loci
* generates the array details that need to be added to subsequent array submission scripts (sbatch_array_directive.txt)
* Note: example array details included in subsequent submission scripts: #SBATCH --array=[1-40]%40

### 01. Unconstrained Gene Trees

Slurm submission script: 01_iqtree_array_gtree.sh

### 02. Constrained Gene Trees
