%% Dates Dataset management script
%
% check if folder exist and add new files in "destination"
% create table with available dates
%
% Thomas Quettier 
%
%% liste de dates
calendario = csvread('calendar2019.csv');
calendar = calendario;

%% One loop per day
for cal_idx = 1:length(calendario(:,1))
   source = '/Volumes/Extreme_SSD/CNRS_THOMAS/multiunit_binned_data/betta';
   destination = '/Users/thomasquettier/Desktop//multiunit_binned_data/betta';
   foldername = sprintf('%02d.%02d.%02d', calendario(cal_idx,1),calendario(cal_idx,2),calendario(cal_idx,3)); 
   date = {foldername};
        
   % check if folder exist 
  folder = fullfile(source, foldername);
    if exist(folder, 'dir') 
                     folder2 = fullfile(folder,'multiunit') ; % check if folder date exist
               if exist(folder2, 'dir') 
                   folder3 = fullfile(folder,'multiunit') ; % check if multiunit folder exist
                         if exist(folder3, 'dir') 
                             source = fullfile(folder,'multiunit/binned') ; % check if binned folder exist
                             
%% Each multiunit directory contains a directory called binned, which contains binned data files for each array and event alignment.
% _whole_trial 
% _trial_start 
% _tool_mvmt_onset 
% _reward _place 
% _obj_contact
% _hand_mvmt_onset 
% _go 
% _fix_on
                             
                             
                             copydatafile(source,destination,{'F1'},date,'fix_on'); % cf note î
                             copydatafile(source,destination,{'F5hand'},date,'fix_on'); 
                             
                          else
                        calendario(cal_idx,1) = NaN; % delete the date from calendar if no available data 
                        calendario(cal_idx,2) = NaN;
                        calendario(cal_idx,3) = NaN;
                        calendario(cal_idx,4) = NaN;
                        calendario(cal_idx,5) = NaN;
                         end
                 else
                calendario(cal_idx,1) = NaN; % delete the date from calendar if if multiunit folder exist
                calendario(cal_idx,2) = NaN;
                calendario(cal_idx,3) = NaN;
                calendario(cal_idx,4) = NaN;
                calendario(cal_idx,5) = NaN;
               end
      else
        calendario(cal_idx,1) = NaN; % delete the date from calendar if if binned folder exist
        calendario(cal_idx,2) = NaN;
        calendario(cal_idx,3) = NaN;
        calendario(cal_idx,4) = NaN;
        calendario(cal_idx,5) = NaN;
    end
end

%% Data Save
daylist = calendario; 
daylist(any(isnan(daylist),2),:) = []; 

save weeks.mat calendario calendar daylist
% calendario = all dates between 25/02/19 and 31/12/19
% calendar = Available data dates
% daylist = Available data dates (NaN removed)

% End