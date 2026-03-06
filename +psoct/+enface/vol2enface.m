function out = vol2enface(dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm, opts)
% psoct.enface.vol2enface
% Compute enface modalities from reconstructed 3D volumes and optionally
% write each modality to disk.
%
%   out = psoct.enface.vol2enface(dBI3D_vol, R3D_vol, O3D_vol, surf, ...
%       enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm)
%
% Inputs
%   dBI3D_vol, R3D_vol, O3D_vol : 3D reconstructed volumes (X x Y x Z).
%   surf                        : 2D surface map (X x Y), z-index per A-line.
%   enfaceOffset                : offset below surface for the enface window. Default 0.
%   enfaceDepth                 : depth of enface window. Default 70.
%   zSizeUm                     : axial pixel size in micrometers.
%   wavelengthUm                : wavelength in micrometers (for biref methods).
%
% Name-value options (opts.*)
%   opts.OriMethod    : "circularMean" (default) or legacy fallback.
%   opts.BirefMethod  : "legacy"(default),"fft","unwrap_old","unwrap_new","exp","".
%   opts.Paths        : struct paths with fields: aip,mip,ret,ori,biref.
%                       Non-empty paths trigger writing for computed outputs.
%   opts.Compute      : struct booleans with fields: aip,mip,ret,ori,biref.
%                       Missing fields default to true.
%   opts.InfoLike     : optional NIfTI-info-like struct used as write template.
%   opts.Save2DAs3D   : if true, write 2D outputs as X-by-Y-by-1 NIfTI.
%   opts.SliceThicknessUm : slice thickness (um) used as PixelDimensions(3)
%                       when Save2DAs3D is true. Default 500.
%
% Output
%   out.aip/out.mip/out.ret/out.ori/out.biref : computed maps (or []).
%   out.paths                                 : resolved per-modality paths.
%   out.compute                               : resolved per-modality flags.
%
% Notes
%   - Compute and write are independent: a modality can be computed without writing.
%   - Writing occurs only when Compute.<modality> is true and Paths.<modality> is non-empty.

arguments
    dBI3D_vol (:,:,:) {mustBeNumeric, mustBeNonempty}
    R3D_vol (:,:,:) {mustBeNumeric, mustBeNonempty}
    O3D_vol (:,:,:) {mustBeNumeric, mustBeNonempty}
    surf (:,:) {mustBeNumeric, mustBeNonempty}
    enfaceOffset (1,1) {mustBeNumeric, mustBeFinite} = 0
    enfaceDepth (1,1) {mustBeNumeric, mustBeFinite} = 70
    zSizeUm (1,1) {mustBeNumeric, mustBeFinite} = 2.5
    wavelengthUm (1,1) {mustBeNumeric, mustBeFinite} = 0.0013
    opts.OriMethod = "circularMean"
    opts.BirefMethod = "legacy"
    opts.Paths struct = struct()
    opts.Compute struct = struct()
    opts.InfoLike struct = struct()
    opts.Save2DAs3D (1,1) logical = false
    opts.SliceThicknessUm (1,1) {mustBeNumeric, mustBeFinite} = 500
end

[nx, ny, nz] = size(dBI3D_vol);
if ~isequal(size(R3D_vol), [nx ny nz]) || ~isequal(size(O3D_vol), [nx ny nz])
    error("psoct.enface.vol2enface:VolumeSizeMismatch", ...
        "dBI3D, R3D, and O3D must have identical size [nx ny nz].");
end
if ~isequal(size(surf), [nx ny])
    error("psoct.enface.vol2enface:SurfaceSizeMismatch", ...
        "surf must have size [%d %d] to match volume lateral dimensions.", nx, ny);
end

% Clamp surface indices for downstream window-based operations.
surf = max(1, min(nz, round(surf)));

modalities = ["aip", "mip", "ret", "ori", "biref"];
paths = opts.Paths;
compute = opts.Compute;
for k = 1:numel(modalities)
    fieldName = modalities(k);
    paths = psoct.internal.paths.ensurePathField(paths, fieldName);
    compute = ensureComputeField(compute, fieldName);
end

infoIn = psoct.internal.nifti.defaultNiftiHeader( ...
    opts.InfoLike, size(dBI3D_vol), [0.01 0.01 zSizeUm/1000]);
info2D = shrinkHeader(infoIn, opts.Save2DAs3D, opts.SliceThicknessUm);
writeOpts = struct("Expand2DTo3D", opts.Save2DAs3D);

out = struct();
out.aip = [];
out.mip = [];
out.ret = [];
out.ori = [];
out.biref = [];
writeFutures = {};

