function plotFilterComparison(allEctopicSegments, allResponseBeats, originalSignals, segmentIndex, fs, preBeatDuration, postBeatDuration, ectopicTypeNames, ectopicTypeCodes)
% plotFilterComparison - Plot comparison of ectopic beat segments before and after filtering
%
% Inputs:
%   allEctopicSegments - Cell array containing filtered ECG segments with ectopic beats and their responses
%   allResponseBeats - Struct array containing information about ectopic beats
%   originalSignals - Map of original ECG signals, with record name as keys
%   segmentIndex - Index of the ectopic beat segment to display
%   fs - Sampling frequency (Hz)
%   preBeatDuration - Duration to extract before ectopic beat (seconds)
%   postBeatDuration - Duration to extract after ectopic beat (seconds)
%   ectopicTypeNames - Array of ectopic beat type names
%   ectopicTypeCodes - Array of ectopic beat type codes

% Get selected ectopic beat segment (filtered)
selectedSegment = allEctopicSegments{segmentIndex};
selectedBeatInfo = allResponseBeats(segmentIndex);

% Get original record name and index of ectopic beat in original signal
recordName = selectedBeatInfo.recordName;
ectopicIndex = selectedBeatInfo.ectopicIndex;

% Get original signal
originalSignal = originalSignals(recordName);

% Calculate start and end indices of the segment
segmentStart = max(1, ectopicIndex - round(preBeatDuration * fs));
segmentEnd = min(ectopicIndex + round(postBeatDuration * fs) - 1, length(originalSignal));

% Extract original ECG segment of the same position and length
originalSegment = originalSignal(segmentStart:segmentEnd);

% Create time axis
timeAxis = (0:length(selectedSegment)-1) / fs;
% Adjust time axis origin to place ectopic beat at time 0
timeAxis = timeAxis - preBeatDuration;

% % Use heplab_T_detect_MTEO to detect PQRST waves in filtered signal
% [R_wave, ~, ~, T_wave, ~] = heplab_T_detect_MTEO(selectedSegment, fs, 0);
% 
% % Extract T wave and R wave indices
% t_indices = T_wave(:, 1);
% qrs_indices = R_wave(:, 1);

% Plot results
figure('Name', 'Ectopic Beat Filtering Comparison', 'Position', [100, 100, 1200, 800]);

% Plot signal before filtering
subplot(2, 1, 1);
plot(timeAxis, originalSegment, 'b');
hold on;

% % Highlight ectopic beat position
% ectopicSampleIndex = round(preBeatDuration * fs);  % Position of ectopic beat in segment
% scatter(0, originalSegment(ectopicSampleIndex), 100, 'ks', 'LineWidth', 2, 'DisplayName', 'Ectopic Beat');

% Get ectopic beat type
ectopicTypeIdx = find(ectopicTypeCodes == selectedBeatInfo.ectopicType);
if ~isempty(ectopicTypeIdx)
    ectopicTypeName = ectopicTypeNames{ectopicTypeIdx};
else
    ectopicTypeName = ['Unknown Type(' num2str(selectedBeatInfo.ectopicType) ')'];
end

title(['Original Signal - Ectopic Beat (' ectopicTypeName ')']);
xlabel('Time (seconds)');
ylabel('Amplitude (mV)');
grid on;
xlim([-preBeatDuration postBeatDuration]);
% legend('Location', 'best');

% Plot signal after filtering
subplot(2, 1, 2);
plot(timeAxis, selectedSegment, 'b');
hold on;

% % Mark R wave positions
% if ~isempty(qrs_indices)
%     % Ensure indices are within valid range
%     valid_qrs = qrs_indices(qrs_indices <= length(selectedSegment));
%     scatter((valid_qrs/fs - preBeatDuration), selectedSegment(valid_qrs), 80, 'ro', 'LineWidth', 2, 'DisplayName', 'R Wave');
% end
% 
% % Mark T wave positions
% if ~isempty(t_indices)
%     % Ensure indices are within valid range
%     valid_t = t_indices(t_indices <= length(selectedSegment));
%     scatter((valid_t/fs - preBeatDuration), selectedSegment(valid_t), 80, 'go', 'LineWidth', 2, 'DisplayName', 'T Wave');
% end
% 
% % Highlight ectopic beat position
% scatter(0, selectedSegment(ectopicSampleIndex), 100, 'ks', 'LineWidth', 2, 'DisplayName', 'Ectopic Beat');

title(['Filtered Signal - Ectopic Beat (' ectopicTypeName ') and Its Responses']);
xlabel('Time (seconds)');
ylabel('Amplitude (mV)');
grid on;
xlim([-preBeatDuration postBeatDuration]);
% legend('Location', 'best');

% % Add text description of ectopic beat type
% text(0.02, 0.98, ['Ectopic Beat Type: ' ectopicTypeName], ...
%     'Units', 'normalized', 'VerticalAlignment', 'top', 'BackgroundColor', [1 1 1 0.7]);
% 
% % Adjust overall figure
% sgtitle(['Ectopic Beat Segment Filtering Comparison - Record: ' num2str(recordName)]);

% Create a new figure for power spectrum analysis
figure;
% Calculate and plot power spectrum of raw signal
subplot(2, 1, 1);
[pxx_noisy, f_noisy] = pwelch(originalSegment, [], [], [], fs);
semilogy(f_noisy, pxx_noisy);
title('Power Spectrum of Raw ECG Signal');
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
grid on;
xlim([0, 100]);  % Only display 0-100Hz range

% Calculate and plot power spectrum of filtered signal
subplot(2, 1, 2);
[pxx_filtered, f_filtered] = pwelch(selectedSegment, [], [], [], fs);
semilogy(f_filtered, pxx_filtered);
title('Power Spectrum of Filtered ECG Signal');
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
grid on;
xlim([0, 100]);  % Only display 0-100Hz range

% Add marker line showing 60Hz power line frequency
hold on;
plot([60, 60], get(gca, 'YLim'), 'r--');
text(62, min(get(gca, 'YLim'))*10, '60Hz', 'Color', 'r');
hold off;

end