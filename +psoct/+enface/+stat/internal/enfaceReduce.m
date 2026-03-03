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

narginchk(3, 5);

if nargin < 3 || isempty(enfaceOffset)
    enfaceOffset = 0;
end

if nargin < 4 || isempty(enfaceDepth)
    enfaceDepth = 70;
end

% ----- Validate volume -----
validateattributes(vol, {'numeric'}, {'real', 'nonempty'}, ...
    mfilename, 'vol', 1);
if ndims(vol) ~= 3
    error('vol must be a real numeric 3-D array.');
end
[nx, ny, nz] = size(vol);

validateattributes(surfaceMap, {'numeric'}, ...
    {'real', 'size', [nx, ny]}, mfilename, 'surfaceMap', 2);
validateattributes(enfaceOffset, {'numeric'}, ...
    {'scalar', 'real', 'finite'}, mfilename, 'enfaceOffset', 3);
validateattributes(enfaceDepth, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>', 0}, mfilename, 'enfaceDepth', 4);

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


