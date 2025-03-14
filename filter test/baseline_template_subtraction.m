function [Data_filtered, template_across_chan] = baseline_template_subtraction(Data)


template_params = struct( 'NSTIM', 0, ...  % number of stim pulses
    'isstim', true, ... % true if the data is from a stim channel
    'period_avg', 30, ... % number of points to average for the template
    'start', 1, ... % skip the first number of pulses when calculating the template
    'buffer', 0, ... % thenumber of points before each oulse to be considered in calculating the template
    'skip_n', 1 ...% number of initial pulses to skip to calculate the template
    );
visualize = ""; % if we need to visualize the result 
% "stim": visualize only result of stim channels
% "neighbor-stim": visualize the stim channels and its neighboring
% channels
% "non-stim": only non-stim channels
% "all": all the channels
% "": none
%%
fs = 30000;

TRIGDAT =Data.Neural(:, 131);

trigs1 = find(diff(TRIGDAT) < 0); % Biphasic pulse, first phase negative.
trigs2 = find(diff(TRIGDAT) > 0);
if length(trigs1) > length(trigs2)
    trigs  = trigs1;
else
    trigs = trigs2;
end
trigs = trigs(1:2:end);
    
NSTIM = length(trigs);

template_params.NSTIM = NSTIM;
    

NSTIM = template_params.NSTIM;
start = template_params.start;
isstim = template_params.isstim; % if it is stim channel, we want to blank the signal during stimulus
period = trigs(2)- trigs(1);
period_avg = template_params.period_avg; % 1ms
prebuffer = template_params.buffer;
skip_n = template_params.skip_n;
time_diffs = diff(trigs);
repeat_gap_threshold = period*2;
repeat_boundaries = [0; find(time_diffs > repeat_gap_threshold); numel(trigs)];
num_repeats = numel(repeat_boundaries) - 1;
num_pulse = NSTIM/num_repeats;

amplifier_data_copy = Data.Neural(:, 1:128);

 % extract pulses
segments_aligned = [];
for i = 1:NSTIM
    segment = (-prebuffer+1 + trigs(i) ):(period+ trigs(i));
    
    segments_aligned = [segments_aligned; segment];
   
end
%%
% extract segments for template
temp = start:NSTIM;
temp = temp(or(mod(temp, num_pulse)==0, mod(temp, num_pulse) > skip_n));

template_segments= reshape(segments_aligned(:, 1:period_avg+prebuffer), 1, []);
segments_linear = reshape(segments_aligned, 1, []);
chn_pulse_data = amplifier_data_copy(template_segments, 1:128);

%% ICA Artifact removal
stim_chans = Data.stim_channels;
artifact_ICA = extract_artifact_ICA(chn_pulse_data, stim_chans, 4, 16, '');
    
%% 
% average_across_chan = movmean(chn_pulse_data, 5, 2);
average_across_chan = artifact_ICA;
template_across_chan = amplifier_data_copy(segments_linear, :);
template_period = length(1:period_avg+prebuffer);


for i= 1:num_pulse
    temp_seg = (1:period_avg+prebuffer) + (i-1)*template_period;
    template_across_chan(temp_seg, :) = average_across_chan(temp_seg, :) - average_across_chan(temp_seg(1), :);
    for j = 1:128
        template_across_chan(temp_seg(end)+1:temp_seg(1)+period, j) = linspace(template_across_chan(temp_seg(end),j), 0,period-template_period+1);
    end
end
Data_filtered = amplifier_data_copy;
Data_filtered(segments_linear, :) = amplifier_data_copy(segments_linear, :) - template_across_chan;

end