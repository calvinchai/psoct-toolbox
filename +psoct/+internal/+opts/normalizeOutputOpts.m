function outputOpts = validateOutputOpts(outputOpts)
    nargs = namedargs2cell(outputOpts);
    outputOpts = iNormalizeOutputOpts(nargs{:});
end

function nargs = iNormalizeOutputOpts(nargs)
    arguments
        nargs.Paths struct = struct()
        nargs.InfoLike struct = defaultNiftiHeader()
    end
    modalities = ["complex", "dBI3D", "R3D", "O3D", "surf", "aip", "mip", "ret", "ori", "biref"];
    for k = 1:numel(modalities)
        nargs.Paths = ensurePathField(nargs.Paths, modalities(k));
    end
end

function infoLike = defaultNiftiHeader()
    infoLike = images.internal.nifti.niftiImage(images.internal.nifti.niftiImage.niftiDefaultHeader([],'Version','NIfTI1')).simplifyStruct();
end

function paths = ensurePathField(paths, fieldName)
    if ~isfield(paths, fieldName) || strlength(string(paths.(fieldName))) == 0
        paths.(fieldName) = "";
    end
end