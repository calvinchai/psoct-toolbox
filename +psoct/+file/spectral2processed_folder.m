function spectral2processed_folder(inputPatternOrFolder, outputDir, spectralOpts, surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, optsMatFile, numWorkers, poolType)
%SPECTRAL2PROCESSED_FOLDER Batch wrapper accepting a folder or glob of spectral files.
%
%   psoct.file.spectral2processed_folder(inputPatternOrFolder, outputDir, ...
%       spectralOpts, surfaceOpts, enfaceOpts, acquisitionOpts, ...
%       outputOpts, volumeOpts, optsMatFile, numWorkers, poolType)
%
%   This function is a convenience wrapper around
%   psoct.file.spectral2processed_batch. Instead of passing an explicit
%   list of spectral filenames, you may pass:
%
%     - A folder path: non-recursively processes all files matching
%           *_spectral_*.*
%       within that folder.
%     - A glob pattern (containing '*' or '?'), e.g.
%           /data/subj*/run*_spectral_*.mat
%     - A single spectral filename.
%
%   The remaining arguments are forwarded unchanged to
%   psoct.file.spectral2processed_batch.
%
%   See also: psoct.file.spectral2processed_batch

arguments
    inputPatternOrFolder {mustBeTextScalar}
    outputDir {mustBeText} = ""
    spectralOpts struct = struct()
    surfaceOpts struct = struct()
    enfaceOpts struct = struct()
    acquisitionOpts struct = struct()
    outputOpts struct = struct()
    volumeOpts struct = struct()
    optsMatFile {mustBeTextScalar} = ""
    numWorkers double = []
    poolType string {mustBeMember(poolType, ["process","thread"])} = "process"
end

files = psoct.file.internal.resolveBatchInputs( ...
    inputPatternOrFolder, ...
    "*_spectral_*.*", ...
    "psoct:file:spectral2processed_folder", ...
    "spectral (<prefix>_spectral_*.*)");

psoct.file.spectral2processed_batch( ...
    files, outputDir, spectralOpts, surfaceOpts, enfaceOpts, ...
    acquisitionOpts, outputOpts, volumeOpts, optsMatFile, ...
    numWorkers, poolType);

end

