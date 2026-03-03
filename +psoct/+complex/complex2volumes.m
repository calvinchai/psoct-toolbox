function [dBI3D_vol, R3D_vol, O3D_vol] = complex2volumes(J1, J2, flipPhase, phaseOffset, flipZ)
% complex2volumes Convert complex Jones volumes into PS-OCT metric volumes.
%
% J1 and J2 are complex-valued 3D arrays of size X × Y × Z representing the
% two Jones vector components.
% Returns backscatter (dBI3D_vol), retardance (R3D_vol), and optic axis
% orientation (O3D_vol) volumes.
%
% OPTIONAL:
%   flipPhase   : boolean, flip the phase of the optic axis orientation (default false).
%   phaseOffset : scalar, phase offset in radians (default 100/180*pi).
%   flipZ       : boolean, flip the volume along the z-axis (default true).
% Returns:
%   dBI3D_vol : backscatter volume (dB)
%   R3D_vol : retardance volume (degrees)
%   O3D_vol : optic axis orientation volume (degrees)

arguments
    J1 (:,:,:) {mustBeReal, mustBeNonempty}
    J2 (:,:,:) {mustBeReal, mustBeNonempty}
    flipPhase (1,1) boolean = false
    phaseOffset (1,1) double = 100/180*pi
    flipZ (1,1) boolean = true
end

% Intensity and dB backscatter
IJones = abs(J1).^2 + abs(J2).^2;
dBI3D_vol = 10*log10(max(IJones, eps('single')));

% Retardance volume (degrees)
absJ1 = abs(J1);
absJ2 = abs(J2);
epsJ  = eps('single');
R3D_vol  = atan(absJ1 ./ max(absJ2, epsJ)) / pi * 180;

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
    dBI3D_vol = flip(dBI3D_vol, 3);
    R3D_vol = flip(R3D_vol, 3);
    O3D_vol = flip(O3D_vol, 3);
end
end


