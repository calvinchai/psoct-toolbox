function birefMap = fftLinear(R3D_deg, surfaceMap, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm)
%FFTLINEAR Birefringence via FFT-based dominant-component transform.
%
%   birefMap = psoct.enface.biref.fftLinear(R3D_deg, surfaceMap, ...)
%
%   Implements the original diff_fft logic from the nested helper in
%   psoct.recon.complex2processed, but expressed in terms of the shared
%   enface window (surfaceMap, enfaceOffset, enfaceDepth).

arguments
    R3D_deg (:,:,:) {mustBeReal, mustBeNonempty}
    surfaceMap (:,:) {mustBeReal, mustBeNonempty}
    enfaceOffset (1,1) {mustBeReal, mustBeFinite} = 0
    enfaceDepth (1,1) {mustBeReal, mustBeFinite, mustBePositive} = 70
    zSizeUm (1,1) {mustBeReal, mustBeFinite, mustBePositive} = 2.5
    wavelengthUm (1,1) {mustBeReal, mustBeFinite, mustBePositive} = 0.0013
end

[nx, ny, nz] = size(R3D_deg);
if ~isequal(size(surfaceMap), [nx, ny])
    error('psoct:fftLinear:surfaceSizeMismatch', ...
        'surfaceMap must be size [%d %d] to match the lateral dimensions of R3D.', nx, ny);
end

birefMap = zeros(nx, ny, 'single');
for ix = 1:nx
    for iy = 1:ny
        z1 = min(nz, max(1, surfaceMap(ix, iy) + enfaceOffset));
        z2 = min(nz, z1 + enfaceDepth);
        if z2 < z1
            z2 = z1;
        end
        R_line = squeeze(R3D_deg(ix, iy, z1:z2));
        birefMap(ix, iy) = localFftReducer(R_line, zSizeUm, wavelengthUm, enfaceOffset, enfaceDepth);
    end
end

end

function val = localFftReducer(R_line_deg, zSizeUm, wavelengthUm, enfaceOffset, enfaceDepth)
% Per-A-line FFT-based birefringence estimator.

rp = R_line_deg(:);

% Stop early if zeros (e.g., crop) appear
zZeros = find(rp == 0, 1, 'first');
if ~isempty(zZeros)
    rp = rp(1:zZeros);
end

% Apply the monotone dominant-component transform
rp = psoct.enface.biref.internal.transformDominantComponentTrig(rp, 1, 0);

% Legacy diff_fft used rp(enfaceOffset+1 : enfaceOffset+enfaceDepth) on the
% full A-line from surf. Here rp is already cropped to start at enfaceOffset,
% so convert those absolute bounds into local indices in this cropped line.
startIdxAbs = round(enfaceOffset) + 1;
stopIdxAbs = round(enfaceOffset + enfaceDepth);
localStart = max(1, startIdxAbs - round(enfaceOffset));
localStop = min(numel(rp), stopIdxAbs - round(enfaceOffset));
if localStop < localStart
    val = single(0);
    return
end
rp = rp(localStart:localStop);

cycles = rp / 360;
OPD = cycles * wavelengthUm;              % micrometers
depth_um = zSizeUm * (0:numel(OPD)-1)';   % relative to start index

if numel(OPD) >= 3 && any(OPD) && any(depth_um)
    p = polyfit(double(depth_um), double(OPD), 1);  % slope ~ Delta n (unitless)
    val = single(p(1));
else
    val = single(0);
end

end

