rawData = Data.Neural(:, 1:128);
TRIGDAT =Data.Neural(:, 131);
% STIM_CHANS = find(any(stim_data~=0, 2));
% TRIGDAT = stim_data(STIM_CHANS(1),:)';
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

fs = 30000; % samplig rate at 30kHz
fc = 300; % highpass at 300 Hz
f = num_pulse*20;  % frequency of stim wave
cutoff = 2*f;  % cutoff frequency (just above fundamental)
[b, a] = butter(4, 250/ (30000 / 2) , 'high');  % 4th-order Butterworth filter
sample_chans = 1:128;
sample_trials = 1:num_repeats;
prebuffer =40;
postbuffer =15;
raw_signal_segs = zeros(length(sample_trials), prebuffer+num_pulse*period+postbuffer, length(sample_chans));
stim_segs = zeros(length(sample_trials), prebuffer+num_pulse*period+postbuffer, length(sample_chans));
for i = 1:length(sample_trials)
    sample_trial = sample_trials(i);

    for j = 1:length(sample_chans)
        sample_chan = sample_chans(j);
        sample_pulses = (1+(sample_trial-1)*num_pulse:sample_trial*num_pulse);
        train_seg = reshape(segments_aligned(sample_pulses, :)', 1, []);
        prebuffer_seg = -prebuffer+train_seg(1):train_seg(1)-1;
        postbuffer_seg = train_seg(end)+1:postbuffer+train_seg(end);
        segment = [prebuffer_seg, train_seg, postbuffer_seg];
        % raw_signal_segs(i, :, j) = filtfilt(b,a,rawData(segment, sample_chan));
        raw_signal_segs(i, :, j) =rawData(segment, sample_chan);
        stim_segs(i, :, j) =  TRIGDAT(segment,:);
    end

end
%%
x = stim_segs(2,:,63);

y = raw_signal_segs(2, :, 63);
% Assume x and y are column vectors of the same length
N = length(x);
filterOrder =16;       % Number of lags to include (x(t), x(t-1), ...)
windowSize =12;       % Number of time points in each window

a_est = zeros(N, 1);   % Output estimate of a(t)

for t = windowSize + filterOrder - 1 : N
    % Construct y_local from the current window
    y_local = y(t - windowSize + 1 : t);  % [windowSize x 1]

    % Initialize X_local
    X_local = zeros(windowSize, filterOrder);  % [windowSize x filterOrder]
    
    for k = 1:filterOrder
        % Fill each column with shifted x values
        X_local(:, k) = x(t - windowSize - k + 2 : t - k + 1);
    end
    % X_local = [X_local, ones(windowSize, 1)];
    % Solve least squares: theta = (X'X)^-1 X'y
    theta = pinv(X_local) * y_local';  % [filterOrder x 1]

    % Use most recent x values to estimate a(t)
    % x_recent = [x(t:-1:t - filterOrder + 1), 1];  % [filterOrder x 1]
    x_recent = x(t:-1:t - filterOrder + 1); 
    a_est(t) = x_recent(:)' * theta;        % scalar
end

% Final output
y_true = y - a_est';

% Plot
figure;
subplot(3,1,1); 
plot(y, 'DisplayName','Raw Data'); 
hold on
plot([0, 0, 0, x(1:end-3)]*200, 'DisplayName','Stim Signal')
legend
box off
subplot(3,1,2); 
plot(y, 'LineWidth',3.0, 'DisplayName','raw signal')
hold on
plot(a_est, 'LineWidth',1.0, 'DisplayName','estimated artifact'); 


title('Estimated a(t)');
legend
box off
subplot(3,1,3); 
plot(filtfilt(b, a, y_true));

title('Recovered y_{true}(t)');
box off
%%

ZoomPlot([a_est, [0, 0, 0, x(1:end-3)]'*100, filtfilt(b, a, y_true)', y'])
