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

```bash
sbatch 1.1_format_tree.sh
```
Reformats empirical tree to produce ultrametric tree with numerical tip labels ahead of simulations.
