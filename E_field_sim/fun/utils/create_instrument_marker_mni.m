function create_instrument_marker_mni(params)    
    space = 32;
    ind4 = [space, space, space, space];
    out_folder = fullfile(params.subpath, 'instrument_markers');
    if not(isfolder(out_folder))
        [~, ~] = mkdir(out_folder);
    end

    fname = fullfile(out_folder, strcat(params.participant, '_', params.simflag, '_mni.xml'));    
    fid = fopen(fname, 'wt');
    fprintf(fid, '<?xml version="1.0" encoding="UTF-8"?> \n');
    fprintf(fid, '<InstrumentMarkerList coordinateSpace="RAS"> \n'); 
    matsimnibs = load(fullfile(params.simpath, strcat(params.participant, '_mni_matsimnibs.mat')));
    matsimnibs = struct2cell(matsimnibs);
    matsimnibs = matsimnibs{:};
    label = 'Localite_idx-MNI';
    additionalInformation = 'NA';
    matsim = matsimnibs{1, 1}{1, 1};
    
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
    fprintf(fid, strcat(ind4, '<InstrumentMarker alwaysVisible="false" index="0" selected="false"> \n'));
    fprintf(fid, strcat(ind4, ind4, '<Marker additionalInformation="', additionalInformation, '" color="#ff0000" description="', label, '" set="true"> \n'));
    fprintf(fid, strcat(ind4, ind4, ind4, '<Matrix4D \n'));
    fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data00="', data00, '" data01="', data01, '" data02="', data02, '" data03="', data03, '" \n'));
    fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data10="', data10, '" data11="', data11, '" data12="', data12, '" data13="', data13, '" \n'));
    fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data20="', data20, '" data21="', data21, '" data22="', data22, '" data23="', data23, '" \n'));
    fprintf(fid, strcat(ind4, ind4, ind4, ind4, 'data30="+0.00000000000000000" data31="+0.00000000000000000" data32="+0.00000000000000000" data33="+1.00000000000000000"/> \n'));
    fprintf(fid, strcat(ind4, ind4, '</Marker> \n'));
    fprintf(fid, strcat(ind4, '</InstrumentMarker> \n'));     
    fprintf(fid, '</InstrumentMarkerList> \n');
    fclose(fid);
end