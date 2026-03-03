function s2c_batch_stdin(input_file)
% s2c_batch_stdin  Wrapper for s2c that reads arguments from stdin/file and processes them in parallel.
%
%   s2c_batch_stdin()
%   s2c_batch_stdin(input_file)
%
%   Reads input from stdin or a file, one set of arguments per line.
%   Each line should contain 6 space-separated or tab-separated arguments:
%     filename FileNum dispCompFile Aline_length Bline_length output_path
%
%   FileNum can be a single number or a comma-separated list (e.g., "1,2,3")
%
%   Arguments:
%     input_file  (optional) Path to input file. If not provided, reads from stdin.
%
%   Example usage from command line:
%     echo -e "/path/to/file1.nii 1 /path/to/disp.dat 350 350 /path/to/output\n/path/to/file2.nii 2 /path/to/disp.dat 200 350 /path/to/output" > args.txt
%     matlab -batch "s2c_batch_stdin('args.txt')"
%
%   Or from MATLAB:
%     s2c_batch_stdin('args.txt')
%     % Or interactively:
%     s2c_batch_stdin()
%     % Then paste lines of arguments, press Ctrl+D (Unix) or Ctrl+Z (Windows) when done

    %% === Dependency Paths ===
    if ~isdeployed
        addpath('/autofs/cluster/octdata2/users/Hui/PSCalibration/code');
        addpath('/autofs/cluster/octdata2/users/Hui/tools/rob_utils');
        addpath('/autofs/space/megaera_001/users/kchai/code/psoct-renew/telesto');
        addpath('/autofs/cluster/octdata2/users/Chao/code/tools/freesurfer')
    end

    %% === Read from stdin or file ===
    lines = {};
    
    % If input file is provided, read from file
    if nargin > 0 && ~isempty(input_file)
        if ~exist(input_file, 'file')
            error('Input file does not exist: %s', input_file);
        end
        fprintf('Reading arguments from file: %s\n', input_file);
        fid = fopen(input_file, 'r');
        if fid == -1
            error('Could not open input file: %s', input_file);
        end
        while ~feof(fid)
            line = fgetl(fid);
            if isnumeric(line) && line == -1
                break;
            end
            if ischar(line)
                line = strtrim(line);
                if ~isempty(line) && ~strncmp(line, '#', 1)  % Skip comment lines
                    lines{end+1} = line; %#ok<AGROW>
                end
            end
        end
        fclose(fid);
    else
        % Try to read from stdin (file descriptor 0) for piped input
        fprintf('Reading arguments from stdin...\n');
        try
            fid = fopen(0, 'r');
            if fid ~= -1
                while ~feof(fid)
                    line = fgetl(fid);
                    if isnumeric(line) && line == -1
                        break;
                    end
                    if ischar(line)
                        line = strtrim(line);
                        if ~isempty(line) && ~strncmp(line, '#', 1)  % Skip comment lines
                            lines{end+1} = line; %#ok<AGROW>
                        end
                    end
                end
                fclose(fid);
            end
        catch
            % If reading from file descriptor fails, try interactive input
        end
        
        % If no input was read, try interactive input
        if isempty(lines)
            fprintf('Enter arguments (one set per line, empty line to finish):\n');
            fprintf('Format: filename FileNum dispCompFile Aline_length Bline_length output_path\n');
            while true
                try
                    line = input('', 's');
                catch
                    % Handle Ctrl+D or Ctrl+Z
                    break;
                end
                if isempty(line)
                    break;
                end
                line = strtrim(line);
                if ~isempty(line) && ~strncmp(line, '#', 1)  % Skip comment lines
                    lines{end+1} = line; %#ok<AGROW>
                end
            end
        end
    end
    
    if isempty(lines)
        error('No input provided. Please provide arguments via stdin or interactive input.');
    end
    
    numTasks = numel(lines);
    fprintf('Found %d tasks to process.\n', numTasks);
    
    %% === Parse arguments ===
    filenames = cell(numTasks, 1);
    fileNums = cell(numTasks, 1);
    dispCompFiles = cell(numTasks, 1);
    Aline_lengths = zeros(numTasks, 1);
    Bline_lengths = zeros(numTasks, 1);
    output_paths = cell(numTasks, 1);
    
    for idx = 1:numTasks
        % Split line by whitespace (space or tab)
        parts = regexp(lines{idx}, '\s+', 'split');
        parts = parts(~cellfun(@isempty, parts));
        
        if numel(parts) < 6
            error('Line %d: Expected 6 arguments, found %d. Format: filename FileNum dispCompFile Aline_length Bline_length output_path', ...
                  idx, numel(parts));
        end
        
        filenames{idx} = parts{1};
        fileNums{idx} = parts{2};
        dispCompFiles{idx} = parts{3};
        Aline_lengths(idx) = str2double(parts{4});
        Bline_lengths(idx) = str2double(parts{5});
        output_paths{idx} = parts{6};
        
        % Validate numeric inputs
        if isnan(Aline_lengths(idx)) || isnan(Bline_lengths(idx))
            error('Line %d: Aline_length and Bline_length must be numeric', idx);
        end
        
        % Parse FileNum (can be single number or comma-separated list)
        fileNumStr = fileNums{idx};
        if contains(fileNumStr, ',')
            % Comma-separated list
            fileNumParts = strsplit(fileNumStr, ',');
            fileNums{idx} = cellfun(@str2double, fileNumParts);
        else
            % Single number
            fileNums{idx} = str2double(fileNumStr);
        end
        
        if any(isnan(fileNums{idx}))
            error('Line %d: FileNum must be numeric or comma-separated numeric list', idx);
        end
    end
    
    %% === Start parallel pool ===
    pool = gcp('nocreate');
    if isempty(pool)
        % Use default number of workers (or set a specific number)
        pool = parpool;
        fprintf('Started parallel pool with %d workers.\n', pool.NumWorkers);
    else
        fprintf('Using existing parallel pool with %d workers.\n', pool.NumWorkers);
    end
    
    %% === Parallel processing ===
    fprintf('Starting parallel processing...\n');
    parfor idx = 1:numTasks
        try
            fprintf('[Task %d/%d] Processing: %s\n', idx, numTasks, filenames{idx});
            
            % Call s2c with parsed arguments
            s2c(filenames{idx}, fileNums{idx}, dispCompFiles{idx}, ...
                Aline_lengths(idx), Bline_lengths(idx), output_paths{idx});
            
            fprintf('[Task %d/%d] SUCCESS: %s\n', idx, numTasks, filenames{idx});
            
        catch ME
            fprintf('[Task %d/%d] ERROR: %s\n\tError message: %s\n', ...
                    idx, numTasks, filenames{idx}, ME.message);
            % Re-throw to see full stack trace in parallel workers if needed
            % (commented out to allow other tasks to continue)
            % rethrow(ME);
        end
    end
    
    fprintf('Batch processing completed.\n');
end
