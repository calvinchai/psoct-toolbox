function out = complex2processed(complexNiftiPath, surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, optsMatFile)
%COMPLEX2PROCESSED Wrapper around psoct.recon.complex2processed using a complex NIfTI and Opts .mat file.
%
%   out = psoct.file.complex2processed( ...
%       complexNiftiPath, surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, optsMatFile)
%
%   This is a convenience wrapper around psoct.recon.complex2processed
%   that:
%     - Loads default options from an Opts .mat file (expected variables
%       `surfaceOpts`, `enfaceOpts`, `acquisitionOpts`, `outputOpts`,
%       and `volumeOpts`).
%     - Merges the loaded options with the function arguments so that
%       fields from the function arguments overwrite fields from the file.
%     - Reads a complex NIfTI volume, unpacks J1 and J2 using
%       psoct.complex.unpackComplexData, then runs the reconstruction.
%
%   Input
%     complexNiftiPath : Path to the complex NIfTI data file. The first
%                        dimension is expected to stack
%                        [J1_real; J1_imag; J2_real; J2_imag].
%     surfaceOpts      : Struct whose fields override those loaded from the
%                        Opts file variable `surfaceOpts`. Can be empty.
%     enfaceOpts       : Struct whose fields override those loaded from the
%                        Opts file variable `enfaceOpts`. Can be empty.
%     acquisitionOpts  : Struct whose fields override those loaded from the
%                        Opts file variable `acquisitionOpts`. Can be empty.
%     outputOpts       : Struct whose fields override those loaded from the
%                        Opts file variable `outputOpts`. Can be empty.
%     volumeOpts       : Struct whose fields override those loaded from the
%                        Opts file variable `volumeOpts`. Can be empty.
%     optsMatFile      : Path to a .mat file containing variables named
%                        `surfaceOpts`, `enfaceOpts`, `acquisitionOpts`,
%                        `outputOpts`, and `volumeOpts` (any may be absent).

arguments
    complexNiftiPath {mustBeTextScalar, mustBeNonempty}
    surfaceOpts struct = struct()
    enfaceOpts struct = struct()
    acquisitionOpts struct = struct()
    outputOpts struct = struct()
    volumeOpts struct = struct()
    optsMatFile {mustBeTextScalar} = ""
end

complexNiftiPath = string(complexNiftiPath);
if ~isfile(complexNiftiPath)
    error('psoct:file:complex2processed:NiftiNotFound', ...
        'Complex NIfTI file not found: "%s".', complexNiftiPath);
end

optsMatFile = string(optsMatFile);
if optsMatFile == ""
    fileSurfaceOpts     = struct();
    fileEnfaceOpts      = struct();
    fileAcquisitionOpts = struct();
    fileOutputOpts      = struct();
    fileVolumeOpts      = struct();
else
    loadedOpts = psoct.internal.opts.loadOptsWithDefaults( ...
        optsMatFile, ["surfaceOpts", "enfaceOpts", "acquisitionOpts", "outputOpts", "volumeOpts"], ...
        "psoct:file:complex2processed");
    fileSurfaceOpts     = loadedOpts.surfaceOpts;
    fileEnfaceOpts      = loadedOpts.enfaceOpts;
    fileAcquisitionOpts = loadedOpts.acquisitionOpts;
    fileOutputOpts      = loadedOpts.outputOpts;
    fileVolumeOpts      = loadedOpts.volumeOpts;
end

mergedSurfaceOpts     = psoct.internal.opts.mergeStructs(fileSurfaceOpts,     surfaceOpts);
mergedEnfaceOpts      = psoct.internal.opts.mergeStructs(fileEnfaceOpts,      enfaceOpts);
mergedAcquisitionOpts = psoct.internal.opts.mergeStructs(fileAcquisitionOpts, acquisitionOpts);
mergedOutputOpts      = psoct.internal.opts.mergeStructs(fileOutputOpts,      outputOpts);
mergedVolumeOpts      = psoct.internal.opts.mergeStructs(fileVolumeOpts,      volumeOpts);

V = niftiread(complexNiftiPath);

if ~isnumeric(V)
    error('psoct:file:complex2processed:InvalidNiftiDataType', ...
        'Complex NIfTI data must be numeric.');
end

[J1, J2] = psoct.complex.unpackComplexData(V);

out = psoct.recon.complex2processed( ...
    J1, J2, mergedSurfaceOpts, mergedEnfaceOpts, ...
    mergedAcquisitionOpts, mergedOutputOpts, mergedVolumeOpts);

end
