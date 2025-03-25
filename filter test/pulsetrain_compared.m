%%
close all
clear all

[filtered, location] = uigetfile("E:\neuraldata\CRR_002_ERASER\filtered\", 'select filtered data');
Data_filtered = load([location filtered]);
Data_filtered_ERASER = load(['D:\Oculomotor Research\ArtefactRemovalPipeline\filtered\' filtered]);
filename = strrep(filtered, '_filtered', '_Neural');
Data_raw = load(['E:\neuraldata\Caesar_002\seperate_cells\Kilosort4\Project 1 - Occulomotor Kinematics_CELL_7_kilo_11_good\' filename]);

file_directory = '\\10.16.59.34\cullenlab_server\Current Project Databases - NHP\2021 Abducens Stimulation (Neuropixel)\Data\Project 1 - Occulomotor Kinematics\Caesar_Session_2 - Copy\Renamed';
filename = strrep(filtered, '_filtered.mat', '');
dataFileDir = [file_directory,'\', filename, '.bin'];
raw = ReadBin(dataFileDir , 128, [1:128], [1:30*Data_raw.Data.N]);
Data_raw.Data.Neural(:, 1:128) = raw;
%%
% mean
[Data_mean, template_mean] = baseline_template_subtraction(Data_raw.Data, 1);
% movmean
[Data_movmean, template_movmean] = baseline_template_subtraction(Data_raw.Data, 2);
% % ICA
% [Data_ICA, template_ICA] = baseline_template_subtraction(Data_raw.Data, 3);
% PCA
[Data_PCA, template_PCA] = baseline_template_subtraction(Data_raw.Data, 4);

%% visualize artifact removal

% first extract segments
TRIGDAT =Data_raw.Data.Neural(:, 131);

trigs1 = find(diff(TRIGDAT) < 0); 
trigs2 = find(diff(TRIGDAT) > 0);
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
stim_chans = Data_raw.Data.stim_channels;

%% generate tensor
fs = 30000; % samplig rate at 30kHz
fc = 250; % highpass at 300 Hz
[b, a] = butter(4, fc/(fs/2), 'high');
sample_chans = [ 76:81];
sample_trials = 1:3:num_repeats;
prebuffer = 500;
postbuffer = 500;
template_ERASER = zeros(length(sample_trials), prebuffer+num_pulse*period+postbuffer, length(sample_chans));
stimData_seg =zeros(length(sample_trials), prebuffer+num_pulse*period+postbuffer);
raw_signal_segs = template_ERASER;
template_mean_tensor = template_ERASER;
template_movmean_tensor = template_ERASER;
template_PCA_tensor = template_ERASER;
template_ERAASR = template_ERASER;

ERASER_tensor = template_ERASER;
ERAASR_tensor = template_ERASER;
mean_tensor = template_ERASER;
movmean_tensor = template_ERASER;
PCA_tensor = template_ERASER;

% template_ICA_tensor = template_ERASER;
% ICA_tensor = template_ERASER;

for i = 1:length(sample_trials)
    sample_trial = sample_trials(i);
    sample_pulses = (1+(sample_trial-1)*num_pulse:sample_trial*num_pulse);
    train_seg = reshape(segments_aligned(sample_pulses, :)', 1, []);
    prebuffer_seg = -prebuffer+train_seg(1):train_seg(1)-1;
    postbuffer_seg = train_seg(end)+1:postbuffer+train_seg(end);
    segment = [prebuffer_seg, train_seg, postbuffer_seg];
    stimData_seg(i, :) = Data_raw.Data.Neural(segment, 131);
    for j = 1:length(sample_chans)
        sample_chan = sample_chans(j);
        
        raw_signal_segs(i, :, j) = Data_raw.Data.Neural(segment, sample_chan);
        template_ERASER(i, :, j) = Data_raw.Data.Neural(segment, sample_chan) - Data_filtered_ERASER.Data.Neural(segment, sample_chan);
        template_mean_tensor(i, :, j) = Data_raw.Data.Neural(segment, sample_chan) - Data_mean(segment, sample_chan);
        template_movmean_tensor(i, :, j) = Data_raw.Data.Neural(segment, sample_chan) - Data_movmean(segment, sample_chan);
        template_PCA_tensor(i, :, j) = Data_raw.Data.Neural(segment, sample_chan) - Data_PCA(segment, sample_chan);
        template_ERAASR(i, :, j) = Data_raw.Data.Neural(segment, sample_chan) - Data_filtered.Data.Neural(segment, sample_chan);
        
        ERASER_tensor(i, :, j) = filtfilt(b, a, Data_filtered_ERASER.Data.Neural(segment, sample_chan));
        ERAASR_tensor(i, :, j) = filtfilt(b, a,Data_filtered.Data.Neural(segment, sample_chan));
        mean_tensor(i, :, j) = filtfilt(b, a,Data_mean(segment, sample_chan));
        movmean_tensor(i, :, j) = filtfilt(b, a,Data_movmean(segment, sample_chan));
        PCA_tensor(i, :, j) = filtfilt(b, a,Data_PCA(segment, sample_chan));
        % ERASER_tensor(i, :, j) = Data_filtered_ERASER.Data.Neural(segment, sample_chan);
        % ERAASR_tensor(i, :, j) = Data_filtered.Data.Neural(segment, sample_chan);
        % mean_tensor(i, :, j) = Data_mean(segment, sample_chan);
        % movmean_tensor(i, :, j) = Data_movmean(segment, sample_chan);
        % PCA_tensor(i, :, j) = Data_PCA(segment, sample_chan);
        % template_ICA_tensor(i, :, j) = Data_raw.Data.Neural(segment, sample_chan) - Data_ICA(segment, sample_chan);
        % ICA_tensor(i, :, j) = Data_ICA(segment, sample_chan);
    end

end

%% visualization
% low freq, low current 
% 4
% low freq, hi current
% 1, 2
% high freq, lo current
% 8, 12, 20
% high freq, hi cur
% 7, 19, 21
% pulse train trial 12 (middle part )
% 2 stim channel 2 
n = 5;
sample_trial = sample_trials(n); % 5th in sample_trials
% tag = 'Experiment 4 low freq low current ';
% tag = 'Experiment 2 low freq high current ';
% tag = 'Experiment 8 high freq low current ';
tag = 'Experiment 7 high freq high current ';
% tag = 'Experiment 1 low freq high current';
experiment_no = 7;
figure('Name',tag)
tiledlayout(6, length(sample_chans))
for i = 1:length(sample_chans)
    nexttile;
    sample_chan = sample_chans(i);
    plot(raw_signal_segs(n, :, i), 'LineWidth',2.0, 'Color','b')
    title(sprintf(['Channel # %i, Pulse Train # %i'  '\n'  '%s '],sample_chan, sample_trial, 'raw data' ), 'FontSize',16);
    set(gca,'xticklabel',[])
    xline(prebuffer,'LineStyle','--', 'Color','r')
    xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','r')
    xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
    ylim([-700, 700]);
    box off

end

for i = 1:length(sample_chans)
    nexttile;
    sample_chan = sample_chans(i);
    plot( mean_tensor(n, :, i), 'LineWidth',2.0, 'Color','b')
    title(sprintf( 'filtered with standard mean template' ), 'FontSize',16);
    set(gca,'xticklabel',[])
    xline(prebuffer,'LineStyle','--', 'Color','r')
    xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','r')
    xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
    ylim([-700, 700]);
    box off

end

for i = 1:length(sample_chans)
    nexttile;
    sample_chan = sample_chans(i);
    plot( movmean_tensor(n, :, i), 'LineWidth',2.0, 'Color','b')
    title(sprintf( 'filtered with movmean template' ), 'FontSize',16);
    set(gca,'xticklabel',[])
    xline(prebuffer,'LineStyle','--', 'Color','r')
    xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','r')
    xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
    ylim([-700, 700]);
    box off

end

for i = 1:length(sample_chans)
    nexttile;
    sample_chan = sample_chans(i);  
    plot(PCA_tensor(n, :, i), 'LineWidth',2.0, 'Color','b')
    title('filtered with PCA template', 'FontSize',16);
    set(gca,'xticklabel',[])
    xline(prebuffer,'LineStyle','--', 'Color','r')
    xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','r')
    xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
    ylim([-700, 700]);
    box off

end

for i = 1:length(sample_chans)
    nexttile;
    sample_chan = sample_chans(i);
    
    plot( ERASER_tensor(n, :, i), 'LineWidth',2.0, 'Color','b')
    title('filtered with ERASER template', 'FontSize',16);
    set(gca,'xticklabel',[])
    xline(prebuffer,'LineStyle','--', 'Color','r')
    xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','r')
    xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
    ylim([-700, 700]);
    box off

end

for i = 1:length(sample_chans)
    nexttile;
    sample_chan = sample_chans(i);
    
    plot( ERAASR_tensor(n, :, i), 'LineWidth',2.0, 'Color','b')
    title('filtered with ERAASR template', 'FontSize',16);
    set(gca,'xticklabel',[])
    xline(prebuffer,'LineStyle','--', 'Color','r')
    xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','r')
    xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
    ylim([-700, 700]);
    box off

end
%% one pulse train with template overlayed 
n1 = 5; % smaller than 7
n2 = 3; % smaller than 4
sample_trial = sample_trials(n1);
sample_chan = sample_chans(n2);

figure('Name',tag)
plot(raw_signal_segs(n1, :, n2), 'LineWidth', 3.0, 'Color','b', 'DisplayName','Raw Data')
hold on
plot( template_ERASER(n1, :, n2), 'LineWidth', 1.0, 'Color','r', 'DisplayName','ERASER Template')
xline(prebuffer,'LineStyle','--', 'Color','r', 'DisplayName','Stim onset')
xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','k', 'DisplayName','Stim offset')
hold off
title(sprintf(['Experiment # %i Channel # %i, Pulse Train # %i Template Developed with ERASER' ], experiment_no, sample_chan, sample_trial), 'FontSize',16);
xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
ylim([-700, 700]);
legend()
box off
set(gca,'xticklabel',[])
%% one pulse train with template overlayed 

figure('Name',tag)
plot(raw_signal_segs(n1, :, n2), 'LineWidth', 3.0, 'Color','b', 'DisplayName','Raw Data')
hold on
plot( template_ERAASR(n1, :, n2), 'LineWidth', 1.0, 'Color','r', 'DisplayName','ERAASR Template')
xline(prebuffer,'LineStyle','--', 'Color','r', 'DisplayName','Stim onset')
xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','k', 'DisplayName','Stim offset')
hold off
title(sprintf(['Experiment # %i Channel # %i, Pulse Train # %i Template Developed with ERAASR' ], experiment_no, sample_chan, sample_trial), 'FontSize',16);
xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
ylim([-700, 700]);
legend()
box off
set(gca,'xticklabel',[])
%%
figure('Name',tag)
plot(raw_signal_segs(n1, :, n2), 'LineWidth', 3.0, 'Color','b', 'DisplayName','Raw Data')
hold on
plot( template_PCA_tensor(n1, :, n2), 'LineWidth', 1.0, 'Color','r', 'DisplayName','PCA Template')
xline(prebuffer,'LineStyle','--', 'Color','r', 'DisplayName','Stim onset')
xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','k', 'DisplayName','Stim offset')
hold off
title(sprintf(['Experiment # %i Channel # %i, Pulse Train # %i Template Developed with PCA' ], experiment_no, sample_chan, sample_trial), 'FontSize',16);
xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
ylim([-700, 700]);
legend()
box off
set(gca,'xticklabel',[])
%%
figure('Name',tag)
plot(raw_signal_segs(n1, :, n2), 'LineWidth', 3.0, 'Color','b', 'DisplayName','Raw Data')
hold on
plot( template_movmean_tensor(n1, :, n2), 'LineWidth', 1.0, 'Color','r', 'DisplayName','MOVMEAN Template')
xline(prebuffer,'LineStyle','--', 'Color','r', 'DisplayName','Stim onset')
xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','k', 'DisplayName','Stim offset')
hold off
title(sprintf(['Experiment # %i Channel # %i, Pulse Train # %i Template Developed with PCA' ], experiment_no, sample_chan, sample_trial), 'FontSize',16);
xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
ylim([-700, 700]);
legend()
box off
set(gca,'xticklabel',[])

%% single pulse comparison
a = 6;
pulse_segment = (1+prebuffer:period+prebuffer)+a*period;
figure('Name',tag)

n1 = 2;
n2 = 4;
plot(raw_signal_segs(n1, pulse_segment, n2), 'LineWidth', 3.0, 'Color','b', 'DisplayName','Raw Data')
hold on
plot( ERASER_tensor(n1, pulse_segment, n2), 'LineWidth', 2.0, 'DisplayName','ERASR')
plot( movmean_tensor(n1, pulse_segment, n2), 'LineWidth', 2.0, 'DisplayName','MOVMEAN')
% plot( mean_tensor(n1, pulse_segment, n2), 'LineWidth', 2.0, 'DisplayName','MEAN')
plot( PCA_tensor(n1, pulse_segment, n2), 'LineWidth', 2.0, 'DisplayName','PCA')
plot( ERAASR_tensor(n1, pulse_segment, n2), 'LineWidth', 2.0, 'DisplayName','ERAASR')
hold off
title(sprintf(['Experiment # %i Channel # %i, Pulse Train # %i filtered with Template Developed with PCA' ], experiment_no, sample_chan, sample_trial), 'FontSize',16);
xlim([-1 period + 1])
ylim([-1000, 1000]);
legend()
box off
set(gca,'xticklabel',[])

%%
tag = 'Experiment 7 high freq high current ';
experiment_no = 7;
figure('Name',tag)
tiledlayout(3,3) %  length(sample_chans)
n =7;
segmentlen = 600;
start = prebuffer + 1200;

sample_trial = sample_trials(n);
for i = 2:4 %  length(sample_chans)
    nexttile;
    sample_chan = sample_chans(i);
    plot(raw_signal_segs(n, start:start+segmentlen, i), 'LineWidth',1.0, 'Color','b')
    hold on
    plot(stimData_seg(n, start:start+segmentlen)*500, 'LineStyle','--')
    title(sprintf(['Channel # %i, Pulse Train # %i'  '\n'  '%s '],sample_chan, sample_trial, 'raw data' ), 'FontSize',16);
    set(gca,'xticklabel',[])
    % xline(prebuffer,'LineStyle','--', 'Color','r')
    % xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','r')
    % xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
    ylim([-3000, 3000]);
    box off
    hold off

end

for i = 2:4 %  length(sample_chans)
    nexttile;
    sample_chan = sample_chans(i);
    plot(ERASER_tensor(n, start:start+segmentlen, i), 'LineWidth',1.0, 'Color','b')
    hold on
    plot(stimData_seg(n, start:start+segmentlen)*100, 'LineStyle','--')
    title( 'ERASER', 'FontSize',16);
    set(gca,'xticklabel',[])
    % xline(prebuffer,'LineStyle','--', 'Color','r')
    % xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','r')
    % xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
    ylim([-1000, 1000]);
    box off
    hold off

end

for i = 2:4 %  length(sample_chans)
    nexttile;
    sample_chan = sample_chans(i);
    plot(ERAASR_tensor(n, start:start+segmentlen, i), 'LineWidth',1.0, 'Color','b')
    hold on
    plot(stimData_seg(n, start:start+segmentlen)*100, 'LineStyle','--')
    title('ERAASR', 'FontSize',16);
    set(gca,'xticklabel',[])
    % xline(prebuffer,'LineStyle','--', 'Color','r')
    % xline(length(raw_signal_segs(n, :, i)) - postbuffer,'LineStyle','--', 'Color','r')
    % xlim([-1 length(raw_signal_segs(n, :, i)) + 1])
    ylim([-1000, 1000]);
    box off
    hold off

end
%%
ZoomPlot([Data_raw.Data.Neural(:, 131)*500, Data_raw.Data.Neural(:, 5)])