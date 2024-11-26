'''
Alexandra Walling and Rohit Tripathy.
A script to train a DNN and evaluate feature importances
with SHAP values
'''
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
from sklearn.preprocessing import StandardScaler
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


RESULTSDIR = "./wrf_DNN_results"

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

class TensorDataset(torch.utils.data.Dataset):
    def __init__(self, *tensors):
        self.tensors = []
        for t in tensors:
            _t = t
            if not torch.is_tensor(_t):
                _t = torch.tensor(_t).to(torch.float32)
            self.tensors.append(_t)

    def __len__(self,):
        return len(self.tensors[0])

    def __getitem__(self, idx):
        item = [] 
        for t in self.tensors:
            item.append(t[idx])
        return item

class DNNModel(nn.Module):
    """
    A simple Multilayer Perceptron (MLP).

    
    """
    def __init__(self, in_features, num_layers=3, hidden_size=50, num_outputs=1):
        super().__init__()
        sizes = [in_features] + [hidden_size for _ in range(num_layers)] + [num_outputs]
        layers = []
        for in_size, out_size in zip(sizes[:-1], sizes[1:]):
            layers.append(nn.Linear(in_size, out_size))
            layers.append(nn.ReLU())
        layers.pop()
        self.layers = nn.ModuleList(layers)

    def forward(self, x):
        out = x 
        for layer in self.layers:
            out = layer(out)
        return out 

    def norm_penalty(self, p=2):
        """
        Compute total p-norm penalty over all
        weights in the model. 

        Arguments
        ---------
        p <int> - Norm order (default : 2)


        Returns
        res - float 
        """
        res = 0. 
        for name, module in self.named_modules():
            if isinstance(module, nn.Linear):
                res = res + module.weight.norm(p=p)**(1./p)
        return res


def masker(binary_mask, x):
    """
    binary_mask <np.float32> - Binary mask to be applied. 
    x <np.float32> - Input sample.
    """
    return binary_mask * x


