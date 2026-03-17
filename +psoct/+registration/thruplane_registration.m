function out = thruplane_registration( ...
    fixed_bi1, moving_bi1, fixed_o1, moving_o1, gamma, mask)
% THRUPLANE_REGISTRATION Register orientation/biref maps.
% Compute registration and 3D-axis estimation outputs in memory, and
% optionally write selected artifacts to disk.

arguments
    fixed_bi1 (:,:) {mustBeNumeric, mustBeNonempty}
    moving_bi1 (:,:) {mustBeNumeric, mustBeNonempty}
    fixed_o1 (:,:) {mustBeNumeric, mustBeNonempty}
    moving_o1 (:,:) {mustBeNumeric, mustBeNonempty}
    gamma (1,1) double = -15
    mask (:,:) = []
end


fixed_bi1(fixed_bi1 < 0) = 1e-9;
moving_bi1(moving_bi1 < 0) = 1e-9;
fixed_o1(isnan(fixed_o1)) = 1e-9;
moving_o1(isnan(moving_o1)) = 1e-9;

fixed_o2 = 90 - fixed_o1;
moving_o2 = 90 - moving_o1;
fixed_o2(fixed_o2 > 90) = fixed_o2(fixed_o2 > 90) - 180;
fixed_o2(fixed_o2 < -90) = fixed_o2(fixed_o2 < -90) + 180;
moving_o2(moving_o2 > 90) = moving_o2(moving_o2 > 90) - 180;
moving_o2(moving_o2 < -90) = moving_o2(moving_o2 < -90) + 180;

moving_o1 = imresize(moving_o1, size(fixed_o1), 'nearest');
moving_o2 = imresize(moving_o2, size(fixed_o1), 'nearest');
moving_bi1 = imresize(moving_bi1, size(fixed_o1), 'nearest');

disp('start registration');
[optimizer, metric] = imregconfig("multimodal");
optimizer.InitialRadius = optimizer.InitialRadius/3.5;
optimizer.MaximumIterations = 500;
t = imregtform(moving_bi1, fixed_bi1, "affine", optimizer, metric);
Rfixed = imref2d(size(fixed_bi1));
movingReg_bi1 = imwarp(moving_bi1, t, OutputView=Rfixed);

disp('register orientation');
movingReg_o1 = warpOrientationAngle(moving_o1, t, Rfixed);
movingReg_o2 = warpOrientationAngle(moving_o2, t, Rfixed);

disp('registration done');

phi_n = fixed_o1/180*pi;
phi_x = movingReg_o1;
phi_n2 = fixed_o2/180*pi;
phi_x2 = movingReg_o2;
gamma1 = gamma/180*pi;
psi = acot(sin(phi_n)./(sin(gamma1)*tan(phi_x)) - cos(phi_n)./tan(gamma1));

imgR1 = (movingReg_bi1 + fixed_bi1)/2;
imgR1(imgR1 < 0) = 0;
imgR1(imgR1 > 1) = 1;
minO = -pi/2;
maxO = pi/2;

disp('start 3d axis estimation');
k1loc = squeeze(shiftdim([0;0;1], -2));
k2loc_0 = squeeze(shiftdim([0;-sin(gamma1);cos(gamma1)], -2));
k2loc_90 = squeeze(shiftdim([sin(gamma1);0;cos(gamma1)], -2));
r1est = @(x) (x(:)-k1loc'*x(:)*k1loc)*sqrt(1-(k1loc'*x(:))^2/sum(x(:).^2));
r2est_0 = @(x) (x(:)-k2loc_0'*x(:)*k2loc_0)*sqrt(1-(k2loc_0'*x(:))^2/sum(x(:).^2));
r2est_90 = @(x) (x(:)-k2loc_90'*x(:)*k2loc_90)*sqrt(1-(k2loc_90'*x(:))^2/sum(x(:).^2));
options = optimset('MaxFunEvals', 200*3*10, 'MaxIter', 200*3*10, 'TolFun', 1e-20);

dneff_n = fixed_bi1;
dneff_x = movingReg_bi1;
nRows = size(dneff_n, 1);
progressStep = max(1, floor(nRows / 100));

if isempty(mask)
    useMask = false;
else
    if ~isequal(size(mask), size(dneff_n))
        error("thruplane_registration:maskSizeMismatch", ...
            "mask must have the same size as fixed_bi1 (expected %s, got %s).", ...
            mat2str(size(dneff_n)), mat2str(size(mask)));
    end
    useMask = true;
    mask = (mask ~= 0);
end

biref_ObsLSQ = NaN(size(dneff_n));
Psi_ObsLSQ = NaN(size(dneff_n));
Theta_ObsLSQ = NaN(size(dneff_n));

