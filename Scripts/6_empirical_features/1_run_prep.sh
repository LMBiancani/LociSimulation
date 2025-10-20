#!/bin/bash
#SBATCH --job-name="prep"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G



date


pwd

mkdir Fong_features
mkdir Wickett_features
mkdir McGowen_features
mkdir Liu_features


cd Fong_features
pwd
mkdir alignments2
cp ../../datasets/Fong_alignments/*fas alignments2/
aligned_loci_path="../alignments2"

mkdir alignmentGroups
cd alignmentGroups
ls ${aligned_loci_path} | rev | cut -f1 -d/ | rev | split -l 250 - aligned_loci_list_
ls aligned_loci_list_* > array_list.txt
cd ..

mkdir alignments3
mkdir iqtree_genetrees2
mkdir iqtree_genetrees3
mkdir phylomad_assessment
mkdir rate_assessment
mkdir iqtree_concattree
mkdir astral_tree
cd ..

cd Wickett_features
pwd     
mkdir alignments2
cp ../../datasets/Wickett_alignments/*f25 alignments2/

aligned_loci_path="../alignments2"
mkdir alignmentGroups
cd alignmentGroups
ls ${aligned_loci_path} | rev | cut -f1 -d/ | rev | split -l 250 - aligned_loci_list_
ls aligned_loci_list_* > array_list.txt
cd ..   
mkdir alignments3
mkdir iqtree_genetrees2
mkdir iqtree_genetrees3
mkdir phylomad_assessment
mkdir rate_assessment
mkdir iqtree_concattree
mkdir astral_tree
cd ..

cd Liu_features
pwd     
mkdir alignments2
cp ../../datasets/Liu_alignments/*fas alignments2/
aligned_loci_path="../alignments2"
mkdir alignmentGroups
cd alignmentGroups
ls ${aligned_loci_path} | rev | cut -f1 -d/ | rev | split -l 250 - aligned_loci_list_
ls aligned_loci_list_* > array_list.txt
cd ..   
mkdir alignments3
mkdir iqtree_genetrees2
mkdir iqtree_genetrees3
mkdir phylomad_assessment
mkdir rate_assessment
mkdir iqtree_concattree
mkdir astral_tree
cd ..


cd McGowen_features
pwd     

mkdir alignments2

cp ../../datasets/McGowen_alignments/*fas alignments2/
aligned_loci_path="../alignments2/"
mkdir alignmentGroups
cd alignmentGroups
ls ${aligned_loci_path} | rev | cut -f1 -d/ | rev | split -l 250 - aligned_loci_list_
ls aligned_loci_list_* > array_list.txt
cd ..   
mkdir alignments3
mkdir iqtree_genetrees2
mkdir iqtree_genetrees3
mkdir phylomad_assessment
mkdir rate_assessment
mkdir iqtree_concattree
mkdir astral_tree

date
