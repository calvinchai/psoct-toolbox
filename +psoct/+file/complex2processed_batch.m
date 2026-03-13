function complex2processed_batch(filenames, outputDir, surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, optsMatFile, numWorkers, poolType)
%COMPLEX2PROCESSED_BATCH Batch wrapper for psoct.file.complex2processed.
%
%   complex2processed_batch(filenames, outputDir, surfaceOpts, enfaceOpts, ...
%       acquisitionOpts, outputOpts, volumeOpts, optsMatFile, ...
%       numWorkers, poolType)
%
%   This function runs psoct.file.complex2processed on an array of complex
%   NIfTI files in parallel. For each input file whose base name matches
%       <prefix>_complex.nii
%   (or .nii.gz), it derives processed output paths by replacing the
%   `_complex` postfix with the following postfixes:
%       dBI3D, R3D, O3D, surf, aip, mip, ret, ori, biref
%   and assigns those paths into outputOpts.Paths.<key>.
%
%   Input
%     filenames    : String/char/cell array of complex NIfTI paths.
%     outputDir    : Base directory for processed outputs. If empty, the
%                    directory of each input file is used.
%     surfaceOpts  : Struct overriding Opts-file `surfaceOpts`.
%     enfaceOpts   : Struct overriding Opts-file `enfaceOpts`.
%     acquisitionOpts : Struct overriding Opts-file `acquisitionOpts`.
%     outputOpts   : Struct overriding Opts-file `outputOpts`. Its Paths
%                    fields for the keys above will be set per file.
%     volumeOpts   : Struct overriding Opts-file `volumeOpts`.
%     optsMatFile  : (Optional) Path to Opts .mat file used by
%                    psoct.file.complex2processed. If empty, only the
%                    provided option structs are used.
%     numWorkers   : Optional positive integer number of parallel workers.
%                    If empty, MATLAB's default pool size is used.
%     poolType     : Either "process" (default) or "thread", determining
%                    whether to use a process-based or thread-based pool.

arguments
    filenames
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

files = psoct.file.internal.normalizeFilenames(filenames);
outputDir = string(outputDir);
optsMatFile = string(optsMatFile);

if optsMatFile ~= "" && ~isfile(optsMatFile)
    error('psoct:file:complex2processed_batch:OptsFileNotFound', ...
        'Opts .mat file not found: "%s".', optsMatFile);
end

psoct.file.internal.ensureParpool(numWorkers, poolType);

modalities = psoct.file.internal.processedModalities();

if ~isempty(numWorkers) && numWorkers == 1
for idx = 1:numel(files)
    inFile = files{idx};
    try
        [prefix, inDir] = inferPrefixFromComplexFilename(inFile);

        perOutputOpts = outputOpts;
        if ~isfield(perOutputOpts, "Paths") || isempty(perOutputOpts.Paths)
            perOutputOpts.Paths = struct();
        end

        baseDir = outputDir;
        if strlength(baseDir) == 0
            baseDir = inDir;
        end

        for m = 1:numel(modalities)
            key = modalities(m);
            outName = prefix + "_" + key + ".nii";
            perOutputOpts.Paths.(key) = fullfile(baseDir, outName);
        end

        fprintf("complex2processed_batch: %s -> %s_*\n", inFile, prefix);

        psoct.file.complex2processed( ...
            inFile, surfaceOpts, enfaceOpts, acquisitionOpts, ...
            perOutputOpts, volumeOpts, optsMatFile);
    catch ME
        warning("psoct:file:complex2processed_batch:FailedFile", ...
            "Failed to process %s: %s", inFile, ME.message);
    end
end
else
parfor idx = 1:numel(files)
    inFile = files{idx};
    try
        [prefix, inDir] = inferPrefixFromComplexFilename(inFile);

        perOutputOpts = outputOpts;
        if ~isfield(perOutputOpts, "Paths") || isempty(perOutputOpts.Paths)
            perOutputOpts.Paths = struct();
        end

        baseDir = outputDir;
        if strlength(baseDir) == 0
            baseDir = inDir;
        end

        for m = 1:numel(modalities)
            key = modalities(m);
            outName = prefix + "_" + key + ".nii";
            perOutputOpts.Paths.(key) = fullfile(baseDir, outName);
        end

        fprintf("complex2processed_batch: %s -> %s_*\n", inFile, prefix);

        psoct.file.complex2processed( ...
            inFile, surfaceOpts, enfaceOpts, acquisitionOpts, ...
            perOutputOpts, volumeOpts, optsMatFile);
    catch ME
        warning("psoct:file:complex2processed_batch:FailedFile", ...
            "Failed to process %s: %s", inFile, ME.message);
    end
end
end

end

function [prefix, inDir] = inferPrefixFromComplexFilename(filename)
%INFERPREFIXFROMCOMPLEXFILENAME Extract <prefix> from <prefix>_complex.nii[.gz].

filename = string(filename);
[inDir, baseName, ext] = fileparts(filename);

% Handle .nii.gz by stripping the .gz and re-parsing the base name.
if ext == ".gz"
    [inDir2, baseName2, ext2] = fileparts(fullfile(inDir, baseName));
    inDir = inDir2;
    baseName = baseName2;
    ext = ext2;
end

if ext ~= ".nii"
    error("psoct:file:complex2processed_batch:BadExtension", ...
        "Complex file ""%s"" must be a NIfTI (.nii or .nii.gz).", filename);
end

tokens = regexp(baseName, "^(.*)_complex$", "tokens", "once");
if isempty(tokens)
    error("psoct:file:complex2processed_batch:BadFilenamePattern", ...
        "Filename ""%s"" does not match <prefix>_complex*.nii pattern.", baseName);
end

prefix = tokens{1};

end

