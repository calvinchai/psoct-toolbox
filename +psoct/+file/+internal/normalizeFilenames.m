function files = normalizeFilenames(filenames)
%NORMALIZEFILENAMES Normalize filenames to a cell array of char vectors.
%
%   files = psoct.file.internal.normalizeFilenames(filenames)
%
%   Accepts string arrays, character arrays (optionally comma/space
%   separated), or cell arrays of character vectors/strings and returns
%   a cell array of character vectors suitable for use in batch wrappers.

if isstring(filenames)
    files = cellstr(filenames);
    return;
end

if ischar(filenames)
    parts = regexp(filenames, "[,\s]+", "split");
    parts = parts(~cellfun(@isempty, parts));
    files = parts;
    return;
end

if iscell(filenames)
    files = filenames;
    return;
end

error("psoct:file:internal:normalizeFilenames:BadFilenamesType", ...
    "filenames must be a cell array, string array, or char array.");

end

