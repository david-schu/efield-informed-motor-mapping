function surface = extract_save_efields(params, simulation, roi)       
    
	% load E-field simulation mesh file
    mesh_path = fullfile(params.simulations_path, simulation(1:end-4), 'subject_overlays');
    mesh_name = strcat(params.participant, '_TMS_1-0001_', params.simnibs.coil, '_vn_central.msh');
    mesh = mesh_load_gmsh4(fullfile(mesh_path, mesh_name));
      
    % crop mesh and extract E-field values
    cropped = mesh_extract_points(mesh, roi);

    % extract surface and volume data 
    field_index = get_field_idx(cropped, params.simnibs.field_type, 'node');
    surface = cropped.node_data{field_index}.data;   
    save(fullfile(params.efields_path, simulation), 'surface');
end