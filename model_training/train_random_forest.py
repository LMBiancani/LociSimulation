'''
Caitlin  Guccione, modified by Alex Knyshov
A script to train random forest regressor
'''
import sys
import pandas as ps
import numpy as np
import pickle
import argparse
from sklearn import tree
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn.inspection import permutation_importance
from sklearn.model_selection import RandomizedSearchCV
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


def model_tuning(param_list, x_train, y_train, n_jobs):
    '''
    A function to tune random forest hyperparameters
    '''
    #coarse tuning
    rfr = RandomForestRegressor()
    rfr_random = RandomizedSearchCV(estimator = rfr,
                                    param_distributions = param_list,
                                    n_iter = 100, cv = 5, verbose=2,
                                    random_state=42, n_jobs = n_jobs)

    rfr_random.fit(x_train, y_train)
    print("Coarse tuning complete:")
    print(rfr_random.best_params_)

    #fine tuning
    param_grid2 = {}
    if rfr_random.best_params_['max_depth'] == None:
        param_grid2['max_depth'] = None
    else:
        param_grid2['max_depth'] = [int(rfr_random.best_params_['max_depth']-
                                    rfr_random.best_params_['max_depth']*0.25),
                                    rfr_random.best_params_['max_depth'],
                                    int(rfr_random.best_params_['max_depth']+
                                        rfr_random.best_params_['max_depth']*0.25)]
    if rfr_random.best_params_['max_features'] in ('auto', 'sqrt'):
        param_grid2['max_features'] = rfr_random.best_params_['max_features']
    else:
        param_grid2['max_features'] = [rfr_random.best_params_['max_features']-
                                        rfr_random.best_params_['max_features']*0.25,
                                       rfr_random.best_params_['max_features'],
                                       rfr_random.best_params_['max_features']+
                                       rfr_random.best_params_['max_features']*0.25]
    param_grid2['min_samples_leaf'] = [int(rfr_random.best_params_['min_samples_leaf']-
                                        rfr_random.best_params_['min_samples_leaf']*0.25),
                                       rfr_random.best_params_['min_samples_leaf'],
                                       int(rfr_random.best_params_['min_samples_leaf']+
                                        rfr_random.best_params_['min_samples_leaf']*0.25)]
    param_grid2['n_estimators'] = [int(rfr_random.best_params_['n_estimators']-
                                    rfr_random.best_params_['n_estimators']*0.25),
                                   rfr_random.best_params_['n_estimators'],
                                   int(rfr_random.best_params_['n_estimators']+
                                    rfr_random.best_params_['n_estimators']*0.25)]
    param_grid2['min_samples_split'] = [int(rfr_random.best_params_['min_samples_split']-
                                        rfr_random.best_params_['min_samples_split']*0.25),
                                        rfr_random.best_params_['min_samples_split'],
                                        int(rfr_random.best_params_['min_samples_split']+
                                            rfr_random.best_params_['min_samples_split']*0.25)]
    # Instantiate the grid search model
    rfr_grid = GridSearchCV(estimator = rfr, param_grid = param_grid2,
                              cv = 3, n_jobs = n_jobs, verbose = 2)
    rfr_grid.fit(x_train, y_train)
    
    print("Fine tuning complete")
    return rfr_grid.best_params_


def model_training(param_list, x_train, y_train, n_jobs):
    '''
    A function to train the final model
    '''
    #Initialize and train the model
    rfr = RandomForestRegressor(min_samples_leaf=param_list["min_samples_leaf"],
                                min_samples_split=param_list["min_samples_split"],
                                random_state=40,
                                n_estimators=param_list["n_estimators"],
                                n_jobs=n_jobs)
    rfr_tt = rfr.fit(x_train, y_train)

    return rfr_tt


def evaluate_model(input_model, x_test, y_test, feature_names):
    '''
    A function to evaluate model's performance
    '''
    #Compare Test and Training Set
    predictions = input_model.predict(x_test)
    #The most common way to evaluate the RandomForest Run
    rmse = np.sqrt(mean_squared_error(y_test, predictions))
    print ('RMSE:'+ str(rmse))
    current_score = input_model.score(x_test, y_test)
    print ('Score:'+ str(current_score))
    print('Feature Importance')
    
    r = permutation_importance(input_model, x_test, y_test,
                               n_repeats=10,
                               random_state=40)
    for feature in range(len(feature_names)):
        print(feature_names[feature], ":",
              r['importances_mean'][feature], "+-",
              r['importances_std'][feature])


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
    optional.add_argument('-t', metavar='N', help='number of threads',
                            dest="n_jobs", type=int, default=1)
    optional.add_argument('-e', metavar='N', help='number of decision trees',
                            dest="n_estimators", type=int, default=5000)
    optional.add_argument('-f', choices=['auto','sqrt','0.5'],
                            help='max features to use',
                            dest="max_features", default='auto')
    optional.add_argument('-d', metavar='N', help='max depth',
                            dest="max_depth", type=int, default=None)    
    optional.add_argument('--msl', metavar='N', help='min samples per leaf',
                            dest="min_samples_leaf", type=int, default=20)
    optional.add_argument('--mss', metavar='N', help='min samples per split',
                            dest="min_samples_split", type=int, default=5)
    optional.add_argument('--tune', dest='tuning', action='store_true',
                            help='tune hyperparameters?', default=False)
    optional.add_argument('--train-test-split', metavar='N',
                            help='proportion of test data',
                            dest="test_size", type=float, default=0.25)
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit()
    else:
        args = parser.parse_args()
        locus_data = ps.read_csv(vars(args)["locus_data"], sep='\t')
        n_jobs = vars(args)["n_jobs"]

        #parse the input table
        y_data, x_data, feature_names = parse_input_table(locus_data)
        #Split the dataset into trainning and test 
        x_train, x_test, y_train, y_test = train_test_split(x_data, y_data,
                                                random_state=42,
                                                test_size=vars(args)["test_size"])

        #tune the hyperparams if required
        if vars(args)["tuning"]:
            print("performing hyperparameter tuning")
            param_grid = {'max_depth': [1000, 5000, 10000, 20000, None],
                'max_features': ['auto', 'sqrt', 0.5],
                'min_samples_leaf' : [5,20,50,100],
                'n_estimators' : [1000,5000,10000],
                'min_samples_split' : [2, 5, 10]}
            param_list = model_tuning(param_grid, x_train, y_train, n_jobs)
        else:
            print("regular training goes here")
            param_list = {'max_depth': vars(args)["max_depth"],
                'max_features': vars(args)["max_features"],
                'min_samples_leaf' : vars(args)["min_samples_leaf"],
                'n_estimators' : vars(args)["n_estimators"],
                'min_samples_split' : vars(args)["min_samples_split"]}
            if param_list['max_features'] == '0.5':
                param_list['max_features'] = 0.5

        #train model
        print ("parameters used for final model training:")
        print (param_list)
        rfr_tt = model_training(param_list, x_train, y_train, n_jobs)

        #evaluate model accuracy
        evaluate_model(rfr_tt, x_test, y_test, feature_names)

        #save the model
        with open('model_file.bin', 'wb') as f:
            pickle.dump(rfr_tt, f)


if __name__ == "__main__":
    main()
