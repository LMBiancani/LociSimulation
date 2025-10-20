'''
A script to investigate feature interactions via random forest regressor
Code is adopted and modified after Seppe "Macuyiko" vanden Broucke
https://blog.macuyiko.com/post/2019/discovering-interaction-effects-in-ensemble-models.html
https://blog.macuyiko.com/post/2021/revisiting-discovery-of-interaction-effects.html
'''
import sys
import pandas as ps
import numpy as np
import matplotlib.pyplot as plt
import pickle
import argparse
import itertools
from sklearn import tree
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.inspection import partial_dependence
from sklearn.inspection import plot_partial_dependence
from sklearn.inspection import PartialDependenceDisplay


def center(arr):
    '''
    A function to center an array
    '''
    return arr - np.mean(arr)


def cartesian_product(*arrays):
    '''
    A function to obtain a cartesian product of arrays
    '''
    la = len(arrays)
    dtype = np.result_type(*arrays)
    arr = np.empty([len(a) for a in arrays] + [la], dtype=dtype)
    for i, a in enumerate(np.ix_(*arrays)):
        arr[...,i] = a
    return arr.reshape(-1, la)


def compute_f_vals_sklearn(model, X, feats=None, grid_resolution=2):
    '''
    A function to compute F values (partial dependence values)
    using synthetic grid values
    '''

    def _pd_to_df(pde, feature_names):
        grid_points = pde["values"]
        df = ps.DataFrame(cartesian_product(*grid_points))
        rename = {i: feature_names[i] for i in range(len(feature_names))}
        df.rename(columns=rename, inplace=True)
        df['preds'] = pde["average"].flatten()
        return df


    def _get_feat_idxs(feats):
        return [X.columns.get_loc(f) for f in feats]

    f_vals = {}
    if feats is None:
        feats = list(X.columns)

    # Calculate partial dependencies for full feature set
    pd_full = partial_dependence(
        model, X, _get_feat_idxs(feats), 
        grid_resolution=grid_resolution
    )



    # Establish the grid
    df_full = _pd_to_df(pd_full, feats)
    grid = df_full.drop('preds', axis=1)

    # Store
    f_vals[tuple(feats)] = center(df_full.preds.values)

    # Calculate partial dependencies for [1..SFL-1]
    for n in range(1, len(feats)):
        for subset in itertools.combinations(feats, n):
            pd_part = partial_dependence(
                model, X, _get_feat_idxs(subset),
                grid_resolution=grid_resolution
            )
            df_part = _pd_to_df(pd_part, subset)
            joined = ps.merge(grid, df_part, how='left')
            f_vals[tuple(subset)] = center(joined.preds.values)

    return f_vals


#compute partial dep manually - faster but less accurate
def compute_f_vals_manual(model, X, feats=None):
    '''
    A function to compute F values (partial dependence values)
    using actual data values (less precise but much faster)
    '''
    def _partial_dependence(model, X, feats):
        P = X.copy()
        for f in P.columns:
            if f in feats: continue
            P.loc[:,f] = np.mean(P[f])
        # Assumes a regressor here, use return model.predict_proba(P)[:,1] for binary classification
        return model.predict(P)

    f_vals = {}
    if feats is None:
        feats = list(X.columns)

    # Calculate partial dependencies for full feature set
    full_preds = _partial_dependence(model, X, feats)
    f_vals[tuple(feats)] = center(full_preds)

    # Calculate partial dependencies for [1..SFL-1]
    for n in range(1, len(feats)):
        for subset in itertools.combinations(feats, n):
            pd_part = _partial_dependence(model, X, subset)
            f_vals[tuple(subset)] = center(pd_part)

    return f_vals


def compute_h_val(f_vals, selectedfeatures):
    '''
    A function to compute second order H measure
    checking interactions btw selected features
    '''
    numer_els = f_vals[tuple(selectedfeatures)].copy()
    denom_els = f_vals[tuple(selectedfeatures)].copy()
    sign = -1.0
    for n in range(len(selectedfeatures)-1, 0, -1):
        for subfeatures in itertools.combinations(selectedfeatures, n):
            numer_els += sign * f_vals[tuple(subfeatures)]
        sign *= -1.0
    numer = np.sum(numer_els**2)
    denom = np.sum(denom_els**2)
    return np.sqrt(numer/denom)


