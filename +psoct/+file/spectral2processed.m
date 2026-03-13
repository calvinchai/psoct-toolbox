function out = spectral2processed(spectralFile, spectralOpts, surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, optsMatFile)
%SPECTRAL2PROCESSED Wrapper to convert spectral data directly to processed outputs.
%
%   out = psoct.file.spectral2processed( ...
%       spectralFile, spectralOpts, surfaceOpts, enfaceOpts, ...
%       acquisitionOpts, outputOpts, volumeOpts, optsMatFile)
%
%   This is a convenience wrapper that chains the spectral and reconstruction
%   steps:
%     1) psoct.spectral.spectral2complex to obtain J1 and J2 from spectral data.
%     2) psoct.recon.complex2processed to compute processed 3D and enface outputs.
%
%   It:
%     - Loads default options from an Opts .mat file (expected variables
%       `spectralOpts`, `surfaceOpts`, `enfaceOpts`, `acquisitionOpts`,
%       `outputOpts`, and `volumeOpts`).
%     - Merges the loaded options with the function arguments so that
%       fields from the function arguments overwrite fields from the file.
%     - Optionally uses a NIfTI header from the spectral input as the
%       output template (InfoLike) when not otherwise specified, following
%       the behavior of psoct.file.spectral2complex.
%
%   Input
%     spectralFile    : Path to the spectral data file. This may be a raw
%                       spectral file or a NIfTI file.
%     spectralOpts    : Struct overriding Opts-file `spectralOpts`.
%     surfaceOpts     : Struct overriding Opts-file `surfaceOpts`.
%     enfaceOpts      : Struct overriding Opts-file `enfaceOpts`.
%     acquisitionOpts : Struct overriding Opts-file `acquisitionOpts`.
%     outputOpts      : Struct overriding Opts-file `outputOpts`.
%     volumeOpts      : Struct overriding Opts-file `volumeOpts`.
%     optsMatFile     : Path to a .mat file containing any subset of the
%                       variables above.

arguments
    spectralFile {mustBeTextScalar, mustBeNonempty}
    spectralOpts struct = struct()
    surfaceOpts struct = struct()
    enfaceOpts struct = struct()
    acquisitionOpts struct = struct()
    outputOpts struct = struct()
    volumeOpts struct = struct()
    optsMatFile {mustBeTextScalar} = ""
end

spectralFile = string(spectralFile);

optsMatFile = string(optsMatFile);
if optsMatFile == ""
    fileSpectralOpts    = struct();
    fileSurfaceOpts     = struct();
    fileEnfaceOpts      = struct();
    fileAcquisitionOpts = struct();
    fileOutputOpts      = struct();
    fileVolumeOpts      = struct();
else
    loadedOpts = psoct.internal.opts.loadOptsWithDefaults( ...
        optsMatFile, ["spectralOpts", "surfaceOpts", "enfaceOpts", ...
                      "acquisitionOpts", "outputOpts", "volumeOpts"], ...
        "psoct:file:spectral2processed");
    fileSpectralOpts    = loadedOpts.spectralOpts;
    fileSurfaceOpts     = loadedOpts.surfaceOpts;
    fileEnfaceOpts      = loadedOpts.enfaceOpts;
    fileAcquisitionOpts = loadedOpts.acquisitionOpts;
    fileOutputOpts      = loadedOpts.outputOpts;
    fileVolumeOpts      = loadedOpts.volumeOpts;
end

mergedSpectralOpts    = psoct.internal.opts.mergeStructs(fileSpectralOpts,    spectralOpts);
mergedSurfaceOpts     = psoct.internal.opts.mergeStructs(fileSurfaceOpts,     surfaceOpts);
mergedEnfaceOpts      = psoct.internal.opts.mergeStructs(fileEnfaceOpts,      enfaceOpts);
mergedAcquisitionOpts = psoct.internal.opts.mergeStructs(fileAcquisitionOpts, acquisitionOpts);
mergedOutputOpts      = psoct.internal.opts.mergeStructs(fileOutputOpts,      outputOpts);
mergedVolumeOpts      = psoct.internal.opts.mergeStructs(fileVolumeOpts,      volumeOpts);

isNiftiInput = psoct.internal.nifti.isNiftiPath(spectralFile);
hasInfoLikeField = isfield(mergedOutputOpts, 'InfoLike');
infoLikeEmpty = (~hasInfoLikeField) || isempty(mergedOutputOpts.InfoLike);

if infoLikeEmpty && isNiftiInput
    infoLike = niftiinfo(spectralFile);
    mergedOutputOpts.InfoLike = infoLike;
end

[J1, J2] = psoct.spectral.spectral2complex( ...
    spectralFile, mergedSpectralOpts, mergedOutputOpts);

out = psoct.recon.complex2processed( ...
    J1, J2, mergedSurfaceOpts, mergedEnfaceOpts, ...
    mergedAcquisitionOpts, mergedOutputOpts, mergedVolumeOpts);

end
