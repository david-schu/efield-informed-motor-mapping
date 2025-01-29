function update_matsimnibs(params)
    
	% load matsimnibs
    matsim = load(fullfile(params.simpath, strcat(params.participant, '_matsimnibs.mat')));
    matsim = struct2cell(matsim);
    matsim = matsim{:};    
    
	% load fps results 
    fps = load(fullfile(params.subpath, 'experiment', 'dissim', 'selected_electric_fields.mat'));
    fps = struct2cell(fps);
    fps = fps{:};
    
	% update matlab
    matsimnibs{1, 1} = matsim{1, 1}(fps.idx, :);
    matsimnibs{1, 2} = matsim{1, 2}(fps.idx, :);
    matsimnibs{1, 3} = matsim{1, 3}(fps.idx, :);
    save(fullfile(params.subpath, 'experiment', 'dissim', strcat(params.participant, '_matsimnibs.mat')), 'matsimnibs', '-v7.3');
end