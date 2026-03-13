function complex2processed_folder(inputPatternOrFolder, outputDir, surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, optsMatFile, numWorkers, poolType)
%COMPLEX2PROCESSED_FOLDER Batch wrapper accepting a folder or glob of complex files.
%
%   psoct.file.complex2processed_folder(inputPatternOrFolder, outputDir, ...
%       surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, ...
%       optsMatFile, numWorkers, poolType)
%
%   This function is a convenience wrapper around
%   psoct.file.complex2processed_batch. Instead of passing an explicit list
%   of complex NIfTI filenames, you may pass:
%
%     - A folder path: non-recursively processes all files matching
%           *_complex.nii
%           *_complex.nii.gz
%       within that folder.
%     - A glob pattern (containing '*' or '?'), e.g.
%           /data/subj*/run*_complex.nii
%     - A single complex NIfTI filename.
%
%   The remaining arguments are forwarded unchanged to
%   psoct.file.complex2processed_batch.
%
%   See also: psoct.file.complex2processed_batch

arguments
    inputPatternOrFolder {mustBeTextScalar}
    outputDir {mustBeText} = ""
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
    ["*_complex.nii", "*_complex.nii.gz"], ...
    "psoct:file:complex2processed_folder", ...
    "complex NIfTI (<prefix>_complex.nii[.gz])");

psoct.file.complex2processed_batch( ...
    files, outputDir, surfaceOpts, enfaceOpts, acquisitionOpts, ...
    outputOpts, volumeOpts, optsMatFile, numWorkers, poolType);

end

