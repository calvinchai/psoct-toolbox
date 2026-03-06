function surf = findSurface(dBI3D, surfaceOpts)
%FINDSURFACE Resolve a surface specification into an nx-by-ny surface map.
%
%   surf = psoct.surface.findSurface(dBI3D, surfaceOpts)
%
%   dBI3D:
%       Intensity volume used by algorithmic methods (size nx-by-ny-by-nz).
%
%   Surface options (surfaceOpts.*):
%       surfaceOpts.Spec:
%           - numeric scalar integer : flat surface at that index
%           - string NIfTI path      : load X-by-Y map of 0-based z-indices
%           - other string           : treated as method name under psoct.surface.*
%       surfaceOpts.Args:
%           Optional cell array of positional arguments forwarded to
%           algorithmic surface methods when surfaceOpts.Spec is a method name.
%
    arguments
        dBI3D (:,:,:) {mustBeNumeric, mustBeNonempty}
        surfaceOpts.Spec = "gradient"
        surfaceOpts.Args cell = {}
    end

    surfaceSpec = surfaceOpts.Spec;
    surfaceArgs = surfaceOpts.Args;

    %#ok<*INUSD> nz reserved for future surface methods
    [nx, ny, nz] = size(dBI3D);
    % ---- Numeric flat surface ----
    if isnumeric(surfaceSpec) && isscalar(surfaceSpec) && mod(surfaceSpec, 1) == 0
        surf = psoct.surface.fromNumeric(surfaceSpec, nx, ny);
        return;
    end

    % ---- String-based specifications ----
    if ischar(surfaceSpec)
        surfaceSpec = string(surfaceSpec);
    end

    if isstring(surfaceSpec)
        if numel(surfaceSpec) ~= 1
            error('Surface specification must be a scalar string.');
        end

        methodStr = surfaceSpec;

        if endsWith(methodStr, [".nii", ".nii.gz"]) || isfile(methodStr)
            surf = psoct.surface.fromNifti(methodStr, nx, ny);

        % Otherwise treat as pluggable surface method name
        else
            methodName = char(methodStr);
            fqName = ['psoct.surface.' methodName];
            try
                surf = feval(fqName, dBI3D, surfaceArgs{:});
            catch ME
                if strcmp(ME.identifier, 'MATLAB:UndefinedFunction')
                    error('Unknown surface method "%s". Expected NIfTI path or name of a function in +psoct/+surface.', ...
                          methodName);
                else
                    rethrow(ME);
                end
            end
        end
    else
        error('Unsupported surface specification type: %s', class(surfaceSpec));
    end

    % Final shape validation to guard custom methods.
    if ~isequal(size(surf), [nx, ny])
        error('Surface size mismatch: expected %dx%d, got %s.', nx, ny, mat2str(size(surf)));
    end
end

