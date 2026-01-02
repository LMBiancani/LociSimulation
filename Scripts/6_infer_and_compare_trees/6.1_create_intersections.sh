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

# Output Directory
OutDir="$Output/6.1_intersection_data"
mkdir -p "$OutDir/all_pass" "$OutDir/all_fail"

# Move to output directory to generate lists
cd "$OutDir"

# Temporary list files for matching
ls "$S3_Pass" | sort > s3_pass_list.txt
ls "$S3_Fail" | sort > s3_fail_list.txt
ls "$S4_Pass" | sort > s4_pass_list.txt
ls "$S4_Fail" | sort > s4_fail_list.txt

# 1. Intersection: ALL PASS (Passed Clade Test AND BLC Test)
comm -12 s3_pass_list.txt s4_pass_list.txt > all_pass_names.txt

# 2. Intersection: ALL FAIL (Failed Clade Test AND BLC Test)
comm -12 s3_fail_list.txt s4_fail_list.txt > all_fail_names.txt

# Function to copy files based on the generated lists
copy_loci() {
    list=$1
    dest=$2
    if [ -s "$list" ]; then
        count=$(wc -l < "$list")
        echo "Copying $count loci to $dest..."
        while read locus; do
            cp "$Original_Alignments/$locus" "$dest/"
        done < "$list"
    else
        echo "Warning: No loci found for $dest"
    fi
}

# Execute copies
copy_loci all_pass_names.txt "all_pass"
copy_loci all_fail_names.txt "all_fail"

# Cleanup temp files
rm s3_pass_list.txt s3_fail_list.txt s4_pass_list.txt s4_fail_list.txt

echo "Step 6.1 Complete. Intersection datasets are ready."
