function complex2processed_directory(input_directory, output_directory, surface, depth, zSize, wavelength, oriMethod, birefMethod)
% complex2processed_directory  Wrapper to process all .nii/.nii.gz files in a directory.
%
%   complex2processed_directory(input_directory, output_directory, surface, depth, zSize, wavelength, oriMethod, birefMethod)
%
%   Input
%     input_directory  : string, path to directory containing input .nii or .nii.gz files
%     output_directory : string, path to directory where outputs will be written
%     surface          : string path to surface NIfTI, "find", or numeric (same as complex2processed)
%     depth            : scalar nonneg int, #pixels below surface (same as complex2processed)
%     zSize            : scalar >0, axial voxel size in micrometers (same as complex2processed)
%     wavelength       : string, wavelength in micrometers (same as complex2processed)
%     oriMethod        : string, orientation method (same as complex2processed)
%     birefMethod      : string, birefringence method (same as complex2processed)
%
%   Output
%     For each input file matching pattern mosaic_XXX_image_XXXX*.nii(.gz),
%     writes outputs with prefix: output_directory/mosaic_XXX_image_XXXX
%
%   Example:
%     complex2processed_directory('/data/input', '/data/output', "find", 100, 3.3, "1.3", "new", "new");

% Validate input directory
if ~isfolder(input_directory)
    error('Input directory does not exist: %s', input_directory);
end

% Create output directory if it doesn't exist
if ~isfolder(output_directory)
    mkdir(output_directory);
    fprintf('Created output directory: %s\n', output_directory);
end

% Find all .nii and .nii.gz files in the input directory
file_list = dir(fullfile(input_directory, '*.nii'));
file_list_gz = dir(fullfile(input_directory, '*.nii.gz'));

% Combine file lists
all_files = [file_list; file_list_gz];

if isempty(all_files)
    warning('No .nii or .nii.gz files found in directory: %s', input_directory);
    return;
end

% Filter files that match the mosaic_XXX_image_XXXX pattern
valid_files = {};
for i = 1:numel(all_files)
    full_path = fullfile(all_files(i).folder, all_files(i).name);
    [~, base_name, ext] = fileparts(full_path);
    
    % Handle .gz extension
    if strcmpi(ext, '.gz')
        [~, base_name, ~] = fileparts(base_name);
    end
    
    % Check if filename matches mosaic_XXX_image_XXXX pattern
    tokens = regexp(base_name, '^mosaic_(\d{3})_image_(\d{3,4})', 'tokens', 'once');
    if ~isempty(tokens)
        valid_files{end+1} = full_path;
    else
        warning('Skipping file "%s": does not match mosaic_{3d}_image_{3-4d}* pattern', full_path);
    end
end

if isempty(valid_files)
    warning('No valid files found matching pattern mosaic_XXX_image_XXXX in directory: %s', input_directory);
    return;
end

fprintf('Found %d valid file(s) to process\n', numel(valid_files));

% Pre-compute output prefixes for all files
output_prefixes = cell(size(valid_files));
for i = 1:numel(valid_files)
    input_file = valid_files{i};
    [~, base_name, ~] = fileparts(input_file);
    if endsWith(base_name, '.gz', 'IgnoreCase', true)
        [~, base_name, ~] = fileparts(base_name);
    end
    
    tokens = regexp(base_name, '^mosaic_(\d{3})_image_(\d{3,4})', 'tokens', 'once');
    if ~isempty(tokens)
        mosaic_num = tokens{1};
        image_num = tokens{2};
        output_prefixes{i} = fullfile(output_directory, sprintf('mosaic_%s_image_%s', mosaic_num, image_num));
    else
        output_prefixes{i} = '';
    end
end

% Ensure a parallel pool exists
if isempty(gcp('nocreate'))
    parpool(10);
end

% Process each file in parallel
parfor idx = 1:numel(valid_files)
    input_file = valid_files{idx};
    output_prefix = output_prefixes{idx};
    
    if isempty(output_prefix)
        warning('Skipping file "%s": could not determine output prefix', input_file);
        continue;
    end
    
    try
        fprintf('Processing %s -> prefix: %s\n', input_file, output_prefix);
        complex2processed(input_file, output_prefix, surface, depth, zSize, wavelength, oriMethod, birefMethod);
        fprintf('Completed: %s\n', input_file);
    catch ME
        warning('Failed to process %s: %s', input_file, ME.message);
    end
end

fprintf('Done processing all files. Outputs written to: %s\n', output_directory);

end

