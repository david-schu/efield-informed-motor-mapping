function fps(params)
% furthest point sampling

% this function performs fps on X and stops when n_samples are chosen
% chosen samples are returned
    n_samples = params.n_fps;

    load(fullfile(params.simpath , strcat(params.participant,'_matsimnibs.mat')),'matsimnibs');
    all_files = matsimnibs{2};
    for k = 1:numel(all_files)
        data(k) = load(fullfile(params.simpath , 'efield_results', all_files{k,1})); 
    end
    data       = squeeze(cell2mat(struct2cell(data)));
    X = data.';

    if size(X,1)<n_samples
        error('FPS: Number of samples must be larger than dataset')
    end
    

    [~, start_idx] = min(sum((X-mean(X,1)).^2,2));
    
    points_left = 1:size(X,1);
    sample_inds = zeros(n_samples,1);
    dists = Inf(size(X,1),1);
    
    selected = start_idx;
    sample_inds(1) = points_left(selected);
    points_left(selected) = [];
    
    for i = 2:n_samples
        last_added = sample_inds(i-1);
        dist_to_last_added_point = vecnorm(X(last_added,:) - X(points_left,:), 2,2);
    
        dists(points_left) = min(dist_to_last_added_point, dists(points_left,:));
        
        [~, selected] = max(dists(points_left));
        sample_inds(i) = points_left(selected);
    
        points_left(selected) = [];
    
    end
    
    % save output
    selected_sims            = struct();
    selected_sims.idx        = sample_inds;
    selected_sims.sims       = X(sample_inds,:);
    save(fullfile(params.subpath, 'experiment', 'dissim', 'selected_electric_fields.mat'), 'selected_sims', '-v7.3');

end