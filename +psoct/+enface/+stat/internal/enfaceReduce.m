function enfaceMap = enfaceReduce(vol, reducer, surfaceMap, enfaceOffset, enfaceDepth)
%ENFACEREDUCE Shared core for en face projections with a custom reducer.
%
%   enfaceMap = psoct.enface.stat.internal.enfaceReduce( ...
%       vol, reducer, surfaceMap, enfaceOffset, enfaceDepth)
%
%   This internal helper validates common inputs, applies default values,
%   and loops over (x, y) positions to extract an axial window starting
%   from surfaceMap(x, y) plus an optional offset and extending over a
%   specified depth. For each (x, y) location, the provided reducer
%   function handle is applied to the vector of values along z to produce a
%   single scalar output.
%
%   reducer must be a function handle of the form:
%
%       s = reducer(vals)
%
%   where vals is a column vector of values along the axial dimension.

arguments
    vol (:,:,:) {mustBeReal, mustBeNonempty}
    reducer (1,1) function_handle
    surfaceMap (:,:) {mustBeReal, mustBeNonempty}
    enfaceOffset (1,1) {mustBeReal, mustBeFinite} = 0
    enfaceDepth (1,1) {mustBeReal, mustBeFinite, mustBePositive} = 70
end

[nx, ny, nz] = size(vol);

if ~isequal(size(surfaceMap), [nx, ny])
    error('psoct:enfaceReduce:surfaceSizeMismatch', ...
        'surfaceMap must be size [%d %d] to match the lateral dimensions of vol.', nx, ny);
end

enfaceMap = zeros(nx, ny, 'single');
for x = 1:nx
    for y = 1:ny
        z1 = max(1, surfaceMap(x, y) + enfaceOffset);
        z2 = min(nz, z1 + enfaceDepth);
        vals = squeeze(vol(x, y, z1:z2));
        enfaceMap(x, y) = reducer(vals);
    end
end
end


