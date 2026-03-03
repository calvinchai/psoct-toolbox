function [J1, J2] = unpackComplexData(V)
% UNPACKCOMPLEXDATA Unpack complex J1 and J2 volumes from a stacked real/imag volume.
%
% V is a 3D array of size (4*X) × Y × Z, where the first dimension stacks
% [J1_real; J1_imag; J2_real; J2_imag].

% Inputs
%   V : 3D array of size (4*X) × Y × Z, where the first dimension stacks
%       [J1_real; J1_imag; J2_real; J2_imag].
%
% Outputs
%   J1 : complex array of size X × Y × Z.
%   J2 : complex array of size X × Y × Z.

arguments
    V (:,:,:) {mustBeReal, mustBeNonempty}
end

[nx, ~, ~] = size(V);
if mod(nx, 4) ~= 0
    error('psoct:unpackComplexData:invalidInput', ...
        'Input first dimension must be a multiple of 4: got %d.', nx);
end
nx = nx/4;

J1r = V(1:nx,         :, :);
J1i = V(nx+1:2*nx,    :, :);
J2r = V(2*nx+1:3*nx,  :, :);
J2i = V(3*nx+1:4*nx,  :, :);

J1  = complex(J1r, J1i);
J2  = complex(J2r, J2i);
end
