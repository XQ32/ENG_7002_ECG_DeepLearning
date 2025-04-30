%% Main function: Load ECG data from MIT-BIH database, extract ectopic beats and their subsequent responses, and perform waveform detection
% This program uses loadECGData to load data, heplab_ecg_filt for filtering, extracts ectopic beats
% Then uses heplab_slowdetect for R wave detection and heplab_T_detect_MTEO for T wave detection

%% Parameter Settings
PATH = 'D:\Download\Google Drive\2025 Semester 1\ENG 7002A Masters Eng Res Project\ENG 7002 Master Project Code\MIT-BIH'; % Specify database path
SAMPLES2READ = 650000;      % Number of samples to read
fs = 360;                   % Sampling frequency (Hz)
filterLowCf = 0.5;          % Low cutoff frequency for filter (Hz)
filterHighCf = 60;          % High cutoff frequency for filter (Hz)
preBeatDuration = 0.1;      % Duration to extract before ectopic beat (seconds)
postBeatDuration = 10;      % Duration to extract after ectopic beat (seconds)

% Ectopic beat type definitions
ectopicTypeNames = {'Abnormal Atrial Premature Beat', 'Ventricular Premature Beat', 'Nodal Premature Beat', 'Atrial Premature Beat', 'Supraventricular Premature Beat', 'Ventricular Escape Beat', 'Nodal Escape Beat', 'Atrial Escape Beat', 'Supraventricular Escape Beat'};
ectopicTypeCodes = [4, 5, 7, 8, 9];

% MIT-BIH database record names
Name_whole = [100,101,102,103,104,105,106,107,108,109,111,112,113,114,115,...
    116,117,118,119,121,122,123,124,200,201,202,203,205,207,208,209,...
    210,212,213,214,215,217,219,220,221,222,223,228,230,231,232,233,234];

% Name_whole = [201];
% Note: R and T waves are difficult to detect in record 114

%% Initialize variables
% Use cell arrays to store ECG segments of different lengths
allEctopicSegments = cell(0);  
allResponseBeats = struct('recordName', {}, 'patientSurvival', {}, 'ectopicType', {}, 'ectopicTime', {}, 'ectopicIndex', {}, ...
                       'responseTimes', {}, 'responseIndices', {}, 'responseTypes', {});

%% Randomly assign survival status for each record
% Randomly assign patient survival status for each data file in Name_whole
rng(42); % Set random seed to ensure reproducible results
survivalStatus = rand(length(Name_whole), 1) > 0.5; % Random assignment of survival status, 1 for survival, 0 for death
recordSurvivalMap = containers.Map(num2cell(Name_whole), num2cell(survivalStatus));

%% Create a Map to store original ECG signals
originalSignalsMap = containers.Map('KeyType', 'double', 'ValueType', 'any');

%% Process each data record
fprintf('Starting to process MIT-BIH database, identifying ectopic beats...\n');
for na = 1:length(Name_whole)
    recordName = num2str(Name_whole(na));
    recordNameNum = Name_whole(na);
    fprintf('Processing record: %s\n', recordName);
    
    % Load ECG data
    [M, ATRTIMED, ANNOTD, TIME] = loadECGData(recordName, PATH, SAMPLES2READ);
    
    % Store original signal data (channel 1)
    originalSignalsMap(recordNameNum) = M(:, 1);
    
    % Filter ECG signal
%     ecg_filtered = heplab_ecg_filt(M(:, 1), fs, filterLowCf, filterHighCf);
    ecg_filtered = ecgFilter(M, fs);

    % Extract ectopic beats and their responses
    [ectopicSegments, responseBeats] = extractEctopicResponses(ecg_filtered, ATRTIMED, ANNOTD, ...
        fs, preBeatDuration, postBeatDuration, recordNameNum, recordSurvivalMap(recordNameNum));

    % Merge data
    allEctopicSegments = [allEctopicSegments; ectopicSegments];
    allResponseBeats = [allResponseBeats; responseBeats];
    
    fprintf('Found %d ectopic beats in record %s\n', length(responseBeats), recordName);
end


% Select ectopic beat segment number to display
segmentIndex = min(80, length(allEctopicSegments));  % Ensure index doesn't exceed range
% Call function to plot comparison before and after filtering
plotFilterComparison(allEctopicSegments, allResponseBeats, originalSignalsMap, segmentIndex, fs, preBeatDuration, postBeatDuration, ectopicTypeNames, ectopicTypeCodes);


%% Ectopic beat type statistics
fprintf('\nEctopic beat type statistics:\n');
if ~isempty(allResponseBeats)
    ectopicTypes = [allResponseBeats.ectopicType];
    
    for i = 1:length(ectopicTypeCodes)
        count = sum(ectopicTypes == ectopicTypeCodes(i));
        fprintf('%s: %d\n', ectopicTypeNames{i}, count);
    end
    
    fprintf('Total number of ectopic beats: %d\n', length(allResponseBeats));
else
    fprintf('No ectopic beats found\n');
    return;
end

%% Perform R wave and T wave detection on ectopic beat segments
fprintf('\nStarting waveform detection on ectopic beat segments...\n');

% Call function to extract features, also get valid indices
[featureTable, validIndices] = extractECGFeatures(allEctopicSegments, allResponseBeats, fs);

% Remove invalid rows
allEctopicSegments = allEctopicSegments(validIndices);
allResponseBeats = allResponseBeats(validIndices);

fprintf('After removing invalid data, %d ectopic beat segments remain\n', length(allEctopicSegments));


% Select ectopic beat segment number to display
segmentIndex = min(50, length(allEctopicSegments));  % Ensure index doesn't exceed range
% Call function to plot ectopic beat segment waveform
plotEctopicSegment(allEctopicSegments, allResponseBeats, segmentIndex, fs, preBeatDuration, postBeatDuration, ectopicTypeNames, ectopicTypeCodes);