if compute.aip
    out.aip = psoct.enface.stat.enfaceMean(dBI3D_vol, surf, enfaceOffset, enfaceDepth);
    writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
        psoct.internal.nifti.writeNiftiIfPath(paths.aip, out.aip, info2D, writeOpts));
end

if compute.mip
    out.mip = psoct.enface.stat.enfaceMax(dBI3D_vol, surf, enfaceOffset, enfaceDepth);
    writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
        psoct.internal.nifti.writeNiftiIfPath(paths.mip, out.mip, info2D, writeOpts));
end

if compute.ret
    out.ret = psoct.enface.stat.enfaceMean(R3D_vol, surf, enfaceOffset, enfaceDepth);
    writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
        psoct.internal.nifti.writeNiftiIfPath(paths.ret, out.ret, info2D, writeOpts));
end

if compute.ori
    oriMethod = string(opts.OriMethod);
    if oriMethod == "circularMean"
        out.ori = psoct.enface.stat.enfaceCircularMean(O3D_vol, surf, enfaceOffset, enfaceDepth);
    else
        out.ori = psoct.enface.stat.enfaceMean(O3D_vol, surf, enfaceOffset, enfaceDepth);
    end
    writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
        psoct.internal.nifti.writeNiftiIfPath(paths.ori, out.ori, info2D, writeOpts));
end

if compute.biref
    if ~(isscalar(zSizeUm) && zSizeUm > 0)
        error("psoct.enface.vol2enface:BadZSize", ...
            "zSizeUm must be provided and > 0 (micrometers) to compute biref.");
    end
    if ~(isscalar(wavelengthUm) && wavelengthUm > 0)
        error("psoct.enface.vol2enface:BadLambda", ...
            "wavelengthUm must be provided and > 0 (micrometers) to compute biref.");
    end

    birefMethod = string(opts.BirefMethod);
    switch birefMethod
        case {"legacy",""}
            out.biref = psoct.enface.biref.fitLinear(R3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        case "fft"
            out.biref = psoct.enface.biref.fftLinear(R3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        case "unwrap_old"
            out.biref = psoct.enface.biref.unwrapOld(dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        case "unwrap_new"
            out.biref = psoct.enface.biref.unwrapNew(dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        case "exp"
            out.biref = psoct.enface.biref.unwrapExp(dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        otherwise
            error("psoct.enface.vol2enface:UnknownBirefMethod", ...
                "Unknown birefMethod ""%s"".", birefMethod);
    end
    writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
        psoct.internal.nifti.writeNiftiIfPath(paths.biref, out.biref, info2D, writeOpts));
end

psoct.internal.nifti.waitWriteFutures(writeFutures);

out.paths = paths;
out.compute = compute;

end

function compute = ensureComputeField(compute, fieldName)
if ~isfield(compute, fieldName) || isempty(compute.(fieldName))
    compute.(fieldName) = true;
else
    compute.(fieldName) = logical(compute.(fieldName));
end
end

function info2 = shrinkHeader(infoIn, expand2DTo3D, sliceThicknessUm)
info2 = infoIn;
imgSize = infoIn.ImageSize;
if numel(imgSize) < 2
    error("psoct.enface.vol2enface:BadInfoLike", ...
        "InfoLike.ImageSize must contain at least two dimensions.");
end

if expand2DTo3D
    info2.ImageSize = [imgSize(1:2), 1];
else
    info2.ImageSize = imgSize(1:2);
end

if isfield(info2, "PixelDimensions") && numel(info2.PixelDimensions) >= 2
    pd = info2.PixelDimensions(1:2);
else
    pd = [1 1];
end
if expand2DTo3D
    pd(3) = sliceThicknessUm / 1000;
end
info2.PixelDimensions = pd;

if isfield(info2, "Raw") && isfield(info2.Raw, "dim")
    if expand2DTo3D
        info2.Raw.dim(1) = 3;
        info2.Raw.dim(2) = imgSize(1);
        info2.Raw.dim(3) = imgSize(2);
        info2.Raw.dim(4) = 1;
    else
        info2.Raw.dim(1) = 2;
        info2.Raw.dim(2) = imgSize(1);
        info2.Raw.dim(3) = imgSize(2);
        info2.Raw.dim(4) = 1;
    end
    if isfield(info2.Raw, "pixdim")
        info2.Raw.pixdim(1) = 1;
        info2.Raw.pixdim(2) = info2.PixelDimensions(1);
        info2.Raw.pixdim(3) = info2.PixelDimensions(2);
        if expand2DTo3D
            info2.Raw.pixdim(4) = info2.PixelDimensions(3);
        else
            info2.Raw.pixdim(4) = 1;
        end
    end
end
end
