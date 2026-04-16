#!/bin/bash
#SBATCH --job-name=gather_results
#SBATCH --partition=uri-cpu
#SBATCH --time=00:15:00
#SBATCH --mem=1G

# Source parameters script:
vars="/scratch4/workspace/biancani_uri_edu-LociSimulation/LociSimulation/Scripts/variables.sh"
source $vars
echo "Variables sourced into current shell environment:"
cat $vars

# Define the results file location
mkdir -p $out6_5
ResultsCSV="$out6_5/Results_All_Seeds.csv"

echo "Merging results from $out6_4 into $ResultsCSV"

# 1. Create the results file with a header (Updated to "Simulation_Set")
first_seed=$(echo $seeds | awk '{print $1}')
header=$(head -n 1 "$out6_4/set_$first_seed/Tree_Comparison_Report.csv")
echo "Simulation_Set,$header" > "$ResultsCSV"

# 2. Loop through each seed and append the data
for random_seed in $seeds; do
    input_file="$out6_4/set_$random_seed/Tree_Comparison_Report.csv"
    
    if [ -f "$input_file" ]; then
        echo "Processing Seed: $random_seed"
        # Prepend "Set_" followed by the seed number to every line
        # sed "s/^/Set_$random_seed,/" inserts the string at the start of the line
        tail -n +2 "$input_file" | sed "s/^/Set_$random_seed,/" >> "$ResultsCSV"
    else
        echo "Warning: No results found for seed $random_seed"
    fi
done

echo "Done! results file created with $(wc -l < $ResultsCSV) lines."
