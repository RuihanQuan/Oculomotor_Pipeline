clc
clear all
close all
[datafolder, folderlist] = readfolder("", "");
outputdir = uigetdir(pwd, 'choose a folder to save the output');
p.prebuffer = 100; %prepulse length ms
p.postbuffer = 150; %postpulse length ms
% p.num_pulse_threshold = 5; %An BR file should have >5 pulses
p.fc1 = 125;
p.fc2 = 75;
p.fs = 1000; 
p.flag = 1;
p.threshs = [45, 0.3, 0.6, 0.3, 0.3];
session_name = "Daphne-session-3";
for i = 1:length(folderlist)
    outputfolder = fullfile(outputdir, folderlist{i});
    mkdir(outputfolder)
    folder_path = fullfile(datafolder, folderlist{i});
    [~, filelist] = readfolder(folder_path, '*_neural.mat');
    for j = 1:length(filelist)
        file_path = fullfile(folder_path, filelist{j});
        parts = strsplit(filelist{j}, '-');
        number = parts{1};
        [~, Processed_Data, ~] = pipeline_neural(file_path, p, session_name);
        ua = Processed_Data.ua;
        temp = sum(cell2mat(ua))>20;
        timeframe = Processed_Data.timeframe;
        C = bone(length(ua)*2);
        C=flip(C(1:length(ua),:));
        fig = figure;
        hold on
        for row = 1
            ua_seg = ua{row}; % Extract the binary array
            x = find(ua_seg == 1);    % Get indices of 1s
            yStart = row - 0.4;            % Start position of vertical line
            yEnd = row + 0.4;              % End position of vertical line
    
            % Plot vertical lines at each '1' position
            for k = 1:length(x)
                plot([timeframe(x(k)) timeframe(x(k))], [yStart yEnd], 'Color', C(row,:), 'LineWidth', 2);
            end
        end
        % Formatting
        ylim([0 length(ua)+1]);
        xlabel('time (ms)');
        ylabel('trials');
        yticks(1:length(ua));
        title(['Raster Plot of ' + session_name + '-'+ number]);
        grid off;
        box off;
        hold off;
        figure_id = [number '.fig'];
        savefig(fig, fullfile(outputfolder, figure_id))
        %%
        close(fig)
    end
end