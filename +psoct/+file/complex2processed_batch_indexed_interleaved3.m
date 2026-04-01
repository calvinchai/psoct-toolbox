function complex2processed_batch_indexed_interleaved3( ...
    filenames, outputDir, mosaicId, tileIndices, ...
    surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, ...
    optsMatFile, numWorkers, poolType)
%COMPLEX2PROCESSED_BATCH_INDEXED_INTERLEAVED3 Batch complex→processed with 3-way interleaved split.
%
%   complex2processed_batch_indexed_interleaved3(filenames, outputDir, mosaicId, tileIndices, ...
%       surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts, ...
%       optsMatFile, numWorkers, poolType)
%
%   For each input complex NIfTI file k, read and unpack J1/J2 once, then
%   split the Jones volumes along dimension 1 using channel patterns:
%     c=1 -> 1:3:end  (writes mosaicId + 0)
%     c=2 -> 2:3:end  (writes mosaicId + 1)
%     c=3 -> 3:3:end  (writes mosaicId + 2)
%
%   Outputs use the same naming convention as complex2processed_batch_indexed:
%     mosaic_{mosaicIdOut:03d}_image_{tileIndices(k):04d}_{modality}.nii
%
%   The complex NIfTI first dimension is expected to stack
%   [J1_real; J1_imag; J2_real; J2_imag] (see psoct.complex.unpackComplexData).

arguments
    filenames
    outputDir {mustBeText}
    mosaicId (1,1) double {mustBeInteger, mustBeNonnegative}
    tileIndices double
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
tileIndices = tileIndices(:);
if numel(tileIndices) ~= numel(files)
    error("psoct:file:complex2processed_batch_indexed_interleaved3:TileIndicesMismatch", ...
        "tileIndices must have length %d (number of files), got %d.", ...
        numel(files), numel(tileIndices));
end

outputDir = string(outputDir);
optsMatFile = string(optsMatFile);

if optsMatFile ~= "" && ~isfile(optsMatFile)
    error("psoct:file:complex2processed_batch_indexed_interleaved3:OptsFileNotFound", ...
        "Opts .mat file not found: ""%s"".", optsMatFile);
end

psoct.file.internal.ensureParpool(numWorkers, poolType);
modalities = psoct.file.internal.processedModalities();

% Merge opts once before the loop (same behavior as psoct.file.complex2processed).
if optsMatFile == ""
    fileSurfaceOpts     = struct();
    fileEnfaceOpts      = struct();
    fileAcquisitionOpts = struct();
    fileOutputOpts      = struct();
    fileVolumeOpts      = struct();
else
    loadedOpts = psoct.internal.opts.loadOptsWithDefaults( ...
        optsMatFile, ["surfaceOpts", "enfaceOpts", "acquisitionOpts", "outputOpts", "volumeOpts"], ...
        "psoct:file:complex2processed_batch_indexed_interleaved3");
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

if ~isempty(numWorkers) && numWorkers == 1
    for idx = 1:numel(files)
        inFile = files{idx};
        try
            if ~isfile(inFile)
                error("psoct:file:complex2processed_batch_indexed_interleaved3:NiftiNotFound", ...
                    "Complex NIfTI file not found: ""%s"".", inFile);
            end

            inDir = string(fileparts(inFile));
            baseDir = outputDir;
            if strlength(baseDir) == 0
                baseDir = inDir;
            end

            V = niftiread(inFile);
            if ~isnumeric(V)
                error("psoct:file:complex2processed_batch_indexed_interleaved3:InvalidNiftiDataType", ...
                    "Complex NIfTI data must be numeric.");
            end
            [J1, J2] = psoct.complex.unpackComplexData(V);

            for c = 1:3
                [J1c, J2c] = psoct.file.internal.splitJonesInterleaved3(J1, J2, c);
                mosaicIdOut = mosaicId + (c - 1);
                prefix = psoct.file.internal.buildProcessedOutputPrefix(mosaicIdOut, tileIndices(idx));

                perOutputOpts = mergedOutputOpts;
                if ~isfield(perOutputOpts, "Paths") || isempty(perOutputOpts.Paths)
                    perOutputOpts.Paths = struct();
                end
                for m = 1:numel(modalities)
                    key = modalities(m);
                    perOutputOpts.Paths.(key) = fullfile(baseDir, prefix + "_" + key + ".nii");
                end

                fprintf("complex2processed_batch_indexed_interleaved3: %s -> %s_*\n", inFile, prefix);

                psoct.recon.complex2processed( ...
                    J1c, J2c, mergedSurfaceOpts, mergedEnfaceOpts, ...
                    mergedAcquisitionOpts, perOutputOpts, mergedVolumeOpts);
            end
        catch ME
            warning("psoct:file:complex2processed_batch_indexed_interleaved3:FailedFile", ...
                "Failed to process %s: %s", inFile, ME.message);
        end
    end
else
parfor idx = 1:numel(files)
    inFile = files{idx};
    try
        if ~isfile(inFile)
            error("psoct:file:complex2processed_batch_indexed_interleaved3:NiftiNotFound", ...
                "Complex NIfTI file not found: ""%s"".", inFile);
        end

        inDir = string(fileparts(inFile));
        baseDir = outputDir;
        if strlength(baseDir) == 0
            baseDir = inDir;
        end

        V = niftiread(inFile);
        if ~isnumeric(V)
            error("psoct:file:complex2processed_batch_indexed_interleaved3:InvalidNiftiDataType", ...
                "Complex NIfTI data must be numeric.");
        end
        [J1, J2] = psoct.complex.unpackComplexData(V);

        for c = 1:3
            [J1c, J2c] = psoct.file.internal.splitJonesInterleaved3(J1, J2, c);
            mosaicIdOut = mosaicId + (c - 1);
            prefix = psoct.file.internal.buildProcessedOutputPrefix(mosaicIdOut, tileIndices(idx));

            perOutputOpts = mergedOutputOpts;
            if ~isfield(perOutputOpts, "Paths") || isempty(perOutputOpts.Paths)
                perOutputOpts.Paths = struct();
            end
            for m = 1:numel(modalities)
                key = modalities(m);
                perOutputOpts.Paths.(key) = fullfile(baseDir, prefix + "_" + key + ".nii");
            end

            fprintf("complex2processed_batch_indexed_interleaved3: %s -> %s_*\n", inFile, prefix);

            psoct.recon.complex2processed( ...
                J1c, J2c, mergedSurfaceOpts, mergedEnfaceOpts, ...
                mergedAcquisitionOpts, perOutputOpts, mergedVolumeOpts);
        end
    catch ME
        warning("psoct:file:complex2processed_batch_indexed_interleaved3:FailedFile", ...
            "Failed to process %s: %s", inFile, ME.message);
    end
end
end

end
