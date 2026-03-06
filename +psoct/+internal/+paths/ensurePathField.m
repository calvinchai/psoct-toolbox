function paths = ensurePathField(paths, fieldName, defaultValue)
% psoct.internal.paths.ensurePathField
% Ensure a struct field exists and has a non-empty path-like value.
%
% If paths.(fieldName) is missing or empty, assign defaultValue.
% defaultValue defaults to "".

arguments
    paths struct
    fieldName
    defaultValue = ""
end

fieldName = char(string(fieldName));
if ~isfield(paths, fieldName) || strlength(string(paths.(fieldName))) == 0
    paths.(fieldName) = string(defaultValue);
end
end
