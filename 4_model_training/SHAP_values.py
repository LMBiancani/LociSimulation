'''
A script to compute SHAP values to explore feature importances for a random forest regressor
Code written by Alexandra Walling
'''
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import pickle
import argparse
import itertools
from sklearn import tree
from matplotlib import pyplot as plt  
from sklearn.utils import shuffle
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score
import shap 

def center(arr):
    '''
    A function to center an array
    '''
    return arr - np.mean(arr)

def parse_input_table(input_table):
    '''
    A function to parse input table and split into
    X and Y data
    '''
    y_data = []
    headers = input_table.columns.values.tolist()
    feature_names = headers[2:]
    x_data = []
    for index, row in input_table.iterrows(): #Loops through the data frame
        # (y value) Response Variable 
        y_data.append(row[1])
        # features
        x_data.append(row[2:])
    return y_data, x_data, feature_names




def main():
    '''
    The main function
    '''
    parser = argparse.ArgumentParser(description='Train Random Forest',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser._action_groups.pop()
    required = parser.add_argument_group('required arguments')
    optional = parser.add_argument_group('optional arguments')

    required.add_argument('-i', metavar='table', help='input table file',
                            dest="locus_data", required=True)
    required.add_argument('-m', metavar='modelfile', help='input trained model',
                            dest="modelfilename", required=True)
    optional.add_argument('-t', metavar='N', help='number of threads',
                            dest="n_jobs", type=int, default=1)
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit()
    else:
        args = parser.parse_args()
        locus_data = pd.read_csv(vars(args)["locus_data"], sep='\t')
        with open(vars(args)["modelfilename"], 'rb') as f:
            rfr_tt = pickle.load(f)
        n_jobs = vars(args)["n_jobs"]

        #reformat data
        #parse the input table
        y_data, x_data, feature_names = parse_input_table(locus_data)
        x_data = pd.concat(x_data, axis=1).T 
        x_data = x_data.values.astype(np.float32)
        y_data = np.array(y_data).astype(np.float32)

        #Split the dataset into training and test 
        Xtrain, Xval, Ytrain, Yval = train_test_split(x_data, y_data,
                                                random_state=42,
                                                train_size=0.75)
        #make predictions
        y_pred = rfr_tt.predict(Xval)



        #Evaluate the model
        r2 = r2_score(y_pred=y_pred, y_true=Yval)
        plt.plot(Yval, y_pred, ".")
        plt.title(f"$R^2$ score on test data = {r2:.4f}");
        plt.savefig('r2_score_rfr.png', dpi = 300, bbox_inches='tight')
        plt.close()

        #Initialize the SHAP explainer
        explainer=shap.TreeExplainer(rfr_tt, Xval, model_output="raw")

        #Calculate SHAP values

        shap_values = explainer(Xval)

        #Plot SHAP values summary plot

        shap.summary_plot(shap_values, features=Xval, feature_names=feature_names)
	
	#Save figure
        plt.savefig('rfr_shap_summary_plot.png', dpi=300, bbox_inches='tight')
        plt.close()

if __name__ == "__main__":
    main()
