function enfaceOpts = normalizeEnfaceOpts(enfaceOpts)
%NORMALIZEENFACEOPTS Normalize enface options for vol2enface / pipelines.
%
%   enfaceOpts = psoct.internal.opts.normalizeEnfaceOpts(enfaceOpts)
%
% Accepted fields (with defaults):
%   Offset          : numeric, offset below surface for enface window (default 0)
%   Depth           : numeric, enface window depth (default 70)
%   OriMethod       : string, orientation method ("circularMean" default)
%   OriMethodArgs   : struct, reserved for future use (default struct())
%   BirefMethod     : string, birefringence method ("legacy" default)
%   BirefMethodArgs : struct, reserved for future use (default struct())
%   Compute         : struct of logical flags for modalities (fields
%                     aip,mip,ret,ori,biref). Missing fields default true.
%   Save2DAs3D      : logical, write 2D outputs as X-by-Y-by-1 NIfTI (default false)

if nargin == 0 || isempty(enfaceOpts)
    enfaceOpts = struct();
end

nargs = namedargs2cell(enfaceOpts);
enfaceOpts = iNormalizeEnfaceOpts(nargs{:});


end

function nargs = iNormalizeEnfaceOpts(nargs)

arguments
    nargs.Offset (1,1) {mustBeNumeric, mustBeFinite} = 0
    nargs.Depth (1,1) {mustBeNumeric, mustBeFinite} = 70
    nargs.OriMethod = "circularMean"
    nargs.OriMethodArgs struct = struct()
    nargs.BirefMethod = "legacy"
    nargs.BirefMethodArgs struct = struct()
    nargs.Compute struct = struct()
    nargs.Save2DAs3D (1,1) logical = true
end
    modalities = ["aip","mip","ret","ori","biref"];
    for k = 1:numel(modalities)
        nargs.Compute = ensureComputeField(nargs.Compute, modalities(k));
    end 
end


function compute = ensureComputeField(compute, fieldName)
    if ~isfield(compute, fieldName) || isempty(compute.(fieldName))
        compute.(fieldName) = true;
    else
        compute.(fieldName) = logical(compute.(fieldName));
    end
end

