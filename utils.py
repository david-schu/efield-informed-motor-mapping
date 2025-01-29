import numpy as np
import os
import h5py
import pandas as pd
from sklearn.manifold import MDS
from joblib import Parallel, delayed
import pynibs
from h5py import h5o
from collections import abc
from simnibs import read_msh

np.seterr(all='ignore')

file_dir = os.path.dirname(os.path.realpath(__file__))

def read_msh_summary(fn):
    m = read_msh(fn)
    nodes = m.nodes.node_coord
    tags = m.elm.tag1
    tris = m.elm.node_number_list[tags==1002][:,:3]-1
    
    return nodes, tris 


class h5py_dataset(h5py.Dataset):
    def __init__(self, file_path, fieldname):
        self.f = h5py.File(file_path)
        bind = h5o.open(self.f.id, self.f._e(fieldname), lapl=self._lapl)
        super().__init__(bind, readonly=(self.f.file.mode == 'r'))


    def __getitem__(self, key):
        if isinstance(key, tuple):
            data = super().__getitem__(slice(None, None, None))[key]
        elif isinstance(key, abc.Sequence) or isinstance(key, np.ndarray):
            if key.dtype=='bool':
                key = np.where(key)[0]
            key_ = np.array(key)
            sorted_key = key_.argsort().argsort()
            data = []
            for k in np.array_split(np.sort(key_), (len(sorted_key)//1000)):
                data.append(super().__getitem__(k))
            data = np.concatenate(data, axis=0)
            data = data[sorted_key]
        else: 
            data = super().__getitem__(key)
        return data


def sigmoid(x, x0, k, ymax):
    y = (ymax) / (1 + np.exp(-k*(x-x0)))
    return y


def load_exp_data(subj_id, data_path='/home/dschulth/Documents/RLroboTMS/data/', exp_type='all'):
    sub = 'sub-' +  subj_id
    exp_path = os.path.join(data_path, sub, 'experiment', exp_type)

    nodes, tris = read_msh_summary(os.path.join(exp_path, sub + '_middle_gray_matter_roi.msh'))

    if os.path.isfile(os.path.join(exp_path, sub + '_middle_gray_matter_efields.mat')):
        efields = h5py_dataset(os.path.join(exp_path, sub + '_middle_gray_matter_efields.mat'),'efields')
    else:
        efields = h5py_dataset(os.path.join(exp_path, sub + '_middle_gray_matter_efields.h5'),'efields')
    
    if efields.shape[-1]!=len(tris):
        efields = np.mean(efields[:,tris], axis=-1)

    grid = load_grid(os.path.join(exp_path, sub +'_matsimnibs.mat'))
    
    nodes_2d_path = os.path.join(data_path, sub, 'experiment', sub + '_roi_2d.npy')
    if os.path.isfile(nodes_2d_path):
        nodes_2d = np.load(nodes_2d_path, allow_pickle=True)
    else:
        nodes_dist,_ = zip(*Parallel(-2,)(delayed(pynibs.geodesic_dist)(nodes, tris, source=i, source_is_node=True) for i in range(len(nodes)))) 
        nodes_dist = np.array(nodes_dist)
        n_components = 2 
        mds = MDS(n_components=n_components, n_jobs=-1, dissimilarity='precomputed', random_state=0)
        nodes_2d = mds.fit_transform(nodes_dist)
        np.save(nodes_2d_path, nodes_2d)

    return efields, nodes, nodes_2d, tris, grid


def load_grid(grid_dir):
    f = h5py.File(grid_dir)
    grid = f['matsimnibs']
    ref = grid[2][0]
    matsimnibs = np.array(f[ref]).T
    grid = matsimnibs[:,[3,5,6]]
    return grid


def get_k(
    percentile, ymax, x0=0.5, x=1):
    k = 1/(x-x0) * np.log(percentile/(ymax-percentile))
    return k


def set_params(single_params={}, sweep_params={}, default_params={}):

    if default_params:
        params = pd.DataFrame.from_dict(default_params, orient='index').T

        for single_param in single_params.keys():
            new_params = default_params.copy()

            for p in single_params[single_param]:
                new_params[single_param] = p
                
                params.loc[len(params)] = new_params
    
    else:
        params = pd.DataFrame([np.zeros(len(sweep_params.keys()))], columns=sweep_params.keys())

    for sweep_param in sweep_params.keys():
        new_params = params.copy()
        params_ = None

        for p in sweep_params[sweep_param]:
            new_params[sweep_param] = p
            
            params = pd.concat([params_, new_params], ignore_index=True)
            params_ = params

    return params


def get_qof(r2, r2_ref, nodes, tris, score_type='rmse', rad=None, r2_th=None):
    r2_, r2_ref_ = r2.copy(), r2_ref.copy()

    t1_idx = np.argmax(r2_)
    t2_idx = np.argmax(r2_ref)

    gdists = pynibs.geodesic_dist(nodes=nodes, tris=tris, source=t2_idx, source_is_node=False)[1]

    if np.allclose(r2_,0) or np.allclose(r2_ref_,0):
        score = 0
    else:
        if rad is not None:
            r2_ref_[gdists>rad] = 0
            r2_[pynibs.geodesic_dist(nodes=nodes, tris=tris, source=t1_idx, source_is_node=False)[1]>rad] = 0

        if r2_th is not None:
            r2_[r2_<r2_th] = 0

        if score_type == 'rmse':
            score = pynibs.nrmsd(array=r2_, array_ref=r2_ref_, error_norm="relative", x_axis=False) * 100

        elif score_type == 'overlap':
            score = ((r2_/np.linalg.norm(r2_)) * (r2_ref_/np.linalg.norm(r2_ref_))).sum()
    
    dist = gdists[t1_idx]

    return score, dist





