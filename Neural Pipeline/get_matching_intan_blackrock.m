clear all
close all
clc
%% read ccf files
% Get the current directory
currentDirectory = pwd;
ccfdir  = uigetdir('\\10.16.59.34\cullenlab_server\Current Project Databases - NHP\2021 Abducens Stimulation (Neuropixel)\Data\Project 1 - Occulomotor Kinematics\', 'choose root folder for ccf files');
intandir  = uigetdir('\\10.16.59.34\cullenlab_server\Current Project Databases - NHP\2021 Abducens Stimulation (Neuropixel)\Data\Project 1 - Occulomotor Kinematics\', 'choose root folder for intan files');
datafolder = uigetdir('C:\','choose an output data folder');
% Define the output Excel file path
outputFile = fullfile(currentDirectory, 'CCF_Files.xlsx');

% Search for '.ccf' files in the current directory and subfolders
files = dir(fullfile(ccfdir, '**', '*.ccf'));

% Initialize cell array to store file information
data = cell(length(files), 3);

for i = 1:length(files)
    % Extract relevant information
    fullPath = fullfile(files(i).folder, files(i).name);
    
    data{i, 1} = files(i).name;
    data{i, 2} = fullPath;
    data{i, 3} = files(i).date;
end

% Convert to table
T = cell2table(data, 'VariableNames', {'FileName', 'FullPath', 'LastModified'});

% Write to Excel file
writetable(T, outputFile, 'Sheet', 'CCF Files');

disp(['Export complete. The file is saved at ', outputFile]);

%% read setting files
% Search for 'settings.xml' files in the current directory and subfolders
files = dir(fullfile(intandir, '**', 'settings.xml'));

% Initialize cell array to store file information
data = cell(length(files), 4);

for i = 1:length(files)
    % Extract relevant information
    fullPath = fullfile(files(i).folder, files(i).name);
    subfolderName = strsplit(files(i).folder, filesep);
    subfolderName = subfolderName{end};
    
    data{i, 1} = subfolderName;
    data{i, 2} = files(i).name;
    data{i, 3} = fullPath;
    data{i, 4} = files(i).date;
end

% Convert to table
T = cell2table(data, 'VariableNames', {'SubfolderName', 'FileName', 'FullPath', 'LastModified'});

% Write to Excel file
outputFile = fullfile(currentDirectory, 'Output.xlsx');
writetable(T, outputFile, 'Sheet', 'Setting Files');

disp('Export complete. The file is saved as Output.xlsx in the current directory.');

%%
CCFFiles = readtable('CCF_Files.xlsx');
Output = readtable('Output.xlsx');
datesA = datetime(CCFFiles.LastModified);  % Including the time
datesB = datetime(Output.LastModified);  % Including the time
timeA = dateshift(datesA, 'start', 'minute');  % Remove day, keep time part
timeB = dateshift(datesB, 'start', 'minute');  % Same for datesB
timeA = datetime(timeA, 'Format', 'HH:mm');  % Only keep hours and minutes
timeB = datetime(timeB, 'Format', 'HH:mm');  % Only keep hours and minutes
[isMatch, idxB] = ismember(datesA, datesB);  % Check if times in A match with B
%%
matchesA = timeA(isMatch);
matchesB = timeB(idxB(idxB~=0));

%%
filesA = CCFFiles.FileName(isMatch);
filesB = Output.SubfolderName(idxB(idxB~=0));

T = table(filesA, filesB);
filename = 'matches.xlsx';
writetable(T,filename,'Sheet','matched')
%%

cd(datafolder)
for i =  34: length(filesB)
    file = filesB(i);
    folder_path = fullfile('\\10.16.59.34\cullenlab_server\Current Project Databases - NHP\2021 Abducens Stimulation (Neuropixel)\Data\Project 1 - Occulomotor Kinematics\Daphne_Session_3 - Copy\Intan', file);
    [~,file_name,~] = fileparts(filesA(i));
    mkdir(file_name);
    copyfile(folder_path, file_name)
end