function isEctopic = isEctopicBeat(beatType)
% isEctopicBeat - Determine if a beat type is an ectopic beat
%
% Inputs:
%   beatType - Beat type code
%
% Outputs:
%   isEctopic - Boolean indicating whether the beat is ectopic

% Ectopic beat type codes
ectopicCodes = [4, 5, 7, 8, 9, 41];
isEctopic = ismember(beatType, ectopicCodes);
end