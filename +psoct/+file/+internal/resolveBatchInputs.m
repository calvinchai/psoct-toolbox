function files = resolveBatchInputs(inputPatternOrFolder, folderFilePatterns, errorIdPrefix, expectedDescription)
%RESOLVEBATCHINPUTS Expand a folder/glob/single path into a list of files.
%
%   files = psoct.file.internal.resolveBatchInputs( ...
%       inputPatternOrFolder, folderFilePatterns, errorIdPrefix, expectedDescription)
%
%   This helper normalizes a user-supplied folder, glob pattern, or single
%   filename into a cell array of full-path filenames suitable for passing
%   into the existing *_batch wrappers.
%
%   Input
%     inputPatternOrFolder : String/char path that can be:
%                           - A folder path.
%                           - A glob pattern (contains '*' or '?').
%                           - A single filename.
%     folderFilePatterns   : Cell array or string array of file patterns
%                           (e.g. ["*_complex.nii","*_complex.nii.gz"])
%                           used when inputPatternOrFolder is a folder.
%     errorIdPrefix        : Prefix for error identifiers, e.g.
%                           "psoct:file:complex2processed_folder".
%     expectedDescription  : Human-readable description of expected files,
%                           used in error messages.
%
%   Output
%     files : Cell array of character vectors, each a full-path filename.

arguments
    inputPatternOrFolder {mustBeTextScalar}
    folderFilePatterns
    errorIdPrefix {mustBeTextScalar}
    expectedDescription {mustBeTextScalar}
end

inp = string(inputPatternOrFolder);
folderFilePatterns = string(folderFilePatterns);
errorIdPrefix = char(errorIdPrefix);
expectedDescription = char(expectedDescription);

% Decide how to interpret the input.
if isfolder(inp)
    % Folder: build non-recursive patterns inside this folder.
    patterns = fullfile(inp, folderFilePatterns);
elseif contains(inp, ["*", "?"])
    % Glob pattern: use as-is.
    patterns = inp;
else
    % Single path: if it exists as a file, return it directly.
    if isfile(inp)
        files = {char(inp)};
        return;
    end

    % If it's not a file or folder and has no glob chars, treat as missing.
    errorId = sprintf("%s:InputNotFound", errorIdPrefix);
    error(errorId, ...
        "Input ""%s"" is not an existing file or folder for %s.", ...
        inp, expectedDescription);
end

% Expand patterns via dir and collect files.
if ~iscell(patterns)
    patterns = cellstr(patterns);
end

fileSet = {};
for i = 1:numel(patterns)
    pat = patterns{i};
    d = dir(pat);
    if isempty(d)
        continue;
    end

    % Keep only regular files.
    isFile = ~[d.isdir];
    d = d(isFile);

    if isempty(d)
        continue;
    end

    fullPaths = fullfile({d.folder}, {d.name});
    fileSet = [fileSet, fullPaths]; %#ok<AGROW>
end

% De-duplicate while preserving order.
if isempty(fileSet)
    errorId = sprintf("%s:NoFilesFound", errorIdPrefix);
    error(errorId, ...
        "No %s files found for input ""%s"".", expectedDescription, inp);
end

% unique with 'stable' requires a vector; wrap in string to preserve order.
files = cellstr(unique(string(fileSet), "stable"));

end

