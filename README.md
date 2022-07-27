# PML
Phylogenetic Machine Learning and Sequence Simulations

Add contents here

## Simulation

### Species tree simulation

#### Empirical species trees

##### Infer trees of empirical datasets in IQ-TREE

For consistency, as well as because not all studies release the tree files, the trees were inferred denovo based on provided alignments

##### Prepare the starting trees for simulation

First create a folder for empirical simulations

```
mkdir -p simulations/empirical/fong/1/
mkdir -p simulations/empirical/wickett/1/
mkdir -p simulations/empirical/mcgowen/1/
mkdir -p simulations/empirical/liu/1/
```

Place the inferred phylograms for each dataset in the corresponding `1` folder under the name of `inference.treefile`.

Then run the following code in R:

```
library(ape)
library(ggplot2)
library(ggtree)
```

Adjust the path to `modified.write.tree2.R`:
```
source("/home/alex/tools/PML/simulation/modified.write.tree2.R")
assignInNamespace(".write.tree2", .write.tree2, "ape")
```

Adjust the paths to ML species trees for each dataset.

Empirical species tree 1 (Fong et al.):
```
fong_tree <- read.tree("simulations/empirical/fong/1/inference.treefile")
fong_tree <- root(fong_tree, outgroup = "Danio")
ggtree(fong_tree) + theme_tree2()
```
Check the tree rooted correctly. Then transform to ultrametric and rescale to correct number of generations
```
fong_tree_um <- chronos(fong_tree)
class(fong_tree_um) <-"phylo"
fong_scale <- 435000000/10
fong_tree_um <- rescale(fong_tree_um, model = "depth", fong_scale)
ggtree(fong_tree_um) + theme_tree2()
```
Check the tree is correct. Then replace labels with numbers as in regular SimPhy simulations and strip off the node labels (if any). Write out the tree and seeds for subsequent dataset parameter simulations.
```
fong_tree_um$tip.label <- as.character(1:length(fong_tree_um$tip.label))
fong_tree_um$node.label <- NULL
write.tree(fong_tree_um, "simulations/empirical/fong/1/s_tree.trees", digits=8)
write(c(20001,10000),"simulations/empirical/fong/generate_params.txt")
```

Analogously process other datasets:

Empirical species tree 2 (Wickett et al.):
```
wickett_tree <- read.tree("simulations/empirical/wickett/1/inference.treefile")
wickett_tree <- root(wickett_tree, outgroup = "Pyramimonas_parkeae")
wickett_tree_um <- chronos(wickett_tree)
class(wickett_tree_um) <-"phylo"
wickett_scale <- 1200000000/5
wickett_tree_um <- rescale(wickett_tree_um, model = "depth", wickett_scale)
wickett_tree_um$tip.label <- as.character(1:length(wickett_tree_um$tip.label))
wickett_tree_um$node.label <- NULL
write.tree(wickett_tree_um, "simulations/empirical/wickett/1/s_tree.trees", digits=8)
write(c(20002,100000),"simulations/empirical/wickett/generate_params.txt")
```

Empirical species tree 3 (McGowen et al.):
```

mcgowen <- read.nexus("simulations/empirical/mcgowen/1/cetTree1.tre")
mcgowen_um <- chronos(mcgowen)
class(mcgowen_um) <-"phylo"
mcgowen_scale <- 75000000/20
mcgowen_um <- rescale(mcgowen_um, model = "depth", mcgowen_scale)
mcgowen_um$tip.label <- as.character(1:length(mcgowen_um$tip.label))
write.tree(mcgowen_um, "simulations/empirical/mcgowen/1/s_tree.trees", digits=8)
write(c(20003,1000),"simulations/empirical/mcgowen/generate_params.txt")
```

Empirical species tree 4 (Liu et al.):
```
liu_tree <- read.tree("simulations/empirical/liu/1/inference.treefile")
liu_tree <- root(liu_tree, outgroup = "danio_rer")
liu_tree_um <- chronos(liu_tree)
class(liu_tree_um) <-"phylo"
liu_scale <- 435000000/10
liu_tree_um <- rescale(liu_tree_um, model = "depth", liu_scale)
liu_tree_um$tip.label <- as.character(1:length(liu_tree_um$tip.label))
liu_tree_um$node.label <- NULL
write.tree(liu_tree_um, "simulations/empirical/liu/1/s_tree.trees", digits=8)
write(c(20004,10000),"simulations/empirical/liu/generate_params.txt")
```

#### Random species trees

Make the folder for random species tree simulations
```
mkdir simulation/random
cd simulation/random/
```
Run the SimPhy wrapper to simulate each dataset
```
Rscript ~/tools/PML/simulation/run_sptree_SimPhy.R
```

### Locus alignments simulation

For each simulated dataset, navigate into corresponding dataset directory, for ex
```
cd simulations/empirical/fong/
```

Then run the following commands (adjust the paths to scripts accordingly):
```
Rscript ~/tools/PML/simulation/generate_sim_properties.R
Rscript ~/tools/PML/simulation/run_SimPhy.R sptree.nex df.csv
Rscript ~/tools/PML/simulation/prep_INDELible.R ./gene_trees.tre ./df.csv
cd alignments1
cp ../control.txt .
~/tools/INDELibleV1.03/src/indelible
cp ../controlCDS.txt ./control.txt
~/tools/INDELibleV1.03/src/indelible
cd ../
Rscript ~/tools/PML/simulation/post_INDELible.R alignments1/ df.csv
```

