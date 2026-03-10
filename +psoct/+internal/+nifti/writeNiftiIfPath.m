function future = writeNiftiIfPath(pathStr, data, infoLike, options)
% psoct.internal.nifti.writeNiftiIfPath
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

    if strlength(pathStr) == 0 || isempty(pathStr)
        future =[]; 
        return; 
    end
    % ---- Normalize class (NIfTI has no logical) ----
    if islogical(data)
        data = uint8(data);  % 0/1
    end
    % ---- Build output header from input ----
    infoOut = infoLike;
    % Dimension fixups
    sz    = size(data);
    nDims = ndims(data);
    infoOut.ImageSize = sz;
    % PixelDimensions length must match dims
    if isfield(infoOut, 'PixelDimensions')
        pd = infoOut.PixelDimensions;
        if numel(pd) < nDims, pd(end+1:nDims) = 1; end
        if numel(pd) > nDims, pd = pd(1:nDims); end
        infoOut.PixelDimensions = pd;
    end
    % ---- Datatype/BitsPerPixel must match class(data) ----
    [dtype, bpp] = class2niftiMeta(class(data));
    infoOut.Datatype     = dtype;
    infoOut.BitsPerPixel = bpp;
    infoOut.Description = '';
    isgz = endsWith(string(pathStr), ".nii.gz");
    pool = [];
    if exist("gcp", "file") == 2
        pool = gcp("nocreate");
    end

    if isempty(pool)
        localWriteNifti(data, pathStr, infoOut, isgz);
        future = [];
    else
        future = parfeval(pool, @localWriteNifti, 0, data, pathStr, infoOut, isgz);
    end
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
            error("psoct.internal.nifti.writeNiftiIfPath:UnsupportedClass", ...
                "Unsupported data class for NIfTI: %s", cls);
    end
end

function localWriteNifti(data, pathStr, infoOut, isgz)
    niftiwrite(data, pathStr, infoOut, "Compressed", isgz);
end
