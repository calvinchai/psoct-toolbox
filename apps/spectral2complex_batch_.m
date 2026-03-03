function spectral2complex_batch_(filenames, Aline_length, Bline_length)
% spectral2complex_batch  Wrapper to run spectral2complex on many files in parallel.
%
%   spectral2complex_batch(filenames, Aline_length, Bline_length)
%
%   Input
%     filenames     Cell array or string array of input spectral files. Each
%                   filename must match either
%                       mosaic_{:3d}_image_{:4d}*
%                   or
%                       mosaic_{:3d}_image_{:3d}*
%                   (leading zeros allowed).
%     Aline_length  Same as spectral2complex input.
%     Bline_length  Same as spectral2complex input.
%
%   Output
%     For each input file, writes a NIfTI named
%       mosaic_{:3d}_image_{:4d}_complex.nii
%     in the same directory as the input file. The 3d component is padded to
%     3 digits and the 4d component is padded to 4 digits even if the input
%     used 3 digits.
%
%   Example:
%     spectral2complex_batch({'/data/mosaic_002_image_003.nii', ...
%                              '/data/mosaic_002_image_0012.nii'}, 500, 700);
%

filenames = normalize_filenames(filenames);

% Ensure a pool exists so parfor can run.
if isempty(gcp('nocreate'))
    parpool(16);
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

