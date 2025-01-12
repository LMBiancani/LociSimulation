'''
Alexandra Walling 
A script to train a Support Vector Machine regressor
and use SHAP values to evaluate feature importances
'''


import os
import sys
import pandas as pd
import numpy as np
import argparse
import pickle
import matplotlib as mpl 
from matplotlib import pyplot as plt 
from sklearn.preprocessing import StandardScaler
from sklearn.utils import shuffle
from sklearn.svm import SVR
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score
import shap
from sklearn.model_selection import GridSearchCV



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
    parser = argparse.ArgumentParser(description='Train SVR',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser._action_groups.pop()
    required = parser.add_argument_group('required arguments')
    optional = parser.add_argument_group('optional arguments')

    required.add_argument('-i', metavar='table', help='input table file',
                            dest="locus_data", required=True)
    
    optional.add_argument('-t', metavar='N', help='number of threads',
                            dest="n_jobs", type=int, default=1)
    required.add_argument('-o', metavar="output", help="output file name", 
                            dest = "output_file", type=str, required=True)

    if len(sys.argv) == 0:
        parser.print_help()
        sys.exit()
    else:
        args = parser.parse_args()
        locus_data = pd.read_csv(vars(args)["locus_data"], sep='\t')
        n_jobs = vars(args)["n_jobs"]        

        #parse the input table
        y_data, x_data, feature_names = parse_input_table(locus_data)
        #Split the dataset into training and test 
        x_data, y_data = shuffle(x_data, y_data)
        Xtrain, Xval, Ytrain, Yval = train_test_split(x_data, y_data, train_size=0.7)

        # scale the X data 
        scaler = StandardScaler()
        scaler.fit(Xtrain)
        Xtrain, Xval = scaler.transform(Xtrain), scaler.transform(Xval)
        
    # Define the parameter grid
    #param_grid = {
    #    'C': [0.1, 1, 10, 100],
    #    'gamma': ['scale', 'auto', 0.001, 0.01, 0.1, 1],
    #    'epsilon': [0.1, 0.2, 0.5, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

    #}


    #Train SVR
    #svm_regressor_scaled = SVR(kernel='rbf')
    

    # Set up the GridSearchCV
    #grid_search = GridSearchCV(estimator=svm_regressor_scaled, param_grid=param_grid, cv=5, scoring='neg_mean_squared_error', verbose=2, n_jobs=-1)

    #Fit the GridSearchCV to the data
    #grid_search.fit(Xtrain, Ytrain)

    # Get the best parameters and the best model
    #best_params = grid_search.best_params_
    #best_model = grid_search.best_estimator_
    #print("Best Parameters:", best_params)
    
    #Fit the model
    #svm_regressor_scaled.fit(Xtrain, Ytrain) 
    



    # Define specific parameters
    specific_params = {
        'C': 10,         # Replace with your chosen value for C
        'gamma': 0.01,   # Replace with your chosen value for gamma
        'epsilon': 0.2   # Replace with your chosen value for epsilon
    }

    # Train SVR with specific parameters
    svm_regressor_scaled = SVR(kernel='rbf', 
                               C=specific_params['C'], 
                               gamma=specific_params['gamma'], 
                               epsilon=specific_params['epsilon'])

    # Fit the model to the data
    svm_regressor_scaled.fit(Xtrain, Ytrain)

    # Optional: Evaluate the model on training data or test data
    print("Model trained with specific parameters: C=10, gamma=0.01, epsilon=0.2.")

    
    #save the model
    with open(vars(args)["output_file"], 'wb') as f:
        pickle.dump((svm_regressor_scaled, scaler), f) 
    # Use the best parameters to predict
    y_pred = svm_regressor_scaled.predict(Xval)
    mse = mean_squared_error(Yval, y_pred)
    
    print("Mean Squared Error:", mse)
    
        
    r2= r2_score(y_pred=y_pred, y_true=Yval)

    plt.plot(Yval, y_pred, ".")
    plt.title(f"R^2$ score on test data = {r2:.4f}");
    plt.savefig('r2_score_wrf_SVM.png', dpi = 300, bbox_inches='tight')
    plt.close()

    #Initialize SHAP explainer

    masker_idx = np.random.choice(len(Xval), size=(50,), replace=False)
    explainer = shap.KernelExplainer(
                            svm_regressor_scaled.predict, 
                            Xval[masker_idx], 
                            feature_names=feature_names,
                                )
    shap_values = explainer.shap_values(Xval, nsamples=500)
    np.save("wrf_svm_shap_vals.npy", shap_values)
    shap.summary_plot(
            shap_values=shap_values, 
            feature_names=feature_names, 
            features=Xval,
                )
    plt.savefig('shap_values_wrf_SVM.png')
    plt.close()

        


if __name__ == "__main__":
    main()
