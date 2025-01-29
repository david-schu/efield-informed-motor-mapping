function save_parameters(params, in_file, out_file)
    run(in_file);
    if not(isfolder(params.simpath))
        [~, ~] = mkdir(params.simpath);
    end
    save(out_file, 'params');
end