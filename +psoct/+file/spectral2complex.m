function [Jones1_3D, Jones2_3D] = spectral2complex(spectralFile, spectralOpts, outputOpts, optsMatFile)
%SPECTRAL2COMPLEX Wrapper around psoct.spectral.spectral2complex using an Opts .mat file.
%
%   [Jones1_3D, Jones2_3D] = psoct.file.spectral2complex( ...
%       spectralFile, spectralOpts, outputOpts, optsMatFile)
%
%   This is a convenience wrapper around psoct.spectral.spectral2complex
%   that:
%     - Loads default options from an Opts .mat file (expected variables
%       `spectralOpts` and `outputOpts`).
%     - Merges the loaded options with the function arguments so that
%       fields from the function arguments overwrite fields from the file.
%     - Optionally uses a NIfTI header from the spectral input as the
%       output template (InfoLike) when not otherwise specified.
%
%   Input
%     spectralFile : Path to the spectral data file. This may be a raw
%                    spectral file or a NIfTI file.
%     spectralOpts : Struct whose fields override those loaded from the
%                    Opts file variable `spectralOpts`. Can be empty.
%     outputOpts   : Struct whose fields override those loaded from the
%                    Opts file variable `outputOpts`. Can be empty.
%     optsMatFile  : Path to a .mat file containing variables named
%                    `spectralOpts` and `outputOpts`.
%
%   NIfTI InfoLike behavior
%     After merging output options from the file and function arguments:
%       - If mergedOutputOpts.InfoLike is non-empty, it is used as-is.
%       - Otherwise, if spectralFile is a NIfTI file (.nii or .nii.gz),
%         niftiinfo(spectralFile) is used as mergedOutputOpts.InfoLike.
%       - Otherwise, InfoLike is left empty and downstream defaults apply.

arguments
    spectralFile {mustBeTextScalar, mustBeNonempty}
    spectralOpts struct = struct()
    outputOpts struct = struct()
    optsMatFile {mustBeTextScalar} = ""
end

optsMatFile = string(optsMatFile);
if optsMatFile == ""
    fileSpectralOpts = struct();
    fileOutputOpts   = struct();
else
    loadedOpts = psoct.internal.opts.loadOptsWithDefaults( ...
        optsMatFile, ["spectralOpts", "outputOpts"], "psoct:file:spectral2complex");
    fileSpectralOpts = loadedOpts.spectralOpts;
    fileOutputOpts   = loadedOpts.outputOpts;
end

mergedSpectralOpts = psoct.internal.opts.mergeStructs(fileSpectralOpts, spectralOpts);
mergedOutputOpts   = psoct.internal.opts.mergeStructs(fileOutputOpts,  outputOpts);

isNiftiInput = psoct.internal.nifti.isNiftiPath(spectralFile);
hasInfoLikeField = isfield(mergedOutputOpts, 'InfoLike');
infoLikeEmpty = (~hasInfoLikeField) || isempty(mergedOutputOpts.InfoLike);

if infoLikeEmpty && isNiftiInput
    infoLike = niftiinfo(spectralFile);
    mergedOutputOpts.InfoLike = infoLike;
end

[Jones1_3D, Jones2_3D] = psoct.spectral.spectral2complex( ...
    spectralFile, mergedSpectralOpts, mergedOutputOpts);

end
