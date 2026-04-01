function [J1c, J2c] = splitJonesInterleaved3(J1, J2, channelIndex)
%SPLITJONESINTERLEAVED3 Split interleaved A-lines into one channel (3-way).
%
%   [J1c, J2c] = psoct.file.internal.splitJonesInterleaved3(J1, J2, channelIndex)
%
%   Splits J1/J2 along the first dimension using the pattern:
%     channelIndex = 1 -> 1:3:end
%     channelIndex = 2 -> 2:3:end
%     channelIndex = 3 -> 3:3:end

arguments
    J1 (:,:,:) {mustBeNonempty}
    J2 (:,:,:) {mustBeNonempty}
    channelIndex (1,1) double {mustBeInteger, mustBeInRange(channelIndex, 1, 3)}
end

if size(J1, 1) ~= size(J2, 1)
    error("psoct:file:internal:splitJonesInterleaved3:SizeMismatch", ...
        "J1 and J2 must have the same size in dimension 1, got %d and %d.", ...
        size(J1, 1), size(J2, 1));
end
if mod(size(J1, 1), 3) ~= 0
    error("psoct:file:internal:splitJonesInterleaved3:NotDivisibleBy3", ...
        "First dimension must be divisible by 3 for interleaved split, got %d.", ...
        size(J1, 1));
end

J1c = J1(channelIndex:3:end, :, :);
J2c = J2(channelIndex:3:end, :, :);
end

