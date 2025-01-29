import torch
import numpy as np
from dgl.geometry import farthest_point_sampler


def get_samples(n_samples=100, e_matrix=None,  method='random', verbose=True, seed=None, **kwargs):

    if method == 'random':
        sampled_idcs = select_random(e_matrix, n_sims=n_samples, seed=seed, **kwargs)
    
    elif method=='grid':
        sampled_idcs = select_grid(**kwargs)

    elif method == 'fps':
        sampled_idcs = select_sims_fps(e_matrix, n_sims=n_samples, seed=seed, **kwargs)
    

    return sampled_idcs

def select_random(e_matrix, n_sims=100, seed=None, restrict_random=False, **kwargs):
    np.random.seed(seed)

    if restrict_random:
        grid_idcs = select_grid(**kwargs)
        idcs = np.random.choice(grid_idcs, size=n_sims, replace=False)
    else:

        idcs = np.random.choice(np.arange(len(e_matrix)), size=n_sims, replace=False)
    return idcs


def select_grid(grid, a_res=10, s_res=3, search_r=50, symmetric=True, **kwargs):
    grid_cond = ((grid[:,0]%a_res) == 0) * ((grid[:,1]%s_res) == 0) * ((grid[:,2]%s_res) == 0) * (np.sqrt(grid[:,1]**2 + grid[:,2]**2) <= search_r)
    if symmetric:
        grid_cond *= (grid[:,0] < 180)

    grid_idcs = np.argwhere(grid_cond).flatten()
    return grid_idcs


def select_sims_fps(data, grid=None, start_idx=None, seed=None, n_sims=100, a_res=5, s_res=3, search_r=50, symmetric=True, **kwargs):
    
    if not grid is None:
        grid_idcs = select_grid(grid, a_res, s_res, search_r, symmetric)
        efields = data[grid_idcs]
    else:
        efields = data[:].copy()

    if start_idx is None:
        np.random.seed(seed)
        start_idx = np.random.randint(len(efields))

    taken = farthest_point_sampler(torch.from_numpy(efields).unsqueeze(0), npoints=int(n_sims), start_idx=start_idx).flatten().numpy()

    if not grid is None:
        idcs = grid_idcs[taken]
    else:
        idcs = taken

    return idcs
