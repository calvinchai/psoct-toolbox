function out = thruplane( ...
    fixed_orientation, moving_orientation, ...
    fixed_birefringence, moving_birefringence, ...
    fixed_mask, moving_mask, ...
    fixed_mask_threshold, moving_mask_threshold, ...
    crop_rect, gamma, outputOpts)
% THRUPLANE Single-slice thru-plane registration wrapper.
%   out = THRUPLANE(fixed_orientation, moving_orientation, ...
%                   fixed_birefringence, moving_birefringence, ...
%                   fixed_mask, moving_mask, ...
%                   fixed_mask_threshold, moving_mask_threshold, ...
%                   crop_rect, gamma, outputOpts)
%
%   This function wraps thru-plane registration for a single 2D slice.
%   It accepts four image files (fixed/moving orientation and
%   birefringence), optional masks for fixed and moving images, and an
%   optional crop region. Inputs may be TIFF (`.tif`/`.tiff`) or NIfTI
%   (`.nii`/`.nii.gz`); for 3D NIfTI volumes, the first slice is used.
%
%   Masks (if provided) are smoothed and thresholded, applied to the input
%   images, and then re-applied to the registration outputs so that masked
%   pixels remain suppressed. If a crop is provided, registration is run on
%   the cropped region and the outputs are padded back to the original
%   fixed-image size.
%
%   Inputs
%   ------
%   fixed_orientation        Path to fixed orientation image (TIFF or NIfTI).
%   moving_orientation       Path to moving orientation image (TIFF or NIfTI).
%   fixed_birefringence      Path to fixed birefringence image (TIFF or NIfTI).
%   moving_birefringence     Path to moving birefringence image (TIFF or NIfTI).
%   fixed_mask               (Optional) Path to fixed mask image; "" to skip.
%   moving_mask              (Optional) Path to moving mask image; "" to skip.
%   fixed_mask_threshold     Threshold applied to smoothed fixed_mask (default 55).
%   moving_mask_threshold    Threshold applied to smoothed moving_mask (default 55).
%   crop_rect                (Optional) [r1 r2 c1 c2] crop in fixed-image coords;
%                            [] means no cropping.
%   gamma                    Source/receiver angle in degrees (default -15).
%   outputOpts               Struct with output options; passed through
%                            psoct.internal.opts.normalizeOutputOpts.
%
%   Outputs
%   -------
%   out.paths                Struct of resolved output paths.
%   out.registration         Struct returned from thruplane_registration,
%                            after mask re-application and optional padding.

arguments
    fixed_orientation
    moving_orientation
    fixed_birefringence
    moving_birefringence
    fixed_mask = ""
    moving_mask = ""
    fixed_mask_threshold double = 55
    moving_mask_threshold double = 55
    crop_rect = []
    gamma double = -15
    outputOpts struct = struct()
end

outputOpts = psoct.internal.opts.normalizeOutputOpts(outputOpts);
paths = outputOpts.Paths;

% Ensure parallel pool exists for downstream parfor usage.
nWorkers = 24;
pool = gcp("nocreate");
if isempty(pool)
    if isempty(nWorkers)
        parpool;
    else
        parpool(nWorkers);
    end
else
    fprintf("Using existing parallel pool with %d workers.\n", pool.NumWorkers);
end

% Load orientation/birefringence images (TIFF or NIfTI).
fixed_ori_img = loadImage2D(fixed_orientation, "fixed orientation");
moving_ori_img = loadImage2D(moving_orientation, "moving orientation");
fixed_bi_img = loadImage2D(fixed_birefringence, "fixed birefringence");
moving_bi_img = loadImage2D(moving_birefringence, "moving birefringence");

% Load masks if provided.
has_fixed_mask = ~(strlength(string(fixed_mask)) == 0);
has_moving_mask = ~(strlength(string(moving_mask)) == 0);
fixed_mask_img = [];
moving_mask_img = [];

if has_fixed_mask
    fixed_mask_img = loadImage2D(fixed_mask, "fixed mask");
end
if has_moving_mask
    moving_mask_img = loadImage2D(moving_mask, "moving mask");
end

% Apply masks to inputs (after smoothing/thresholding).
if has_fixed_mask
    fixed_mask_smooth = imgaussfilt(fixed_mask_img, 5);
    fixed_mask_logical = fixed_mask_smooth > fixed_mask_threshold;
    fixed_ori_img = fixed_ori_img .* double(fixed_mask_logical);
    fixed_bi_img = fixed_bi_img .* double(fixed_mask_logical);
else
    fixed_mask_logical = [];
end

if has_moving_mask
    moving_mask_smooth = imgaussfilt(moving_mask_img, 5);
    moving_mask_logical = moving_mask_smooth > moving_mask_threshold;
    moving_ori_img = moving_ori_img .* double(moving_mask_logical);
    moving_bi_img = moving_bi_img .* double(moving_mask_logical);
else
    moving_mask_logical = [];
end

% Record original size and optionally crop.
szFixed = size(fixed_ori_img);
rows = [];
cols = [];
if ~isempty(crop_rect)
    if numel(crop_rect) ~= 4
        error("crop_rect must be [] or a 4-element vector [r1 r2 c1 c2].");
    end
    r1 = crop_rect(1);
    r2 = crop_rect(2);
    c1 = crop_rect(3);
    c2 = crop_rect(4);
    rows = r1:r2;
    cols = c1:c2;
    fixed_ori_img = fixed_ori_img(rows, cols);
    fixed_bi_img = fixed_bi_img(rows, cols);
    moving_ori_img = moving_ori_img(rows, cols);
    moving_bi_img = moving_bi_img(rows, cols);
    if ~isempty(fixed_mask_logical)
        fixed_mask_logical = fixed_mask_logical(rows, cols);
    end
    if ~isempty(moving_mask_logical)
        moving_mask_logical = moving_mask_logical(rows, cols);
    end
