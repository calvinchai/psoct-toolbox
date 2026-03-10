function birefMap = fitLinear(R3D_deg, surfaceMap, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm)
%FITLINEAR Linear-fit birefringence from retardance vs depth.
%
%   birefMap = psoct.enface.biref.fitLinear(R3D_deg, surfaceMap, ...)
%
%   Implements the same per-A-line linear fit used in the original
%   nested fitBirefringence helper inside psoct.recon.complex2processed.

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
    error('psoct:fitLinear:surfaceSizeMismatch', ...
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
        birefMap(ix, iy) = localFitReducer(R_line, zSizeUm, wavelengthUm);
    end
end

end

function val = localFitReducer(R_line_deg, zSizeUm, wavelengthUm)
% Per-A-line linear fit of OPD vs depth to estimate Delta n.

rp = R_line_deg(:);
% Stop early if zeros (e.g., crop) appear
zZeros = find(rp == 0, 1, 'first');
if ~isempty(zZeros)
    rp = rp(1:zZeros);
end

cycles = rp / 360;
OPD = cycles * wavelengthUm;              % micrometers
depth_um = zSizeUm * (0:numel(OPD)-1)';   % relative to z1

if numel(OPD) >= 3 && any(OPD) && any(depth_um)
    p = polyfit(double(depth_um), double(OPD), 1);  % slope ~ Delta n (unitless)
    val = single(p(1));
else
    val = single(0);
end

end

