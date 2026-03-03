function p = getDataFile(filename)
    arguments
        filename (1,:) char {mustBeTextScalar, mustBeNonempty}
    end

    pkgFolder = fileparts(mfilename('fullpath'));
    p = fullfile(pkgFolder, "data", filename);

    if ~isfile(p)
        error("Data file not found: %s", p);
    end
end