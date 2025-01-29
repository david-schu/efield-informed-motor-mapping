function running_efield_simulations(params)
    
    % creating required folder(s)
    if not(isfolder(params.simulations_path))
        mkdir(params.simulations_path);
    end
	params.efields_path = fullfile(params.simpath, 'efield_results');
    if not(isfolder(params.efields_path))
        [~, ~] = mkdir(params.efields_path);
    end

    % prepare parallel pool 
    params.simulations_path = fullfile(params.simpath, 'simulations');   
    if isempty(gcp('nocreate'))      
        cluster = parcluster('local');
        pool = parpool(cluster, cluster.NumWorkers);  
    else
        pool = gcp();
    end
    
    % define ROI 
    % first, run a single simulation to get the coordinates of the middle
    % gray matter cortical layer.
    
    % load simulations (matsimnibs)
    simulations = load(fullfile(params.simpath, strcat(params.participant, '_matsimnibs.mat')));
    simulations = struct2cell(simulations);
    simulations = simulations{:};
    
    % run a single simulation
    matsimnibs = simulations{1, 1}{1, 1};
    simulation = simulations{1, 2}{1, 1};
    run_tms_simulation(params, simulation, matsimnibs);
    
    mesh_path = fullfile(params.simulations_path, simulation(1:end - 4), 'subject_overlays');
    mesh_name = strcat(params.participant, '_TMS_1-0001_', params.simnibs.coil, '_vn_central.msh');
    mesh = mesh_load_gmsh4(fullfile(mesh_path, mesh_name));
    mesh_save_gmsh4(mesh, fullfile(params.simpath, strcat(params.participant, '_middle_gray_matter.msh')));

    % load ROI center 
    roi_center_path = fullfile(params.subpath, 'experiment');
    roi_center_name = strcat(params.participant, '_roi_center.mat'); 
    roi_center = load(fullfile(roi_center_path, roi_center_name));
    roi_center = cell2mat(struct2cell(roi_center));
    
    % get initial cylindric ROI
    % roi = sqrt(sum(bsxfun(@minus, mesh.nodes, roi_center.gm).^2, 2)) < params.simnibs.roi_radius; 
    skin_normal_avg = get_skin_average_normal_vector(params);
    top = roi_center.gm + (skin_normal_avg * 10);
    base = roi_center.gm - (skin_normal_avg * 30);
    rA = transpose(top); 
    rB = transpose(base);
    e = rB - rA;
    m = cross(rA, rB);
    
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
    cylinder_roi = logical(mask(:, 1)==1 & mask(:, 2)==1); 

    cropped = mesh_extract_points(mesh, cylinder_roi);

    % remove islands of nodes using geodesic distance
    pyenv('Version', params.python_env);
    pyenv("ExecutionMode","OutOfProcess")
    P = py.sys.path;
    if count(P, fullfile(params.workspace, 'toolboxes', 'pynibs-master')) == 0
        insert(P, int32(0), fullfile(params.workspace, 'toolboxes', 'pynibs-master'));
    end
    py_pynibs = py.importlib.import_module('pynibs');
    [~,center_id]=min(sqrt(sum((cropped.nodes-repmat(roi_center.gm, size(cropped.nodes,1), 1)).^2,2)));
    source_id = py.numpy.int32(center_id - 1);
    nodes = py.numpy.array(cropped.nodes);
    tris = py.numpy.array(cropped.triangles - 1).astype(py.numpy.int32);
    py_result = py_pynibs.geodesic_dist(pyargs('nodes', nodes, 'tris', tris, 'source', source_id, 'source_is_node', true));
    dists = double(py_result{1})'; % Assuming dists is returned as the second element of the result tuple
    island_roi = dists ~= Inf;
    
    % get final ROI
    roi = cylinder_roi;
    roi(roi) = island_roi;
    save(fullfile(params.simpath, strcat(params.participant, '_roi_bool_nodes_middle_gray_matter.mat')), 'roi');
    
    % save cropped mesh for latter visualization
    cropped_final = mesh_extract_points(mesh, roi);
    cropped_mesh = struct();
    cropped_mesh.node_data{1, 1} = cropped_final.node_data{1, 1};
    cropped_mesh.element_data = cropped_final.element_data;
    cropped_mesh.nodes = cropped_final.nodes;
    cropped_mesh.triangles = cropped_final.triangles;
    cropped_mesh.triangle_regions = cropped_final.triangle_regions;
    cropped_mesh.tetrahedra = cropped_final.tetrahedra;
    cropped_mesh.tetrahedron_regions = cropped_final.tetrahedron_regions;
    mesh_save_gmsh4(cropped_mesh, fullfile(params.simpath, strcat(params.participant, '_middle_gray_matter_roi.msh')));    
    
    % save E-field
    efield = extract_save_efields(params, simulation, roi);  
   
    % Run efield simulation
    nsims = length(simulations{1,1});
    start_idx = 1; 
    end_idx = nsims;
    efields = zeros(length(efield), nsims) * inf;
    
    parfor ii = 1:(end_idx-start_idx+1)

        matsimnibs = simulations{1, 1}{ii+start_idx-1, 1};
        simulation = simulations{1, 2}{ii+start_idx-1, 1};
    
        folder = fullfile(params.simulations_path, simulation(1:end-4));

        if isfolder(folder)
            system(strjoin({'rm -r', folder}))
        end

        run_tms_simulation(params, simulation, matsimnibs);
        efields(:, ii) = extract_save_efields(params, simulation, roi);
        
        cleanup_simulation_folder(params, simulation); 
    end

    save(fullfile(params.simpath, strcat(params.participant, '_middle_gray_matter_efields.mat')), 'efields', '-v7.3');
    delete(pool);
 
end