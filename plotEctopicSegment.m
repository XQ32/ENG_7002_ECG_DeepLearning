function plotEctopicSegment(allEctopicSegments, allResponseBeats, segmentIndex, fs, preBeatDuration, postBeatDuration, ectopicTypeNames, ectopicTypeCodes)
% plotEctopicSegment - Plot waveform of ectopic beat segment
%
% Inputs:
%   allEctopicSegments - Cell array containing ECG segments with ectopic beats and their responses
%   allResponseBeats - Struct array containing information about ectopic beats
%   segmentIndex - Index of the ectopic beat segment to display
%   fs - Sampling frequency (Hz)
%   preBeatDuration - Duration to extract before ectopic beat (seconds)
%   postBeatDuration - Duration to extract after ectopic beat (seconds)
%   ectopicTypeNames - Array of ectopic beat type names
%   ectopicTypeCodes - Array of ectopic beat type codes

% Get selected ectopic beat segment
selectedSegment = allEctopicSegments{segmentIndex};
selectedBeatInfo = allResponseBeats(segmentIndex);

% Use heplab_T_detect_MTEO to detect PQRST waves
[R_wave, ~, S_wave, T_wave, ~] = heplab_T_detect_MTEO(selectedSegment, fs, 0);

% Create time axis
timeAxis = (0:length(selectedSegment)-1) / fs;
% Adjust time axis origin to place ectopic beat at time 0
timeAxis = timeAxis - preBeatDuration;

% Plot results
figure('Name', 'Ectopic Beat and Response Analysis', 'Position', [100, 100, 1200, 600]);

% Plot ECG signal
plot(timeAxis, selectedSegment, 'b');
hold on;

% Mark R wave positions
if ~isempty(R_wave)
    % Ensure indices are within valid range
    valid_r = R_wave(:, 1);
    valid_r = valid_r(valid_r > 0 & valid_r <= length(selectedSegment));
    if ~isempty(valid_r)
        scatter((valid_r/fs - preBeatDuration), selectedSegment(valid_r), 80, 'ro', 'LineWidth', 2, 'DisplayName', 'R Wave');
    end
end

% % Mark Q wave positions
% if ~isempty(Q_wave)
%     % Ensure indices are within valid range
%     valid_q = Q_wave(:, 1);
%     valid_q = valid_q(valid_q > 0 & valid_q <= length(selectedSegment));
%     if ~isempty(valid_q)
%         scatter((valid_q/fs - preBeatDuration), selectedSegment(valid_q), 80, 'mo', 'LineWidth', 2, 'DisplayName', 'Q Wave');
%     end
% end

% Mark S wave positions
if ~isempty(S_wave)
    % Ensure indices are within valid range
    valid_s = S_wave(:, 1);
    valid_s = valid_s(valid_s > 0 & valid_s <= length(selectedSegment));
    if ~isempty(valid_s)
        scatter((valid_s/fs - preBeatDuration), selectedSegment(valid_s), 80, 'co', 'LineWidth', 2, 'DisplayName', 'S Wave');
    end
end

% Mark T wave positions
if ~isempty(T_wave)
    % Ensure indices are within valid range
    valid_t = T_wave(:, 1);
    valid_t = valid_t(valid_t > 0 & valid_t <= length(selectedSegment));
    if ~isempty(valid_t)
        scatter((valid_t/fs - preBeatDuration), selectedSegment(valid_t), 80, 'go', 'LineWidth', 2, 'DisplayName', 'T Wave');
    end
end

% % Mark P wave positions
% if ~isempty(P_wave)
%     % Ensure indices are within valid range
%     valid_p = P_wave(:, 1);
%     valid_p = valid_p(valid_p > 0 & valid_p <= length(selectedSegment));
%     if ~isempty(valid_p)
%         scatter((valid_p/fs - preBeatDuration), selectedSegment(valid_p), 80, 'yo', 'LineWidth', 2, 'DisplayName', 'P Wave');
%     end
% end

% Highlight ectopic beat position
ectopicSampleIndex = round(preBeatDuration * fs);  % Position of ectopic beat in segment
scatter(0, selectedSegment(ectopicSampleIndex), 100, 'ks', 'LineWidth', 2,'DisplayName', 'Ectopic Beat');

% Get ectopic beat type
ectopicTypeIdx = find(ectopicTypeCodes == selectedBeatInfo.ectopicType);
if ~isempty(ectopicTypeIdx)
    ectopicTypeName = ectopicTypeNames{ectopicTypeIdx};
else
    ectopicTypeName = ['Unknown Type(' num2str(selectedBeatInfo.ectopicType) ')'];
end

% Add legend and labels
legend('Location', 'best');
title(['Ectopic Beat (' ectopicTypeName ') and Its Responses']);
xlabel('Time (seconds)');
ylabel('Amplitude (mV)');
grid on;
xlim([-preBeatDuration postBeatDuration]);

% Add text description of ectopic beat type
text(0.02, 0.98, ['Ectopic Beat Type: ' ectopicTypeName], ...
    'Units', 'normalized', 'VerticalAlignment', 'top', 'BackgroundColor', [1 1 1 0.7]);

% Display number of detected waveforms
fprintf('Ectopic beat segment analysis results:\n');
fprintf('R wave count: %d\n', sum(valid_r > 0));
% fprintf('Q wave count: %d\n', sum(valid_q > 0));
fprintf('S wave count: %d\n', sum(valid_s > 0));
fprintf('T wave count: %d\n', sum(valid_t > 0));
% fprintf('P wave count: %d\n', sum(valid_p > 0));
end