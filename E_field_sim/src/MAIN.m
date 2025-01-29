%% Description
% This script performs the following tasks:
% 1. Prepares and saves simulation-specific parameter files.
% 2. Generates TMS coil configuration (= matsimnibs) files.
% 3. Conducts E-field simulations using the SimNIBS toolbox.
% 4. Creates instrument markers for neuronavigation.

% Prerequisites:
% Ensure you have the necessary head model and coordinates for the region 
% of interest before running this script. Follow these steps:
% 1. Run create_head_model.m to generate a participant-specific head model 
% using headreco and dwi2cond.
% 2. Run determine_motor_cortex_center.m to determine the center for the 
% simulations.

% Simulation Overview:
% The following simulations are conducted. For detailed parameters, refer to
% the data > input_data > simulation_parameters folder:
% 1. initial: Estimation of the resting motor threshold.
% 2. random: Motor mapping using random trial selection.
% 3. dissim: Motor mapping utilizing trial selection via a dissimilarity
% algorithm (furthest point sampling; fps).
% 5. all: Motor mapping employing the fps algorithm for trial selection.
% 6. high_resolution: High-resolution simulations with large number of coil
% configurations.   

% More info to SimNIBS: 
% SimNIBS: https://simnibs.github.io/simnibs/build/html/index.html
% Matsimnibs: https://simnibs.github.io/simnibs/build/html/documentation/sim_struct/position.html
% Head models: https://simnibs.github.io/simnibs/build/html/tutorial/head_meshing.html
% dwi2cond: https://simnibs.github.io/simnibs/build/html/documentation/command_line/dwi2cond.html

% Note: Some functions used in this script are from the OPITZ lab (https://opitzlab.umn.edu/).  
% These functions have been omitted from this shared version.  
% - creating_coil_parameters_*()
% - mesh_extract_points()
% - mesh_get_closest_triangle_from_point2()
% To fully reproduce the workflow, please contact us and the OPITZ lab for permission.  

%%  Set preliminaries and simulation parameters 
% In this section, essential path information is assigned to the 'params'
% structure. This data will be utilized later to disseminate simulation 
% parameters throughout the script.

clear; close; clc;
params                        = struct();
params.repository             = 'E_fields_sim';
params.workspace              = ...; 
params.simnibs.path           = ...;
params.python_env             = ...;
addpath(genpath(fullfile(params.workspace, 'fun')));       
addpath(genpath(fullfile(params.simnibs.path, 'matlab'))); 
disp(['Initializing for Project: ', params.repository])
cd(params.workspace);

%% Set participant-specific parameters
% This section initializes participant-specific information.
simflags = {'initial', 'random', 'dissim', 'all'};

for pidx = <ID>
    params.participant = create_participant_id(pidx);
    params.subpath = fullfile(params.workspace, 'sims', params.participant);
    % load hair thickness information
    hair = readtable(fullfile(params.workspace, 'data', 'input_data', 'hair_thickness.xlsx'));
    params.simnibs.distance = hair.thickness(pidx) + 1; % adjust coil distance with an additional 1 mm due to the coil sensor!
    clearvars pidx hair
    
    %% Save parameters 
    % This section updates the 'params' structure with simulation-specific 
    % information and saves it for future reference.

    for i = 1:length(simflags)  
        in_file = fullfile(params.workspace, 'data', 'input_data', 'simulation_parameters', strcat('parameters_', simflags{i}, '.m'));
        out_file = fullfile(params.workspace, 'sims', params.participant, 'experiment', simflags{i}, strcat(params.participant, '_simulation_parameters.mat'));
        save_parameters(params, in_file, out_file);
    end
    
    %% Create coil parameters
    % This section generates coil configuration files (matsimnibs files)
    % Note: The 'simflags' variable excludes the 'dissim' method since coil 
    % configurations are selected after the E-field simulations (see next section).
    
    for i = 1:length(simflags)
        if strcmp(simflags{i}, 'dissim')
            continue
        end
        simparams = load(fullfile(params.workspace, 'sims', params.participant, 'experiment', simflags{i}, strcat(params.participant, '_simulation_parameters.mat')));
        simparams = struct2cell(simparams);
        simparams = simparams{:};
        run(strcat('creating_coil_parameters_', simflags{i}, '(simparams).m'));    
    end
    
    %% Run E-field simulations
    % This section runs the E-field simulations for the selected coil configurations.
    % Note: The 'simflags' variable excludes the 'dissim' method because trials
    % are selected from 'all' E-fields using the fps method.
    
    for i = 1:length(simflags) 
        if strcmp(simflags{i}, 'dissim')
            continue
        end
        simparams = load(fullfile(params.workspace, 'sims', params.participant, 'experiment', simflags{i}, strcat(params.participant, '_simulation_parameters.mat')));
        simparams = struct2cell(simparams);
        simparams = simparams{:};
        running_efield_simulations(simparams);    
        if strcmp(simflags{i}, 'all')
            dissim_params = load(fullfile(params.workspace, 'sims', params.participant, 'experiment', 'dissim', strcat(params.participant, '_simulation_parameters.mat'))).params;
            simparams.n_fps = dissim_params.n_fps;
            fps(simparams);
            update_matsimnibs(simparams);
        end
    end
    
    %% Create instrument markers
    % This section creates instrument markers for the neuronavigation software 
    % and randomizes the trial order.
    % Note: For the 'random' method, the trial order will be sequential.
    
    for i = 1:length(simflags) 
        if strcmp(simflags{i}, 'all')
            continue
        end
        simparams = load(fullfile(params.workspace, 'sims', params.participant, 'experiment', simflags{i}, strcat(params.participant, '_simulation_parameters.mat')));
        simparams = struct2cell(simparams);
        simparams = simparams{:};
        create_instrument_markers(simparams);    
    end
end