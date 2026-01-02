# Loci Simulation Scripts

## 0_data_prep

Prepares aligned loci for simulations by concatenating alignments and inferring an empirical tree.

### 0.0_amas_concat.sh

```bash
sbatch 0.0_amas_concat.sh
```

Runs AMAS on an empirical dataset to concatenate input fasta files and prepare partitions file ahead of IQTree run. Uses a helper Python script `run_amas.py`, which wraps around the `AMAS.py` concat command.

#### run_amas.py

A custom AMAS wrapper (run by `0.0_amas_concat.sh`): processes FASTA alignments in batches of 1000 files (to avoid overloading AMAS input limitations), concatenates those outputs, and appends the results into cumulative files. Produces a concatenated alignment file and a corresponding partition file: ```concatenated.fasta partitions.txt```

### 0.1_iqtree_empirical.sh

```bash
sbatch 0.1_iqtree_empirical.sh
```
Runs IQ-Tree to generate an empirical species tree.

## 1_prep_empirical_tree

Prepare (reformat) empirical tree file ahead of simulations.

### 1.0_prep_R_env.sh

```bash
sbatch 1.0_prep_R_env.sh
```
Creates a local space for R packages (`~/R-packages`), runs `install.packages.R`, and installs necessary R libraries.

#### install.packages.R

Checks for, installs, and loads necessary R packages.

### 1.1_format_tree.sh

Generates a formatted, ultrametric, and rescaled empirical species tree and a parameters file containing a random seed and estimated Ne (effective population size) for the simulation of 2000 loci.

```bash
sbatch 1.1_format_tree.sh
```
Reformats the empirical tree to produce an ultrametric tree with numerical tip labels. This step also generates taxon_map.csv, which preserves the link between the new numerical IDs and the original empirical taxon names for later restoration.

#### empirical_tree_processor.R

The R engine for tree formatting. Handles rooting, ultrametric transformation via `chronos`, and the generation of the master taxon map.

## 2_simulation_setup

Generates simulation parameters, creates the `SimPhy` command list, and executes simulations in parallel.

### 2.0_prep_simphy.sh

```bash
sbatch 2.0_prep_simphy.sh

```
Initiates parameter generation by calling `generate_sim_properties.R` to create the blueprint for 2,000 loci.

#### generate_sim_properties.R

An R script executed by `2.0_prep_simphy.sh`. Generates a CSV file (`df.csv`) containing stochastic parameters for each locus, including Effective Population Size (N_e), substitution rates, heterotachy parameters, and unique random seeds.

### 2.1_simphy_commands.sh

```bash
sbatch 2.1_simphy_commands.sh

```

Runs `run_SimPhy.R` to translate the parameter file (`df.csv`) into a raw list of 2,000 SimPhy terminal commands (`simphy_command_list.txt`).

#### run_SimPhy.R

An R script run by `2.1_simphy_commands.sh`. Maps variables from `df.csv` to SimPhy flags. It outputs `simphy_command_list.txt`, a 2,000-line file where each line is a unique, fully-formed SimPhy execution string.

### 2.2_run_simulations.sh

```bash
sbatch 2.2_run_simulations.sh

```

The Executioner and Harvester. Uses GNU Parallel to run 2,000 SimPhy tasks. Includes an auto-recovery loop to audit output folders and retry failed simulations, eventually gathering all verified trees into a master `gene_trees.tre`.

### 2.3_INDELible.sh

```bash
sbatch 2.3_INDELible.sh

```

The Sequence Evolution Engine. This script translates gene trees into DNA sequences using INDELible V1.03 with a custom parallelized architecture.

* Dynamic Parameterization: Calls `prep_INDELible.R` to generate 2,000 unique control files based on the stochastic parameters in `df.csv`.
* Thread-Safe Parallelization: Executes INDELible via GNU Parallel. To bypass INDELible's fixed-input filename requirement (`control.txt`), the script creates 2,000 temporary subdirectories (`tmp_$i`). Each instance runs in isolation to prevent file-access collisions.
* Stochastic Modeling: Supports both Nucleotide and Codon models, implementing site-rate heterogeneity (RVAS), indel power-law distributions, and model-shift logic across the phylogeny.
* Post-Simulation Modification: Executes `post_INDELible.R` to introduce real-world "noise" into the perfect simulations, producing the final experimental dataset.

#### prep_INDELible.R

Generates unique control files for every locus, performing "tree surgery" to add paralogy and defining evolutionary models.:

