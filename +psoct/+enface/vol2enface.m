function out = vol2enface(dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOpts, acquisitionOpts, outputOpts)
% psoct.enface.vol2enface
% Compute enface modalities from reconstructed 3D volumes and optionally
% write each modality to disk.
%
%   out = psoct.enface.vol2enface(dBI3D_vol, R3D_vol, O3D_vol, surf, ...
%       enfaceOpts, acquisitionOpts, outputOpts)
%
% Inputs
%   dBI3D_vol, R3D_vol, O3D_vol : 3D reconstructed volumes (X x Y x Z).
%   surf                        : 2D surface map (X x Y), z-index per A-line.
%
% Enface options (enfaceOpts.*)
%   enfaceOpts.Offset           : offset below surface for enface window. Default 0.
%   enfaceOpts.Depth            : enface window depth. Default 70.
%   enfaceOpts.OriMethod        : "circularMean" (default) or legacy fallback.
%   enfaceOpts.OriMethodArgs    : reserved for future orientation method args.
%   enfaceOpts.BirefMethod      : "legacy"(default),"fft","unwrap_old","unwrap_new","exp","".
%   enfaceOpts.BirefMethodArgs  : reserved for future biref method args.
%   enfaceOpts.Compute          : struct booleans with fields: aip,mip,ret,ori,biref.
%                                 Missing fields default to true.
%   enfaceOpts.Save2DAs3D       : if true, write 2D outputs as X-by-Y-by-1 NIfTI.
%
% Acquisition options (acquisitionOpts.*)
%   acquisitionOpts.ZSizeUm          : axial pixel size in micrometers.
%   acquisitionOpts.WavelengthUm     : wavelength in micrometers (for biref methods).
%   acquisitionOpts.SliceThicknessUm : slice thickness (um) used as PixelDimensions(3)
%                                      when Save2DAs3D is true. Default 500.
%
% Output options (outputOpts.*)
%   outputOpts.Paths    : struct paths with fields: aip,mip,ret,ori,biref,surf.
%                         Non-empty paths trigger writing for computed outputs.
%   outputOpts.InfoLike : optional NIfTI-info-like struct used as write template.
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
    enfaceOpts struct = struct()
    acquisitionOpts struct = struct()
    outputOpts struct = struct()
end

enfaceOpts = psoct.internal.opts.normalizeEnfaceOpts(enfaceOpts);
acquisitionOpts = psoct.internal.opts.normalizeAcquisitionOpts(acquisitionOpts);
outputOpts = psoct.internal.opts.normalizeOutputOpts(outputOpts);

enfaceOffset = enfaceOpts.Offset;
enfaceDepth = enfaceOpts.Depth;
zSizeUm = acquisitionOpts.PixelDimensionsUm(3);
wavelengthUm = acquisitionOpts.WavelengthUm;
oriMethod = string(enfaceOpts.OriMethod);
birefMethod = string(enfaceOpts.BirefMethod);
oriMethodArgs = enfaceOpts.OriMethodArgs; %#ok<NASGU>
birefMethodArgs = enfaceOpts.BirefMethodArgs; %#ok<NASGU>

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

paths = outputOpts.Paths;
infoIn = outputOpts.InfoLike;
compute = enfaceOpts.Compute;

out = struct();
out.aip = [];
out.mip = [];
out.ret = [];
out.ori = [];
out.biref = [];
out.surf = surf;
writeFutures = {};

writeFutures = writeEnfaceModality(writeFutures, paths.surf, out.surf, infoIn, acquisitionOpts.PixelDimensionsUm, enfaceOpts);

if compute.aip
    out.aip = psoct.enface.stat.enfaceMean(dBI3D_vol, surf, enfaceOffset, enfaceDepth);
    writeFutures = writeEnfaceModality(writeFutures, paths.aip, out.aip, infoIn, acquisitionOpts.PixelDimensionsUm, enfaceOpts);
end

if compute.mip
    out.mip = psoct.enface.stat.enfaceMax(dBI3D_vol, surf, enfaceOffset, enfaceDepth);
    writeFutures = writeEnfaceModality(writeFutures, paths.mip, out.mip, infoIn, acquisitionOpts.PixelDimensionsUm, enfaceOpts);
end

if compute.ret
    out.ret = psoct.enface.stat.enfaceMean(R3D_vol, surf, enfaceOffset, enfaceDepth);
    writeFutures = writeEnfaceModality(writeFutures, paths.ret, out.ret, infoIn, acquisitionOpts.PixelDimensionsUm, enfaceOpts);
end

if compute.ori
    if oriMethod == "circularMean"
        out.ori = psoct.enface.stat.enfaceCircularMean(O3D_vol, surf, enfaceOffset, enfaceDepth);
    else
        out.ori = psoct.enface.stat.enfaceMean(O3D_vol, surf, enfaceOffset, enfaceDepth);
    end
    writeFutures = writeEnfaceModality(writeFutures, paths.ori, out.ori, infoIn, acquisitionOpts.PixelDimensionsUm, enfaceOpts);

if compute.biref
    if ~(isscalar(zSizeUm) && zSizeUm > 0)
        error("psoct.enface.vol2enface:BadZSize", ...
            "zSizeUm must be provided and > 0 (micrometers) to compute biref.");
    end
    if ~(isscalar(wavelengthUm) && wavelengthUm > 0)
        error("psoct.enface.vol2enface:BadLambda", ...
            "wavelengthUm must be provided and > 0 (micrometers) to compute biref.");
    end

    switch birefMethod
        case {"legacy",""}
            out.biref = psoct.enface.biref.fitLinear(R3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        case "fft"
            out.biref = psoct.enface.biref.fftLinear(R3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        case "unwrap_old"
            out.biref = psoct.enface.biref.unwrapOld(dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        case "unwrap_new"
            out.biref = psoct.enface.biref.unwrapNew(dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        case "unwrap_exp"
            out.biref = psoct.enface.biref.unwrapExp(dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm);
        otherwise
            error("psoct.enface.vol2enface:UnknownBirefMethod", ...
                "Unknown birefMethod ""%s"".", birefMethod);
    end
    writeFutures = writeEnfaceModality(writeFutures, paths.biref, out.biref, infoIn, acquisitionOpts.PixelDimensionsUm, enfaceOpts);
end


psoct.internal.nifti.waitWriteFutures(writeFutures);

out.paths = paths;
out.compute = compute;

end

function futures = writeEnfaceModality(futures, path, data, infoLike, pixelDimensions, enfaceOpts)
    shrinkedHeader = psoct.internal.nifti.shrinkNiftiHeader(data, infoLike, pixelDimensions, "Expand2DTo3D", enfaceOpts.Save2DAs3D, "channelDimension", false, "SliceThicknessUm", acquisitionOpts.SliceThicknessUm);
    if enfaceOpts.Save2DAs3D
        data = data(:,:,1);
    end
    futures = psoct.internal.nifti.appendWriteFuture(futures, ...
        psoct.internal.nifti.writeNiftiIfPath(path, data, shrinkedHeader));
end

end