for ii = 1:nRows
    if mod(ii, progressStep) == 0 || ii == 1 || ii == nRows
        fprintf('\rRow=%d/%d (%.1f%%)', ii, nRows, 100 * ii / nRows);
    end
    parfor jj = 1:size(dneff_n, 2)
        if useMask && ~mask(ii, jj)
            continue;
        end
        r_initial = [0;0;0];
        if abs(phi_n(ii,jj)) < pi/4
            r1loc = squeeze(cat(3, cos(phi_n(ii,jj)), sin(phi_n(ii,jj)), 0) .* dneff_n(ii,jj));
            r2loc = squeeze(cat(3, cos(phi_x(ii,jj)).*cos(gamma1), sin(phi_x(ii,jj)), ...
                -cos(phi_x(ii,jj)).*sin(gamma1)) .* dneff_x(ii,jj));
            fun = @(x) (sum(abs(r1loc-r1est(x)).^2) + sum(abs(r2loc-r2est_90(x)).^2));
        else
            r1loc = squeeze(cat(3, cos(phi_n2(ii,jj)), sin(phi_n2(ii,jj)), 0) .* dneff_n(ii,jj));
            r2loc = squeeze(cat(3, cos(phi_x2(ii,jj)), sin(phi_x2(ii,jj)).*cos(gamma1), ...
                sin(phi_x2(ii,jj)).*sin(gamma1)) .* dneff_x(ii,jj));
            fun = @(x) (sum(abs(r1loc-r1est(x)).^2) + sum(abs(r2loc-r2est_0(x)).^2));
        end

        opt = fminsearch(fun, r_initial', options);
        biref_ObsLSQ(ii,jj) = norm(opt(:));
        Psi_ObsLSQ(ii,jj) = acos(opt(3)/norm(opt(:)));

        if abs(phi_n(ii,jj)) < pi/4
            Theta_ObsLSQ(ii,jj) = atan2(opt(2), opt(1));
        else
            temp = pi/2 - atan2(opt(2), opt(1));
            temp(temp > pi/2) = temp(temp > pi/2) - pi;
            temp(temp < -pi/2) = temp(temp < -pi/2) + pi;
            Theta_ObsLSQ(ii,jj) = temp;
        end
    end
end
fprintf('\n');

Psi_ObsLSQ(Psi_ObsLSQ > pi/2) = Psi_ObsLSQ(Psi_ObsLSQ > pi/2) - pi;
Psi_ObsLSQ(Psi_ObsLSQ < -pi/2) = Psi_ObsLSQ(Psi_ObsLSQ < -pi/2) + pi;
Theta_ObsLSQ(Theta_ObsLSQ > pi/2) = Theta_ObsLSQ(Theta_ObsLSQ > pi/2) - pi;
Theta_ObsLSQ(Theta_ObsLSQ < -pi/2) = Theta_ObsLSQ(Theta_ObsLSQ < -pi/2) + pi;

imgR1 = (medfilt2(biref_ObsLSQ, [2 2]) - 1.3e-7)/1e-7;
imgR1(imgR1 < 0) = 0;
imgR1(imgR1 > 1) = 1;

HMap = ones([size(imgR1), 3]);
imgOA1 = (Theta_ObsLSQ - minO)/(maxO - minO);
imgOA1(imgOA1 > 1) = 1;
imgOA1(imgOA1 < 0) = 0;
HMap(:,:,1) = imgOA1;
HMap(:,:,3) = imgR1;
inplaneRgb = hsv2rgb(HMap);

alpha = pi/2 - Psi_ObsLSQ;
alpha(alpha > pi/2) = alpha(alpha > pi/2) - pi;
alpha(alpha < -pi/2) = alpha(alpha < -pi/2) + pi;
imgOA1 = (alpha - minO)/(maxO - minO);
imgOA1(imgOA1 > 1) = 1;
imgOA1(imgOA1 < 0) = 0;
HMap(:,:,1) = imgOA1;
HMap(:,:,3) = imgR1;
alphaRgb = hsv2rgb(HMap);



out = struct();
out.dneff_n = dneff_n;
out.dneff_x = dneff_x;
out.phi_n = phi_n;
out.phi_x = phi_x;
out.psi = psi;
out.Psi_ObsLSQ = Psi_ObsLSQ;
out.Theta_ObsLSQ = Theta_ObsLSQ;
out.biref_ObsLSQ = biref_ObsLSQ;
out.alpha = alpha;
out.inplaneRgb = inplaneRgb;
out.alphaRgb = alphaRgb;
end

function writeImageIfPath(pathValue, img, varargin)
pathValue = string(pathValue);
if strlength(pathValue) == 0
    return;
end
imwrite(img, convertStringsToChars(pathValue), varargin{:});
end

function paths = normalizePathFields(paths, fieldNames)
for k = 1:numel(fieldNames)
    paths = psoct.internal.paths.ensurePathField(paths, fieldNames(k));
end
end

function movingReg_o = warpOrientationAngle(moving_o, t, Rfixed)
moving_OC = angle2tensor(moving_o);
movingReg_OC = zeros(size(moving_OC), "like", moving_OC);
for c = 1:size(moving_OC, 3)
    movingReg_OC(:,:,c) = imwarp(moving_OC(:,:,c), t, OutputView=Rfixed);
end
movingReg_o = tensor2angle(movingReg_OC);
end
