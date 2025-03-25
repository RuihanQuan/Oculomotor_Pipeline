 clear all
 close all
%% initialize
[filename, folder_dir] = uigetfile(pwd,'choose the filtered data');

outputfolder = uigetdir(pwd, "select folder to store the output");
prompt = {'name session .bin file: '};
dlgtitle = 'bin file naming';
fieldsize = [1 45];
definput = {'all_files_'};
temp = inputdlg(prompt,dlgtitle,fieldsize,definput);
temp = cell2mat(temp);
temp(isspace(temp)) = '_';



load([folder_dir filename]);
fileID = fopen(fullfile(outputfolder, ['all_files_' temp '.bin']),'w');



fwrite(fileID,int16(Data.Neural(:, 1:128)'),'int16');
    

fclose(fileID);
