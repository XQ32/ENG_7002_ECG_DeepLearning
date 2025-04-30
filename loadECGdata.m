function [M, ATRTIMED, ANNOTD, TIME] = loadECGData(recordName, PATH, SAMPLES2READ)
% loadECGData - Load ECG data from the MIT-BIH database
%
% Inputs:
%   recordName - Record name (e.g., '100', '101', etc.)
%   PATH - Path to the data files
%   SAMPLES2READ - Number of samples to read
%
% Outputs:
%   M - ECG signal data (waveform)
%   ATRTIMED - Annotation time points
%   ANNOTD - Annotation labels
%   TIME - Time axis vector
%
% This function reads ECG data from three files:
% - Header file (.hea): Contains signal information (format, channels, gain)
% - Data file (.dat): Contains the actual ECG signal data
% - Annotation file (.atr): Contains beat annotations and their timestamps

% Construct file names
HEADERFILE = strcat(recordName, '.hea');
ATRFILE = strcat(recordName, '.atr');
DATAFILE = strcat(recordName, '.dat');

% Read header file to get signal information
signalh = fullfile(PATH, HEADERFILE);
fid1 = fopen(signalh, 'r');
z = fgetl(fid1);
A = sscanf(z, '%*s %d %d %d', [1, 3]);
nosig = A(1);    % Number of signal channels
sfreq = A(2);    % Data sampling frequency (Hz)
clear A;

% Read parameters for each signal channel
for k = 1:nosig
    z = fgetl(fid1);
    A = sscanf(z, '%*s %d %d %d %d %d', [1, 5]);
    dformat(k) = A(1);   % Format of data
    gain(k) = A(2);      % ADC gain (units/mV)
    bitres(k) = A(3);    % ADC resolution in bits
    zerovalue(k) = A(4); % ADC zero value
    firstvalue(k) = A(5); % First integer value of signal
end
fclose(fid1);
clear A;

% Check if data format is 212 (MIT-BIH standard format)
if dformat ~= [212, 212]
    error('This script only works with binary data in format 212');
end

% Read binary ECG data from .dat file
signald = fullfile(PATH, DATAFILE);
fid2 = fopen(signald, 'r');
A = fread(fid2, [3, SAMPLES2READ], 'uint8')';
fclose(fid2);

% Convert binary data to actual signal values (Format 212 decoding)
% Each sample is represented by 12 bits, with two samples stored in 3 bytes
M2H = bitshift(A(:, 2), -4);           % Most significant 4 bits of second sample
M1H = bitand(A(:, 2), 15);             % Most significant 4 bits of first sample
PRL = bitshift(bitand(A(:, 2), 8), 9); % Parity bit for first sample
PRR = bitshift(bitand(A(:, 2), 128), 5); % Parity bit for second sample
M(:, 1) = bitshift(M1H, 8) + A(:, 1) - PRL; % Reconstruct first sample
M(:, 2) = bitshift(M2H, 8) + A(:, 3) - PRR; % Reconstruct second sample

% Verify first value matches expected value from header
if M(1, :) ~= firstvalue
    error('First value does not match expected value from header');
end

% Process data based on number of channels
switch nosig
    case 2
        % For 2-channel recordings: apply gain correction and create time vector
        M(:, 1) = (M(:, 1) - zerovalue(1)) / gain(1); % Convert to millivolts
        M(:, 2) = (M(:, 2) - zerovalue(2)) / gain(2); % Convert to millivolts
        TIME = (0:(SAMPLES2READ - 1)) / sfreq;         % Time in seconds
    case 1
        % For 1-channel recordings: special processing
        M(:, 1) = (M(:, 1) - zerovalue(1));
        M(:, 2) = (M(:, 2) - zerovalue(1));
        M = M';
        M(1) = [];
        sM = size(M);
        sM = sM(2) + 1;
        M(sM) = 0;
        M = M';
        M = M / gain(1);  % Convert to millivolts
        TIME = (0:2 * (SAMPLES2READ) - 1) / sfreq;  % Time in seconds
    otherwise
        disp('No sorting algorithm has been programmed for more than 2 channel signals!');
end
clear A M1H M2H PRR PRL;

% Read annotation data from .atr file
atrd = fullfile(PATH, ATRFILE);
fid3 = fopen(atrd, 'r');
A = fread(fid3, [2, inf], 'uint8')';
fclose(fid3);
ATRTIME = [];  % Annotation time points
ANNOT = [];    % Annotation labels
sa = size(A);
saa = sa(1);
i = 1;

% Parse annotation data according to MIT annotation file format
while i <= saa
    annoth = bitshift(A(i, 2), -2);  % Get annotation code
    
    if annoth == 59
        % Skip time - next 4 bytes specify timestamp
        ANNOT = [ANNOT; bitshift(A(i+3, 2), -2)];
        ATRTIME = [ATRTIME; A(i+2, 1) + bitshift(A(i+2, 2), 8) + ...
            bitshift(A(i+1, 1), 16) + bitshift(A(i+1, 2), 24)];
        i = i + 3;
    elseif annoth == 60 || annoth == 61 || annoth == 62
        % Skip byte codes 60-62 (unused in this implementation)
    elseif annoth == 63
        % Skip bytes - special handling for SKIP byte code
        hilfe = bitshift(bitand(A(i, 2), 3), 8) + A(i, 1);
        hilfe = hilfe + mod(hilfe, 2);
        i = i + hilfe / 2;
    else
        % Standard annotation
        ATRTIME = [ATRTIME; bitshift(bitand(A(i, 2), 3), 8) + A(i, 1)];
        ANNOT = [ANNOT; bitshift(A(i, 2), -2)];
    end
    i = i + 1;
end

% Remove the last entry (EOF)
ANNOT(length(ANNOT)) = [];
ATRTIME(length(ATRTIME)) = [];
clear A;

% Convert ATRTIME to seconds and filter annotations to match time range
ATRTIME = (cumsum(ATRTIME)) / sfreq;  % Convert sample numbers to time in seconds
ind = find(ATRTIME <= TIME(end));     % Find annotations within loaded time range
ATRTIMED = ATRTIME(ind);              % Filter annotation times
ANNOT = round(ANNOT);                 
ANNOTD = ANNOT(ind);                  % Filter annotation labels
end