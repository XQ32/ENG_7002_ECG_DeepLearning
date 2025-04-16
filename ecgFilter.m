function ecg_filtered = ecgFilter(ecg, fs)
% ecgFilter - Filter ECG signals using traditional filtering methods
% 
% Inputs:
%   ecg - Raw ECG signal
%   fs - Sampling frequency (Hz)
% 
% Outputs:
%   ecg_filtered - Filtered ECG signal
%
% This function performs two-stage filtering of ECG signals:
% 1. Notch filtering to remove 60Hz power line interference
% 2. High-pass filtering to remove baseline wander
%
% The filtering is performed using zero-phase filtering to avoid phase distortion

% Ensure ecg is a column vector for consistent processing
if size(ecg, 2) > size(ecg, 1)
    ecg = ecg';
end

%% Step 1: Remove 60Hz power line interference using a notch filter
% Design a narrow-band 60Hz notch filter
wo = 60/(fs/2);  % Normalized cutoff frequency (60Hz)
bw = wo/35;      % Set narrow bandwidth (Q-factor = 35)
                 % Higher Q-factor gives narrower notch
[b, a] = iirnotch(wo, bw);  % Design IIR notch filter

% Apply the notch filter using zero-phase filtering (filtfilt)
% Zero-phase filtering prevents phase distortion by filtering forwards 
% and backwards, effectively doubling the filter order
ecg_notch_filtered = filtfilt(b, a, ecg);

%% Step 2: Remove baseline wander using a high-pass filter
% Baseline wander typically occurs below 0.5Hz
cutoff_freq = 0.5;  % Cutoff frequency 0.5Hz
order = 2;          % 2nd-order filter (effective order will be 4 due to filtfilt)

% Design Butterworth high-pass filter
% Butterworth filters have maximally flat frequency response in the passband
[b, a] = butter(order, cutoff_freq/(fs/2), 'high');

% Apply high-pass filter using zero-phase filtering
ecg_filtered = filtfilt(b, a, ecg_notch_filtered);

% Note: The final signal will preserve the morphology of the ECG signal while
% removing both high-frequency noise (60Hz) and low-frequency baseline drift.
end