function prefix = buildProcessedOutputPrefix(mosaicId, tileIndex)
%BUILDPROCESSEDOUTPUTPREFIX Stem for per-tile processed NIfTI outputs.
%
%   prefix = buildProcessedOutputPrefix(mosaicId, tileIndex)
%
%   Returns the basename stem ``mosaic_{id:03d}_image_{tile:04d}`` (no extension),
%   matching Fiji / Opticstream naming (see ``mosaic_prefix`` and
%   ``processed_output_prefix`` in ``opticstream.flows.psoct.utils``).
%
%   Example
%     >> buildProcessedOutputPrefix(1, 3)
%     ans =
%       "mosaic_001_image_0003"

arguments
    mosaicId (1,1) double {mustBeInteger, mustBeNonnegative}
    tileIndex (1,1) double {mustBeInteger, mustBeNonnegative}
end

prefix = string(sprintf("mosaic_%03d_image_%04d", mosaicId, tileIndex));

end
