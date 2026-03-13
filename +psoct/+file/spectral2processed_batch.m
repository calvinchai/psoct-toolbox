function spectral2processed_batch(filenames, outputDir, spectralOpts, surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, optsMatFile, numWorkers, poolType)
%SPECTRAL2PROCESSED_BATCH Batch wrapper for psoct.file.spectral2processed.
%
%   spectral2processed_batch(filenames, outputDir, spectralOpts, surfaceOpts, ...
%       enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, optsMatFile, ...
%       numWorkers, poolType)
%
%   This function runs psoct.file.spectral2processed on an array of spectral
%   files in parallel. For each input file whose base name matches
%       <prefix>_spectral_*.*
%   it derives processed output paths by using the same <prefix> and
%   attaching modality-specific postfixes:
%       dBI3D, R3D, O3D, surf, aip, mip, ret, ori, biref
%   which are assigned into outputOpts.Paths.<key>.
%
%   Input
%     filenames    : String/char/cell array of spectral file paths.
%     outputDir    : Base directory for processed outputs. If empty, the
%                    directory of each input file is used.
%     spectralOpts : Struct overriding Opts-file `spectralOpts`.
%     surfaceOpts  : Struct overriding Opts-file `surfaceOpts`.
%     enfaceOpts   : Struct overriding Opts-file `enfaceOpts`.
%     acquisitionOpts : Struct overriding Opts-file `acquisitionOpts`.
%     outputOpts   : Struct overriding Opts-file `outputOpts`. Its Paths
%                    fields for the keys above will be set per file.
%     volumeOpts   : Struct overriding Opts-file `volumeOpts`.
%     optsMatFile  : (Optional) Path to Opts .mat file used by
%                    psoct.file.spectral2processed. If empty, only the
%                    provided option structs are used.
%     numWorkers   : Optional positive integer number of parallel workers.
%                    If empty, MATLAB's default pool size is used.
%     poolType     : Either "process" (default) or "thread", determining
%                    whether to use a process-based or thread-based pool.

arguments
    filenames
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

files = psoct.file.internal.normalizeFilenames(filenames);
outputDir = string(outputDir);
optsMatFile = string(optsMatFile);

if optsMatFile ~= "" && ~isfile(optsMatFile)
    error('psoct:file:spectral2processed_batch:OptsFileNotFound', ...
        'Opts .mat file not found: "%s".', optsMatFile);
end

psoct.file.internal.ensureParpool(numWorkers, poolType);

modalities = psoct.file.internal.processedModalities();

if ~isempty(numWorkers) && numWorkers == 1
    for idx = 1:numel(files)
        inFile = files{idx};
        try
            [prefix, inDir] = inferPrefixFromSpectralFilename(inFile);

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

            fprintf("spectral2processed_batch: %s -> %s_*\n", inFile, prefix);

            psoct.file.spectral2processed( ...
                inFile, spectralOpts, surfaceOpts, enfaceOpts, ...
                acquisitionOpts, perOutputOpts, volumeOpts, optsMatFile);
        catch ME
            warning("psoct:file:spectral2processed_batch:FailedFile", ...
                "Failed to process %s: %s", inFile, ME.message);
        end
    end
else
parfor idx = 1:numel(files)
    inFile = files{idx};
    try
        [prefix, inDir] = inferPrefixFromSpectralFilename(inFile);

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

        fprintf("spectral2processed_batch: %s -> %s_*\n", inFile, prefix);

        psoct.file.spectral2processed( ...
            inFile, spectralOpts, surfaceOpts, enfaceOpts, ...
            acquisitionOpts, perOutputOpts, volumeOpts, optsMatFile);
    catch ME
        warning("psoct:file:spectral2processed_batch:FailedFile", ...
            "Failed to process %s: %s", inFile, ME.message);
    end
end
end

end

function [prefix, inDir] = inferPrefixFromSpectralFilename(filename)
%INFERPREFIXFROMSPECTRALFILENAME Extract <prefix> from <prefix>_spectral_*.

filename = string(filename);
[inDir, baseName, ~] = fileparts(filename);

tokens = regexp(baseName, "^(.*)_spectral_.*$", "tokens", "once");
if isempty(tokens)
    error("psoct:file:spectral2processed_batch:BadFilenamePattern", ...
        "Filename ""%s"" does not match <prefix>_spectral_* pattern.", baseName);
end

prefix = tokens{1};

end

