function infoLike = shrinkNiftiHeader(V, infoIn, pixelDimensions, enfaceVolumeOpts)
% psoct.internal.nifti.shrinkNiftiHeader
% Create an info-like NIfTI header whose ImageSize / PixelDimensions
% are compatible with the data V, with special handling for 2D
% (optionally channelized) images that may be written as 3D.
%
% enfaceVolumeOpts is mainly used when the input is a 2D image
% or a 2D image with a channel dimension; in that case, when
% Expand2DTo3D is true we insert a singleton dimension at index 3
% and set PixelDimensions(3) based on SliceThicknessUm.

    arguments
        V (:,:,:) {mustBeNumeric, mustBeNonempty}
        infoIn struct = struct()
        pixelDimensions (1,:) {mustBeNumeric, mustBeNonempty} = [10 10 2.5]
        enfaceVolumeOpts.Expand2DTo3D (1,1) logical = false
        enfaceVolumeOpts.SliceThicknessUm (1,1) {mustBeNumeric, mustBeFinite} = 500
        enfaceVolumeOpts.channelDimension (1,1) logical = false
    end

    % If no template header is provided, fall back to a minimal default.
    if isempty(fieldnames(infoIn))
        infoLike = psoct.internal.nifti.defaultNiftiHeader(size(V), pixelDimensions, infoIn);
    else
        infoLike = infoIn;
    end
    % convert um to mm 
    pixelDimensions = pixelDimensions / 1000;
    
    fullSize = size(V);
    nDimsFull = ndims(V);
    hasChannel = enfaceVolumeOpts.channelDimension && nDimsFull > 2;
    nImageDims = nDimsFull - double(hasChannel);

    if nImageDims < 2
        error("psoct.internal.nifti.shrinkNiftiHeader:BadInputDims", ...
            "Input data must have at least two spatial dimensions.");
    end

    if nImageDims >= 3
        infoLike.ImageSize = size(V);
        infoLike.PixelDimensions = pixelDimensions;

        % fill in the missing dimensions with 1
        if numel(infoLike.PixelDimensions) < nImageDims
            infoLike.PixelDimensions(numel(infoLike.PixelDimensions)+1:nImageDims) = 1;
        end
        if numel(infoLike.ImageSize) < nImageDims
            infoLike.ImageSize(numel(infoLike.ImageSize)+1:nImageDims) = 1;
        end
        return;
    end

    % 2D case
    infoLike.ImageSize = [fullSize(1:2), 1];
    infoLike.PixelDimensions = pixelDimensions(1:2);
    if channelDimension
        infoLike.ImageSize(4) = fullSize(3);
        infoLike.PixelDimensions(4) = 1;
    end
    return;
end