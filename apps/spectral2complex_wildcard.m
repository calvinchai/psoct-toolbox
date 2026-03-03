function spectral2complex_wildcard(wildcard_pattern, Aline_length, Bline_length)
% spectral2complex_wildcard  Wrapper to run spectral2complex on files matching a wildcard pattern.
%
%   spectral2complex_wildcard(wildcard_pattern, Aline_length, Bline_length)
%
%   Input
%     wildcard_pattern  String containing a wildcard pattern (e.g., '*.nii' or
%                       '/data/mosaic_*_image_*.nii'). The pattern can include
%                       wildcards (*) and will be used with dir() to find
%                       matching files. Files must match either
%                           mosaic_{:3d}_image_{:4d}*
%                       or
%                           mosaic_{:3d}_image_{:3d}*
%                       (leading zeros allowed).
%     Aline_length      Same as spectral2complex input.
%     Bline_length      Same as spectral2complex input.
%
%   Output
%     For each matching file, writes a NIfTI named
%       mosaic_{:3d}_image_{:4d}_complex.nii
%     in the same directory as the input file. The 3d component is padded to
%     3 digits and the 4d component is padded to 4 digits even if the input
%     used 3 digits.
%
%   Example:
%     spectral2complex_wildcard('/data/mosaic_*_image_*.nii', 500, 700);
%     spectral2complex_wildcard('mosaic_002_image_*.nii', 500, 700);

% Convert to char if it's a string
if isstring(wildcard_pattern)
    wildcard_pattern = char(wildcard_pattern);
end

if ~ischar(wildcard_pattern)
    error('wildcard_pattern must be a string or char array');
end

% Find all files matching the pattern
file_list = dir(wildcard_pattern);

if isempty(file_list)
    warning('No files found matching pattern: %s', wildcard_pattern);
    return;
end

% Extract full paths
filenames = cell(numel(file_list), 1);
valid_count = 0;

for i = 1:numel(file_list)
    % Skip directories
    if file_list(i).isdir
        continue;
    end
    
    % Build full path
    full_path = fullfile(file_list(i).folder, file_list(i).name);
    
    % Verify the filename matches the expected pattern
    [~, base_name, ~] = fileparts(full_path);
    tokens = regexp(base_name, '^mosaic_(\d{3})_image_(\d{3,4})', 'tokens', 'once');
    
    if ~isempty(tokens)
        valid_count = valid_count + 1;
        filenames{valid_count} = full_path;
    else
        warning('Skipping file "%s": does not match mosaic_{3d}_image_{3-4d}* pattern', full_path);
    end
end

% Trim to valid files only
filenames = filenames(1:valid_count);

if isempty(filenames)
    warning('No valid files found matching pattern: %s', wildcard_pattern);
    return;
end

fprintf('Found %d matching file(s) for pattern: %s\n', numel(filenames), wildcard_pattern);

% Ensure a pool exists so parfor can run.
if isempty(gcp('nocreate'))
    parpool;
end

parfor idx = 1:numel(filenames)
    fname = filenames{idx};
    try
        out_path = infer_output_path(fname);
        fprintf('Processing %s -> %s\n', fname, out_path);
        spectral2complex(fname, Aline_length, Bline_length, out_path);
    catch ME
        warning('Failed to process %s: %s', fname, ME.message);
    end
end

end

% -------------------------------------------------------------------------
function output_path = infer_output_path(filename)
% infer_output_path  Build output path based on mosaic/image numbering.
    [in_dir, base_name, ~] = fileparts(filename);

    % Expect patterns like mosaic_001_image_0001* or mosaic_001_image_001*
    tokens = regexp(base_name, '^mosaic_(\d{3})_image_(\d{3,4})', 'tokens', 'once');
    if isempty(tokens)
        error('Filename "%s" does not match mosaic_{3d}_image_{3-4d}* pattern', base_name);
    end

    mosaic_idx = str2double(tokens{1});
    image_idx  = str2double(tokens{2});

    % Always pad to 3 and 4 digits respectively.
    mosaic_str = sprintf('%03d', mosaic_idx);
    image_str  = sprintf('%04d', image_idx);

    out_name = sprintf('mosaic_%s_image_%s_complex.nii', mosaic_str, image_str);
    output_path = fullfile(in_dir, out_name);
end
