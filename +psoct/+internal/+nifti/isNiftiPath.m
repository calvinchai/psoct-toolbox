function tf = isNiftiPath(pathStr)
%ISNIFTIPATH Heuristic check for NIfTI file extensions.
%
%   tf = psoct.internal.nifti.isNiftiPath(pathStr)
%
%   Returns true if PATHSTR appears to be a NIfTI file based on its
%   extension (.nii or .nii.gz), case-insensitive.

pathStr = string(pathStr);
[~, ~, ext] = fileparts(pathStr);
ext = lower(ext);

if ext == ".nii"
    tf = true;
elseif ext == ".gz"
    if endsWith(lower(pathStr), ".nii.gz")
        tf = true;
    else
        tf = false;
    end
else
    tf = false;
end

end

