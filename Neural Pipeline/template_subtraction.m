function amplifier_data_copy = template_subtraction(amplifier_data, trigs, chan, params)
NSTIM = params.NSTIM;
start = params.start;
isstim = params.isstim; % if it is stim channel, we want to blank the signal during stimulus
period = trigs(2)- trigs(1);
period_avg = params.period_avg; % 1ms
prebuffer = params.buffer;
chn_data = zeros(NSTIM, period+prebuffer);
rhs_name = params.name;

time_diffs = diff(trigs);
repeat_gap_threshold = period*2;
repeat_boundaries = [0; find(time_diffs > repeat_gap_threshold); numel(trigs)];
num_repeats = numel(repeat_boundaries) - 1;
num_pulse = NSTIM/num_repeats;


for i = 1:NSTIM
    segment = [-prebuffer+1:period] + trigs(i);
    chn_data(i, :) = amplifier_data(segment); 
end
template1 = chn_data;
template2 = chn_data;
temp = start:NSTIM;
temp = temp(and(mod(temp, num_pulse)~=1, mod(temp, num_pulse) ~= 2));
for i = 1:NSTIM
    if and(mod(i, num_pulse) ~= 1, mod(i, num_pulse) ~= 2)
        template2(i, 1:period_avg+prebuffer) = mean(chn_data(temp, 1:period_avg+prebuffer), 1);
    end
    template2(i, period_avg+prebuffer:end) = linspace(template2(i,period_avg+prebuffer), 0, period-period_avg+1);
end
 

% if isstim
%     template = template1;
% else
    template = template2;
% end
amplifier_data_copy = amplifier_data;
for i = 1 : NSTIM
    segment = [-prebuffer+1:period] + trigs(i);
    amplifier_data_copy( segment) = amplifier_data_copy( segment) - template(i,:);
  
end

if isstim 
    mark = "(Stim Channel and Neighboring Channel)";
else
    mark = "(Non Stim Channel)";
end


if chan ~= 0 % if we give a channel number, that would let the function plot the artifact removal of the corresponding channel

figure 

plot(amplifier_data, 'linewidth', 1.5, 'color',[0 1 0 0.5],'DisplayName','Original Data')
hold on
plot(amplifier_data_copy,'linewidth', 0.6, 'color',[0 0 1], 'DisplayName', 'After Template Subtraction')

hold off 
legend
xlabel('sample');
ylabel('amplitude');
title(sprintf('channel %i before and after template subtraction ' + mark, chan));

subfolderName = [rhs_name '_channel_data'];
if ~exist(subfolderName, 'dir')
    mkdir(subfolderName)
end
figurename = sprintf('channel_%i_full_' + mark + '.fig', chan);
savepath = fullfile(pwd, subfolderName, figurename);
savefig(savepath)
close
end