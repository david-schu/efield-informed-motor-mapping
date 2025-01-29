%% Description
% This script facilitates the manual approval of the initial center location 
% for the "motor cortex".

%%  Set preliminaries 
% Assign basic path information to the 'params' structure.
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

%% Set participant-specific parameters!
pidx = <ID>;
params.participant = create_participant_id(pidx);

% load hair thickness information
hair = readtable(fullfile(params.workspace, 'data', 'input_data', 'hair_thickness.xlsx'));
params.simnibs.distance = hair.thickness(pidx) + 1; % adjust coil distance with an additional 1 mm due to the coil sensor!

%% Update parameteres
params.simpath              = fullfile(params.workspace, 'sims', params.participant);
params.simnibs.headmod_path = fullfile(params.simpath, 'headmodel');
params.simnibs.matlab_path  = fullfile(params.simnibs.path, 'matlab');
disp('Update params with ''parameters_determine_MCC.m file''');

%% Load participant-specific mesh
msh = mesh_load_gmsh4(fullfile(params.simpath, 'headmodel', strcat(params.participant, '.msh')));
   
% get skin and gray matter surfaces from mesh
msh_skin_surface = mesh_extract_regions(msh, 'elemtype', 'tri', 'region_idx', 1005);
msh_gm_surface = mesh_extract_regions(msh, 'elemtype', 'tri', 'region_idx', 1002);

% get surface center points and normal vectors for skin and gray matter
surface_skin_centers = mesh_get_triangle_centers(msh_skin_surface);
surface_skin_normals = mesh_get_triangle_normals(msh_skin_surface);  
surface_gm_centers = mesh_get_triangle_centers(msh_gm_surface);
surface_gm_normals = mesh_get_triangle_normals(msh_gm_surface);  

%% Transform MNI coordinate to subject space
% inspired  by: https://simnibs.github.io/simnibs/build/html/tutorial/analysis.html    
mni_coordinate = [-37 -21 58]; % for FDI muscle: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2034289/
subj_gm = mni2subject_coords(mni_coordinate, fullfile(params.simpath, 'headmodel', strcat('m2m_', params.participant)));    

% get the closest point over the gray matter surface 
idx = mesh_get_closest_triangle_from_point2(msh_gm_surface, subj_gm, 1002);
subj_gm_surf = surface_gm_centers(idx, :);
subj_gm_surf_vec = surface_gm_normals(idx, :);
clearvars idx

% get skin point closest to the roi center coordiante
idx = mesh_get_closest_triangle_from_point2(msh_skin_surface, subj_gm, 1005);
subj_skin = surface_skin_centers(idx, :);
subj_skin_vec = surface_skin_normals(idx, :);
clearvars idx

% view locations
marker_size = 50;
mesh_show_surface(msh, 'faceAlpha', 0.8);
scatter3(subj_gm(1), subj_gm(2), subj_gm(3), marker_size, 'red', 'filled');
scatter3(subj_gm_surf(1), subj_gm_surf(2), subj_gm_surf(3), marker_size, 'blue', 'filled');
scatter3(subj_skin(1), subj_skin(2), subj_skin(3), marker_size, 'black', 'filled');

% save initial coordinates
if not(isfolder(params.simpath))
     [~,~] = mkdir(params.simpath);
end
roi_init              = struct();
roi_init.mni          = mni_coordinate;   % original MNI coordinate
roi_init.subj_gm      = subj_gm;      % MNI coordinate transformed to subject space
roi_init.subj_gm_surf = subj_gm_surf; % closest point between subj_gm and gray matter surface
roi_init.subj_skin    = subj_skin;    % closest point between subj_gm and skin surface
save(fullfile(params.simpath, strcat(params.participant, '_roi_init.mat')), 'roi_init');

%% Adjust initial center manually
adjusted_center = [<x,y,z>]; % <- this step may involve an iterative process
mesh_show_surface(msh);
scatter3(adjusted_center(1), adjusted_center(2), adjusted_center(3), marker_size, 'red', 'filled');

% determine center in gray matter
offset_gm = -2.5;
idx_gm = mesh_get_closest_triangle_from_point2(msh_gm_surface, adjusted_center, 1002);
centerpoint_gm = surface_gm_centers(idx_gm, :);
centernormal_gm = surface_gm_normals(idx_gm, :);
centerpoint_gm_offset = centerpoint_gm + (offset_gm * centernormal_gm);

idx_skin = mesh_get_closest_triangle_from_point2(msh_skin_surface, adjusted_center, 1005);
centerpoint_skin = surface_skin_centers(idx_skin, :);
centernormal_skin = surface_skin_normals(idx_skin, :);
centerpoint_skin_offset = centerpoint_skin + (params.simnibs.distance * centernormal_skin);

%% View adjusted locations
% skin surface
mesh_show_surface(msh, 'region_idx', 1005);
scatter3(centerpoint_skin(1), centerpoint_skin(2), centerpoint_skin(3), 'blue', 'filled');
scatter3(centerpoint_skin_offset(1), centerpoint_skin_offset(2), centerpoint_skin_offset(3), 'black', 'filled');

% gray matter surface
mesh_show_surface(msh, 'region_idx', 1002);
scatter3(centerpoint_gm(1), centerpoint_gm(2), centerpoint_gm(3), 'red', 'filled');
scatter3(centerpoint_skin(1), centerpoint_skin(2), centerpoint_skin(3), 'blue', 'filled');
scatter3(centerpoint_skin_offset(1), centerpoint_skin_offset(2), centerpoint_skin_offset(3), 'black', 'filled');

% gray matter depth
mesh_show_surface(msh, 'region_idx', 1002, 'facealpha', 0.2);
scatter3(centerpoint_gm(1), centerpoint_gm(2), centerpoint_gm(3), 'red', 'filled');
scatter3(centerpoint_gm_offset(1), centerpoint_gm_offset(2), centerpoint_gm_offset(3), 'black', 'filled');

%% Save locations
roi_center                 = struct();
roi_center.adjusted_center = adjusted_center;        
roi_center.gm              = centerpoint_gm;         
roi_center.gm_vec          = centernormal_gm;         
roi_center.skin            = centerpoint_skin;
roi_center.skin_vec        = centernormal_skin;
roi_center.coil            = centerpoint_skin_offset;
save(fullfile(params.simpath, strcat(params.participant, '_roi_center.mat')), 'roi_center');