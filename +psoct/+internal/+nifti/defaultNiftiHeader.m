function infoOut = defaultNiftiHeader(infoIn, imageSize, pixelDimensions)
% psoct.internal.nifti.defaultNiftiHeader
% Return infoIn when provided, otherwise a minimal default NIfTI header.
%
% Inputs:
%   infoIn          : NIfTI-info-like struct (empty struct triggers default).
%   imageSize       : image size for the default header.
%   pixelDimensions : voxel size for the default header.

arguments
    infoIn struct = struct()
    imageSize {mustBeNumeric, mustBeNonempty}
    pixelDimensions {mustBeNumeric, mustBeNonempty}
end

if isempty(fieldnames(infoIn))
    infoOut = struct();
    infoOut.ImageSize = imageSize;
    infoOut.PixelDimensions = pixelDimensions;
else
    infoOut = infoIn;
end
end
