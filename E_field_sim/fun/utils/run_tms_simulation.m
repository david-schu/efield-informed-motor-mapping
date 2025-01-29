function run_tms_simulation(params, simulation, matsimnibs)   
    S = sim_struct('SESSION');
    S.fnamehead = fullfile(params.subpath,'headmodel', strcat(params.participant, '.msh'));
    S.pathfem = fullfile(params.simulations_path, simulation(1:end-4)); 
    if not(isfolder(params.efields_path))
        [~, ~] = mkdir(S.pathfem);
    end
    mkdir(S.pathfem);
    S.fields = 'eE'; 
    S.poslist{1} = sim_struct('TMSLIST');
    S.poslist{1}.fnamecoil = params.simnibs.fnamecoil; 
    S.map_to_surf = 'true';
    S.poslist{1}.anisotropy_type = 'vn';
    S.poslist{1}.fn_tensor_nifti = params.simnibs.fn_tensor_nifti;
    S.poslist{1}.aniso_maxratio = 10;
    S.poslist{1}.aniso_maxcond = 2;
    S.poslist{1}.pos(1).matsimnibs = matsimnibs;      
    S.poslist{1}.pos(1).didt = params.simnibs.ccr * params.simnibs.mso * 1000000; 
    run_simnibs(S);
end