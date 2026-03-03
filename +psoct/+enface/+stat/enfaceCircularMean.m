function oriMap = enfaceCircularMean(O3D_deg, surfaceMap, enfaceOffset, enfaceDepth)
%ENFACECIRCULARMEAN Circular mean of 180°-periodic orientations along depth.
%
%   oriMap = psoct.enface.stat.enfaceCircularMean(O3D, surf, stopIdx)
%
%   For each (x, y) position, this computes the circular mean of
%   180°-periodic orientation angles along the axial (z) dimension between
%   the indices given by surf(x,y) and stopIdx(x,y), using the doubled-angle
%   trick:
%
%       mean_angle = 0.5 * atan2(sum(sin(2*theta)), sum(cos(2*theta)))
%
%   Inputs
%   ------
%   O3D_deg      - 3-D numeric array of orientations in degrees, size [nx, ny, nz].
%   surfaceMap   - 2-D numeric array [nx, ny] giving start index along z.
%   enfaceOffset - (optional) scalar numeric offset in voxels added to
%                  surfaceMap before integration. Default: 0.
%   enfaceDepth  - (optional) positive scalar numeric depth in voxels over
%                  which to compute the circular mean. Must be > 0. Default: 70.
%
%   Output
%   ------
%   oriMap   - 2-D single-precision en face orientation map [nx, ny] in degrees.

reducer = @(valsDeg) single( ...
    0.5 * atan2( ...
    sum(sin(2 * deg2rad(valsDeg))), ...
    sum(cos(2 * deg2rad(valsDeg)))) ...
    / pi * 180);

oriMap = enfaceReduce( ...
    O3D_deg, reducer, surfaceMap, enfaceOffset, enfaceDepth);
end

