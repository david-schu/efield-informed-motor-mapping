%% Description
% This file contains simulation-specific parameters. 
run(fullfile(params.workspace, 'data', 'input_data', 'simulation_parameters', 'parameters_base.m'));
params.simflag                    = 'angular_sym';     
params.simpath                    = fullfile(params.subpath, 'experiment', params.simflag);
params.simnibs.rotation_angles    = 0:5:355;               % coil rotation angles 
params.simnibs.spatial_resolution = 3;                     % distance between coil centers in mm
params.simnibs.search_radius      = 50;                    % ROI radius in mm for placing coils in E-field simulations
params.simnibs.field_type         = 'E_norm';              % absolute E-field value
params.simnibs.roi_radius         = 20;                    % ROI radius in mm for extracting E-field 