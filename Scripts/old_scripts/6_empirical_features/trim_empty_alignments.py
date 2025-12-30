from Bio import AlignIO
from Bio.Align import MultipleSeqAlignment

input_folder1 = "McGowen_features/alignments2/"  # Folder with your input alignments
input_folder2 = "McGowen_features/alignments3/" #Folder with input alignments
output_folder1 = "McGowen_features/alignments4/"
output_folder2 = "McGowen_features/alignments5/"  # Folder to save the cleaned alignments
alignment_format = "fasta"  # Replace with your format (e.g., "phylip", "nexus")

import os

def remove_empty_taxa(input_file, output_file, alignment_format="fasta"):
    #print(input_file,output_file)
    try:
        alignment = AlignIO.read(input_file, alignment_format)
        #print(alignment)
        # Filter out taxa with all gaps/missing data
        cleaned_records = [
            record for record in alignment 
            if not all(base in ["-", "?", "N"] for base in str(record.seq))
        ] 
        if cleaned_records:
            # Recreate a MultipleSeqAlignment object
            cleaned_alignment = MultipleSeqAlignment(cleaned_records)
            AlignIO.write(cleaned_alignment, output_file, alignment_format)
        else:
            print(f"WARNING: No valid sequences left in {input_file}. Skipping.")
    except ValueError as e:
        print(f"ERROR: {e} in file {input_file}.Skipping.")


#remove_empty_taxa(input_file="McGowen_features/alignments2/DATASET_A_Subset1126-out.fas", output_file="McGowen_features/alignments4/DATASET_A_Subset1126-out.fas", alignment_format="fasta")

if not os.path.exists(output_folder1):
    os.makedirs(output_folder1)

if not os.path.exists(output_folder2):
    os.makedirs(output_folder2)

for file_name in os.listdir(input_folder1):
    if file_name.endswith(".fas") or file_name.endswith(".fasta"):  # Adjust extensions if needed
        input_file = os.path.join(input_folder1, file_name)
        output_file = os.path.join(output_folder1, file_name)
        #print(input_file,output_file)
        remove_empty_taxa(input_file, output_file, alignment_format)

for file_name in os.listdir(input_folder2):
    if file_name.endswith(".fas") or file_name.endswith(".fasta"):  # Adjust extensions if needed
        input_file = os.path.join(input_folder2, file_name)
        output_file = os.path.join(output_folder2, file_name)
        #print(input_file,output_file)
        remove_empty_taxa(input_file, output_file, alignment_format)