# better way but doesnt combine
# def compute_h_val(f_vals, selectedfeatures):
#     numer_els = f_vals[tuple(selectedfeatures)].copy()
#     denom_els = f_vals[tuple(selectedfeatures)].copy()
#     for n in range(len(selectedfeatures)-1, 0, -1):
#         for subfeatures in itertools.combinations(selectedfeatures, n):
#             sign = -1 if n == selectedfeatures - 1 else +1
#             numer_els += sign * f_vals[tuple(subfeatures)]
#     numer = np.sum(numer_els**2)
#     denom = np.sum(denom_els**2)
#     return np.sqrt(numer/denom)


def compute_h_val_any(f_vals, allfeatures, selectedfeature):
    '''
    A function to compute first order H measure
    checking if a feature interacts with any other subset of features
    '''
    otherfeatures = list(allfeatures)
    otherfeatures.remove(selectedfeature)
    denom_els = f_vals[tuple(allfeatures)].copy()
    numer_els = denom_els.copy()
    numer_els -= f_vals[(selectedfeature,)]
    numer_els -= f_vals[tuple(otherfeatures)]
    numer = np.sum(numer_els**2)
    denom = np.sum(denom_els**2)
    return np.sqrt(numer/denom)


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
        locus_data = ps.read_csv(vars(args)["locus_data"], sep='\t')
        with open(vars(args)["modelfilename"], 'rb') as f:
            rfr_tt, scaler = pickle.load(f)
       	n_jobs = vars(args)["n_jobs"]

	#reformat data
        df = locus_data.iloc[:,2:]
        headers = locus_data.columns.values.tolist()
        feats = headers[2:]
        print(feats)
        #compute PD values
        f_vals = compute_f_vals_sklearn(rfr_tt, df, feats=feats)

        #compute first order H-values
        print ("compute first order H-values")
        subsets = []
        h_vals = []
        for subset in feats:
            h_val = compute_h_val_any(f_vals, feats, subset)
            subsets.append(subset)
            h_vals.append(h_val)
        df1 = ps.DataFrame(list(zip(subsets, h_vals)),
                            columns =['features', 'h_vals'])
        df1.to_csv("first_order_H_vals.csv", index=False, encoding='utf-8')

        #compute second order H-values
        print ("compute second order H-values")
        subsets = []
        h_vals = []
        for n in [2,3]:
            combs = itertools.combinations(feats, n)
            print ("level:", n)
            for subset in combs:
                h_val = compute_h_val(f_vals, subset)
                #print(h_val)
                #print(subset)
                subsets.append(' x '.join(subset))
                h_vals.append(h_val)
            if n == 2:
                #for pairwise interactions plot top 4
                print ("plot PDs")
                plt.rcParams.update({'figure.figsize': [4,3]})
                subsets1 = np.array(subsets)
                h_vals1 = np.array(h_vals)
                k1 = 8
                for subset1 in subsets1[h_vals1.argsort()[::-1][:k1]]:
                    split_feats = tuple(subset1.split(' x ')) # Produces a list of strings
                        
                    print("Features:", split_feats) 
            
            
                    pd_result = partial_dependence(rfr_tt, df, split_feats, kind='average')
                    pd_average = pd_result["average"]  # Extract the average PD values

                    if np.ptp(pd_average) == 0:
                        print(f"Skipping flat PD plot for features: {split_feats}")
                    elif np.isnan(pd_average).any() or np.isinf(pd_average).any():
                        print(f"Skipping PD plot for features {split_feats} due to NaN or Infinity in values.")
                    else:

                
                        split_feats = [split_feats]    
                        # Plot the Partial Dependence
            
                        PartialDependenceDisplay.from_estimator(rfr_tt, df, features=split_feats, kind='average')
                        plt.show()
                        plt.tight_layout(pad=0.5)
                        plt.savefig(f"{subset1}.svg")
                        plt.close()  # Close the plot to free up memory
            
    subsets = np.array(subsets)
    h_vals = np.array(h_vals)
    df2 = ps.DataFrame({'features':subsets[h_vals.argsort()[::-1]], 'h_vals':h_vals[h_vals.argsort()[::-1]]})
    df2.to_csv("second_order_H_vals.csv", index=False, encoding='utf-8')

if __name__ == "__main__":
    main()
