import numpy as np
import pandas as pd
from tqdm import tqdm
import pynibs
import os

import FPS_Paper.utils as mu

subjs = ['002', '003', '004', '006', '007', '008', '009', '010']
result = pd.DataFrame(columns=['sub', 'score', 'dist', 'exp', 'n', 'seed'])
n_samples = np.linspace(10,150,50, dtype=int)

exp = ['dissim','random']

for subj in tqdm(subjs):
    _, nodes, nodes_2d, tris, _ = mu.load_exp_data(subj)
    exp_path = '/home/dschulth/Documents/RLroboTMS/data/sub-' + subj + '/experiment/measurements/motor_mapping'
    res = np.load(os.path.join(exp_path, 'result_all.npy'), allow_pickle=True)[()]
    meps = res['meps']
    grid = res['grid']
    efields = res['efields']
    efields = np.mean(efields[:,tris], axis=-1)

    r2_gt = pynibs.regress_data(efields, meps, n_cpu=30, con=tris, n_refit=10, verbose=False)

    for i, e in enumerate(exp):
        res = np.load(os.path.join(exp_path, 'result_' + e + '.npy'), allow_pickle=True)[()]
        meps = res['meps']
        grid = res['grid']
        efields = res['efields']
        efields = np.mean(efields[:,tris], axis=-1)

        for seed in range(10):           
            if seed:
                idc = np.random.permutation(np.arange(len(meps)))
            else:
                idc = np.arange(len(meps))

            for n in n_samples:
                r2 = pynibs.regress_data(efields[idc][:n], meps[idc][:n], n_cpu=30, con=tris, n_refit=10, verbose=False)
                
                score, dist = mu.get_qof(r2, r2_gt, nodes, tris, score_type='overlap')
                result.loc[len(result)] = {
                    'sub': subj,
                    'exp': e,
                    'score': score,
                    'dist': dist,
                    'n': n,
                    'seed': seed
                }

pd.to_pickle(result, './res_all_subs.pkl')