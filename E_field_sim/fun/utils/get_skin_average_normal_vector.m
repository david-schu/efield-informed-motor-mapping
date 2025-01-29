function skin_normal_avg = get_skin_average_normal_vector(params)
    
    % load mesh
    msh_path = fullfile(params.subpath,'headmodel');
    msh_name = strcat(params.participant, '.msh');    
    msh = mesh_load_gmsh4(fullfile(msh_path, msh_name));
    
    % load ROI center
    roi_center_path = fullfile(params.subpath, 'experiment');
    roi_center_name = strcat(params.participant, '_roi_center.mat'); 
    roi_center = load(fullfile(roi_center_path, roi_center_name));
    roi_center = cell2mat(struct2cell(roi_center));

    % get skin roi
    skin = mesh_extract_regions(msh, 'region_idx', 1005);
    skin_centers = mesh_get_triangle_centers(skin);
    skin_normals = mesh_get_triangle_normals(skin); % unit vectors
    skin_roi = sqrt(sum(bsxfun(@minus, skin_centers, roi_center.skin).^2, 2)) < params.simnibs.roi_radius; 
    skin_normal_avg = mean(skin_normals(skin_roi, :), 1);
    
end