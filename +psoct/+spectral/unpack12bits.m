function data = unpack12bits(raw)
%UNPACK12BITS Unpack 12‑bit samples from packed 8‑bit stream.
%   DATA = UNPACK12BITS(RAW) takes a uint8 vector RAW containing 12‑bit
%   samples packed as three bytes per two samples and returns a column
%   vector DATA of type double with one element per 12‑bit sample.
%
%   The packing format is:
%     - b0: low 8 bits of sample 1
%     - b1: high 4 bits of sample 1 (low nibble) and low 4 bits of
%           sample 2 (high nibble)
%     - b2: high 8 bits of sample 2
%
%   RAW is typically read directly from the acquisition file as uint8.
%
%   Inputs
%   ------
%   raw - uint8 vector containing 12‑bit samples packed as three bytes per two samples.
%
%   Outputs
%   ------
%   data - column vector of type double with one element per 12‑bit sample.

narginchk(1, 1);
validateattributes(raw, {'uint8'}, {'vector'}, mfilename, 'raw', 1);

nn = numel(raw) * 2 / 3;
b0 = double(raw(1:3:end));
b1 = double(raw(2:3:end));
b2 = double(raw(3:3:end));
data = zeros(nn, 1, 'double');
data(1:2:end) = b0 + mod(b1, 16) * 256;
data(2:2:end) = floor(b1 / 16) + b2 * 16;
end