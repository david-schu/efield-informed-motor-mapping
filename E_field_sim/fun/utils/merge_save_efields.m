function merge_save_efields(params, simulations, nelem)
    nsims = length(simulations{1, 2});    
    start_idx = 1;
    end_idx = nsims;
    out_file = fullfile(params.simpath, strcat(params.participant, '_middle_gray_matter', '_efields.mat'));
    efields = zeros(nelem, nsims);

    parfor j = start_idx:end_idx
        simulation = simulations{1, 2}(j, 1);
        simulation = simulation{:};
        in_path = fullfile(params.simpath, 'efield_results');
        r = load(fullfile(in_path, strcat(element, '_', simulation)));
        efields{j, 1} = cell2mat(struct2cell(r));
    end
    efields = efields(start_idx:end_idx, 1);
    save(out_file, 'efields', '-v7.3');     
end