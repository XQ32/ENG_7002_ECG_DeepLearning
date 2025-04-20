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
ectopicTypeNames = {'Abnormal Atrial Premature Beat', 'Ventricular Premature Beat', 'Nodal Premature Beat', 'Atrial Premature Beat', 'Supraventricular Premature Beat', 'R-on-T Ventricular Premature Beat'};
ectopicTypeCodes = [4, 5, 7, 8, 9, 41];

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

%% Process each data record
fprintf('Starting to process MIT-BIH database, identifying ectopic beats...\n');
for na = 1:length(Name_whole)
    recordName = num2str(Name_whole(na));
    recordNameNum = Name_whole(na);
    fprintf('Processing record: %s\n', recordName);
    
    % Load ECG data
    [M, ATRTIMED, ANNOTD, TIME] = loadECGdata(recordName, PATH, SAMPLES2READ);
    
    % Filter ECG signal
    ecg_filtered = heplab_ecg_filt(M(:, 1), fs, filterLowCf, filterHighCf);
    
    % Extract ectopic beats and their responses
    [ectopicSegments, responseBeats] = extractEctopicResponses(ecg_filtered, ATRTIMED, ANNOTD, ...
        fs, preBeatDuration, postBeatDuration, recordNameNum, recordSurvivalMap(recordNameNum));
    
    % Merge data
    allEctopicSegments = [allEctopicSegments; ectopicSegments];
    allResponseBeats = [allResponseBeats; responseBeats];
    
    fprintf('Found %d ectopic beats in record %s\n', length(responseBeats), recordName);
end

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

% Check if any ectopic beats were extracted
if isempty(allEctopicSegments)
    error('No ectopic beats detected, cannot perform waveform detection.');
end

% Call function to extract features, also get valid indices
[featureTable, validIndices] = extractECGFeatures(allEctopicSegments, allResponseBeats, fs);

% Remove invalid rows
allEctopicSegments = allEctopicSegments(validIndices);
allResponseBeats = allResponseBeats(validIndices);

fprintf('After removing invalid data, %d ectopic beat segments remain\n', length(allEctopicSegments));

% Select ectopic beat segment number to display
segmentIndex = min(5992, length(allEctopicSegments));  % Ensure index doesn't exceed range

% Get selected ectopic beat segment
selectedSegment = allEctopicSegments{segmentIndex};
selectedBeatInfo = allResponseBeats(segmentIndex);

% Use heplab_slowdetect to detect R waves
% fprintf('Using heplab_slowdetect to detect R waves in the selected ectopic beat segment...\n');
% qrs_indices = heplab_slowdetect(selectedSegment, fs);

% Use heplab_T_detect_MTEO to detect PQRST waves
fprintf('Using heplab_T_detect_MTEO to detect T waves in the selected ectopic beat segment...\n');
[R_wave, ~, ~, T_wave, ~] = heplab_T_detect_MTEO(selectedSegment, fs, 0);
% [R_wave, ~, ~, T_wave, ~] = MTEO_qrst(selectedSegment, fs, 0);

% Extract T wave indices
t_indices = T_wave(:, 1);
qrs_indices = R_wave(:, 1);

%% Plot one segment
fprintf('Plotting waveform detection results...\n');
figure('Name', 'Ectopic Beat and Response Analysis', 'Position', [100, 100, 1200, 600]);

% Create time axis
timeAxis = (0:length(selectedSegment)-1) / fs;
% Adjust time axis origin to place ectopic beat at time 0
timeAxis = timeAxis - preBeatDuration;

% Plot ECG signal
plot(timeAxis, selectedSegment, 'b');
hold on;

% Mark R wave positions
if ~isempty(qrs_indices)
    % Ensure indices are within valid range
    valid_qrs = qrs_indices(qrs_indices <= length(selectedSegment));
    scatter((valid_qrs/fs - preBeatDuration), selectedSegment(valid_qrs), 80, 'ro', 'LineWidth', 2, 'DisplayName', 'R wave');
end

% Mark T wave positions
if ~isempty(t_indices)
    % Ensure indices are within valid range
    valid_t = t_indices(t_indices <= length(selectedSegment));
    scatter((valid_t/fs - preBeatDuration), selectedSegment(valid_t), 80, 'go', 'LineWidth', 2, 'DisplayName', 'T wave');
end

% Highlight ectopic beat position
ectopicSampleIndex = round(preBeatDuration * fs);  % Position of ectopic beat in the segment
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
title(['Ectopic Beat (' ectopicTypeName ') and Response Analysis']);
xlabel('Time (seconds)');
ylabel('Amplitude (mV)');
grid on;
xlim([-preBeatDuration postBeatDuration]);

% Add text description of ectopic beat type
text(0.02, 0.98, ['Ectopic Beat Type: ' ectopicTypeName], ...
    'Units', 'normalized', 'VerticalAlignment', 'top', 'BackgroundColor', [1 1 1 0.7]);

% Display number of detected waveforms
if exist('valid_qrs', 'var')
    fprintf('Detected %d R waves\n', length(valid_qrs));
else
    fprintf('No R waves detected\n');
end

if exist('valid_t', 'var')
    fprintf('Detected %d T waves\n', length(valid_t));
else
    fprintf('No T waves detected\n');
end

fprintf('Processing complete!\n');