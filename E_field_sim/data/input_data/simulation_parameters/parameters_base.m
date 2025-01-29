% Define the base parameters that remain constant across different methods.
params.simnibs.ccr             = 1.49;                  % coil current rate of change (depends on device)
params.simnibs.mso             = 1;                     % maximum stimulator output percentage
params.simnibs.coil            = 'MagVenture_Cool-B65'; % coil model
params.simnibs.coilpath        = fullfile(params.workspace, 'data', 'input_data', 'coil');
params.simnibs.fnamecoil       = fullfile(params.simnibs.coilpath, strcat(params.simnibs.coil, '.ccd'));
params.simnibs.fn_tensor_nifti = fullfile(params.subpath, 'headmodel', strcat('d2c_', params.participant), 'dti_results_T1space', 'DTI_conf_tensor.nii.gz');
params.simnibs.roi_radius      = 20;                    % ROI radius in mm for extracting E-field
params.simnibs.field_type      = 'E_norm';              % extract absolute E-field value 
params.simnibs.tilt_angles     = 0;                     % coil tilt anlge