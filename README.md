# Loci Simulation Scripts

## 0_data_prep

Prepares aligned loci for simulations by concatenating alignments and inferring an empirical tree.

### 0.0_amas_concat.sh

```bash
sbatch 0.0_amas_concat.sh
```

Runs AMAS on an empirical dataset to concatenate input fasta files and prepare partitions file ahead of IQTree run. Uses a helper Python script `run_amas.py`, which wraps around the `AMAS.py` concat command.

#### run_amas.py

A custom AMAS wrapper run by `0.0_amas_concat.sh`: processes FASTA alignments in batches of 1000 files (to avoid overloading AMAS input limitations), concatenates those outputs, and appends the results into cumulative files. Produces a concatenated alignment file and a corresponding partition file: ```concatenated.fasta partitions.txt```

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
Creates a local space for R packages (`~/R-packages`), runs `install.packages.R`, and installs necessary R packages.

#### install.packages.R

Checks for, installs, and loads necessary R packages.


### 1.1_format_tree.sh

Generates a formatted, ultrametric, and rescaled empirical species tree and a parameters file, which includes a random seed for reproducibility and estimated Ne (effective population size).

```bash
sbatch 1.1_format_tree.sh
```
Reformats empirical tree to produce ultrametric tree with numerical tip labels ahead of simulations.


## 2_simulation_setup

Generates simulation parameters, creates the command list, and executes simulations in parallel with built-in error recovery.

### 2.0_prep_simphy.sh

```bash
sbatch 2.0_prep_simphy.sh

```
Initiates the simulation parameter generation by calling `generate_sim_properties.R` to create the blueprint for 2,000 loci.

#### generate_sim_properties.R

An R script executed by `2.0_prep_simphy.sh`. Generates a CSV file (`df.csv`) containing stochastic parameters for each locus, including Effective Population Size (N_e), substitution rates, heterotachy parameters, and unique random seeds.

### 2.1_simphy_commands.sh

```bash
sbatch 2.1_simphy_commands.sh

```

The **Command Factory** script. Runs `run_SimPhy.R` to translate the CSV parameters into a raw list of 2,000 SimPhy terminal commands (`simphy_command_list.txt`).

#### run_SimPhy.R

An R script run by `2.1_simphy_commands.sh`. Maps variables from `df.csv` to SimPhy flags. It outputs `simphy_command_list.txt`, a 2,000-line file where each line is a unique, fully-formed SimPhy execution string.

### 2.2_run_simulations.sh

```bash
sbatch 2.2_run_simulations.sh

```

The **Executioner and Harvester** script. The primary workhorse script that executes simulations and ensures data integrity.

* **Parallel Execution:** Uses **GNU Parallel** to distribute 2,000 tasks across requested CPU cores. Includes a `--joblog` for resuming interrupted runs.
* **Auto-Recovery Loop:** Post-simulation, the script audits all 2,000 output folders. If a tree file is missing or 0 bytes, it extracts the original command from the command list and re-runs it (up to 2 retry attempts).
* **Sequential Harvesting:** Once verified, trees are gathered into a master `gene_trees.tre` file using a strict numerical loop (`1 to 2000`). This ensures that **Line N** in the tree file corresponds exactly to **Row N** in the parameter metadata.
* **Final Audit:** Performs a grep-count of Newick strings to confirm exactly 2,000 trees were successfully merged.
