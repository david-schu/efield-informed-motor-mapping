function create_instrument_markers(params)
    space = 32;
    ind4 = [space, space, space, space];
    out_folder = fullfile(params.subpath, 'experiment', 'instrument_markers');
    if not(isfolder(out_folder))
        [~, ~] = mkdir(out_folder);
    end    
        
    % load matsimnibs file
    matsimnibs = load(fullfile(params.simpath, strcat(params.participant, '_matsimnibs.mat')));
    matsimnibs = struct2cell(matsimnibs);
    matsimnibs = matsimnibs{:};
    
    % extract block size (used for chunking neuronavigation sessions)
    nsims = size(matsimnibs{1, 1}, 1);
    block_size = 50;
    nblocks = nsims / block_size;
    idx1 = 1:block_size:nblocks*block_size;
    idx2 = block_size:block_size:nblocks*block_size;

    % determine trial order
    if strcmp(params.simflag, 'initial')        
        pos1 = load(fullfile(params.simpath, strcat(params.participant, '_mni_idx.mat')));
        pos1 = cell2mat(struct2cell(pos1));
        pos2 = load(fullfile(params.simpath, strcat(params.participant, '_roi_center_idx.mat'))); 
        pos2 = cell2mat(struct2cell(pos2));
        pos = setdiff(1:nsims, [pos1, pos2]);        
        trial_order = [pos1, pos2, randsample(pos, length(pos), false)];       
    elseif contains(params.simflag, {'hotspot', 'dissim'})           
        trial_order = randsample(1:nsims, nsims, false);   
    else
        trial_order = 1:nsims;
    end
    % Localite/Python indexing starts with zero
    trial_order = trial_order - 1;
    
    % Chunk trial order information for motor mapping experiments only
    if contains(params.simflag, {'dissim', 'random'})  
        for idx_b = 1:nblocks
            trl_ordr = trial_order(idx1(idx_b):idx2(idx_b));
            save(fullfile(params.simpath, strcat(params.participant, '_trial_order_block_', num2str(idx_b), '.mat')), 'trl_ordr');

            fname = fullfile(out_folder, strcat(params.participant, '_', params.simflag, '_block_', num2str(idx_b), '.xml'));  
            fid = fopen(fname, 'wt');
            fprintf(fid, '<?xml version="1.0" encoding="UTF-8"?> \n');
            fprintf(fid, '<InstrumentMarkerList coordinateSpace="RAS"> \n');            
            for k = idx1(idx_b):idx2(idx_b)
                label = strcat('Localite_idx-', num2str(trial_order(k)));
                additionalInformation = strcat('Matlab_idx-', num2str(trial_order(k) + 1)); % correct for Matlab indexing
                matsim = matsimnibs{1, 1}{trial_order(k) + 1}; % correct for Matlab indexing       
            
                % Adjust SimNIBS coordinates to Localite coordinates
                x =  matsim(1:3, 3);      % Localite X = SimNIBS Z coordinate
                y = -1 *  matsim(1:3, 2); % Localite Y = SimNIBS -1 * Y;
                z =  matsim(1:3, 1);      % Localite Z = SimNIBS X coordinate
                c =  matsim(1:3, 4);
                
                % X (direction vector)
                data00 = sprintf('%+.17f', x(1));
                data10 = sprintf('%+.17f', x(2));
                data20 = sprintf('%+.17f', x(3));
                
                % Y (direction vector)
                data01 = sprintf('%+.17f', y(1));
                data11 = sprintf('%+.17f', y(2));
                data21 = sprintf('%+.17f', y(3));
                
                % Z (direction vector)
                data02 = sprintf('%+.17f', z(1));
                data12 = sprintf('%+.17f', z(2));
                data22 = sprintf('%+.17f', z(3));
                
                % Coil center (position vector)
                data03 = sprintf('%+.17f', c(1));
                data13 = sprintf('%+.17f', c(2));
                data23 = sprintf('%+.17f', c(3));
                
                % Write to XML        
                fprintf(fid, strcat(ind4, '<InstrumentMarker alwaysVisible="false" index="', num2str(k - 1), '" selected="false"> \n'));
                fprintf(fid, strcat(ind4, ind4, '<Marker additionalInformation="', additionalInformation, '" color="#ff0000" description="', label, '" set="true"> \n'));
                fprintf(fid, strcat(ind4, ind4, ind4, '<Matrix4D \n'));
                fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data00="', data00, '" data01="', data01, '" data02="', data02, '" data03="', data03, '" \n'));
                fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data10="', data10, '" data11="', data11, '" data12="', data12, '" data13="', data13, '" \n'));
                fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data20="', data20, '" data21="', data21, '" data22="', data22, '" data23="', data23, '" \n'));
                fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data30="+0.00000000000000000" data31="+0.00000000000000000" data32="+0.00000000000000000" data33="+1.00000000000000000"/> \n'));
                fprintf(fid, strcat(ind4, ind4, '</Marker> \n'));
                fprintf(fid, strcat(ind4, '</InstrumentMarker> \n'));                
            end            
            fprintf(fid, '</InstrumentMarkerList> \n');
            fclose(fid);
        end    
    else
        save(fullfile(params.simpath, strcat(params.participant, '_trial_order.mat')), 'trial_order');
        fname = fullfile(out_folder, strcat(params.participant, '_', params.simflag,'.xml'));  
        fid = fopen(fname, 'wt');
        fprintf(fid, '<?xml version="1.0" encoding="UTF-8"?> \n');
        fprintf(fid, '<InstrumentMarkerList coordinateSpace="RAS"> \n');
        for idx_s = 1:nsims
            label = strcat('Localite_idx-', num2str(trial_order(idx_s)));
            additionalInformation = strcat('Matlab_idx-', num2str(trial_order(idx_s) + 1)); % correct for Matlab indexing
            matsim = matsimnibs{1, 1}{trial_order(idx_s) + 1}; % correct for Matlab indexing       
        
            % Adjust SimNIBS coordinates to Localite coordinates
            x =  matsim(1:3, 3);      % Localite X = SimNIBS Z coordinate
            y = -1 *  matsim(1:3, 2); % Localite Y = SimNIBS -1 * Y;
            z =  matsim(1:3, 1);      % Localite Z = SimNIBS X coordinate
            c =  matsim(1:3, 4);
            
            % X (direction vector)
            data00 = sprintf('%+.17f', x(1));
            data10 = sprintf('%+.17f', x(2));
            data20 = sprintf('%+.17f', x(3));
            
            % Y (direction vector)
            data01 = sprintf('%+.17f', y(1));
            data11 = sprintf('%+.17f', y(2));
            data21 = sprintf('%+.17f', y(3));
            
            % Z (direction vector)
            data02 = sprintf('%+.17f', z(1));
            data12 = sprintf('%+.17f', z(2));
            data22 = sprintf('%+.17f', z(3));
            
            % Coil center (position vector)
            data03 = sprintf('%+.17f', c(1));
            data13 = sprintf('%+.17f', c(2));
            data23 = sprintf('%+.17f', c(3));
            
            % Write to XML        
            fprintf(fid, strcat(ind4, '<InstrumentMarker alwaysVisible="false" index="', num2str(idx_s - 1), '" selected="false"> \n'));
            fprintf(fid, strcat(ind4, ind4, '<Marker additionalInformation="', additionalInformation, '" color="#ff0000" description="', label, '" set="true"> \n'));
            fprintf(fid, strcat(ind4, ind4, ind4, '<Matrix4D \n'));
            fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data00="', data00, '" data01="', data01, '" data02="', data02, '" data03="', data03, '" \n'));
            fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data10="', data10, '" data11="', data11, '" data12="', data12, '" data13="', data13, '" \n'));
            fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data20="', data20, '" data21="', data21, '" data22="', data22, '" data23="', data23, '" \n'));
            fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data30="+0.00000000000000000" data31="+0.00000000000000000" data32="+0.00000000000000000" data33="+1.00000000000000000"/> \n'));
            fprintf(fid, strcat(ind4, ind4, '</Marker> \n'));
            fprintf(fid, strcat(ind4, '</InstrumentMarker> \n'));
        end
        fprintf(fid, '</InstrumentMarkerList> \n');
        fclose(fid);
    end    
end