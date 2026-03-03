function surf = fromNumeric(surfaceVal, nx, ny)
%FROMNUMERIC Create a flat surface map from a numeric specification.
%
%   surf = psoct.surface.fromNumeric(surfaceVal, nx, ny)

    if ~(isnumeric(surfaceVal) && isscalar(surfaceVal) && mod(surfaceVal, 1) == 0)
        error('Numeric surface specification must be a scalar integer.');
    end

    surf = surfaceVal * ones(nx, ny, 'like', surfaceVal);
end

