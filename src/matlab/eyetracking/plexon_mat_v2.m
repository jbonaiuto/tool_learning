function [] = plexon_mat_v2()
% [] = plexon_mat()
%
% function to transfer data from plexon file format to matlab
% 
% Author: Marco Bimbi
% Version: 2.0
% 08th Nov, 2019

clear
[filename,pathname] = uigetfile('*.plx','Select the plexon file');
file = strcat(pathname,filename);
file_output = strcat(pathname,filename(1:end-3),'mat');
[n_chan,chan_names] = plx_adchan_names(file);

for i = 1 : n_chan
   
    chan_names(i,:) = strrep(chan_names(i,:),'-','_');
    chan_names(i,:) = strrep(chan_names(i,:),',',' ');
    chan_names(i,:) = strrep(chan_names(i,:),' ','_');
    [analog.(chan_names(i,:)).sampling_freq,analog.(chan_names(i,:)).n_points,analog.(chan_names(i,:)).frag_timestamps,analog.(chan_names(i,:)).frag_n_points,signal] = plx_ad_v(file,i - 1);
    analog.(chan_names(i,:)).('frag_1') = signal(1:analog.(chan_names(i,:)).frag_n_points(1));
    n_frags = size(analog.(chan_names(i,:)).frag_n_points,1);
    
    if n_frags > 1
        
        index = analog.(chan_names(i,:)).frag_n_points(1);
        
        for k = 2 : n_frags
        
            analog.(chan_names(i,:)).(strcat('frag_',num2str(k))) = signal(index + 1: index + analog.(chan_names(i,:)).frag_n_points(k));
            index = index + analog.(chan_names(i,:)).frag_n_points(k);
            
        end
        
    end
        
end

[~, ~, evcounts, ~] = plx_info(file,1);
% and finally the events
[~,nevchannels] = size( evcounts );  
if ( nevchannels > 0 ) 
    % need the event chanmap to make any sense of these
    [~,evchans] = plx_event_chanmap(file);
	for iev = 1:nevchannels
		if ( evcounts(iev) > 0 )
            evch = evchans(iev);
            if ( evch == 257 )
				[nevs{iev}, tsevs{iev}, svStrobed] = plx_event_ts(file, evch); 
			else
				[nevs{iev}, tsevs{iev}, svdummy] = plx_event_ts(file, evch);
            end
		end
	end
end
[~,evnames] = plx_event_names(file);
save(file_output,'analog','nevs','tsevs','evnames')

return