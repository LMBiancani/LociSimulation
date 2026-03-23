#!/bin/bash
#SBATCH --job-name="6.1_intersection"
#SBATCH --time=00:15:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=1G
#SBATCH -p uri-cpu
#SBATCH --constraint=avx512
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

random_seed=$1
echo "Random number seed = $random_seed"
dir_name="set_$random_seed"

# Source master parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

# --- Variables ---

# Final named alignments from 2.4)
Alignments="$out2_4/$dir_name"

# Input Directories
clades_PASS="$out3_3/$dir_name/pass_0.05"
clades_FAIL="$out3_3/$dir_name/fail_0.05"
blc_PASS="$out4_2/$dir_name/pass_loci"
blc_FAIL="$out4_2/$dir_name/fail_loci"

# Define and Create Output Directory
OutDir="$out6_1/$dir_name"
mkdir -p "$OutDir/all_PASS" "$OutDir/all_FAIL" \
         "$OutDir/clades_PASS_blc_FAIL" "$OutDir/blc_PASS_clades_FAIL" \
         "$OutDir/FAIL_at_least_one" "$OutDir/PASS_at_least_one"

# Move to output directory for generating lists
cd "$OutDir"

# Ensure consistent sorting for comm command
export LC_ALL=C

# --- Function to copy files based on the generated lists ---
copy_loci() {
    local list=$1
    local dest=$2
    if [ -s "$list" ]; then
        count=$(wc -l < "$list")
        echo "Processing $dest: Copying $count loci..."
        # -r prevents backslash interpretation, IFS= prevents trimming whitespace
        while IFS= read -r locus; do
            cp "$Alignments/$locus" "$dest/"
        done < "$list"
    else
        echo "Warning: No names found in $list for $dest"
    fi
}

# Generate a master list of all 2000 loci for subtraction logic
ls "$Alignments" | sort > master_list.txt

# Existing list files
ls "$clades_PASS" | sort > clades_PASS_list.txt
ls "$clades_FAIL" | sort > clades_FAIL_list.txt
ls "$blc_PASS" | sort > blc_PASS_list.txt
ls "$blc_FAIL" | sort > blc_FAIL_list.txt

# --- Intersection Logic ---

# 1. ALL PASS (Elite: 529)
comm -12 clades_PASS_list.txt blc_PASS_list.txt > elite_names.txt

# 2. ALL FAIL (Noisy: 28)
comm -12 clades_FAIL_list.txt blc_FAIL_list.txt > noisy_names.txt

# 3. clades PASS / blc FAIL (104)
comm -12 clades_PASS_list.txt blc_FAIL_list.txt > cladesP_blcF_names.txt

# 4. blc PASS / clades FAIL (1,339)
comm -12 blc_PASS_list.txt clades_FAIL_list.txt > blcP_cladesF_names.txt

# 5. FAIL AT LEAST ONE (Everything except Elite: 1,471)
comm -23 master_list.txt elite_names.txt > FAIL_at_least_one_names.txt

# 6. PASS AT LEAST ONE (Everything except Noisy: 1,972)
comm -23 master_list.txt noisy_names.txt > PASS_at_least_one_names.txt

echo "------------------------------------------------"
echo "INTERSECTION SUMMARY REPORT"
echo "------------------------------------------------"
copy_loci elite_names.txt "all_PASS"
copy_loci noisy_names.txt "all_FAIL"
copy_loci cladesP_blcF_names.txt "clades_PASS_blc_FAIL"
copy_loci blcP_cladesF_names.txt "blc_PASS_clades_FAIL"
copy_loci FAIL_at_least_one_names.txt "FAIL_at_least_one"
copy_loci PASS_at_least_one_names.txt "PASS_at_least_one"
echo "------------------------------------------------"

# --- Cleanup ---
rm *_list.txt *_names.txt

echo "Step 6.1 Complete. Intersection datasets are ready."
