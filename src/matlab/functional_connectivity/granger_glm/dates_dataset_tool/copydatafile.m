function copydatafile=copydatafile(source,destination,arrays,dates,alignment)
%% copie data
% copie data from volumes to a new directory
% arrays:  names of array to import (cell array)
% dates:   dates to import (cell array)
%
%% Thomas Quettier 

%% Each multiunit directory contains a directory called binned, which contains binned data files for each array and event alignment.
% _whole_trial 
% _trial_start 
% _tool_mvmt_onset 
% _reward _place 
% _obj_contact
% _hand_mvmt_onset 
% _go 
% _fix_on

for array_idx=1:length(arrays)
    for date_idx=1:length(dates)
        date=dates{date_idx};
        array=arrays{array_idx};
        
        psource = source; % data folder path
        pattern = sprintf('fr_b_%s_%s_%s.mat', array, date,alignment );
        sourceDir = dir(fullfile(psource, pattern));
        sourceDir([sourceDir.isdir]) = [];
        
        pdest   = destination;
        copie = sprintf('fr_b_%s_%s_%s.mat', array, date, alignment);
        destDir = dir(fullfile(pdest));
        destDir([destDir.isdir]) = []; 
        
        sourceFile = fullfile(psource, sourceDir.name);
        destFile   = fullfile(pdest, copie); 
        copyfile(sourceFile, destFile);
    end
end
end

%% end 


