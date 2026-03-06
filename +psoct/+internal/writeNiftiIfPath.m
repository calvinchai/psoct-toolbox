function writeNiftiIfPath(pathStr, data, infoLike, options)
% psoct.internal.writeNiftiIfPath
% Write NIfTI if path is non-empty, with header/datatype fixups.
%
% options.Expand2DTo3D (logical, default false):
%   If true, 2D data is written as X-by-Y-by-1.

    arguments
        pathStr
        data
        infoLike
        options.Expand2DTo3D (1,1) logical = false
    end

    if strlength(string(pathStr)) == 0 || isempty(pathStr)
        return;
    end

    % NIfTI does not support logical values directly.
    if islogical(data)
        data = uint8(data);
    end

    if options.Expand2DTo3D && ismatrix(data)
        data = reshape(data, size(data, 1), size(data, 2), 1);
    end

    infoOut = infoLike;

    % Dimension fixups.
    sz = size(data);
    nDims = numel(sz);
    infoOut.ImageSize = sz;

    % PixelDimensions length must match nDims.
    if isfield(infoOut, "PixelDimensions")
        pd = infoOut.PixelDimensions;
        if numel(pd) < nDims
            pd(end+1:nDims) = 1;
        end
        if numel(pd) > nDims
            pd = pd(1:nDims);
        end
        infoOut.PixelDimensions = pd;
    end

    % Datatype/BitsPerPixel must match class(data).
    [dtype, bpp, dtcode] = class2niftiMeta(class(data));
    infoOut.Datatype = dtype;
    infoOut.BitsPerPixel = bpp;

    if ~isfield(infoOut, "Raw")
        infoOut.Raw = struct();
    end
    if ~isfield(infoOut.Raw, "dim")
        infoOut.Raw.dim = ones(1,8);
    end
    if ~isfield(infoOut.Raw, "pixdim")
        infoOut.Raw.pixdim = ones(1,8);
    end

    infoOut.Raw.dim(:) = 1;
    infoOut.Raw.dim(1) = nDims;
    infoOut.Raw.dim(2:1+numel(sz)) = sz;

    infoOut.Raw.pixdim(:) = 1;
    if isfield(infoOut, "PixelDimensions") && ~isempty(infoOut.PixelDimensions)
        infoOut.Raw.pixdim(2:1+numel(infoOut.PixelDimensions)) = infoOut.PixelDimensions;
    end

    infoOut.Raw.datatype = dtcode;
    infoOut.Raw.bitpix = bpp;

    isgz = endsWith(string(pathStr), ".nii.gz");
    niftiwrite(data, pathStr, infoOut, "Compressed", isgz);
end

function [dtype, bpp, dtcode] = class2niftiMeta(cls)
    switch cls
        case "uint8",   dtype = "uint8";   bpp = 8;  dtcode = 2;
        case "int16",   dtype = "int16";   bpp = 16; dtcode = 4;
        case "int32",   dtype = "int32";   bpp = 32; dtcode = 8;
        case "single",  dtype = "single";  bpp = 32; dtcode = 16;
        case "double",  dtype = "double";  bpp = 64; dtcode = 64;
        case "int8",    dtype = "int8";    bpp = 8;  dtcode = 256;
        case "uint16",  dtype = "uint16";  bpp = 16; dtcode = 512;
        case "uint32",  dtype = "uint32";  bpp = 32; dtcode = 768;
        case "int64",   dtype = "int64";   bpp = 64; dtcode = 1024;
        case "uint64",  dtype = "uint64";  bpp = 64; dtcode = 1280;
        otherwise
            error("psoct.internal.writeNiftiIfPath:UnsupportedClass", ...
                "Unsupported data class for NIfTI: %s", cls);
    end
end
