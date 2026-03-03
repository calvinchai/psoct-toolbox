function surf = fromNifti(pathStr, nx, ny)
%FROMNIFTI Load a surface map from a NIfTI file and validate its size.
%
%   surf = psoct.surface.fromNifti(pathStr, nx, ny)

    if isstring(pathStr)
        if numel(pathStr) ~= 1
            error('NIfTI surface path must be a scalar string.');
        end
        pathStr = char(pathStr);
    elseif ~ischar(pathStr)
        error('NIfTI surface path must be a character vector or string scalar.');
    end

    surf = single(niftiread(pathStr));  % expected X × Y of 0-based z-indices
    if ~isequal(size(surf), [nx, ny])
        error('Surface size mismatch: expected %dx%d, got %s.', nx, ny, mat2str(size(surf)));
    end
end

