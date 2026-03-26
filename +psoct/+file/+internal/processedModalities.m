function modalities = processedModalities()
%PROCESSEDMODALITIES Return list of standard processed output modalities.
%
%   modalities = psoct.file.internal.processedModalities()
%
%   This is a convenience helper for batch wrappers to keep the list of
%   processed output postfixes in one place, in sync with the fields used
%   in psoct.internal.opts.normalizeOutputOpts.

modalities = ["dBI","R3D","O3D", ...
              "surf","aip","mip","ret","ori","biref"];

end

