function opts = loadOptsWithDefaults(optsMatFile, varNames, idPrefix)
%LOADOPTSWITHDEFAULTS Load option structs from a .mat file with fallbacks.
%
%   opts = psoct.internal.opts.loadOptsWithDefaults(optsMatFile, varNames, idPrefix)
%
%   - Verifies that OPTSMATFILE exists; otherwise throws an error with ID
%     "<idPrefix>:OptsFileNotFound".
%   - Loads the requested variable names from the .mat file.
%   - For each requested name:
%       * If present and non-empty in the file, returns the value.
%       * Otherwise, returns struct() and emits a warning with ID
%         "<idPrefix>:Missing<VarName>", e.g. MissingSpectralOpts.
%
%   The return value OPTS is a struct-of-structs with one field per
%   requested variable name.

arguments
    optsMatFile (1,1) string
    varNames (1,:) string
    idPrefix (1,1) string
end

if ~isfile(optsMatFile)
    error(idPrefix + ":OptsFileNotFound", ...
        'Opts .mat file not found: "%s".', optsMatFile);
end

S = load(optsMatFile, varNames{:});

opts = struct();
for k = 1:numel(varNames)
    nameStr = varNames(k);
    nameChar = char(nameStr);

    hasField = isfield(S, nameChar);
    if hasField && ~isempty(S.(nameChar))
        opts.(nameChar) = S.(nameChar);
    else
        warnId = idPrefix + ":Missing" + upperFirst(nameStr);
        warning(warnId, ...
            'Variable `%s` not found or empty in "%s". Using empty struct.', ...
            nameChar, optsMatFile);
        opts.(nameChar) = struct();
    end
end

end

function out = upperFirst(str)
%UPPERFIRST Upper-case the first character of a string.

str = char(str);
if isempty(str)
    out = string(str);
    return;
end

str(1) = upper(str(1));
out = string(str);

end

