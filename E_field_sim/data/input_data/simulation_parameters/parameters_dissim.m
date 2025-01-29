%% Description
% This file contains simulation-specific parameters. 
run(fullfile(params.workspace, 'data', 'input_data', 'simulation_parameters', 'parameters_base.m'));
params.simflag                    = 'dissim';              % method to select simulations
params.simpath                    = fullfile(params.subpath, 'experiment', params.simflag);
params.simnibs.rotation_angles    = 0:20:160;              % coil rotation angles 
params.simnibs.spatial_resolution = 5;                     % distance between coil centers in mm
params.simnibs.search_radius      = 30;                    % ROI radius in mm for placing coils in E-field simulations
params.n_fps                      = 150;                   % number of samples