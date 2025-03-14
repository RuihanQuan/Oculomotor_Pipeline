Data_filtered = load("D:\neuraldata\CRR_002_ERASER\filtered\004-8channels-50ms-200hz-40uA_filtered.mat");
Data_raw = load("D:\neuraldata\Caesar_002\seperate_cells\Kilosort4\Project 1 - Occulomotor Kinematics_CELL_7_kilo_11_good\004-8channels-50ms-200hz-40uA_Neural.mat");
%%
Z = ZoomPlot([Data_filtered.Data.Neural(:, 78), Data_raw.Data.Neural(:, 78)]);
%% mean
[Data_mean, template_mean] = baseline_template_subtraction(Data_raw.Data, 1);
%% ICA
[Data_ICA, template_ICA] = baseline_template_subtraction(Data_raw.Data, 3);
%% PCA
[Data_PCA, template_PCA] = baseline_template_subtraction(Data_raw.Data, 4);
%%
Z = ZoomPlot([Data_filtered.Data.Neural(:, 78), Data_raw.Data.Neural(:, 78), Data_baseline(:, 78)]);
%%
% Z = ZoomPlot([template_movmean(:, 78)])