def main():
    '''
    The main function
    '''
    parser = argparse.ArgumentParser(description='Train Random Forest',
                formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser._action_groups.pop()
    required = parser.add_argument_group('required arguments')
    optional = parser.add_argument_group('optional arguments')
    parser.add_argument("-lmbda", metavar='lmbda', help='regularization constant', type=float, default=1e-4)
    parser.add_argument("-lr", metavar='learning_rate', help='Learning rate', type=float, default=1e-3)
    parser.add_argument("-bs", metavar='batch_size', help='batch size', type=int, default=32)
    parser.add_argument("-epochs", metavar="epochs", type=int, default=100, help="Number of epochs")
    required.add_argument('-i', metavar='table', help='input table file',
                            dest="locus_data", required=True)
    optional.add_argument('-t', metavar='N', help='number of threads',
                            dest="n_jobs", type=int, default=1)
    
    if len(sys.argv) == 0:
        parser.print_help()
        sys.exit()
    else:
        args = parser.parse_args()
        locus_data = pd.read_csv(vars(args)["locus_data"], sep='\t')
        n_jobs = vars(args)["n_jobs"]

        #parse the input table
        y_data, x_data, feature_names = parse_input_table(locus_data)
        x_data = pd.concat(x_data, axis=1).T 
        x_data = x_data.values.astype(np.float32)
        y_data = np.array(y_data).astype(np.float32)

        #Split the dataset into training and test 
        Xtrain, Xtest, Ytrain, Ytest = train_test_split(x_data, y_data,
                                                random_state=42,
                                                train_size=0.75)
        # scale the X data 
        scaler = StandardScaler()
        scaler.fit(Xtrain)
        Xtrain, Xtest = scaler.transform(Xtrain), scaler.transform(Xtest)
    
    train_dataset = TensorDataset(Xtrain, Ytrain)
    val_dataset = TensorDataset(Xtest, Ytest)
    num_in_features = train_dataset[0][0].shape[-1]


    # define data loaders  - BATCH SIZE SHOULD BE TESTED
    batch_size = args.bs 
    train_dataloader = torch.utils.data.DataLoader(dataset=train_dataset, batch_size=batch_size, shuffle=True)
    val_dataloader = torch.utils.data.DataLoader(dataset=val_dataset, batch_size=100,)


    # define model
    model = DNNModel(in_features=num_in_features, num_layers=3, num_outputs=1)

    # define optimizer - THESE PARAMETERS SHOULD BE TESTED
    learning_rate = args.lr
    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)
    epochs = args.epochs

    # other hyperparameters 
    lmbda = args.lmbda # regularization constant

    # training loop
    history = {'loss':[], 'val_loss':[]}
    best_model, best_val_loss = None, np.inf
    for epoch in range(1, 1 + epochs):
        losses = []
        for batch in train_dataloader:
            model.train()
            optimizer.zero_grad()
            x, y = batch
            ypred = model(x).squeeze()
            loss = F.mse_loss(ypred, y)
            if lmbda:
                reg_loss = lmbda*model.norm_penalty(2) #+ lmbda*model.norm_penalty(1)
            else:
                reg_loss = 0.
            total_loss = loss + reg_loss
            losses.append(loss.detach().cpu().numpy().item())
            total_loss.backward()
            optimizer.step()
            model.eval()
        history['loss'].append(np.mean(losses))

        losses = []
        for batch in val_dataloader:
            x, y = batch
            ypred = model(x).squeeze()
            loss = F.mse_loss(ypred, y)
            losses.append(loss.detach().cpu().numpy().item())
        history['val_loss'].append(np.mean(losses))

        # print to std out 
        if epoch == 1 or epoch%10 == 0:
            out_str = f"[Epoch {epoch:3d}] : "
            for k, v in history.items():
                out_str += f"{k} : {v[-1]:.4f}, "
            out_str = out_str[:-2]
            print(out_str)

        # checkpointing 
        current_val_loss = history['val_loss'][-1]
        if current_val_loss < best_val_loss:
            best_val_loss = current_val_loss
            best_model = model
    model = best_model  
    

    resdir = os.path.join(
                    RESULTSDIR,
                    f"lmbda={lmbda}",
                    f"bs={batch_size}",
                    f"lr={learning_rate}",
                        )
    if not os.path.exists(resdir):
        os.makedirs(resdir)
    model_state_dict = model.state_dict()
    torch.save(model_state_dict, os.path.join(resdir, "model.pt"),)
    with open(os.path.join(resdir, "val_loss.txt"), "w") as f:
        f.write(str(best_val_loss))
    history_df = pd.DataFrame(history,)
    history_df.to_csv(os.path.join(resdir, "train_history.csv"))

    ypred = model(torch.tensor(Xtest).to(torch.float32)).detach().cpu().numpy().squeeze()
    mse = mean_squared_error(Ytest, ypred)
    
    print("Mean Squared Error:", mse)
    #Evaluate the model
    r2 = r2_score(y_pred=ypred, y_true=Ytest)
    plt.plot(Ytest, ypred, ".")
    plt.title(f"$R^2$ score on test data = {r2:.4f}");
    plt.savefig(os.path.join(resdir, 'r2_score_dnn.png'), dpi = 300, bbox_inches='tight')
    plt.close()



    #Initialize SHAP explainer and Compute SHAP values
    model.eval()
    predict_fn = lambda x: model(torch.tensor(x).to(torch.float32)).detach().cpu().numpy()[:, 0]
    masker_idx = np.random.choice(len(Xtest), size=(50,), replace=False)
    explainer = shap.KernelExplainer(
                            predict_fn, 
                            Xtest[masker_idx], 
                            feature_names=feature_names,
                                )
    shap_values = explainer.shap_values(Xtest, nsamples=500)
    np.save(os.path.join(resdir, "shap_vals.npy"), shap_values)
    shap.summary_plot(
            shap_values=shap_values, 
            feature_names=feature_names, 
            features=Xtest,
            plot_type="violin",
                )
    plt.savefig(os.path.join(resdir, 'shap_DNN.png'))
    plt.close()
    
if __name__ == "__main__":
    main()
