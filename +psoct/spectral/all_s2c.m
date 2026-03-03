function all_s2c(base_dir, output_dir, pattern1, pattern2)
% BATCH_RUN_S2C Batch-launch s2c over mosaic files in parallel.
%
% Usage: 
%   batch_run_s2c(base_dir, output_dir, pattern1, pattern2)
%
% Arguments:
%   base_dir   : Directory where the source files are located.
%   output_dir : Directory where outputs and logs will be saved.
%   pattern1   : Pattern for the first set of files (e.g., 'mosaic_003*.nii').
%                (Applies Aline=350, Bline=350)
%   pattern2   : Pattern for the second set of files (e.g., 'mosaic_004*.nii').
%                (Applies Aline=200, Bline=350)

    %% === Dependency Paths ===
    if isdeployed
    else
        addpath('/autofs/cluster/octdata2/users/Hui/PSCalibration/code');
        addpath('/autofs/cluster/octdata2/users/Hui/tools/rob_utils');
        addpath('/autofs/space/megaera_001/users/kchai/code/psoct-renew/telesto');
        addpath('/autofs/cluster/octdata2/users/Chao/code/tools/freesurfer')
    end

    %% === Internal Settings ===
    % Dispersion compensation file
    dispCompFile = '/autofs/cluster/octdata2/users/Hui/tools/dg_utils/spectralprocess/dispComp/mineraloil_LSM03/dispersion_compensation_LSM03_mineraloil_20240829/LSM03_mineral_oil_placecorrectionmeanall2.dat';

    % Parameters for Pattern 1 (formerly mosaic_003)
    Aline_003 = 350;
    Bline_003 = 350;

    % Parameters for Pattern 2 (formerly mosaic_004)
    Aline_004 = 200;
    Bline_004 = 350;

    % Parallel workers settings
    nWorkers = 12; 

    % Log file setup
    logFile = fullfile(output_dir, 'batch_run_s2c_log.txt');

    %% === Input Validation ===
    if ~exist(base_dir, 'dir')
        error('Base directory does not exist: %s', base_dir);
    end

    if ~exist(output_dir, 'dir')
        fprintf('Creating output directory: %s\n', output_dir);
        mkdir(output_dir);
    end

    %% === Build file list ===
    files1 = dir(fullfile(base_dir, pattern1 ));
    files2 = dir(fullfile(base_dir, pattern2 ));
    fileList = {};
    paramsA = [];
    paramsB = [];

    % Process files matching Pattern 1 (Apply 003 dims)
    for k = 1:numel(files1)
        fileList{end+1} = fullfile(base_dir, files1(k).name); %#ok<AGROW>
        paramsA(end+1) = Aline_003; %#ok<AGROW>
        paramsB(end+1) = Bline_003; %#ok<AGROW>
    end

    % Process files matching Pattern 2 (Apply 004 dims)
    for k = 1:numel(files2)
        fileList{end+1} = fullfile(base_dir, files2(k).name); %#ok<AGROW>
        paramsA(end+1) = Aline_004; %#ok<AGROW>
        paramsB(end+1) = Bline_004; %#ok<AGROW>
    end

    numFiles = numel(fileList);
    fprintf('Found %d files to process in %s.\n', numFiles, base_dir);
    
    if numFiles == 0
        warning('No files found matching patterns %s or %s.', pattern1, pattern2);
        return
    end

    %% === Start parallel pool ===
    pool = gcp('nocreate');
    if isempty(pool)
        if isempty(nWorkers)
            pool = parpool; 
        else
            pool = parpool(nWorkers);
        end
    else
        fprintf('Using existing parallel pool with %d workers.\n', pool.NumWorkers);
    end

    %% === Prepare logging ===
    fidLog = fopen(logFile, 'a');
    if fidLog ~= -1
        fprintf(fidLog, '=== Batch started: %s ===\n', datestr(now));
        fprintf(fidLog, 'Base: %s\nOutput: %s\n', base_dir, output_dir);
        fclose(fidLog);
    else
        warning('Could not open log file: %s', logFile);
    end

    %% === Parallel processing ===
    parfor idx = 1:numFiles
        fname = fileList{idx};
        AlineVal = paramsA(idx);
        BlineVal = paramsB(idx);
        
        try
            fprintf('Worker processing (%d/%d): %s\n', idx, numFiles, fname);
            
            % Call s2c
            % Note: passing 'idx' as FileNum, and 'output_dir' as output path
            s2c(fname, idx, dispCompFile, AlineVal, BlineVal, output_dir);
            
            % Log success
            logmsg = sprintf('[%s] SUCCESS: %s\n', datestr(now), fname);
            
        catch ME
            % Log error
            logmsg = sprintf('[%s] ERROR: %s\n\tError message: %s\n', datestr(now), fname, ME.message);
        end
        
        % Append to log (blocking file I/O inside parfor)
        fid = fopen(logFile, 'a');
        if fid ~= -1
            fprintf(fid, '%s', logmsg);
            fclose(fid);
        end
    end

    fprintf('Batch processing completed. See log: %s\n', logFile);
end
