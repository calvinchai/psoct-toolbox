function out = thruplane_from_files( ...
    fixed_ori_path, moving_ori_path, fixed_biref_path, moving_biref_path, output_dir, gamma, outputOpts)
% THRUPLANE_FROM_FILES Register normal/tilted images from file paths.
% Compute registration outputs in memory and optionally write selected files.
%
% Legacy compatibility:
%   If output_dir is provided and outputOpts.Paths fields are empty, legacy
%   filenames are auto-populated.

arguments
    fixed_ori_path string
    moving_ori_path string
    fixed_biref_path string
    moving_biref_path string
    output_dir string = ""
    gamma double = -15
    outputOpts.Paths struct = struct()
end

nWorkers = 24;
pool = gcp('nocreate');
if isempty(pool)
    if isempty(nWorkers)
        parpool;
    else
        parpool(nWorkers);
    end
else
    fprintf('Using existing parallel pool with %d workers.\n', pool.NumWorkers);
end

pathFields = ["inplaneTiff", "inplaneJpg", "alphaTiff", "alphaJpg", "dataMat", "axisNii", "axisJpg"];
paths = normalizePathFields(outputOpts.Paths, pathFields);
paths = applyLegacyOutputDirDefaults(paths, output_dir);
ensureParentDirsForPaths(paths, pathFields);

fprintf('Reading input NIfTI files...\n');
fixed1 = readNiftiFirstSlice(fixed_ori_path, "fixed orientation");
moving1 = readNiftiFirstSlice(moving_ori_path, "moving orientation");
fixed2 = readNiftiFirstSlice(fixed_biref_path, "fixed birefringence");
moving2 = readNiftiFirstSlice(moving_biref_path, "moving birefringence");

fixed1 = double(fixed1);
moving1 = double(moving1);
fixed2 = double(fixed2);
moving2 = double(moving2);
fixed2 = imgaussfilt(fixed2, 3);
moving2 = imgaussfilt(moving2, 3);

fixed_o1 = -fixed1;
fixed_bi1 = fixed2;
moving_o1 = -moving1;
moving_bi1 = moving2;
moving_bi1(~isfinite(moving_bi1)) = 1e-9;
fixed_bi1(~isfinite(fixed_bi1)) = 1e-9;

fprintf('Starting registration...\n');
regOutputOpts = struct("Paths", paths);
regOut = psoct.registration.thruplane_reg_optiz_tensor_XY_final_par( ...
    fixed_bi1, moving_bi1, fixed_o1, moving_o1, gamma, regOutputOpts);

I_B = (regOut.biref_ObsLSQ - prctile(regOut.biref_ObsLSQ(:), 1)) / prctile(regOut.biref_ObsLSQ(:), 20);
I_B(I_B > 1) = 1;
I_B(I_B < 0) = 0;
[X, Y, Z] = sph2cart(regOut.Theta_ObsLSQ, regOut.alpha, I_B);
oct_vec_3d = cat(3, -X, Z, Y);

fprintf('Normalizing 3D axis vectors...\n');
norm_data = sqrt(sum(oct_vec_3d.^2, 3));
oct_vec_3d_norm = oct_vec_3d ./ (norm_data + eps);
oct_vec_3d_norm(~isfinite(oct_vec_3d_norm)) = 0;

if strlength(paths.axisNii) > 0
    niftiwrite(oct_vec_3d_norm, convertStringsToChars(paths.axisNii));
    fprintf('Saved normalized 3D axis NIfTI: %s\n', paths.axisNii);
end
if strlength(paths.axisJpg) > 0
    imwrite(abs(oct_vec_3d), convertStringsToChars(paths.axisJpg));
    fprintf('Saved 3D axis visualization: %s\n', paths.axisJpg);
end

fprintf('Registration and 3D axis generation complete.\n');
out = struct();
out.oct_vec_3d = oct_vec_3d;
out.oct_vec_3d_norm = oct_vec_3d_norm;
out.alpha = regOut.alpha;
out.Theta_ObsLSQ = regOut.Theta_ObsLSQ;
out.Psi_ObsLSQ = regOut.Psi_ObsLSQ;
out.biref_ObsLSQ = regOut.biref_ObsLSQ;
out.paths = paths;
out.registration = regOut;
end

function paths = normalizePathFields(paths, fieldNames)
for k = 1:numel(fieldNames)
    paths = psoct.internal.paths.ensurePathField(paths, fieldNames(k));
end
end

function paths = applyLegacyOutputDirDefaults(paths, output_dir)
if strlength(output_dir) == 0
    return;
end
legacyPaths = struct( ...
    "inplaneTiff", fullfile(output_dir, "data_inplane.tiff"), ...
    "inplaneJpg", fullfile(output_dir, "data_inplane.jpg"), ...
    "alphaTiff", fullfile(output_dir, "data_alpha.tiff"), ...
    "alphaJpg", fullfile(output_dir, "data_alpha.jpg"), ...
    "dataMat", fullfile(output_dir, "data_data.mat"), ...
    "axisNii", fullfile(output_dir, "3daxis.nii"), ...
    "axisJpg", fullfile(output_dir, "3daxis.jpg"));
legacyFields = fieldnames(legacyPaths);
for k = 1:numel(legacyFields)
    fieldName = legacyFields{k};
    if strlength(paths.(fieldName)) == 0
        paths.(fieldName) = legacyPaths.(fieldName);
    end
end
end

function ensureParentDirsForPaths(paths, fieldNames)
for k = 1:numel(fieldNames)
    fieldName = char(fieldNames(k));
    ensureParentDirForPath(paths.(fieldName));
end
end

function img = readNiftiFirstSlice(niftiPath, label)
img = niftiread(niftiPath);
if ndims(img) == 3
    img = img(:,:,1);
    fprintf('Extracted first slice from %s (3D -> 2D)\n', label);
end
end

function ensureParentDirForPath(pathValue)
pathValue = string(pathValue);
if strlength(pathValue) == 0
    return;
end
[parentDir, ~, ~] = fileparts(pathValue);
if strlength(parentDir) == 0
    return;
end
if ~isfolder(parentDir)
    mkdir(parentDir);
end
end
