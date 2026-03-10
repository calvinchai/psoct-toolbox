function surf = gradient(inten, windowSize, kernelSize)
%GRADIENT Gradient-based surface finding method.
%   
%   surf = psoct.surface.gradient(inten, windowSize=5, kernelSize=5)
%
%   Uses a 1D gradient kernel along the axial (z) direction with Gaussian
%   smoothing, followed by a 2D median filter on the resulting surface map.
%
%   NAME-VALUE (optional):
%   "windowSize" : scalar, window size for gradient calculation (default 5).
%   "kernelSize" : scalar, kernel size for gradient calculation (default 5).
    arguments
        inten (:,:,:) {mustBeNumeric, mustBeNonempty}
        windowSize (1,1) double {mustBeInteger, mustBePositive} = 5
        kernelSize (1,1) double {mustBeInteger, mustBePositive} = 5
    end
    [nx, ny, nz] = size(inten);

    w  = windowSize;
    w2 = kernelSize;
    kernel = [-ones(1, w)/w, ones(1, w2)/w2];  

    surf = zeros(nx, ny);  % Output surface map

    for i = 1:nx
        for j = 1:ny
            line = squeeze(inten(i, j, :));
            valid_len = sum(line > 0.01);
            if valid_len > w + w2
                data = imgaussfilt(line(1:valid_len), 5);  
                grad = -conv(data, kernel, 'valid');
                positions = (w+1):(valid_len-w+1);
                [~, idx_min] = max(grad);
                i_min = positions(idx_min);
                surf(i,j) = i_min;
            else
                surf(i, j) = 1;
            end
        end
    end

    % Median filtering of surface map
    surf = medfilt2(surf, [3, 3], 'symmetric');
end