Assess features like pairwise distance, ILS levels, etc.

Repeat for all datasets (species trees)

## Assess loci properties

### Run assessment programs

For each simulated dataset, transfer the folder `alignments2` to a similarly structured folder on a cluster with slurm. Additionally transfer scripts / clone the repo to the cluster as well. Make sure that `MAFFT`, `AMAS`, `IQ-TREE2`, `FastSP`, and `HyPhy` are installed, and correct paths/modules in the submission scripts as needed.

Then, in a given dataset directory (where the folder `alignments2` is located) run the prep script to set up necessary folders:
```
sbatch prep.sh
```

When complete, submit the alignment job (8 array elements correspond to 2000 files split into 250 file bins):
```
sbatch --array=1-8 mafft.sh
```

When complete, submit jobs to run AMAS (properties), IQ-TREE (trees), and FastSP (alignment accuracy)
```
sbatch run_amas.sh
sbatch --array=1-8 iqtree_array.sh
sbatch run_FastSP.sh
sbatch iqtree_concat.sh
```

When complete, submit a job to prepare species tree for each locus to assess rates with HyPhy
```
sbatch prune_rescale_species_tree.sh
```

When complete, submit jobs to run HyPhy to assess site rates for each locus (since separate trees were estimated for Train and Test datasets, rate assessments are done separately as well):
```
sbatch --array=1-4 rate_assessment_Train.sh
sbatch --array=5-8 rate_assessment_Test.sh
```

When complete, download/assemble together the following files/folders for the final assessment steps:
```
inferred_gene_trees*
pruned_species_trees*
amas_output?.txt
rate_assessment
alignments3
fastsp_output.csv
iqtree_concattree/inference*.treefile
```
An example of the `rsync` command would be:
```
rsync -avzr andromeda:/path_to_dataset/inferred_gene_trees* local_path
```

### Run assessment script

For simulation datasets the true trees are known. So instead of using pruned and rescaled inferred trees, we prepare the true simulated trees.

For each dataset, run the following commands:

Run this command to prepare the true species trees for feature assessments:
```
Rscript ~/tools/PML/feature_assessment/prune_tree_simul.R 1/s_tree.trees inferred_gene_trees_Train.tre pruned_simul_trees_Train.tre
Rscript ~/tools/PML/feature_assessment/prune_tree_simul.R 1/s_tree.trees inferred_gene_trees_Test.tre pruned_simul_trees_Test.tre
```

When complete, run the main feature assessment script
```
Rscript ~/tools/PML/feature_assessment/assess_gene_properties.R ./alignments3/ inferred_gene_trees_Train.tre inferred_gene_trees_Train.txt pruned_simul_trees_Train.tre amas_output3.txt ./rate_assessment/ ML_train.txt ./fastsp_output.csv
Rscript ~/tools/PML/feature_assessment/assess_gene_properties.R ./alignments3/ inferred_gene_trees_Test.tre inferred_gene_trees_Test.txt pruned_simul_trees_Test.tre amas_output3.txt ./rate_assessment/ ML_test.txt ./fastsp_output.csv
```

Output files are `ML_train.txt` and `ML_test.txt` respectively. These files are used for some of the downstream interrogations, however, to train / use the machine learning model, ML_train/test file for all datasets are combined together and certain columns are excluded (for ex, wRF column is excluded when training using RF as the proxy for phylogenetic utility).

### Assessment summary

```
R scripts for figs 1, 2
```

## Model training

### Prepare (combine) dataset tables

Before the model is trained, feature assessment tables across all simulation datasets are merged together and subsetted based on the type of model training (for ex, wRF column is excluded when training using RF as the proxy for phylogenetic utility). 

First, prepare a file with a list of files to consider:
```
path_to_simulations/empirical/fong/ML_train.txt
path_to_simulations/empirical/wickett/ML_train.txt
...
etc
```

Then create final files for model training and locus utility prediction, excluding certain columns as follows:
```
#RF similarity
#train Y
python3 ~/tools/PML/model_training/prep_train_table.py train_list.txt 2 3
#all woY
python3 ~/tools/PML/model_training/prep_train_table.py all_list.txt 1 2 3

#wRF similarity
#train Y
python3 ~/tools/PML/model_training/prep_train_table.py train_list.txt 1 3
#all woY
python3 ~/tools/PML/model_training/prep_train_table.py all_list.txt 1 2 3
```


### Run model training

For each of the Y variables, train the model:
```
python ~/tools/PML/model_training/train_random_forest.py RFtrain_tab.tsv
```
and / or:
```
python ~/tools/PML/model_training/train_random_forest.py wRFtrain_tab.tsv
```

Each time the trained model will be saved in a file `model_file.bin` (can overwrite previous results)


## Evaluate model training

### Accuracy / interaction btw features

```
interaction evaluations here, fig 4
```

```
Other features here, R script for figs 3, 5, 6
```


### Impact of subsampling

```
Scripts for fig 7
```


## Evaluate empirical datasets

### Assess features

### Predict utility

### Subsetting experiments

Done