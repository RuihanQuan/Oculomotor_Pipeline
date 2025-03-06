clear all

%%
mat_files = uigetdir(pwd, 'choose root folder for _neural.mat files to stitch kilosort 4 result');

[Path_name, F] = readfolder(mat_files, '*_neural.mat');
trigger_file_path = uigetdir(pwd, "select folder for session trigger files");

file_path= uigetdir(pwd, "select folder for kilosort4 results files");
%%
[bin_file, location] = uigetfile('*.bin', "select .bin file that store the artifact removed neural data");

file_indices = [];
% trial_number =[10:17, 19, 32:38, 40, 43:45];
% trial_number = [10:17, 40, 43:45];
% trigger_file_path = 'D:\Oculomotor Research\Current_non-currtent\Neural data analysis\bin_test\mid_bot_all_session_trigger\';
% trial_number = [4, 8, 14, 20];
trial_number = [];
file_num_list = [];
for i = 1:length(F)
    % Extract the number from the filename
    filename = F{i};
    fileidx = split(filename, ["-","_","."]);
    fileNumber = str2double(fileidx(1));
    % Check if the file number is in the selected ranges
    if ~isempty(trial_number)
        if any(fileNumber == trial_number)
            file_indices = [file_indices, i]; % Add the index to the list
            file_num_list = [file_num_list, fileNumber];
        end
    else 
        file_indices = [file_indices, i];
        file_num_list = [file_num_list, fileNumber];
    end
end
file_names = F(file_indices);
segment_marks = zeros(1, length(file_num_list)+1);
for i = 2:length(file_indices)+1
    trigger_file_name = ['session_trigger_' num2str(file_num_list(i-1)) '.mat'];
    session_trigger = fullfile(trigger_file_path, trigger_file_name);
    trigger = load(session_trigger);
    segment_marks(i) = length(trigger.session_trigger);
end
segment_marks = cumsum(segment_marks);

%%
neuropixel_index = [    18, 19, 20, 21, 22, 23, 24, 25, ...
   26, 27, 29, 17, 2,  32, 1,  30, ...
    31, 39, 3,  36, 38, 28, 35, 37, ...
    4,  34, 16, 33, 15, 14, 13, 12, ...
    11, 10, 9,  8,  7,  6,  5,  63, ...
    59, 56, 64, 58, 55, 40, 57, 54, ...                                                                                               
    41, 60, 53, 43, 61, 52, 44, 62, ...
    51, 42, 47, 50, 45, 48, 49, 46, ...
    65, 96, 69, 66, 95, 68, 67, 94, ...
    70, 83, 93, 72, 84, 92, 71, 85, ...
    91, 73, 88, 90, 81, 87, 89, 82, ...
    86, 108, 107, 106,105,104,103,102,...
    101,100,99, 98, 80, 97, 79, 109,...
    76, 78, 117,75, 77, 110,74, 114,...
    115,112,113,111,128,116,118,119,...
    120,121,122,123,124,125,126,127];

chan = 81;
chan_npxl = find(neuropixel_index==chan);

sample = 1+ segment_marks(7): segment_marks(8);
artifact_removed = ReadBin([location bin_file],128,chan_npxl,sample);
preprocessed = ReadBin([file_path '\temp_wh.dat'], 128, chan, sample);

set(groot,'defaultLineLineWidth',4.0)

Z = ZoomPlot([artifact_removed, preprocessed]);

%%
set(groot,'defaultLineLineWidth',1.0)