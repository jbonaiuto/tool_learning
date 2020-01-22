function [analog,nevs,tsevs,evnames] = plexon_mat_v3(filename)
% [analog,nevs,tsevs,evnames] = plexon_mat(filename)
%
% function to transfer data from plexon file format to matlab
% 
% Author: Marco Bimbi
% Version: 3.0
% 11th Dec, 2019

pathname=pwd;
file = strcat(pathname,filesep,filename);
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
tsevs=cell(nevchannels,1);
nevs=cell(nevchannels,1);
if ( nevchannels > 0 ) 
    % need the event chanmap to make any sense of these
    [~,evchans] = plx_event_chanmap(file);
	for iev = 1:nevchannels
		if ( evcounts(iev) > 0 )
            evch = evchans(iev);
            if ( evch == 257 )
				[nevs{iev}, tsevs{iev}, ~] = plx_event_ts(file, evch); 
			else
				[nevs{iev}, tsevs{iev}, ~] = plx_event_ts(file, evch);
            end
		end
	end
end
[~,evnames] = plx_event_names(file);

return