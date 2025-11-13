function RGB_3Daxis(basename, slice_nums)
% RGB_3Daxis(basename, slice_nums)
% Example: RGB_3Daxis('sample_', [1 5 10])

for i = 1:length(slice_nums)
    slice_num = slice_nums(i);
    
    % Construct file name for this slice
    datafile = sprintf('%spar_slice%d_data_0_100.mat', basename, slice_num);
    
    % Check file exists
    if ~isfile(datafile)
        warning('File not found: %s. Skipping...', datafile);
        continue;
    end

    % Load the data
    load(datafile);

    % Compute alpha (angle adjustment)
    alpha = pi/2 - Psi_ObsLSQ;
    alpha(alpha > pi/2) = alpha(alpha > pi/2) - pi;
    alpha(alpha < -pi/2) = alpha(alpha < -pi/2) + pi;

    % Normalize birefringence intensity
    I_B = (biref_ObsLSQ - prctile(biref_ObsLSQ(:), 1)) / prctile(biref_ObsLSQ(:), 20);
    I_B(I_B > 1) = 1;
    I_B(I_B < 0) = 0;

    % Convert spherical to Cartesian coordinates
    [X, Y, Z] = sph2cart(Theta_ObsLSQ, alpha, I_B);

    % Combine into RGB-like 3D vector field
    oct_vec_3d = cat(3, Y, Z, X);

    % Output filename
    outfile = sprintf('%s3daxis%d.jpg', basename, slice_num);

    % Write image
    imwrite(abs(oct_vec_3d), outfile);

    fprintf('Saved 3D axis image for slice %d: %s\n', slice_num, outfile);
end

end
