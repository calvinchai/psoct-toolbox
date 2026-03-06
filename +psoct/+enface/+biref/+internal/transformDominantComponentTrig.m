function x_modified = transformDominantComponentTrig(x, fs, keep_bandwidth_bins)
%TRANSFORMDOMINANTCOMPONENTTRIG Monotone transform of dominant FFT component.
%
%   x_modified = psoct.enface.biref.internal.transformDominantComponentTrig( ...
%       x, fs, keep_bandwidth_bins)
%
%   This is factored out from the original nested helper in
%   psoct.recon.complex2processed for reuse by en face birefringence methods.

if nargin < 2 || isempty(fs)
    fs = 1;
end
if nargin < 3 || isempty(keep_bandwidth_bins)
    keep_bandwidth_bins = 0;
end

orig_is_row = isrow(x);
x = double(x(:));               % force column vector
N = numel(x);
if N <= 1
    x_modified = x;
    return
end

% --- FFT and dominant-bin selection (positive frequencies only) ---
X = fft(x);
power = abs(X).^2;              % power spectrum

% positive frequency bins correspond to k = 1 .. floor(N/2)+1 (MATLAB 1-based)
% exclude DC (k = 1)
k_pos_max = floor(N/2) + 1;
k_search = 2:k_pos_max;  % exclude DC

% find dominant bin in the positive-frequency range
[~, idx_rel] = max(power(k_search));
dom_k = k_search(idx_rel);      % MATLAB 1-based index of dominant bin
freq_dom = (dom_k - 1) * fs / N;   % frequency in Hz
if freq_dom > 0.01
    % Too high-frequency dominant component: do nothing
    x_modified = x;
    return
end

% Optionally build mask that includes neighbors
lo_k = max(1, dom_k - keep_bandwidth_bins);
hi_k = min(N, dom_k + keep_bandwidth_bins);

X_masked = zeros(size(X));
X_masked(lo_k:hi_k) = X(lo_k:hi_k);

% isolated component in time domain (from masked FFT)
component = real(ifft(X_masked));

% --- derive amplitude, omega, phase for the single dominant bin (exact for single bin) ---
Xk = X(dom_k);
% For k not DC or Nyquist, time-domain amplitude A = 2*|Xk|/N
A = 2 * abs(Xk) / N;
omega = 2 * pi * freq_dom;
phi = angle(Xk);

% time vector
t = (0:(N-1))' / fs;

% represent as sine: s(t) = A * sin(theta_sin) where theta_sin = omega*t + phi + pi/2
theta = omega * t + phi;
theta_sin = theta + 0.5 * pi;

cos_theta_sin = cos(theta_sin);
sin_theta_sin = sin(theta_sin);

% raw mapping: if ascending (cos >= 0) keep A*sin; else reflect -> A*(2 - sin)
raw = zeros(size(sin_theta_sin));
asc_mask = (cos_theta_sin >= 0);
raw(asc_mask) = A * sin_theta_sin(asc_mask);
raw(~asc_mask) = A * (2 - sin_theta_sin(~asc_mask));

% analytic offsets: each completed descending interval increases baseline by 4A
count_completed_desc = floor((theta_sin + 0.5 * pi) / (2 * pi));
offsets = 4 * A * count_completed_desc;

transformed_single = raw + offsets;

% --- Reconstruct final signal ---
x_modified = x - component + transformed_single;

% restore shape to match input (row vs column)
if orig_is_row
    x_modified = x_modified.';
end

end

