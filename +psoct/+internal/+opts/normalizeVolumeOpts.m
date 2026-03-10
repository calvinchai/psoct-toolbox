function volumeOpts = normalizeVolumeOpts(volumeOpts)
%NORMALIZEVOLUMEOPTS Normalize volume options for complex2volumes / pipelines.
%
%   volumeOpts = psoct.internal.opts.normalizeVolumeOpts(volumeOpts)
%
% Accepted fields (with defaults):
%   flipPhase   : logical, flip optic axis phase sign (default false)
%   phaseOffset : scalar, phase offset in radians (default 100/180*pi)
%   flipZ       : logical, flip reconstructed Z direction (default true)
%
% This helper mirrors the pattern used by normalizeSpectralOpts so that
% callers can pass in a loose struct and receive a validated struct back.

if nargin == 0 || isempty(volumeOpts)
    volumeOpts = struct();
end

% Use a nested arguments block to impose defaults and validation.
nargs = namedargs2cell(volumeOpts);
volumeOpts = iNormalizeVolumeOpts(nargs{:});

end

function nargs = iNormalizeVolumeOpts(nargs)

arguments
    nargs.flipPhase (1,1) logical = false
    nargs.phaseOffset (1,1) double = 100/180*pi
    nargs.flipZ (1,1) logical = true
end

end

