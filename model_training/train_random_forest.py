'''
Caitlin  Guccione, modified by Alex Knyshov
A script to train random forest regressor
'''
import sys
import pandas as ps
import numpy as np
import pickle
from sklearn import tree
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error


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
    if len(sys.argv) == 3:
        locus_data = ps.read_csv(sys.argv[1], sep='\t')
        njobs = int(sys.argv[2])
        #parse the input table
        y_data, x_data, feature_names = parse_input_table(locus_data)
        #Split the dataset into trainning and test 
        x_train, x_test, y_train, y_test = train_test_split(x_data, y_data,
                                                            random_state=42,
                                                            test_size = 0.25)
        #Initialize and train the model
        rfr = RandomForestRegressor(min_samples_leaf= 20, min_samples_split=5,
                                    random_state=40, n_estimators=5000,
                                    n_jobs=njobs)
        rfr_tt = rfr.fit(x_train, y_train)
        #Compare Test and Training Set
        predictions = rfr_tt.predict(x_test)
        #The most common way to evaluate the RandomForest Run
        rmse = np.sqrt(mean_squared_error(y_test, predictions))
        print ('RMSE:'+ str(rmse))
        current_score = rfr_tt.score(x_test, y_test)
        print ('Score:'+ str(current_score))
        print('Feature Importance')
        # do not use - unreliable
        # feat_imps = rfr_tt.feature_importances_
        # for feature in range(len(feat_imps)):
        #     print(temp_headers[feature], ":", feat_imps[feature])
        # should use permutation importance instead
        from sklearn.inspection import permutation_importance
        r = permutation_importance(rfr_tt, x_test, y_test,
                                   n_repeats=10,
                                   random_state=40)
        for feature in range(len(feature_names)):
            print(feature_names[feature], ":",
                  r['importances_mean'][feature], "+-",
                  r['importances_std'][feature])
        #Save the model
        with open('model_file.bin', 'wb') as f:
            pickle.dump(rfr_tt, f)
    else:
        print("python3 train_random_forest.py [table] [CPUs]")
        print("python3 train_random_forest.py table.tab 3")


if __name__ == "__main__":
    main()
