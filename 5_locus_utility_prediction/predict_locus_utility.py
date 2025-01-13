'''
A script to use a trained random forest regressor
model to predict locus utility
'''
import sys
import pandas as ps
import numpy as np
import pickle
import argparse
import csv
from sklearn.preprocessing import StandardScaler

from treeinterpreter import treeinterpreter as ti


def parse_input_table(input_table):
    '''
    A function to parse input table and extract X data
    '''
    locnames = []
    headers = input_table.columns.values.tolist()
    feature_names = headers[1:]
    x_data = []
    for index, row in input_table.iterrows():
        # locus name
        locnames.append(row[0])
        # features`
        x_data.append(row[1:])
    return locnames, np.array(x_data), feature_names


def main():
    '''
    The main function
    '''
    parser = argparse.ArgumentParser(description='Predict locus utility using' +
                ' random forest regressor',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser._action_groups.pop()
    required = parser.add_argument_group('required arguments')

    required.add_argument('-i', metavar='table', help='input table file',
                            dest="locus_data", required=True)
    required.add_argument('-m', metavar='modelfile', help='input trained model',
                            dest="modelfilename", required=True)
    
    required.add_argument('-o', metavar='table', help='output table file',
                            dest="outfile", required=True)


    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit()
    else:
        args = parser.parse_args()
        locus_data = ps.read_csv(vars(args)["locus_data"], sep='\t')
        with open(vars(args)["modelfilename"], 'rb') as f:
            data = pickle.load(f)

        if isinstance(data, tuple) and len(data) == 2:
            rfr_tt, scaler = data
        else:
            raise ValueError("Unexpected content in the pickle file. Expected a tuple with (model, scaler).")
        
        #parse the input table
        locnames, x_data, feature_names = parse_input_table(locus_data)
	# Apply the same scaling to the prediction data
        x_data_scaled = scaler.transform(x_data)
        
        # Ensure x_data_scaled is of correct type (if necessary)
        x_data_scaled = np.array(x_data_scaled).astype(np.float32)



        #predict and calculate contributions
        preds, contributions, bias = ti.predict(rfr_tt, x_data_scaled)
        print (preds, contributions, bias)
        #save results
    with open(args.outfile, "w", newline='') as outf:
        writer = csv.writer(outf)
    
        #Write the header
        header = ["locname", "predicted_utility"] 
        writer.writerow(header)
    
        for x in range(len(locnames)):
            predicted_utility = str(preds[x][0])  # If preds is 1D, no indexing with [0]
            #feature_contributions = list(contributions[x])  # Ensure contributions[x] is iterable
            row = locnames[x], predicted_utility
            writer.writerow(row)



if __name__ == "__main__":
    main()
