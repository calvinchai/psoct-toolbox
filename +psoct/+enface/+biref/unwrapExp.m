function birefMap = unwrapExp(dBI3D_vol, R3D_deg, O3D_deg, surfaceMap, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm) %#ok<INUSD>
%UNWRAPEXP Exponential-style V-based unwrapping birefringence estimator.
%
%   birefMap = psoct.enface.biref.unwrapExp(dBI3D_vol, R3D_deg, O3D_deg, surfaceMap, ...)
%
%   Direct translation of the original unwarp_exp nested helper in
%   psoct.recon.complex2processed, using the en face window defined by
%   (surfaceMap, enfaceOffset, enfaceDepth).

arguments
    dBI3D_vol (:,:,:) {mustBeReal} = []  %#ok<INUSA>
    R3D_deg (:,:,:) {mustBeReal, mustBeNonempty}
    O3D_deg (:,:,:) {mustBeReal, mustBeNonempty}
    surfaceMap (:,:) {mustBeReal, mustBeNonempty}
    enfaceOffset (1,1) {mustBeReal, mustBeFinite} = 0
    enfaceDepth (1,1) {mustBeReal, mustBeFinite, mustBePositive} = 70
    zSizeUm (1,1) {mustBeReal, mustBeFinite, mustBePositive} = 2.5
    wavelengthUm (1,1) {mustBeReal, mustBeFinite, mustBePositive} = 0.0013
end

[nx, ny, nz] = size(R3D_deg);
birefMap = zeros(nx, ny, 'single');
RET = R3D_deg / 180 * pi;
ORI = O3D_deg / 180 * pi;
depth_per_pixel = zSizeUm; %#ok<NASGU>
Q = imgaussfilt3(sin(2 * ORI) .* sin(2 * RET), [1 1 5]);
U = imgaussfilt3(cos(2 * ORI) .* sin(2 * RET), [1 1 5]);
V = imgaussfilt3(cos(2 * RET), [1 1 5]);
V_raw = cos(2 * RET);

% Normalize the Stokes vectors
norms = sqrt(Q.^2 + U.^2 + V.^2) + eps;  % eps to avoid divide-by-zero
Q = Q ./ norms; %#ok<NASGU>
U = U ./ norms; %#ok<NASGU>
V = V ./ norms;
V_raw = V_raw ./ norms;

for i = 1:nx
    for j = 1:ny
        surf_ij = round(surfaceMap(i, j));

        % Ensure we don’t go out of bounds
        start_idx = max(1, surf_ij + enfaceOffset);
        end_idx = min(nz, start_idx + enfaceDepth);

        % Compute V-based retardance
        Vseg = squeeze(V_raw(i, j, start_idx:end_idx));
        ret_raw = acos(Vseg) / 2;

        % Use RET directly if mean retardance < pi/5
        if false
            ret_line = ret_raw;
        else
            Vseg1 = squeeze(V(i, j, start_idx+1:end_idx));
            Vseg0 = squeeze(V(i, j, start_idx:(end_idx-1)));
            raw_diff = (acos(Vseg1) - acos(Vseg0)) / 2;
            diffs = abs(raw_diff);
            changed = (diffs - raw_diff);
            rstret = acos(V_raw(i, j, start_idx)) / 2;
            ret_build = zeros(size(diffs)+[1,0]);
            ret_build(1) = rstret;

            for k = 2:length(ret_raw)
                ret_build(k) = ret_raw(k) + changed(k-1);
            end

            ret_line = reshape(ret_build(:), [], 1);
        end

        rp = squeeze(ret_line(1:end));
        cycles = rp / pi / 2;
        OPD = cycles * wavelengthUm;              % micrometers
        depth_um = zSizeUm * (0:numel(OPD)-1)';   % relative to z1

        if numel(OPD) >= 3 && any(OPD) && any(depth_um)
            p = polyfit(double(depth_um), double(OPD), 1);  % slope ~ Delta n (unitless)
            birefMap(i, j) = single(p(1));
        else
            birefMap(i, j) = 0;
        end

    end
end

end

