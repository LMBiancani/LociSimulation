#!/usr/bin/env python3
"""
run_amas.py
------------
Concatenates FASTA alignments in batches using AMAS (to avoid overloading AMAS input limitations).
Creates a concatenated alignment file and a corresponding partition file:
concatenatedTrain.fasta
partitionsTrain.txt

Usage:
    python run_amas.py <fasta_folder> <num_cores> <path_to_AMAS.py>
"""

import sys
import glob
import subprocess
import os

# --- Input arguments ---
fasta_folder = sys.argv[1]
total_cores = sys.argv[2]
amas = sys.argv[3]

# --- Collect all fasta files ---
files = glob.glob(os.path.join(fasta_folder, "*.fasta"))
files.sort()  # ensure consistent, reproducible order

batch_size = 1000
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

cmd_final = (
    f"python3 {amas} concat "
    f"-f fasta -d dna --out-format fasta --part-format raxml "
    f"-i {' '.join(batch_outputs)} "
    f"-c {total_cores} -t concatenated.fasta -p partitions.txt"
)
subprocess.call(cmd_final, shell=True)

# --- Cleanup temporary batch files ---
print("\n=== Cleaning up intermediate files ===")
for f in batch_outputs + batch_parts:
    try:
        os.remove(f)
    except OSError:
        print(f"Warning: could not remove {f}")

print("\n=== All done! ===")
print("Output files:")
print(" - concatenated.fasta")
print(" - partitions.txt\n")
