import sys

# setting path
sys.path.append('..')
sys.path.append('../..')
import numpy as np
import os
from tqdm import tqdm
import pandas as pd
import pynibs

# own modules
import Code.MotorMapping.mm_utils as mu
from fun.mep_model import MEP_model
from fun.fit import get_qof
from fun.sample import get_samples

if __name__ == "__main__":
    mep_gen_seed = int(sys.argv[1])
    sample_seed = int(sys.argv[2])

    #### set parameters
    # initializer
    sub = '005'
    data_path = '/home/fr/fr_fr/fr_ds1211/RLroboTMS/data/'
    save_path = os.path.join(data_path, 'sub-' + sub, 'synth_exp_max_n')


    if not os.path.isdir(save_path):
        os.mkdir(save_path)
    n_samples = np.linspace(10,150,50, dtype='int')

    default_params = {'noise_level': 0.3,
                      'k_fac': 2,
                      'mm_var': 3

    }

    sweep_params = {'method': ['random','dissimilarity'],
                    'target': ['crown', 'roi_edge', 'fold'],
    }

    single_params = {'noise_level': [.2,.75],
                     'k_fac': [1,3],
                     'mm_var': [1,6]}
    
    params = mu.set_params(sweep_params=sweep_params, default_params=default_params)#, single_params=single_params)

    poss_targets = np.load(data_path + 'sub-' + sub + '/targets.npy', allow_pickle=True)[()]

    all_efields, nodes, nodes_2d, tris, grid = mu.load_exp_data(subj_id=sub, data_path=data_path, exp_type='high_resolution')
    grid_cond = np.argwhere(np.sqrt(grid[:,1]**2 + grid[:,2]**2) <= 30).flatten()
    all_efields = all_efields[grid_cond]
    grid = grid[grid_cond]

    search_r = 30
    s_res = 2
    a_res = 10

    # init result array
    result = pd.DataFrame(columns=['n_samples', 'score','dist', 'fit_method', 'score_r2', 'dist_r2', 'mm', 'gt_r2', 'score_gt', 'dist_gt', 'mep_gen_seed', 'sample_seed', 'target', 'method', 'k_fac', 'mm_var', 'noise_level'])
    for i in tqdm(range(len(params))):
        method = params.loc[i,'method']
        target = params.loc[i,'target']
        k_fac = params.loc[i,'k_fac']
        mm_var = params.loc[i,'mm_var']
        noise_level = params.loc[i,'noise_level']

        mep_model = MEP_model(nodes, tris, all_efields, nodes_2d=nodes_2d, sigmoid_facs = [1.1, k_fac, 1], noise_level=noise_level, cov=mm_var, center=poss_targets[target])

        all_meps = mep_model.gen_meps(np.arange(len(all_efields)), seed=mep_gen_seed)[0]
        grid_idcs = get_samples(method='grid', grid=grid, a_res=a_res, s_res=s_res, search_r=search_r)
        # gt_r2 = fit_map(mep_model, grid_idcs, fit_method='r2')
        gt_r2 = pynibs.regress_data(all_efields[grid_idcs], all_meps[grid_idcs], con=tris, n_refit=10, verbose=False, n_cpu=100)

        score_gt, dist_gt = get_qof(gt_r2, mep_model.gt_map, nodes, tris, score_type='overlap')

        samples = get_samples(e_matrix=all_efields, n_samples=np.max(n_samples), method=method, verbose=False, grid=grid, a_res=a_res, s_res=s_res, search_r=search_r,
                              seed=sample_seed, all_meps=all_meps, acquisition_function='REJ', n_init=10, restrict_random=False)

        for n in n_samples:
            # calc the r2 motor map
            mm = pynibs.regress_data(all_efields[samples[:n]], all_meps[samples[:n]], con=tris, n_refit=10, verbose=False, n_cpu=100)

            # get score and dist to all r2 map
            score_r2, dist_r2 = get_qof(mm, gt_r2, nodes, tris, score_type='overlap')

            # get the overlap of ground truth and recovered map
            score, dist = get_qof(mm, mep_model.gt_map, nodes, tris, score_type='overlap')

            # save in result array
            result.loc[len(result)] = {'n_samples':n,
                                    'score': score,
                                    'dist': dist,
                                    'score_r2': score_r2,
                                    'dist_r2': dist_r2,
                                    'mm': mm,
                                    'gt_r2': gt_r2,
                                    'score_gt': score_gt,
                                    'dist_gt': dist_gt,
                                    'mep_gen_seed': mep_gen_seed,
                                    'sample_seed': sample_seed,
                                    'target': target,
                                    'method': method,
                                    'k_fac': k_fac,
                                    'mm_var': mm_var,
                                    'noise_level': noise_level}

    result.to_pickle(save_path + '/exp_%s_%s.pkl' % (str(mep_gen_seed), str(sample_seed)))



