#!/usr/bin/env python3
"""
run_amas.py
------------
Concatenates FASTA alignments in batches using AMAS to avoid memory overload.
Creates a concatenated alignment file and a corresponding partition file.

Usage:
    python run_amas.py <fasta_folder> <num_cores> <path_to_AMAS.py>
"""

import sys
import glob
import subprocess
from pathlib import Path

# -----------------------------
# Parse command-line arguments
# -----------------------------
if len(sys.argv) != 4:
    sys.exit("Usage: python run_amas.py <fasta_folder> <num_cores> <path_to_AMAS.py>")

fasta_folder = Path(sys.argv[1])
total_cores = sys.argv[2]
amas = sys.argv[3]

# -----------------------------
# Gather all FASTA files
# -----------------------------
files = sorted(glob.glob(str(fasta_folder / "*.fasta")))
if not files:
    sys.exit(f"No FASTA files found in {fasta_folder}")

# -----------------------------
# Prepare output filenames
# -----------------------------
concat_out = "concatenated.fasta"
part_out = "concatenated_partitions.txt"

# Clean up any old results
subprocess.run(["rm", "-f", concat_out, part_out])

# -----------------------------
# Define a helper to run AMAS
# -----------------------------
def run_amas_batch(batch_files, first_batch):
    """Run AMAS concat on a batch of files and append results."""
    cmd = [
        "python", amas, "concat",
        "-c", total_cores,
        "-t", "amas_output_temp.fasta",
        "-f", "fasta",
        "-d", "dna",
        "--out-format", "fasta",
        "--part-format", "raxml",
        "-p", "partitions_temp.txt",
        "-i"
    ] + batch_files
    subprocess.run(cmd, check=True)

    if first_batch:
        # First batch: initialize output files
        subprocess.run(["sed", "-e", "$a\\", "amas_output_temp.fasta"], stdout=open(concat_out, "w"))
        subprocess.run(["sed", "-e", "$a\\", "partitions_temp.txt"], stdout=open(part_out, "w"))
    else:
        # Subsequent batches: append excluding the first line
        with open(concat_out, "a") as cat_out:
            subprocess.run("sed -e 1d amas_output_temp.fasta | sed -e '$a\\'", shell=True, stdout=cat_out)
        with open(part_out, "a") as part_cat:
            subprocess.run("sed -e 1d partitions_temp.txt | sed -e '$a\\'", shell=True, stdout=part_cat)

# -----------------------------
# Process files in batches of 1000
# -----------------------------
batch_size = 1000
batch = []
first_batch = True

for f in files:
    batch.append(f)
    if len(batch) == batch_size:
        run_amas_batch(batch, first_batch)
        first_batch = False
        batch = []

# Process remaining files
if batch:
    run_amas_batch(batch, first_batch)

print("AMAS concatenation complete.")
