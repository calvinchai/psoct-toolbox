function birefMap = unwrapNew(dBI3D_vol, R3D_deg, O3D_deg, surfaceMap, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm) %#ok<INUSD>
%UNWRAPNEW Sliding-window V-based unwrapping birefringence estimator.
%
%   birefMap = psoct.enface.biref.unwrapNew(dBI3D_vol, R3D_deg, O3D_deg, surfaceMap, ...)
%

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
depth_per_pixel = zSizeUm;
lambda = wavelengthUm;
Q = imgaussfilt3(sin(2 * ORI) .* sin(2 * RET), [3 3 10]);
U = imgaussfilt3(cos(2 * ORI) .* sin(2 * RET), [3 3 10]);
V = imgaussfilt3(cos(2 * RET), [3 3 10]);

% Normalize the Stokes vectors
norms = sqrt(Q.^2 + U.^2 + V.^2) + eps;  % eps to avoid divide-by-zero
Q = Q ./ norms; %#ok<NASGU>
U = U ./ norms; %#ok<NASGU>
V = V ./ norms;

for i = 1:nx
    for j = 1:ny
        surf_ij = round(surfaceMap(i, j));
        base_len = 40;
        iter_len = 40;

        % Ensure we don’t go out of bounds
        start_idx = max(1, surf_ij + enfaceOffset);
        end_idx = min(nz, start_idx + enfaceDepth);

        % Compute V-based retardance
        Vseg = squeeze(V(i, j, start_idx:end_idx));
        ret_raw = acos(Vseg) / 2;

        % Use RET directly if mean retardance < pi/5
        if mean(ret_raw - prctile(ret_raw, 1), 'omitnan') < pi/8
            ret_line = ret_raw;
        else
            Vseg1 = squeeze(V(i, j, start_idx+1:end_idx));
            Vseg0 = squeeze(V(i, j, start_idx:(end_idx-1)));
            diffs = abs((acos(Vseg1) - acos(Vseg0)) / 2);
            rstret = acos(V(i, j, start_idx)) / 2;
            ret_build = zeros(size(diffs)+[1,0]);
            ret_build(1) = rstret;

            for k = 1:length(diffs)
                ret_build(k+1) = ret_build(k) + diffs(k);
            end

            ret_line = reshape(ret_build(:), [], 1);
        end

        slopes = [];
        for tempi = 0:5:(iter_len-1)
            endcut = base_len + tempi;
            endcut = min(endcut, length(ret_line));
            y = squeeze(ret_line(1:endcut)) * lambda / (2 * pi) / depth_per_pixel;
            sy = size(y);
            if sy(2) == 1
                y = y.';
            end
            x = 0:(length(y)-1);

            y_mean = mean(y);
            x_mean = mean(x);
            numer = sum(squeeze(x - x_mean) .* squeeze(y - y_mean));

            denom = sum((x - x_mean).^2);
            slope = abs(numer / denom);
            slopes(end+1) = slope; %#ok<AGROW>
        end

        if ~isempty(slopes)
            birefMap(i, j) = prctile(slopes, 95);  % high-percentile slope
        else
            birefMap(i, j) = 0;
        end
    end
end

end

