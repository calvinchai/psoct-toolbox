function [dBI3D_vol, R3D_vol, O3D_vol] = complex2volumes(J1, J2, volumeOpts, outputOpts)
% complex2volumes Convert complex Jones volumes into PS-OCT metric volumes.
%
% J1 and J2 are complex-valued 3D arrays of size X × Y × Z representing the
% two Jones vector components.
% Returns backscatter (dBI3D_vol), retardance (R3D_vol), and optic axis
% orientation (O3D_vol) volumes.
%
% OPTIONAL:
%   volumeOpts.flipPhase   : boolean, flip the phase of the optic axis orientation (default false).
%   volumeOpts.phaseOffset : scalar, phase offset in radians (default 100/180*pi).
%   volumeOpts.flipZ       : boolean, flip the volume along the z-axis (default true).
%   outputOpts.Paths       : struct with optional fields dBI3D, R3D, O3D.
%                            Non-empty path writes the corresponding output volume.
%   outputOpts.InfoLike    : optional NIfTI-info-like struct used as write template.
% Returns:
%   dBI3D_vol : backscatter volume (dB)
%   R3D_vol : retardance volume (degrees)
%   O3D_vol : optic axis orientation volume (degrees)

arguments
    J1 (:,:,:) {mustBeNumeric, mustBeNonempty}
    J2 (:,:,:) {mustBeNumeric, mustBeNonempty}
    volumeOpts.flipPhase (1,1) logical = false
    volumeOpts.phaseOffset (1,1) double = 100/180*pi
    volumeOpts.flipZ (1,1) logical = true
    outputOpts.Paths struct = struct()
    outputOpts.InfoLike struct = struct()
end

flipPhase = volumeOpts.flipPhase;
phaseOffset = volumeOpts.phaseOffset;
flipZ = volumeOpts.flipZ;

% Optional writes (no-op for empty paths)
paths = outputOpts.Paths;
paths = psoct.internal.paths.ensurePathField(paths, "dBI3D");
paths = psoct.internal.paths.ensurePathField(paths, "R3D");
paths = psoct.internal.paths.ensurePathField(paths, "O3D");

infoIn = psoct.internal.nifti.defaultNiftiHeader( ...
    outputOpts.InfoLike, size(J1), [0.01 0.01 0.025]);
writeFutures = {};

% Intensity and dB backscatter
IJones = abs(J1).^2 + abs(J2).^2;
dBI3D_vol = 10*log10(max(IJones, eps('single')));
if flipZ
    dBI3D_vol = flip(dBI3D_vol, 3);
end
writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
    psoct.internal.nifti.writeNiftiIfPath(paths.dBI3D, dBI3D_vol, infoIn));

% Retardance volume (degrees)
absJ1 = abs(J1);
absJ2 = abs(J2);
epsJ  = eps('single');
R3D_vol  = atan(absJ1 ./ max(absJ2, epsJ)) / pi * 180;
if flipZ
    R3D_vol = flip(R3D_vol, 3);
end
writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
    psoct.internal.nifti.writeNiftiIfPath(paths.R3D, R3D_vol, infoIn));

phase1 = angle(J1);
phase2 = angle(J2);
phi = phase1 - phase2;
if flipPhase
    phi = -phi;
end
if phaseOffset ~= 0
    phi = phi + phaseOffset*2;
end
phi(phi >  pi) = phi(phi >  pi) - 2*pi;
phi(phi < -pi) = phi(phi < -pi) + 2*pi;
O3D_vol = (phi / (2*pi)) * 180;
if flipZ
    O3D_vol = flip(O3D_vol, 3);
end
writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
    psoct.internal.nifti.writeNiftiIfPath(paths.O3D, O3D_vol, infoIn));
psoct.internal.nifti.waitWriteFutures(writeFutures);
end