end

% Pre-processing for registration.
fixed_bi_img = imgaussfilt(fixed_bi_img, 3);
moving_bi_img = imgaussfilt(moving_bi_img, 3);

fixed_o1 = -double(fixed_ori_img);
moving_o1 = -double(moving_ori_img);
fixed_bi1 = double(fixed_bi_img);
moving_bi1 = double(moving_bi_img);

fixed_bi1(~isfinite(fixed_bi1)) = 1e-9;
moving_bi1(~isfinite(moving_bi1)) = 1e-9;

% Run thruplane registration backend (pass fixed mask logical as mask).
if isempty(fixed_mask_logical)
    maskForReg = [];
else
    maskForReg = fixed_mask_logical;
end
regOut = psoct.registration.thruplane_registration( ...
    fixed_bi1, moving_bi1, fixed_o1, moving_o1, gamma, maskForReg);

% Re-apply fixed mask to registration outputs (on cropped grid).
if ~isempty(fixed_mask_logical)
    regOut = applyMaskToRegOut(regOut, fixed_mask_logical);
end

% Pad results back to original size if cropping was used.
if ~isempty(crop_rect)
    regOut = padRegOutToSize(regOut, szFixed, rows, cols);
end

% Write outputs if paths are provided.
writeImageIfPath(paths.inplaneTiff, regOut.inplaneRgb, "compression", "none");
writeImageIfPath(paths.inplaneJpg, regOut.inplaneRgb);
writeImageIfPath(paths.alphaTiff, regOut.alphaRgb, "compression", "none");
writeImageIfPath(paths.alphaJpg, regOut.alphaRgb);

writeImageIfPath(paths.axisJpg, abs(regOut.oct_vec_3d));
writeNiftiIfPath(paths.axisNii, regOut.oct_vec_3d);
writeNiftiIfPath(paths.axisNiiNorm, regOut.oct_vec_3d_norm);
writeNiftiIfPath(paths.registeredBirefNii, regOut.biref_ObsLSQ);

if strlength(paths.dataMat) > 0
    dneff_n = regOut.dneff_n;       %#ok<NASGU>
    dneff_x = regOut.dneff_x;       %#ok<NASGU>
    phi_n = regOut.phi_n;           %#ok<NASGU>
    phi_x = regOut.phi_x;           %#ok<NASGU>
    psi = regOut.psi;               %#ok<NASGU>
    Psi_ObsLSQ = regOut.Psi_ObsLSQ;         %#ok<NASGU>
    Theta_ObsLSQ = regOut.Theta_ObsLSQ;     %#ok<NASGU>
    biref_ObsLSQ = regOut.biref_ObsLSQ;     %#ok<NASGU>
    save(convertStringsToChars(paths.dataMat), ...
        "dneff_n", "dneff_x", "phi_n", "phi_x", "psi", ...
        "Psi_ObsLSQ", "Theta_ObsLSQ", "biref_ObsLSQ");
end

out = struct();
out.paths = paths;
out.registration = regOut;

end

function img = loadImage2D(pathValue, label)
pathStr = string(pathValue);
if strlength(pathStr) == 0
    error("Path for %s is empty.", label);
end
[~, ~, ext] = fileparts(pathStr);
ext = lower(ext);
if ext == ".nii" || ext == ".gz"
    img = niftiread(pathStr);
    if ndims(img) == 3
        img = img(:,:,1);
        fprintf("Extracted first slice from %s (3D -> 2D)\n", label);
    end
else
    img = imread(pathStr);
end
img = double(img);
end

function regOut = applyMaskToRegOut(regOut, mask)
mask = logical(mask);
fields = fieldnames(regOut);
for k = 1:numel(fields)
    val = regOut.(fields{k});
    if ~isnumeric(val) || isempty(val)
        continue;
    end
    if ismatrix(val)
        regOut.(fields{k}) = val .* mask;
    elseif ndims(val) == 3
        regOut.(fields{k}) = val .* repmat(mask, [1 1 size(val, 3)]);
    end
end
end

function regOut = padRegOutToSize(regOut, szFixed, rows, cols)
rowRange = rows;
colRange = cols;

fields = fieldnames(regOut);
for k = 1:numel(fields)
    name = fields{k};
    value = regOut.(name);
    if isempty(value)
        continue;
    end
    if ismatrix(value) && isequal(size(value), [numel(rowRange), numel(colRange)])
        full = zeros(szFixed, "like", value);
        full(rowRange, colRange) = value;
        regOut.(name) = full;
    elseif ndims(value) == 3 && size(value,1) == numel(rowRange) && size(value,2) == numel(colRange)
        full = zeros([szFixed, size(value,3)], "like", value);
        full(rowRange, colRange, :) = value;
        regOut.(name) = full;
    end
end
end

function writeImageIfPath(pathValue, img, varargin)
pathValue = string(pathValue);
if strlength(pathValue) == 0
    return;
end
imwrite(img, convertStringsToChars(pathValue), varargin{:});
end

function writeNiftiIfPath(pathValue, vol)
pathValue = string(pathValue);
if strlength(pathValue) == 0
    return;
end
niftiwrite(vol, convertStringsToChars(pathValue));
end