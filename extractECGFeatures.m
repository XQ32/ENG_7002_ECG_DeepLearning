function [featureTable, validIndices] = extractECGFeatures(allEctopicSegments, allResponseBeats, fs)
% extractECGFeatures - Extract features from ECG segments for machine learning
%
% Inputs:
%   allEctopicSegments - Cell array containing ECG segments with ectopic beats and their responses
%   allResponseBeats - Struct array containing information about ectopic beats
%   fs - Sampling frequency (Hz)
%
% Outputs:
%   featureTable - Table containing extracted features, first column is ectopic beat type
%   validIndices - Logical array indicating valid rows

% Initialize feature matrix
numSegments = length(allEctopicSegments);
featureMatrix = zeros(numSegments, 5); % [ectopicType, patientSurvival, T_wave_mean, T_wave_std, RR_interval_mean]

% Set up progress indicator
fprintf('Starting ECG feature extraction...\n');
fprintf('Processing a total of %d ECG segments\n', numSegments);

% Track indices of valid segments
validIndices = true(numSegments, 1);

% Process each ECG segment
for i = 1:numSegments
    if mod(i, 10) == 0 || i == numSegments
        fprintf('Processing: %d/%d (%.1f%%)\n', i, numSegments, i/numSegments*100);
    end
    
    % Get current ECG segment and corresponding beat information
    ecgSegment = allEctopicSegments{i};
    beatInfo = allResponseBeats(i);
    
    % First column: ectopic beat type
    featureMatrix(i, 1) = beatInfo.ectopicType;
    % Second column: patient survival status
    featureMatrix(i, 2) = beatInfo.patientSurvival;
    
    try
        % Use heplab_T_detect_MTEO to detect R and T waves
        [R_wave, ~, ~, T_wave, ~] = heplab_T_detect_MTEO(ecgSegment, fs, 0);
        
        % T waves
        t_indices = T_wave(:, 1);
        % Ensure indices are within valid range and positive integers
        valid_t = t_indices(t_indices > 0 & t_indices <= length(ecgSegment));

        % Extract T wave amplitudes
        t_amplitudes = ecgSegment(valid_t);
        
        % Calculate mean and standard deviation of T wave amplitudes
        featureMatrix(i, 3) = mean(t_amplitudes);
        featureMatrix(i, 4) = std(t_amplitudes);

        % R waves
        r_indices = R_wave(:, 1);
        % Ensure indices are within valid range and positive integers
        valid_r = r_indices(r_indices > 0 & r_indices <= length(ecgSegment));

        % Calculate RR intervals (in sample points)
        rr_intervals = diff(valid_r);
        
        % Convert RR intervals to milliseconds
        rr_intervals_ms = rr_intervals * (1000 / fs);
        
        % Calculate mean of RR intervals
        featureMatrix(i, 5) = mean(rr_intervals_ms);
        
        if isnan(featureMatrix(i, 3)) || isnan(featureMatrix(i, 4)) || isnan(featureMatrix(i, 5))
            validIndices(i) = false;
        end
        
    catch ME
        % Catch errors during processing to avoid terminating the entire loop
        fprintf('Error processing segment %d: %s\n', i, ME.message);
        % Mark this data point as invalid
        validIndices(i) = false;
    end
end

% Remove invalid rows
featureMatrix = featureMatrix(validIndices, :);

% Convert feature matrix to table
varNames = {'EctopicType','patientSurvival', 'T_Wave_Mean', 'T_Wave_Std', 'RR_Interval_Mean'};
featureTable = array2table(featureMatrix, 'VariableNames', varNames);

% Report number of removed rows
fprintf('Feature extraction complete, %d segments processed, %d invalid segments removed\n', ...
    numSegments, sum(~validIndices));

end