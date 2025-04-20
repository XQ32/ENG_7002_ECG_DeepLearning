function [ectopicSegments, responseBeats] = extractEctopicResponses(ecg, ATRTIMED, ANNOTD, fs, preBeatDuration, postBeatDuration, recordNameNum, patientSurvival)
% extractEctopicResponses - Extract ectopic beats and their subsequent response sequences
%
% Inputs:
%   ecg - ECG signal data (filtered)
%   ATRTIMED - Annotation time points (seconds)
%   ANNOTD - Annotation labels
%   fs - Sampling frequency (Hz)
%   preBeatDuration - Duration to extract before the ectopic beat (seconds)
%   postBeatDuration - Duration to extract after the ectopic beat (seconds)
%   recordNameNum - Record identifier
%   patientSurvival - Boolean indicating patient survival status
%
% Outputs:
%   ectopicSegments - Cell array containing ECG segments with ectopic beats and their responses
%   responseBeats - Struct array containing information about ectopic beats

% Ensure ecg is a column vector
ecg = ecg(:);

% Initialize output variables
ectopicSegments = cell(0);
responseBeats = struct('recordName', {}, 'patientSurvival', {}, 'ectopicType', {}, 'ectopicTime', {}, 'ectopicIndex', {}, ...
                       'responseTimes', {}, 'responseIndices', {}, 'responseTypes', {});

% Get all beat time points and types
beatTimes = ATRTIMED(:);
beatTypes = ANNOTD(:);
beatIndices = round(beatTimes * fs) + 1; % Convert time points to sample indices

% Find all ectopic beats
ectopicMask = arrayfun(@isEctopicBeat, beatTypes);
ectopicIndices = find(ectopicMask);

% Extract responses for each ectopic beat
for i = 1:length(ectopicIndices)
    idx = ectopicIndices(i);
    ectopicTime = beatTimes(idx);
    ectopicType = beatTypes(idx);
    ectopicIndex = beatIndices(idx);
    
    % Calculate start and end times for the extraction segment
    startTime = ectopicTime - preBeatDuration;
    endTime = ectopicTime + postBeatDuration;
    
    % Find all beats within the response time window
    responseMask = beatTimes > ectopicTime & beatTimes <= endTime;
    responseTimes = beatTimes(responseMask);
    responseIndices = beatIndices(responseMask);
    responseTypes = beatTypes(responseMask);
    
    % Extract ECG segment containing the ectopic beat and its responses
    % Calculate sample indices
    segmentStart = max(1, ectopicIndex - round(preBeatDuration * fs));
    segmentEnd = min(ectopicIndex + round(postBeatDuration * fs) - 1, length(ecg));
    
    if segmentEnd > segmentStart
        segment = ecg(segmentStart:segmentEnd);
        
        % Skip if the extracted sample doesn't match the standard sample size
        if length(segment) ~= fs * (postBeatDuration + preBeatDuration)
            continue;
        end

        % Store segment in cell array
        ectopicSegments{end+1, 1} = segment;
        
        % Store beat information
        beatInfo = struct('recordName', recordNameNum, ...
                          'patientSurvival', patientSurvival, ...
                          'ectopicType', ectopicType, ...
                          'ectopicTime', ectopicTime, ...
                          'ectopicIndex', ectopicIndex, ...
                          'responseTimes', responseTimes, ...
                          'responseIndices', responseIndices, ...
                          'responseTypes', responseTypes);
        responseBeats = [responseBeats; beatInfo];
    end
end
end