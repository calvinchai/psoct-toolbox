function [dBI3D_vol, R3D_vol, O3D_vol] = complex2volumes(V, flipPhase=false, phaseOffset=100/180*pi)
% complex2volumes Convert stacked Jones real/imag volume into PS-OCT metric volumes.
%
% V is a 3D array of size (4*X) × Y × Z, where the first dimension stacks
% [J1_real; J1_imag; J2_real; J2_imag].
% Returns backscatter (dBI3D_vol), retardance (R3D_vol), and optic axis
% orientation (O3D_vol) volumes, along with an intensity alias (inten) and
% the inferred spatial dimensions nx, ny, nz.
%
% NAME-VALUE (optional):
%   "flipPhase" : boolean, flip the phase of the optic axis orientation (default false).
%   "phaseOffset" : scalar, phase offset in radians (default 100/180*pi).

    % Infer dimensions and split Jones components
    X4 = size(V, 1);
    if mod(X4, 4) ~= 0
        error('Input first dimension must be a multiple of 4: got %d.', X4);
    end
    nx = X4/4; 
    ny = size(V, 2); 
    nz = size(V, 3);

    J1r = V(1:nx,         :, :);
    J1i = V(nx+1:2*nx,    :, :);
    J2r = V(2*nx+1:3*nx,  :, :);
    J2i = V(3*nx+1:4*nx,  :, :);

    J1  = complex(J1r, J1i);
    J2  = complex(J2r, J2i);

    % Intensity and dB backscatter
    IJones = abs(J1).^2 + abs(J2).^2;
    dBI3D_vol = flip(10*log10(max(IJones, eps('single'))), 3);

    % Retardance volume (degrees)
    R3D_vol  = flip(atan(abs(J1) ./ max(abs(J2), eps('single'))) / pi * 180, 3);

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
    O3D_vol = flip((phi / (2*pi)) * 180, 3);

end

