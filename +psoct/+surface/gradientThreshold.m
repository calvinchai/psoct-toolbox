function surf = gradientThreshold(inten, n, threshold, windowSize, kernelSize)
%GRADIENTTHRESHOLD Gradient surface method with leading-threshold check.
%
%   surf = psoct.surface.gradientThreshold(inten, n, threshold, windowSize, kernelSize)
%
%   If the mean of the first n pixels of an A-line is >= threshold, the
%   surface is set to the first pixel index where intensity >= threshold.
%   Otherwise, the method falls back to the gradient argmax approach used
%   by psoct.surface.gradient.
    arguments
        inten (:,:,:) {mustBeNumeric, mustBeNonempty}
        n (1,1) double {mustBeInteger, mustBePositive} = 20
        threshold (1,1) double {mustBeInteger, mustBePositive} = 55
        windowSize (1,1) double {mustBeInteger, mustBePositive} = 5
        kernelSize (1,1) double {mustBeInteger, mustBePositive} = 5
    end
    [nx, ny, ~] = size(inten);

    w  = windowSize;
    w2 = kernelSize;
    kernel = [-ones(1, w)/w, ones(1, w2)/w2];

    surf = zeros(nx, ny);

    for i = 1:nx
        for j = 1:ny
            line = squeeze(inten(i, j, :));
            valid_len = sum(line > 0.01);

            if valid_len <= 0
                surf(i, j) = 1;
                continue;
            end

            ncheck = min(n, valid_len);
            leadMean = mean(line(1:ncheck));
            if leadMean >= threshold
                firstIdx = find(line(1:valid_len) >= threshold, 1, 'first');
                if isempty(firstIdx)
                    surf(i, j) = 1;
                else
                    surf(i, j) = firstIdx;
                end
                continue;
            end

            if valid_len > w + w2
                data = imgaussfilt(line(1:valid_len), 5);
                grad = -conv(data, kernel, 'valid');
                positions = (w+1):(valid_len-w+1);
                [~, idx_min] = max(grad);
                i_min = positions(idx_min);
                surf(i, j) = i_min;
            else
                surf(i, j) = 1;
            end
        end
    end

    surf = medfilt2(surf, [3, 3], 'symmetric');
end
