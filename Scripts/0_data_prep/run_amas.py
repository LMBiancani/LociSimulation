#!/usr/bin/env python3
"""
run_amas.py
Concatenates FASTA alignments using AMAS (in batches of 1000 to avoid overloading AMAS input limitations).
Creates a concatenated alignment file and a corresponding partition file:
concatenated.fasta
partitions.txt

Usage:
    python run_amas.py <fasta_folder> <num_cores> <path_to_AMAS.py>
"""
import sys
import glob
import subprocess
import os

batch_size = 1000

# --- Input arguments ---
fasta_folder = sys.argv[1]
total_cores = sys.argv[2]
amas = sys.argv[3]

# --- Collect all fasta files (.fasta or .fas) ---
files = [f for f in glob.glob(os.path.join(fasta_folder, "*")) if f.endswith((".fasta", ".fas"))]
files.sort()  # ensure consistent, reproducible order

if not files:
    print(f"ERROR: No .fasta or .fas files found in {fasta_folder}")
    sys.exit(1)

batch_outputs = []
batch_parts = []

count = 0
fileList = []
batch_num = 1

# --- Process loci in batches ---
for f in files:
    fileList.append(f)
    count += 1

    if count == batch_size:
        batch_fasta = f"amas_batch_{batch_num}.fasta"
        batch_part = f"partitions_batch_{batch_num}.txt"

        cmd = (
            f"python3 {amas} concat "
            f"-f fasta -d dna --out-format fasta --part-format raxml "
            f"-i {' '.join(fileList)} "
            f"-c {total_cores} -t {batch_fasta} -p {batch_part}"
        )
        print(f"\n=== Running AMAS on batch {batch_num} ({len(fileList)} files) ===")
        subprocess.call(cmd, shell=True)

        batch_outputs.append(batch_fasta)
        batch_parts.append(batch_part)
        fileList = []
        count = 0
        batch_num += 1

# --- Final partial batch (if any) ---
if len(fileList) > 0:
    batch_fasta = f"amas_batch_{batch_num}.fasta"
    batch_part = f"partitions_batch_{batch_num}.txt"

    cmd = (
        f"python3 {amas} concat "
        f"-f fasta -d dna --out-format fasta --part-format raxml "
        f"-i {' '.join(fileList)} "
        f"-c {total_cores} -t {batch_fasta} -p {batch_part}"
    )
    print(f"\n=== Running AMAS on final batch {batch_num} ({len(fileList)} files) ===")
    subprocess.call(cmd, shell=True)

    batch_outputs.append(batch_fasta)
    batch_parts.append(batch_part)

# --- Final concatenation across all batches ---
print("\n=== Performing final concatenation across batches ===")

# 1. Concatenate the FASTA files (This part is fine for sequences)
cmd_final = (
    f"python3 {amas} concat "
    f"-f fasta -d dna --out-format fasta --out-format fasta " # No -p here, we do it manually
    f"-i {' '.join(batch_outputs)} "
    f"-c {total_cores} -t concatenated.fasta"
)
subprocess.call(cmd_final, shell=True)

# 2. Manually Merge Partitions to preserve individual locus boundaries
print("=== Merging batch partition files into final partitions.txt ===")
offset = 0
with open("partitions.txt", "w") as final_part:
    for part_file in batch_parts:
        with open(part_file, "r") as pf:
            last_end = 0
            for line in pf:
                if "=" in line:
                    # Example line: DNA, p799_SISRS_contig-999... = 1-500
                    parts = line.strip().split("=")
                    header = parts[0].strip() # "DNA, p799_SISRS_contig-999..."
                    
                    # 1. Remove the "p-number" prefix
                    # We split by "DNA, " then split the remainder by "_" exactly once
                    prefix_data = header.split("DNA, ")[1]
                    clean_locus_name = prefix_data.split("_", 1)[1]
                    
                    # 2. Reconstruct coordinates with the offset
                    coords = parts[1].strip().split("-")
                    start = int(coords[0]) + offset
                    end = int(coords[1]) + offset
                    
                    # 3. Write out the clean version
                    final_part.write(f"DNA, {clean_locus_name} = {start}-{end}\n")
                    last_end = int(coords[1])
            
            # Increase offset by the total length of this batch for the next batch
            offset += last_end

print(f"Total alignment length: {offset} bp across {len(files)} clean partitions.")

# --- Cleanup temporary batch files ---
print("\n=== Cleaning up intermediate files ===")
for f in batch_outputs + batch_parts:
    try:
        os.remove(f)
    except OSError:
        print(f"Warning: could not remove {f}")

print("\n=== run_amas.py execution completed. ===")
print("Output files:")
print(" - concatenated.fasta")
print(" - partitions.txt\n")
