%% Description
% This script generates head modeling command. 
% Important note on data protection: 
% For data protection reasons, store MRI data on a dedicated notebook. 
% dwi2cond:
% With SimNIBS function dwi2cond, we also prepare diffusion tensors for GM 
% and WM from diffusion MRI (dMRI) data. The prepared tensors can then be 
% used by SimNIBS to estimate anisotropic conductivities for GM and WM 
% during the FEM calculations. Use a dedicated Linux notebook. 

%%  Set preliminaries on a dedicated notebook
clear; close; clc;
params                        = struct();
params.repository             = 'E_field_sim';
params.workspace              = ...; 
params.simnibs.path           = ...;
params.python_env             = ...;
addpath(genpath(fullfile(params.workspace, 'fun')));       % add private functions 
addpath(genpath(fullfile(params.simnibs.path, 'matlab'))); % add Matlab functions of SimNIBS
disp(['Initializing for Project: ', params.repository])
cd(params.workspace);
params.participant            = <ID>;  % <- change participant ID here
params.algo                   = 'headreco'; h
params.headmod                = fullfile(params.workspace, 'head_models', params.algo, params.participant);
params.script                 = fullfile(params.workspace, 'head_models', params.algo, 'shell_scripts');
params.mri                    = fullfile(params.workspace, 'mri', params.participant);
params.t1w                    = fullfile(params.mri, strcat(params.participant, '_T1w.nii'));
params.t2w                    = fullfile(params.mri, strcat(params.participant, '_T2w.nii'));
params.dmri                   = fullfile(params.mri, strcat(params.participant, '_dMRI.nii.gz'));
params.bval                   = fullfile(params.mri, strcat(params.participant, '_dMRI.bval'));
params.bvec                   = fullfile(params.mri, strcat(params.participant, '_dMRI.bvec'));
cd(params.workspace);
create_headmodel_script(params)

%% Functions
function create_headmodel_script(params)
    command = struct();
    command.l1 = '#!/bin/bash \n';
    command.l2 = strjoin({'cd', params.headmod, '\n'});

    if not(isfolder(params.headmod))
        [~, ~] = mkdir(params.headmod);
    end

    if not(isfolder(params.script))
        [~, ~] = mkdir(params.script);
    end

    switch params.algo
        case 'headreco'
            command.l3 = strjoin({params.algo, 'all', params.participant, params.t1w, params.t2w, '\n'});
        case 'mri2mesh'
            command.l3 = strjoin({params.algo, '--all', params.participant, params.t1w, params.t2w, '\n'});
        otherwise
            warning('Unexpected head modeling algorythm. No script created.')
    end
    command.l4 = strjoin({'dwi2cond --all', params.participant, params.dmri, params.bval, params.bvec, '\n'});
    
    filepath = params.script;
    filename = strcat(params.participant, '_run_', params.algo, '.sh');
    file = fullfile(filepath, filename);
    fid = fopen(file, 'wt');
    fprintf(fid, command.l1);
    fprintf(fid, command.l2);
    fprintf(fid, command.l3);
    fprintf(fid, command.l4);
    fclose(fid);
    
    % assign file attributes 
    fileattrib(file, '+x', 'a') 
    
    % run headmodeling 
    strjoin({'cd', params.script})
    strjoin({'sh', filename}) % option 1: copy this to shell
    % system(sprintf('sh %s', file), '-echo'); % option 2: run head modeling directly from MATLAB but it will occupy MATLAB
end