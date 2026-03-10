function infoOut = defaultNiftiHeader(imageSize, pixelDimensions, infoIn)
% psoct.internal.nifti.defaultNiftiHeader
% Return infoIn when provided, otherwise a minimal default NIfTI header.
%
% Inputs:
%   imageSize       : image size for the default header.    (required)
%   pixelDimensions : voxel size for the default header.    (optional)
%   infoIn          : NIfTI-info-like struct (empty struct triggers default). (optional)

arguments
    imageSize {mustBeNumeric, mustBeNonempty}
    pixelDimensions {mustBeNumeric, mustBeNonempty} = [0.01 0.01 0.0025]
    infoIn struct = struct()
end

if isempty(fieldnames(infoIn))
    infoOut = images.internal.nifti.niftiImage(images.internal.nifti.niftiImage.niftiDefaultHeader([],'Version','NIfTI1')).simplifyStruct();
    infoOut.ImageSize = imageSize;
    infoOut.PixelDimensions = pixelDimensions;
else
    infoOut = infoIn;
end
end
