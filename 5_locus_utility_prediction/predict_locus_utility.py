'''
A script to use a trained random forest regressor
model to predict locus utility
'''
import sys
import pandas as ps
import numpy as np
import pickle
import argparse

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
        # features
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
            rfr_tt = pickle.load(f)
        #parse the input table
        locnames, x_data, feature_names = parse_input_table(locus_data)
        x_data = x_data.astype(np.float32)
	#predict and calculate contributions
        preds, bias, contributions = ti.predict(rfr_tt, x_data)
        #save results
        with open(vars(args)['outfile'], "w") as outf:
            print("locname,predicted_utility,"+",".join(feature_names), file=outf)
            for x in range(len(locnames)):
                print(locnames[x] + "," + str(preds[x][0]) + "," +
                        ",".join([str(y) for y in contributions[x]]), file=outf)


if __name__ == "__main__":
    main()
