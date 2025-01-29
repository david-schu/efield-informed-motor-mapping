function roi = save_roi_bool(params)

    % load head mesh file
    mesh_path = fullfile(params.subpath, 'headmodel');
    mesh_name = strcat(params.participant, '.msh');    
    mesh = mesh_load_gmsh4(fullfile(mesh_path, mesh_name));

    % load ROI center
    roi_center_path = fullfile(params.simpath);
    roi_center_name = strcat(params.participant, '_roi_center.mat'); 
    roi_center = load(fullfile(roi_center_path, roi_center_name));
    roi_center = cell2mat(struct2cell(roi_center));

    % gray matter
    gm      = struct();
    gm.m    = mesh_extract_regions(mesh, 'region_idx', 1002);
    gm.tri  = mesh_get_triangle_centers(gm.m);
    gm.norm = mesh_get_triangle_normals(gm.m);
    gm.idx  = mesh_get_closest_triangle_from_point2(gm.m, roi_center.gm, 1002);

    gm_vol     = struct();
    gm_vol.m   = mesh_extract_regions(mesh, 'region_idx', 2);
    gm_vol.tet = mesh_get_tetrahedron_centers(gm_vol.m);
    
    % skin
    sk     = struct();
    sk.m   = mesh_extract_regions(mesh, 'region_idx', 1005);
    sk.tri = mesh_get_triangle_centers(sk.m);
    sk.idx = mesh_get_closest_triangle_from_point2(sk.m, roi_center.gm, 1005); 
    
    % get cylinder parameters
    center = gm.tri(gm.idx, :);
    top = sk.tri(sk.idx, :);
    vec = center - top;
    vec_u = vec/norm(vec);
    base = center + (vec_u * norm(vec));
    
    rA = transpose(top); 
    rB = transpose(base);
    e = rB - rA;
    m = cross(rA, rB);
    out_path = fullfile(params.simpath);

    % get ROI for triangle centers
    mask = zeros(length(gm.tri), 3);
    for j = 1:length(gm.tri)
        rP = gm.tri(j, :)'; 
        d = norm(m + cross(e, rP)) / norm(e);
        mask(j, 1) = d <= params.simnibs.roi_radius;
        rQ = rP + (cross(e, (m + cross(e, rP))) / norm(e)^2);
        wA = norm(cross(rQ, rB)) / norm(m); 
        wB = norm(cross(rQ, rA)) / norm(m); 
        mask(j, 2) = wA >= 0 && wA <= 1 && wB >= 0 && wB <= 1;
    end
    roi = logical(mask(:, 1)==1 & mask(:, 2)==1);
    save(fullfile(out_path, strcat(params.participant, '_roi_bool_tri.mat')), 'roi');
    clearvars mask roi

    % get ROI for mesh.nodes (return this in the function)
    mask = zeros(length(mesh.nodes), 3);
    for j = 1:length(mesh.nodes)
        rP = mesh.nodes(j, :)'; 
        d = norm(m + cross(e, rP)) / norm(e);
        mask(j, 1) = d <= params.simnibs.roi_radius;
        rQ = rP + (cross(e, (m + cross(e, rP))) / norm(e)^2);
        wA = norm(cross(rQ, rB)) / norm(m); 
        wB = norm(cross(rQ, rA)) / norm(m); 
        mask(j, 2) = wA >= 0 && wA <= 1 && wB >= 0 && wB <= 1;
    end
    roi = logical(mask(:, 1)==1 & mask(:, 2)==1);    
    save(fullfile(out_path, strcat(params.participant, '_roi_bool.mat')), 'roi');

    % get ROI for mesh.nodes where ROI correspons to the coil's search radius
    mask = zeros(length(mesh.nodes), 3);
    for j = 1:length(mesh.nodes)
        rP = mesh.nodes(j, :)'; 
        d = norm(m + cross(e, rP)) / norm(e);
        mask(j, 1) = d <= params.simnibs.search_radius;
        rQ = rP + (cross(e, (m + cross(e, rP))) / norm(e)^2);
        wA = norm(cross(rQ, rB)) / norm(m); 
        wB = norm(cross(rQ, rA)) / norm(m); 
        mask(j, 2) = wA >= 0 && wA <= 1 && wB >= 0 && wB <= 1;
    end
    roi_search_radius = logical(mask(:, 1)==1 & mask(:, 2)==1);
    save(fullfile(out_path, strcat(params.participant, '_roi_bool_search_radius.mat')), 'roi_search_radius');
   
end