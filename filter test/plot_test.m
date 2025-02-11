%%
clc
clear all
intan_file = 'E:\neuraldata\Daphne_003\DRL_NXPL_STIM_003_045\DRL_NXPL_STIM_003__220427_174641.rhs';
% non current steering
% intan_file = 'E:\neuraldata\Daphne_003\DRL_NXPL_STIM_003_014\DRL_NXPL_STIM_003__220427_163054.rhs';
% % % current steering
read_Intan_RHS2000_file(intan_file)

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
[~,name,~] = fileparts(intan_file);
probe_params = struct('dist', 0, ... % the largest distance between stim channel neighbors and stim channels
    'chanMap', 'ImecPrimateStimRec128_kilosortChanMap.mat', ... % the channel mapping we are using should be a .mat file this is also used for kilosort4
    'sat_thresh', 0, ... % The maximum value of amplifier data before saturation, 0 for not segmenting the channels based on saturation
    'neuropixel_index', neuropixel_index, ... % the channel indexing for neuropixel. 
    'name', '' ... % name the rhs file name
    );

template_params = struct( 'NSTIM', 0, ...  % number of stim pulses
    'isstim', true, ... % true if the data is from a stim channel
    'period_avg', 30, ... % number of points to average for the template
    'start', 30, ... % skip the first number of pulses when calculating the template
    'buffer', 0, ... % thenumber of points before each oulse to be considered in calculating the template
    'skip_n', 2 ...% number of initial pulses to skip to calculate the template
    );
visualize = ""; % if we need to visualize the result 
% "stim": visualize only result of stim channels
% "neighbor-stim": visualize the stim channels and its neighboring
% channels
% "non-stim": only non-stim channels
% "all": all the channels
% "": none
probe_params.name = name;
template_params.name = name;
%%
amplifier_data_copy = artifact_Removal(amplifier_data, stim_data, probe_params, template_params, visualize);
 
%%

STIM_CHANS = find(any(stim_data>0, 2));
chan = STIM_CHANS(4);
% chan = 120;
TRIGDAT = stim_data(STIM_CHANS(1),:)';

set(groot,'defaultLineLineWidth',4.0)
Z = ZoomPlot([TRIGDAT*500 amplifier_data_copy(chan,:)', amplifier_data(chan,:)' ]);