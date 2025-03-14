Data_filtered = load('D:\Oculomotor Research\CRR_002_p1_eraasr\filtered\003-8channels-100ms-200hz-40uA_filtered.mat');
Data_raw = load('E:\neuraldata\Caesar_002\seperate_cells\Kilosort4\Project 1 - Occulomotor Kinematics_CELL_7_kilo_11_good\003-8channels-100ms-200hz-40uA_Neural.mat');
%%
Z = ZoomPlot([Data_filtered.Data.Neural(:, 78), Data_raw.Data.Neural(:, 78)]);

%%
[Data_baseline, template_movmean] = baseline_template_subtraction(Data_raw.Data);

%%
Z = ZoomPlot([Data_filtered.Data.Neural(:, 78), Data_raw.Data.Neural(:, 78), Data_baseline(:, 78)]);
%%
% Z = ZoomPlot([template_movmean(:, 78)])