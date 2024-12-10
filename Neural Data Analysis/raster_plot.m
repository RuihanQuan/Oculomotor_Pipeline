datafolder = 'E:\neuraldata\Daphne_003_mat\Seperate_cells\mid_bot_003_no2021\Kilosort4\';
neurons = dir(fullfile(datafolder, 'Daphne_003_mat_CELL_*'));
neurons = struct2cell(neurons);
neurons = neurons(1,:);
neuralFiles = dir(fullfile([datafolder neurons{1}], '*_neural.mat'));
neuralFiles = struct2cell(neuralFiles);
neuralFiles = neuralFiles(1,:);
trial_number =[10:17, 19, 32:38, 40, 43:47, 49];
file_indices = [];
for i = 1:length(neuralFiles)
    % Extract the number from the filename
    filename = neuralFiles{i};
    fileidx = split(filename, ["-","_","."]);
    fileNumber = str2double(fileidx(1));
    % Check if the file number is in the selected ranges
    if any(fileNumber == trial_number)
        file_indices = [file_indices, i]; % Add the index to the list
    end
end

