%% Description
% This file contains simulation-specific parameters. 
run(fullfile(params.workspace, 'data', 'input_data', 'simulation_parameters', 'parameters_base.m'));
params.simflag                    = 'initial';             % method to select simulations
params.simpath                    = fullfile(params.subpath, 'experiment', params.simflag);
params.simnibs.rotation_angles    = 45;                    % coil rotation angles 
params.simnibs.spatial_resolution = 1;                     % distance between coil centers in mm
params.simnibs.search_radius      = 20;                    % ROI radius in mm for placing coils in E-field simulations
params.simnibs.grid_resolution    = 10;                    % spatial resolution of the "hotspot grid" in mm 