clear all
close all
clc
%% reading file
% file_name = '001-16channels-50ms-200hz-80uA';
% file_name = '001-16channels-50ms-200hz-80uA';
% file_directory = uigetdir('\\10.16.59.34\cullenlab_server\Current Project Databases - NHP\2021 Abducens Stimulation (Neuropixel)\Data\Project 1 - Occulomotor Kinematics\Caesar_Session_2 - Copy\Renamed\', 'select the file that contains the raw _neural.mat data');
[rawDatafile, file_directory] = uigetfile(fullfile("D:\neuraldata\Caesar_002\bin_files_ERAASR", '*.bin'), 'select the .bin file that contains the raw data for ERAASR');
[stimDatafile, file_directory2] = uigetfile(fullfile(file_directory, '*.bin'), 'select the .bin file that contains the raw stim data for ERAASR');
trigger_file_path = uigetdir(file_directory, "select folder for session trigger files");
[~, trigger_files] = readfolder(trigger_file_path, 'session_trigger_*');
neural_directory = uigetdir(file_directory, 'select the file that contains the raw _neural.mat data');
outputfolder = uigetdir(file_directory, 'select output folder');
%%
if ~exist([outputfolder '\filtered'], 'dir')
    mkdir(fullfile(outputfolder, 'filtered'))
end
%% sort the session triggers with respect to the last figure
fileNumberlist = [];
for i = 1:length(trigger_files)
        % Extract the number from the filename
        filename = trigger_files{i};
        fileidx = split(filename, ["_",".", "-"]);
        fileNumber = str2double(fileidx(3));
        fileNumberlist = [fileNumberlist fileNumber];
end

[~, sorted_idx] = sort(fileNumberlist);
trigger_files = trigger_files(sorted_idx);
%% extract sgement marks
file_num_list = [];
segment_marks = zeros(1, length(trigger_files)+1);
for i = 2:length(trigger_files)+1
    trigger_file_name = trigger_files{i-1};
    fileidx = split(trigger_file_name, ["-","_","."]);
    fileNumber = str2double(fileidx(3));
    file_num_list = [file_num_list, fileNumber];
    session_trigger = fullfile(trigger_file_path, trigger_file_name);
    trigger = load(session_trigger);
    segment_marks(i) = length(trigger.session_trigger);
end
segment_marks = cumsum(segment_marks);
%%

t_count = zeros(1, length(file_num_list));
file_names = dir(fullfile(neural_directory, '*_Neural.mat'));

file_names = struct2cell(file_names);
file_names = file_names(1,:);
file_names = strrep(file_names, '_Neural.mat', '');
%% start of loop
h = waitbar(0, 'Processing...'); % Initialize the progress bar
fileID = fopen(fullfile(outputfolder, ['all_files_filtered_lsqr.bin']),'w');
for file_index =1:length(file_num_list)

sample = segment_marks(file_index)+1:segment_marks(file_index+1);
% file_directory = '\\10.16.59.34\cullenlab_server\Current Project Databases - NHP\2021 Abducens Stimulation (Neuropixel)\Data\Project 1 - Occulomotor Kinematics\Caesar_Session_2 - Copy\Renamed\';
rawData = ReadBin([file_directory rawDatafile],128,[1:128], sample);
file_name = file_names{file_index};
% file_directory = '\\10.16.59.34\cullenlab_server\Current Project Databases - NHP\2021 Abducens Stimulation (Neuropixel)\Data\Project 1 - Occulomotor Kinematics\Caesar_Session_2 - Copy\Renamed\';

load([neural_directory,'\', file_name, '_Neural.mat']); % matlab file
stimData = ReadBin([file_directory2 stimDatafile],1,1, sample);
% rawData = ERASER.ReadBin(dataFileDir , 128, [1:128], [1:30*Data.N]);
%% extract trial by time by channel data
% first extract segments
TRIGDAT =stimData;
% STIM_CHANS = find(any(stim_data~=0, 2));
% TRIGDAT = stim_data(STIM_CHANS(1),:)';
trigs1 = find(diff(TRIGDAT) < 0); 
trigs2 = find(diff(TRIGDAT) > 0);
if isempty(trigs1)
    stimData(Data.Intan_idx) = Data.Neural(:, 131);
    TRIGDAT =stimData;
    % STIM_CHANS = find(any(stim_data~=0, 2));
    % TRIGDAT = stim_data(STIM_CHANS(1),:)';
    trigs1 = find(diff(TRIGDAT) < 0); 
    trigs2 = find(diff(TRIGDAT) > 0);
end

if length(trigs1) > length(trigs2)
    trigs  = trigs1;
else
    trigs = trigs2;
end

trigs = trigs(1:2:end);
period = trigs(2) - trigs(1);

NSTIM = length(trigs);

segments_aligned = [];
time_diffs = diff(trigs);
repeat_gap_threshold = period*2;
repeat_boundaries = [0; find(time_diffs > repeat_gap_threshold); numel(trigs)];
num_repeats = numel(repeat_boundaries) - 1;
num_pulse = NSTIM/num_repeats;


for i = 1:NSTIM
    segment = (1 + trigs(i) ):(period+ trigs(i)); 
    segments_aligned = [segments_aligned; segment];  
end

%% generate tensor
fs = 30000; % samplig rate at 30kHz
fc = 300; % highpass at 300 Hz
sample_chans = 1:128;
sample_trials = 1:num_repeats;
prebuffer = 40;
postbuffer =100;
raw_signal_segs = zeros(length(sample_trials), prebuffer+num_pulse*period+postbuffer, length(sample_chans));
stim_segs = zeros(length(sample_trials), prebuffer+num_pulse*period+postbuffer, length(sample_chans));
for i = 1:length(sample_trials)
    sample_trial = sample_trials(i);
    for j = 1:length(sample_chans)
        sample_chan = sample_chans(j);
        sample_pulses = (1+(sample_trial-1)*num_pulse:sample_trial*num_pulse);
        train_seg = reshape(segments_aligned(sample_pulses, :)', 1, []);
        prebuffer_seg = -prebuffer+train_seg(1):train_seg(1)-1;
        postbuffer_seg = train_seg(end)+1:postbuffer+train_seg(end);
        segment = [prebuffer_seg, train_seg, postbuffer_seg];
        raw_signal_segs(i, :, j) = rawData(segment, sample_chan);
        stim_segs(i, :, j) =  TRIGDAT(segment,:);
    end

end

%%
tic
dataCleaned = raw_signal_segs;
for i = 1:1:length(sample_trials)
    for j = 1:length(sample_chans)
        
        x = stim_segs(i,:,j);

        y = raw_signal_segs(i, :, j);
        % Assume x and y are column vectors of the same length
        N = length(x);
        filterOrder =14;       % Number of lags to include (x(t), x(t-1), ...)
        windowSize =12;       % Number of time points in each window

        a_est = zeros(N, 1);   % Output estimate of a(t)

        for t = windowSize + filterOrder - 1 : N
            % Construct y_local from the current window
            y_local = y(t - windowSize + 1 : t);  % [windowSize x 1]

            % Initialize X_local
            X_local = zeros(windowSize, filterOrder);  % [windowSize x filterOrder]

            for k = 1:filterOrder
                % Fill each column with shifted x values
                X_local(:, k) = x(t - windowSize - k + 2 : t - k + 1);
            end
            X_local = [X_local, ones(windowSize, 1)];
            % Solve least squares: theta = (X'X)^-1 X'y
            theta = pinv(X_local) * y_local';  % [filterOrder x 1]

            % Use most recent x values to estimate a(t)
            x_recent = [x(t:-1:t - filterOrder + 1), 1];  % [filterOrder x 1]
            % x_recent = x(t:-1:t - filterOrder + 1); 
            a_est(t) = x_recent(:)' * theta;        % scalar
        end

        % Final output
        y_true = y - a_est';
        dataCleaned(i, :, j) = y_true;
    end
end
toc
%%

%%
filteredData= rawData(:, 1:128);
sample_chans = 1:128;
for i = 1:length(sample_trials)
    sample_trial = sample_trials(i);
    for j = 1:length(sample_chans)
        sample_chan = sample_chans(j);
        sample_pulses = (1+(sample_trial-1)*num_pulse:sample_trial*num_pulse);
        train_seg = reshape(segments_aligned(sample_pulses, :)', 1, []);
        prebuffer_seg = -prebuffer+train_seg(1):train_seg(1)-1;
        postbuffer_seg = train_seg(end)+1:postbuffer+train_seg(end);
        segment = [prebuffer_seg, train_seg, postbuffer_seg]; % , postbuffer_seg
        filteredData(segment, sample_chan) =  dataCleaned(i, :, j);
        % if ismember(sample_chan, Data.stim_channels) % to remove the artifact due to poststim processing from ERAASR in stim channels
        % filteredData(postbuffer_seg, sample_chan) =  filteredData(postbuffer_seg, sample_chan) - linspace(0, (filteredData(postbuffer_seg(end), sample_chan)-filteredData(postbuffer_seg(end)+1, sample_chan)), length(postbuffer_seg))';
            % filteredData(postbuffer_seg, sample_chan) =  filteredData(postbuffer_seg, sample_chan) - linspace(filteredData(postbuffer_seg(1), sample_chan), 0, length(postbuffer_seg))';
        % end
           
    end

end
%%
% chan = 78;
% Z = ZoomPlot([ rawData(:, chan), filteredData(:, chan), stimData*500]);
% % Z = ZoomPlot([ rawData(:, 107), rawData(:, 105), rawData(:, 108)]);
%%
Data.Neural(:, 1:128) = filteredData(Data.Intan_idx, 1:128);
save([outputfolder '\filtered\' file_name '_filtered.mat'], 'Data', '-v7.3');
fwrite(fileID,int16(filteredData(:, 1:128)'),'int16');
waitbar(file_index/length(file_names), h, sprintf('Prosessed %s %d%%', file_name, round(file_index/length(file_names)*100)));



end
fclose(fileID);