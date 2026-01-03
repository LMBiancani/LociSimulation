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

# --- Variables ---
Project="/scratch4/workspace/biancani_uri_edu-LociSimulation"
Output="$Project/output/mammals"
Original_Alignments="$Output/2.4_final_named_alignments"

# Input Directories
S3_Pass="$Output/3.3_loci_filtered_by_known_clades/pass_0.05"
S3_Fail="$Output/3.3_loci_filtered_by_known_clades/fail_0.05"
S4_Pass="$Output/4.2_BLC_filtered/pass_loci"
S4_Fail="$Output/4.2_BLC_filtered/fail_loci"

# Define and Create Output Directory
OutDir="$Output/6.1_intersection_data"
mkdir -p "$OutDir/all_pass" "$OutDir/all_fail" \
         "$OutDir/S3_pass_S4_fail" "$OutDir/S4_pass_S3_fail" \
         "$OutDir/fail_at_least_one" "$OutDir/pass_at_least_one"

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
            cp "$Original_Alignments/$locus" "$dest/"
        done < "$list"
    else
        echo "Warning: No names found in $list for $dest"
    fi
}

# Generate a master list of all 2000 loci for subtraction logic
ls "$Original_Alignments" | sort > master_list.txt

# Existing list files
ls "$S3_Pass" | sort > s3_pass_list.txt
ls "$S3_Fail" | sort > s3_fail_list.txt
ls "$S4_Pass" | sort > s4_pass_list.txt
ls "$S4_Fail" | sort > s4_fail_list.txt

# --- Intersection Logic ---

# 1. ALL PASS (Elite: 529)
comm -12 s3_pass_list.txt s4_pass_list.txt > elite_names.txt

# 2. ALL FAIL (Noisy: 28)
comm -12 s3_fail_list.txt s4_fail_list.txt > noisy_names.txt

# 3. S3 PASS / S4 FAIL (104)
comm -12 s3_pass_list.txt s4_fail_list.txt > s3p_s4f_names.txt

# 4. S4 PASS / S3 FAIL (1,339)
comm -12 s4_pass_list.txt s3_fail_list.txt > s4p_s3f_names.txt

# 5. FAIL AT LEAST ONE (Everything except Elite: 1,471)
comm -23 master_list.txt elite_names.txt > fail_at_least_one_names.txt

# 6. PASS AT LEAST ONE (Everything except Noisy: 1,972)
comm -23 master_list.txt noisy_names.txt > pass_at_least_one_names.txt

echo "------------------------------------------------"
echo "INTERSECTION SUMMARY REPORT"
echo "------------------------------------------------"
copy_loci elite_names.txt "all_pass"
copy_loci noisy_names.txt "all_fail"
copy_loci s3p_s4f_names.txt "S3_pass_S4_fail"
copy_loci s4p_s3f_names.txt "S4_pass_S3_fail"
copy_loci fail_at_least_one_names.txt "fail_at_least_one"
copy_loci pass_at_least_one_names.txt "pass_at_least_one"
echo "------------------------------------------------"

# --- Cleanup ---
rm *_list.txt *_names.txt

echo "Step 6.1 Complete. Intersection datasets are ready."
