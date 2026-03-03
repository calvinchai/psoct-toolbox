function enfaceMap = enfaceMean(vol, surfaceMap, enfaceOffset, enfaceDepth)
%ENFACEMEAN Compute an en face mean projection from a 3-D volume.
%
%   enfaceMap = psoct.enface.stat.enfaceMean(vol, surfaceMap)
%   enfaceMap = psoct.enface.stat.enfaceMean(vol, surfaceMap, enfaceOffset, enfaceDepth)
%
%   Computes, for each (x, y) location, the mean intensity over an axial
%   window of the input volume starting from a surface map location plus an
%   optional offset and extending over a specified depth.
%
%   Inputs
%   ------
%   vol          - 3‑D numeric volume of size [nx, ny, nz].
%   surfaceMap   - 2‑D numeric array of size [nx, ny] giving the starting
%                  axial index for each (x, y) position.
%   enfaceOffset - (optional) scalar numeric offset in voxels added to
%                  surfaceMap before integration. Default: 0.
%   enfaceDepth  - (optional) positive scalar numeric depth in voxels over
%                  which to compute the mean. Must be > 0. Default: 70.
%
%   Output
%   ------
%   enfaceMap    - 2‑D single-precision en face mean map of size [nx, ny].
%
%   Notes
%   -----
%   NaN values within the axial window are ignored when computing the mean.

narginchk(2, 4);
enfaceMap = psoct.enface.stat.internal.enfaceReduce( ...
    vol, @(vals) mean(vals, 'omitnan'), surfaceMap, enfaceOffset, enfaceDepth);
end