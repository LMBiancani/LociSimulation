import os
import sys
import pandas as pd
import numpy as np
import pickle
import argparse
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn.inspection import permutation_importance
from sklearn.model_selection import RandomizedSearchCV
from sklearn.model_selection import GridSearchCV
from sklearn import linear_model
from sklearn.preprocessing import StandardScaler
from sklearn.utils import shuffle
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score
import shap 
import torch
from torch import nn
from torch.nn import functional as F
import matplotlib as mpl 
from matplotlib import pyplot as plt 
from sklearn import linear_model
from pdb import set_trace
from glob import glob


RESULTSDIR = "./wrf_DNN_results"
data = []
columns = []
def main():
    paths = glob(f"{RESULTSDIR}/**/val_loss.txt", recursive=True)
    for i, path in enumerate(paths):
        _path = path.split(RESULTSDIR+"/")[-1].split("val_loss.txt")[0]
        hparam_kv = _path.split("/")[:-1]
        _data = []
        for kv in hparam_kv:
            k, v = kv.split("=")
            _data.append(v)
            if i == 0:
                columns.append(k)
        
        with open(path, "r") as f:
            val_loss = f.read()
        _data.append(float(val_loss))
        data.append(_data)
    
    grid_search_df = pd.DataFrame(columns=columns+['val_loss'], data=data)
    minidx = grid_search_df.val_loss.idxmin()
    
    best_hparams = grid_search_df.iloc[minidx]
    grid_search_df.to_csv("grid_search_results_wrf.csv", sep=",")
    print("Best Hyperparameters:", best_hparams)

if __name__ == '__main__':
    main()
