function acquisitionOpts = normalizeAcquisitionOpts(acquisitionOpts)
%NORMALIZEACQUISITIONOPTS Normalize acquisition options for vol2enface / pipelines.
%
%   acquisitionOpts = psoct.internal.opts.normalizeAcquisitionOpts(acquisitionOpts)
%
% Accepted fields (with defaults):
%   ZSizeUm          : axial pixel size in micrometers (default 2.5)
%   WavelengthUm     : wavelength in micrometers (default 0.0013)
%   SliceThicknessUm : slice thickness (um) used when expanding 2D->3D (default 500)

if nargin == 0 || isempty(acquisitionOpts)
    acquisitionOpts = struct();
end

nargs = namedargs2cell(acquisitionOpts);
acquisitionOpts = iNormalizeAcquisitionOpts(nargs{:});

end

function nargs = iNormalizeAcquisitionOpts(nargs)

arguments
    nargs.PixelDimensionsUm (1,3) {mustBeNumeric, mustBeFinite} = [10 10 2.5]
    nargs.WavelengthUm (1,1) {mustBeNumeric, mustBeFinite} = 0.0013
    nargs.SliceThicknessUm (1,1) {mustBeNumeric, mustBeFinite} = 500
end

end

