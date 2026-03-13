function spectral2complex_batch(filenames, outputDir, spectralOpts, outputOpts, optsMatFile, numWorkers, poolType)
%SPECTRAL2COMPLEX_BATCH Batch wrapper for psoct.file.spectral2complex.
%
%   spectral2complex_batch(filenames, outputDir, spectralOpts, outputOpts, ...
%       optsMatFile, numWorkers, poolType)
%
%   This function runs psoct.file.spectral2complex on an array of input
%   spectral files in parallel, inferring a complex NIfTI output path for
%   each file based on the "_spectral_" naming convention.
%
%   Input
%     filenames   : String/char/cell array of spectral file paths.
%     outputDir   : Base directory for complex outputs. If empty, the
%                   directory of each input file is used.
%     spectralOpts: Struct passed through to psoct.file.spectral2complex
%                   (overrides fields from optsMatFile.spectralOpts).
%     outputOpts  : Struct passed through to psoct.file.spectral2complex
%                   (overrides fields from optsMatFile.outputOpts).
%     optsMatFile : (Optional) Path to Opts .mat file used by
%                   psoct.file.spectral2complex. If empty, only the
%                   provided spectralOpts/outputOpts are used.
%     numWorkers  : Optional positive integer number of parallel workers.
%                   If empty, MATLAB's default pool size is used.
%     poolType    : Either "process" (default) or "thread", determining
%                   whether to use a process-based or thread-based pool.

arguments
    filenames
    outputDir {mustBeText} = ""
    spectralOpts struct = struct()
    outputOpts struct = struct()
    optsMatFile {mustBeTextScalar} = ""
    numWorkers double = []
    poolType string {mustBeMember(poolType, ["process","thread"])} = "process"
end

files = psoct.file.internal.normalizeFilenames(filenames);
outputDir = string(outputDir);
optsMatFile = string(optsMatFile);

if optsMatFile ~= "" && ~isfile(optsMatFile)
    error('psoct:file:spectral2complex_batch:OptsFileNotFound', ...
        'Opts .mat file not found: "%s".', optsMatFile);
end

psoct.file.internal.ensureParpool(numWorkers, poolType);

if ~isempty(numWorkers) && numWorkers == 1
for idx = 1:numel(files)
    inFile = files{idx};
    try
        outPath = inferOutputPathSpectralPattern(inFile, outputDir);

        perOutputOpts = outputOpts;
        if ~isfield(perOutputOpts, "Paths") || isempty(perOutputOpts.Paths)
            perOutputOpts.Paths = struct();
        end
        perOutputOpts.Paths.complex = outPath;

        fprintf("spectral2complex_batch: %s -> %s\n", inFile, outPath);
        psoct.file.spectral2complex(inFile, spectralOpts, perOutputOpts, optsMatFile);
    catch ME
        warning("psoct:file:spectral2complex_batch:FailedFile", ...
            "Failed to process %s: %s", inFile, ME.message);
    end
end
else
parfor idx = 1:numel(files)
    inFile = files{idx};
    try
        outPath = inferOutputPathSpectralPattern(inFile, outputDir);

        perOutputOpts = outputOpts;
        if ~isfield(perOutputOpts, "Paths") || isempty(perOutputOpts.Paths)
            perOutputOpts.Paths = struct();
        end
        perOutputOpts.Paths.complex = outPath;

        fprintf("spectral2complex_batch: %s -> %s\n", inFile, outPath);
        psoct.file.spectral2complex(inFile, spectralOpts, perOutputOpts, optsMatFile);
    catch ME
        warning("psoct:file:spectral2complex_batch:FailedFile", ...
            "Failed to process %s: %s", inFile, ME.message);
    end
end
end

end

function outputPath = inferOutputPathSpectralPattern(filename, outputDir)
%INFEROUTPUTPATHSPECTRALPATTERN Infer complex output path from a spectral filename.

[inDir, baseName, ~] = fileparts(filename);

tokens = regexp(baseName, "^(.*)_spectral_(.*)$", "tokens", "once");
if isempty(tokens)
    error("psoct:file:spectral2complex_batch:BadFilenamePattern", ...
        "Filename ""%s"" does not match *_spectral_* pattern.", baseName);
end

prefix = tokens{1};
outName = prefix + "_complex.nii";

if strlength(outputDir) > 0
    outputPath = fullfile(outputDir, outName);
else
    outputPath = fullfile(inDir, outName);
end

end

