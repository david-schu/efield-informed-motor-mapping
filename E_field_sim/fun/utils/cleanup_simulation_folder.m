function cleanup_simulation_folder(params, simulation)
    folder = fullfile(params.simpath, 'simulations',simulation(1:end-4));
    fclose('all');    
    files = dir(folder);
    files = files(3:end);
    if  isfolder(folder)
    for iii = 1:length(files)
        if not(files(iii).isdir)
            delete(fullfile(folder, files(iii).name));
        else
            L2 = dir(fullfile(folder, files(iii).name));
            L2 = L2(3:end);
            for l = 1:length(L2)
                delete(fullfile(folder, files(iii).name, L2(l).name));
            end
            rmdir(fullfile(folder, files(iii).name)); 
        end
    end
    end
    rmdir(folder);      
end