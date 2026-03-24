#!/bin/bash
#SBATCH --job-name=filter_loci
#SBATCH --partition=uri-cpu
#SBATCH --time=00:15:00
#SBATCH --mem=1G

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

for random_seed in $seeds; do
  set_dir="set_$random_seed"
  echo "Gathering trees for simulation $set_dir";
  
  FinalDir="$out6_3/$set_dir"
  mkdir -p "$FinalDir"

  # 1. Unfiltered (Note: out4_0 path)
  cp "$out4_0/$set_dir/Unfiltered_loci_ref_tree.treefile" "$FinalDir/Unfiltered_all_Loci.treefile"

  # 2. Subset Trees (Tasks 0-9 from Step 6.2)
  # We use a list to make the code cleaner and less prone to typos
  subsets="all_PASS all_FAIL clades_PASS clades_FAIL blc_PASS blc_FAIL \
           clades_PASS_blc_FAIL blc_PASS_clades_FAIL FAIL_at_least_one PASS_at_least_one"

  for name in $subsets; do
    SOURCE_FILE="$out6_2/$set_dir/$name/${name}_tree.treefile"
    if [ -f "$SOURCE_FILE" ]; then
        cp "$SOURCE_FILE" "$FinalDir/${name}.treefile"
    else
        echo "Warning: $name tree not found for $set_dir"
    fi
  done

  echo "Gathered trees in $FinalDir:"
  ls "$FinalDir"
done
