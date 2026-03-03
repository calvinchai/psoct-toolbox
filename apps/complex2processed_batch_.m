function complex2processed_batch_(filenames, output_dir, surface, depth, zSize, wavelength, oriMethod, birefMethod)
% complex2processed_batch  Wrapper to run complex2processed on many files in parallel.
%
%   complex2processed_batch(filenames, surface, depth, zSize, wavelength, oriMethod, birefMethod)
%
%   Input
%     filenames     Cell array or string array of input complex NIfTI files. Each
%                   filename must match the pattern:
%                       mosaic_{:3d}_image_{:4d}_complex.nii
%                   (or .nii.gz)
%     surface       Same as complex2processed input (string path, "find", or numeric).
%     depth         Same as complex2processed input (scalar nonneg int).
%     zSize         Same as complex2processed input (scalar >0, micrometers).
%     wavelength    Same as complex2processed input (string, micrometers).
%     oriMethod     Same as complex2processed input (string, e.g., "new" or "").
%     birefMethod   Same as complex2processed input (string, e.g., "new", "diff", etc.).
%
%   Output
%     For each input file, writes outputs with prefix derived from input filename.
%     Input:  mosaic_001_image_0001_complex.nii
%     Prefix: mosaic_001_image_0001
%     Outputs: mosaic_001_image_0001_dBI.nii, mosaic_001_image_0001_R3D.nii, etc.
%
%   Example:
%     complex2processed_batch({'/data/mosaic_002_image_0003_complex.nii', ...
%                              '/data/mosaic_002_image_0012_complex.nii'}, ...
%                             "find", 100, 3.3, "1.3", "new", "new");

filenames = normalize_filenames(filenames);

% Ensure a pool exists so parfor can run.
if isempty(gcp('nocreate'))
    parpool(16);
end

parfor idx = 1:numel(filenames)
    fname = filenames{idx};
    try
        output_prefix = fullfile(output_dir,infer_output_prefix(fname));
        fprintf('Processing %s -> prefix: %s\n', fname, output_prefix);
        complex2processed(fname, output_prefix, surface, depth, zSize, wavelength, oriMethod, birefMethod);
    catch ME
        warning('Failed to process %s: %s', fname, ME.message);
    end
end

end

% -------------------------------------------------------------------------
function output_prefix = infer_output_prefix(filename)
% infer_output_prefix  Extract output prefix from complex filename.
%
% Input:  mosaic_001_image_0001_complex.nii
% Output: /path/to/mosaic_001_image_0001
    [in_dir, base_name, ~] = fileparts(filename);
    
    % Remove .gz if present (fileparts may not handle it)
    if endsWith(base_name, '.gz', 'IgnoreCase', true)
        base_name = base_name(1:end-3);
    end
    
    % Expect pattern: mosaic_XXX_image_XXXX_complex
    % Remove the _complex suffix
    if endsWith(base_name, '_complex', 'IgnoreCase', true)
        prefix_name = base_name(1:end-8);  % Remove '_complex'
    else
        % If no _complex suffix, try to extract mosaic_XXX_image_XXXX pattern
        tokens = regexp(base_name, '^(mosaic_\d{3}_image_\d{4})', 'tokens', 'once');
        if isempty(tokens)
            error('Filename "%s" does not match mosaic_{3d}_image_{4d}_complex.nii pattern', base_name);
        end
        prefix_name = tokens{1};
    end
    
    % Verify the prefix matches the expected pattern
    tokens = regexp(prefix_name, '^mosaic_(\d{3})_image_(\d{4})', 'tokens', 'once');
    if isempty(tokens)
        error('Could not extract valid mosaic/image pattern from "%s"', base_name);
    end
    
    output_prefix =  prefix_name;
end

% -------------------------------------------------------------------------
function out = normalize_filenames(filenames)
% normalize_filenames  Accept cell/strings or comma/space separated char arrays.
%
% Handles deployed apps where inputs arrive as a single char vector.
    if isstring(filenames)
        out = cellstr(filenames);
        return;
    end

    if ischar(filenames)
        % Split on commas or whitespace, drop empties.
        parts = regexp(filenames, '[,\s]+', 'split');
        parts = parts(~cellfun(@isempty, parts));
        out = parts;
        return;
    end

    if iscell(filenames)
        out = filenames;
        return;
    end

    error('filenames must be a cell array, string array, or char array');
end

