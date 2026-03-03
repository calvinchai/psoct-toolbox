function thruplane_from_files(fixed_ori_path, moving_ori_path, fixed_biref_path, moving_biref_path, output_dir, gamma)
% THRUPLANE_FROM_FILES - Register normal and tilted illumination images and generate 3D axis
%
% This function takes four NIfTI file paths (fixed/moving orientation and birefringence)
% and performs thruplane registration to combine orientations and generate 3D axis vectors.
%
% Syntax:
%   thruplane_from_files(fixed_ori_path, moving_ori_path, fixed_biref_path, moving_biref_path, output_dir, gamma)
%
% Parameters:
%   fixed_ori_path    - Path to fixed orientation image (.nii or .nii.gz)
%   moving_ori_path   - Path to moving orientation image (.nii or .nii.gz)
%   fixed_biref_path  - Path to fixed birefringence image (.nii or .nii.gz)
%   moving_biref_path  - Path to moving birefringence image (.nii or .nii.gz)
%   output_dir        - Directory to save output files
%   gamma             - Tilt angle parameter (default: -15)
%
% Output files saved to output_dir:
%   - data.mat        - Registration data
%   - inplane.tiff    - HSV color-coded inplane angle image
%   - inplane.jpg     - JPEG version of inplane image
%   - alpha.tiff      - HSV color-coded alpha angle image
%   - alpha.jpg       - JPEG version of alpha image
%   - 3daxis.nii      - Normalized 3D axis vectors as NIfTI
%   - 3daxis.jpg      - Visualization of 3D axis
%
% Example:
%   thruplane_from_files('fixed_ori.nii', 'moving_ori.nii', ...
%                        'fixed_biref.nii', 'moving_biref.nii', ...
%                        './output', -15)

arguments
    fixed_ori_path string
    moving_ori_path string
    fixed_biref_path string
    moving_biref_path string
    output_dir string
    gamma double = -15
end

% Setup parallel pool
nWorkers = 24;
pool = gcp('nocreate');
if isempty(pool)
    if isempty(nWorkers)
        pool = parpool; 
    else
        pool = parpool(nWorkers);
    end
else
    fprintf('Using existing parallel pool with %d workers.\n', pool.NumWorkers);
end

% Add required paths
addpath('/autofs/cluster/octdata2/users/Chao/code/demon_registration_version_8f');
addpath('/autofs/cluster/octdata2/users/Chao/code/telesto');
addpath('/space/omega/1/users/3d_axis/PAPER/scripts');

% Create output directory if it doesn't exist
if ~isfolder(output_dir)
    mkdir(output_dir);
end

% Read NIfTI files
fprintf('Reading input NIfTI files...\n');
fixed1 = niftiread(fixed_ori_path);
moving1 = niftiread(moving_ori_path);
fixed2 = niftiread(fixed_biref_path);
moving2 = niftiread(moving_biref_path);

% Handle 3D inputs - extract first slice if needed
if ndims(fixed1) == 3
    fixed1 = fixed1(:,:,1);
    fprintf('Extracted first slice from fixed orientation (3D -> 2D)\n');
end
if ndims(moving1) == 3
    moving1 = moving1(:,:,1);
    fprintf('Extracted first slice from moving orientation (3D -> 2D)\n');
end
if ndims(fixed2) == 3
    fixed2 = fixed2(:,:,1);
    fprintf('Extracted first slice from fixed birefringence (3D -> 2D)\n');
end
if ndims(moving2) == 3
    moving2 = moving2(:,:,1);
    fprintf('Extracted first slice from moving birefringence (3D -> 2D)\n');
end

% Convert to double if needed
fixed1 = double(fixed1);
moving1 = double(moving1);
fixed2 = double(fixed2);
moving2 = double(moving2);

% Apply preprocessing (Gaussian filtering for birefringence)
fixed2 = imgaussfilt(fixed2, 3);
moving2 = imgaussfilt(moving2, 3);

% Prepare orientation and birefringence images
fixed_o1 = -fixed1;
fixed_bi1 = fixed2;
moving_o1 = -moving1;
moving_bi1 = moving2;

% Handle NaN/Inf values
moving_bi1(~isfinite(moving_bi1)) = 1e-9;
fixed_bi1(~isfinite(fixed_bi1)) = 1e-9;

% Set output filename base (without extension)
outimgname = fullfile(output_dir, 'data');
outimgname = convertStringsToChars(outimgname);
% Call registration function
fprintf('Starting registration...\n');
thruplane_reg_optiz_tensor_XY_final_par(fixed_bi1, moving_bi1, fixed_o1, moving_o1, gamma, outimgname);

% Load the saved data file
datafile = [outimgname '_data.mat'];
if ~isfile(datafile)
    error('Registration data file not found: %s', datafile);
end

fprintf('Loading registration data...\n');
load(datafile);

% Compute alpha (angle adjustment)
alpha = pi/2 - Psi_ObsLSQ;
alpha(alpha > pi/2) = alpha(alpha > pi/2) - pi;
alpha(alpha < -pi/2) = alpha(alpha < -pi/2) + pi;

% Normalize birefringence intensity
I_B = (biref_ObsLSQ - prctile(biref_ObsLSQ(:), 1)) / prctile(biref_ObsLSQ(:), 20);
I_B(I_B > 1) = 1;
I_B(I_B < 0) = 0;

% Convert spherical to Cartesian coordinates
[X, Y, Z] = sph2cart(Theta_ObsLSQ, alpha, I_B);

% Combine into RGB-like 3D vector field
oct_vec_3d = cat(3, -X, Z, Y);

% Normalize the 3D axis vectors
fprintf('Normalizing 3D axis vectors...\n');
norm_data = sqrt(sum(oct_vec_3d.^2, 3));
oct_vec_3d_norm = oct_vec_3d ./ (norm_data + eps);
oct_vec_3d_norm(~isfinite(oct_vec_3d_norm)) = 0;

% Save normalized 3D axis as NIfTI
outfile_nii = fullfile(output_dir, '3daxis.nii');
niftiwrite(oct_vec_3d_norm, outfile_nii);
fprintf('Saved normalized 3D axis NIfTI: %s\n', outfile_nii);

% Save visualization image
outfile_jpg = fullfile(output_dir, '3daxis.jpg');
imwrite(abs(oct_vec_3d), outfile_jpg);
fprintf('Saved 3D axis visualization: %s\n', outfile_jpg);

% Note: inplane and alpha images are already saved by thruplane_reg_optiz_tensor_XY_final_par
% They are saved as: [outimgname '_inplane.tiff'], [outimgname '_inplane.jpg'],
%                   [outimgname '_alpha.tiff'], [outimgname '_alpha.jpg']

fprintf('Registration and 3D axis generation complete.\n');
fprintf('Output directory: %s\n', output_dir);

end


