function enfaceMap = enfaceMedian(vol, surfaceMap, enfaceOffset, enfaceDepth)
%ENFACEMEDIAN Compute an en face median projection from a 3-D volume.
%
%   enfaceMap = psoct.enface.stat.enfaceMedian(vol, surfaceMap)
%   enfaceMap = psoct.enface.stat.enfaceMedian(vol, surfaceMap, enfaceOffset, enfaceDepth)
%
%   Computes, for each (x, y) location, the median intensity over an axial
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
%                  which to compute the median. Must be > 0. Default: 70.
%
%   Output
%   ------
%   enfaceMap    - 2‑D single-precision en face median map of size [nx, ny].
%
%   Notes
%   -----
%   NaN values within the axial window are ignored when computing the median.

narginchk(2, 4);
enfaceMap = enfaceReduce( ...
    vol, @(vals) median(vals, 'omitnan'), surfaceMap, enfaceOffset, enfaceDepth);
end

