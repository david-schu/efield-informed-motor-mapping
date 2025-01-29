import numpy as np
import pynibs
from collections import abc
from scipy.stats import norm, multivariate_normal

import FPS_Paper.utils as mu

class MEP_model():
    def __init__(self, 
                 nodes, 
                 tris, 
                 efield_dset = None,
                 cov = None,
                 center = None,
                 nodes_2d = None,
                 sigmoid_facs=None,
                 noise_level = .75) -> None:
        self.nodes = nodes
        self.tris = tris
        self.nodes_2d = nodes_2d
        self.sigmoid_facs = sigmoid_facs
        self.noise_level = noise_level

        if (center is None) or (cov is None):
            self.gt_map = None
        else:
            self.make_gt_map(center, cov)
        self.efields = efield_dset

        if not self.efields is None:
            self.calc_normalization_factor(efield_dset)
            if not self.gt_map is None:
                self.calc_sigmoid_facs()
            else:
                self.k_base = mu.get_k(.95,1)
                self.x0_base = .2


    def gen_meps(self, gen_idcs, sigmoid_facs=None, sd=None, seed=None):

        if isinstance(gen_idcs, int):
            gen_idcs = np.array([gen_idcs])
        np.random.seed(seed)

        if not sigmoid_facs is None:
            x0_fac, k_fac, ymax = sigmoid_facs
            self.sigmoid_facs = sigmoid_facs

        elif self.sigmoid_facs is None:
            raise ValueError('Sigmoid params not set')

        else:
            x0_fac, k_fac, ymax = self.sigmoid_facs
        
        if sd is None:
            sd = self.noise_level
        elif self.noise_level is None:
            raise ValueError('Noise level not set')

        if len(gen_idcs)>1e5:
            x_hat = np.zeros(len(gen_idcs))
            for i in range(int(np.ceil(len(gen_idcs)/1e5))):
                x_hat[i*100000:(i+1)*100000] = (self.efields[gen_idcs[i*100000:(i+1)*100000]] / self.normalization_factor * self.gt_map).sum(-1)
        else:
            x_hat = (self.efields[gen_idcs] / self.normalization_factor * self.gt_map).sum(-1)
        
        x0 = self.x0_base * x0_fac
        k = self.k_base * k_fac

        self.sigmoid_params = np.array([x0, k, ymax])

        x = np.clip(x_hat, 1e-5, 1-1e-5)

        noise = mu.sigmoid(x, 0.8*x0, k, 1) * np.random.normal(0, sd, len(x))
        meps = np.clip(mu.sigmoid(x, *self.sigmoid_params) + noise, 0, 1.5*ymax)
        
        return meps, x
    

    def make_gt_map(self, center, cov):

        if isinstance(center, abc.Sequence):
            center = np.argmin(((np.mean(self.nodes[self.tris],1)-center)**2).sum(-1)) # center element
        
        # check wheter covariance matrix is univariate or multivariate Gaussian
        if not isinstance(cov, abc.Sequence):
            is_multivariate = False
            self.cov = cov
        elif (np.count_nonzero(cov - np.diag(np.diagonal(cov)))==0) and np.all(np.isclose(np.diagonal(cov), cov[0,0])):
            is_multivariate = False
            self.cov = cov[0,0]
        else:
            is_multivariate = True
            self.cov = np.array(cov)
    
        if is_multivariate:
            mean = np.mean(self.nodes_2d[self.tris[center]],0)
            gt_map = multivariate_normal.pdf(np.mean(self.nodes_2d[self.tris],1), mean=mean, cov=self.cov, allow_singular=True)

        else:
            dists = pynibs.geodesic_dist(self.nodes, self.tris, source=center, source_is_node=False)[1]
            gt_map = norm.pdf(dists, loc=0, scale=self.cov)

        self.gt_map = gt_map / np.linalg.norm(gt_map)


    def calc_normalization_factor(self, efield_dset):
        self.efields = efield_dset
        norms = np.zeros(len(efield_dset))
        for i in range(len(efield_dset)):
            norms[i]=np.linalg.norm(efield_dset[i], axis=-1)
        self.normalization_factor = norms.max() #ensures to have latent space in intervall [0,1]


    def calc_sigmoid_facs(self):
        x_hat = (self.gt_map *self.efields[np.random.choice(np.arange(len(self.efields)), np.minimum(5000, len(self.efields)), replace=False)]/self.normalization_factor).sum(-1)
                                     
        self.x0_base = np.median(x_hat)
        self.k_base= mu.get_k(0.95,1,self.x0_base,x_hat.max())

        if not self.sigmoid_facs is None:
            x0_fac, k_fac, ymax = self.sigmoid_facs
            x0 = self.x0_base * x0_fac
            k = self.k_base * k_fac
            self.sigmoid_params = np.array([x0, k, ymax])