* Paralogy/Signal Logic: Uses `modify_gene_tree.R` to graft paralogous subtrees and adjust phylogenetic signal via lambda rescaling.
* Model Generation: Stochastic assignment of substitution models (GTR, HKY, etc.) and codon parameters.
* Control Factory: Writes unique `control_i.txt` files for every locus, ensuring that partitions and branch-specific models are correctly formatted for the INDELible engine.

##### modify_gene_tree.R

Helper R script run by `prep_INDELible.R`. Grafts paralogous subtrees and adjust phylogenetic signal via lambda rescaling.

#### post_INDELible.R

The Data Dirtying script. Processes raw simulated sequences to mimic empirical dataset challenges:

* Cross-Contamination: Simulates lab/sequencing errors by swapping sequence data between specific taxon pairs identified in the metadata.
* Missing Data: Introduces 5' and 3' truncated segments and internal gaps based on stochastic proportions to simulate degraded DNA or poor sequencing coverage.
* Format Conversion: Trims empty alignment columns and converts Phylip outputs into a standardized FASTA format (`loc_1.fas` through `loc_2000.fas`) inside the `alignments_final` directory.

### 2.4_restore_names.sh
```Bash
sbatch 2.4_restore_names.sh
```
The Taxon Restorer. The final step in the simulation pipeline. It bridges the gap between the numerical space required by simulation engines and the human-readable names required for analysis.

#### restore_names.R

Uses the `taxon_map.csv` created in Step 1.1 to perform a 1:1 replacement of numerical headers (e.g., `>1`) with original species names (e.g., ``>Homo_sapiens`). This ensures the final FASTA alignments in `2.4_final_named_alignments` are ready for downstream phylogenetic tools.

## 3_filter_by_known_clades

Filters loci by comparing the likelihood of trees constrained to "Uncontested Clades" versus unconstrained trees.

### 3.0_generate_constraints.sh
```Bash
sbatch 3.0_generate_constraints.sh
```
Uses `generate_constraints.R` to create Newick constraint files for specific clades of interest.

### 3.1_iqtree_likelihoods.sh
```Bash
sbatch 3.1_iqtree_likelihoods.sh
```
Runs IQ-TREE on each locus under two conditions: unconstrained and constrained to known clades.

### 3.2_LRT_filter.sh
```Bash
sbatch 3.2_LRT_filter.sh
```
Executes `LRT_filter.R` to perform Likelihood Ratio Tests, identifying loci where the constraint significantly worsens the fit (p < 0.05).

### 3.3_collect_filtered_loci.sh
```Bash
sbatch 3.3_collect_filtered_loci.sh
```
Uses collect_filtered_loci.R to sort loci into pass_0.05 and fail_0.05 directories based on LRT results.

## 4_filter_by_branch_length

Filters loci based on evolutionary rate consistency using Branch Length Correlation (BLC).

### 4.0_concat_tree.sh
```Bash
sbatch 4.0_concat_tree.sh
```
Builds a 2,000-locus reference tree to serve as the "genomic average" rate proxy.

### 4.1_constrained_gtrees.sh
```Bash
sbatch 4.1_constrained_gtrees.sh
```
Uses `trimConstraintTree.R` to prepare the reference topology, then runs IQ-TREE to estimate gene-specific branch lengths on that fixed topology.

### 4.2_treescreen.sh
```Bash
sbatch 4.2_treescreen.sh
```
Executes `treescreen.R` to calculate Pearson correlation (R^2) between gene trees and the reference tree, sorting them into `pass_loci` and `fail_loci`.

## 5_future_filtering_step

## 6_infer_and_compare_trees

Module comparing the impact of filtering on the species tree.

### 6.0_unfiltered_tree.sh
```Bash
sbatch 6.0_unfiltered_tree.sh
```
Infers the baseline reference tree from all 2,000 loci using GTR+F+R8 and 1,000 UltraFast Bootstraps.

### 6.1_create_intersections.sh
```Bash
sbatch 6.1_create_intersections.sh
```
Identifies the intersection of filters to create the All-Pass (Elite) and All-Fail (Bottom-Tier) datasets.

### 6.2_infer_subset_trees.sh
```Bash
sbatch 6.2_infer_subset_trees.sh
```
A parallel Slurm Job Array (indices 0-5) that infers trees for six subsets: All-Pass, All-Fail, S3-Pass/Fail, and S4-Pass/Fail.

### 6.3_compare_trees.sh
```Bash
sbatch 6.3_compare_trees.sh
```
Compares the resulting trees against the 6.0 baseline to quantify topological shifts and support changes.

