
function Complex2Processed(input, surfaceFile, depth, zSize, aip, mip, ret, ori, biref, O3D, R3D, dBI3D, oriMethod, birefMethod, unwrap,varargin)
% Complex2Processed
% Compute 3D metrics (dBI3D, R3D, O3D) and optional enface 2D maps (AIP, MIP, RET, ORI),
% plus optional birefringence from a single complex PS-OCT NIfTI volume.    
% INPUTS (use "" to skip any output you don't want):
%   input        : string, path to input complex NIfTI. Layout: 4*X × Y × Z
%                  where blocks along dim-1 are [J1_real; J1_imag; J2_real; J2_imag].
%   surfaceFile  : string, path to NIfTI with surface z-index (per X,Y). If "", assume 0.
%                  Indices are assumed 0-based; internally converted to MATLAB 1-based.
%   depth        : scalar nonneg int, #pixels below surface for enface window and biref fit.
%   zSize        : scalar >0, axial voxel size in micrometers; ONLY needed if biref output path is non-empty.
%   aip          : string, path to write AIP (mean dBI over [surf, surf+depth]). NIfTI.
%   mip          : string, path to write MIP (max dBI over [surf, surf+depth]). NIfTI.
%   ret          : string, path to write RET (mean R3D over [surf, surf+depth]) in degrees. NIfTI.
%   ori          : string, path to write ORI (circular mean O3D over [surf, surf+depth]) in degrees [0,180). NIfTI.
%   biref        : string, path to write birefringence Δn (slope of OPD vs depth) over window; NIfTI.
%   O3D          : string, path to write full 3D optic axis orientation (deg), flipped along z to match original script. NIfTI.
%   R3D          : string, path to write full 3D retardance (deg), flipped along z. NIfTI.
%   dBI3D        : string, path to write full 3D backscatter in dB, flipped along z. NIfTI.
%
% NAME-VALUE (optional):
%   "WavelengthUm" : wavelength in micrometers for birefringence fit of retardance (default 1.3).
%                    Only used if 'biref' path is provided.
%
% Example:
% Complex2Processed("complex.nii.gz","surf.nii.gz",100,3.3,"aip.nii.gz","", "", "", "biref.nii.gz", "", "", "");

    arguments
        input string
        surfaceFile string = ""
        depth (1,1) {mustBeInteger, mustBeNonnegative} = 100
        zSize (1,1) double {mustBePositive} = 1.0
        aip string = ""
        mip string = ""
        ret string = ""
        ori string = ""
        biref string = ""
        O3D string = ""
        R3D string = ""
        dBI3D string = ""
        oriMethod string = ""
        birefMethod string = ""
        unwrap (1,1) logical = false
    end
    arguments (Repeating)
        varargin
    end
    % Parse optional wavelength for birefringence (micrometers)
    p = inputParser;
    addParameter(p,"WavelengthUm",1.3, @(x)isnumeric(x)&&isscalar(x)&&x>0);
    parse(p,varargin{:});
    lambda_um = p.Results.WavelengthUm;

    % -------- Load input complex NIfTI --------
    infoIn = niftiinfo(input);
    V = niftiread(infoIn);               % single or double; dimensions: (4*X) × Y × Z
   
    %%
    % V = single(V);                       % enforce single precision downstream  
    %%
    
    % Infer dimensions and split Jones components
    X4 = size(V,1);
    if mod(X4,4)~=0
        error('Input first dimension must be a multiple of 4: got %d.', X4);
    end
    nx = X4/4; ny = size(V,2); nz = size(V,3);

    J1r = V(1:nx,         :, :);
    J1i = V(nx+1:2*nx,    :, :);
    J2r = V(2*nx+1:3*nx,  :, :);
    J2i = V(3*nx+1:4*nx,  :, :);

    J1  = complex(J1r, J1i);
    J2  = complex(J2r, J2i);

    clear V J1r J1i J2r J2i

    IJones = abs(J1).^2 + abs(J2).^2;
    dBI3D_vol =  flip(10*log10(max(IJones, eps('single'))),3);

    R3D_vol  = flip(atan( abs(J1)./max(abs(J2), eps('single')) )/pi*180,3);

    phase1 = angle(J1);
    phase2 = angle(J2);
    phi = (phase1 - phase2);                       % wrap to [-pi,pi]
    phi(phi >  pi) = phi(phi >  pi) - 2*pi;
    phi(phi < -pi) = phi(phi < -pi) + 2*pi;
    O3D_vol = flip((phi/(2*pi))*180,3);         % degrees, nominally [-90,90]

    % -------- Surface handling for enface & biref windows --------
    if strlength(surfaceFile) > 0
        surf = zeros(nx, ny);  % Output surface map
    
        w = 5;
        w2 = 5;
        kernel = [-ones(1, w)/w, ones(1, w2)/w2];  % Gradient kernel
    
        for i = 1:nx
            for j = 1:ny
                line = squeeze(inten(i, j, :) );
                % line = imgaussfilt( squeeze(inten(i, j, :) ) ,5);
                valid_len = sum(line > 0.01);
                norm_profile = squeeze(norms(i, j, 1:min(20, end)));  % match [:10] behavior
    
                if mean(norm_profile(:)) > 0.5
                    surf(i, j) = 1;  % override surface
                elseif (mean(line(1:min(10, end))) > prctile(line,80)) & mean(norm_profile(:)) > 0.30
                    surf(i, j) = 1;  % override surface
                elseif valid_len > w + w2
                    data = imgaussfilt(line(1:valid_len), 5);  % 1D Gaussian smoothing
                    grad = -conv(data, kernel, 'valid');
                    positions = (w+1):(valid_len-w+1);
                    [grad_min, idx_min] = max(grad);
                    i_min = positions(idx_min);
                    surf(i,j) = i_min;
                else
                    surf(i, j) = 1;
                end
            end
        end
    
        % Median filtering of surface map
        surf = medfilt2(surf, [3, 3],'symmetric');
    
        outliers = isoutlier(surf);
        surf( outliers ) = int32(mean( surf(~outliers) ));

        % surf = single(niftiread(surfaceFile));     % expected X × Y of 0-based z-indices
        % if ~isequal(size(surf), [nx, ny])
        %     error('Surface size mismatch: expected %dx%d, got %s.', nx, ny, mat2str(size(surf)));
        % end

        % surf = surf + 11;                           % convert to MATLAB 1-based indexing
    else
        surf = ones(nx,ny,'single')*11;               % "0" → index 1 in MATLAB
    end

    % Clamp surfaces inside [1, nz]
    surf = max(1, min(nz, round(surf)));

    % Compute per-(x,y) window stop index
    stopIdx = min(nz, surf + depth);

    % -------- Write requested 3D outputs --------
    writeIfPath(dBI3D, dBI3D_vol, infoIn);
    writeIfPath(R3D,   R3D_vol,   infoIn);
    writeIfPath(O3D,   O3D_vol,   infoIn);
    if (unwrap)
        [Q,U,V,norms] = stokes_from_ori_ret(O3D_vol, R3D_vol, [3,3,10]);
        ORI = compute_volume_ori(Q, U, V, deg2rad(O3D_vol), dBI3D_vol, surf);
        O3D_vol = rad2deg(ORI);
        RET = deg2rad(R3D_vol);
        RET = compute_ret_lines(V, RET, surf);
        R3D_vol = rad2deg(RET);
        % surf(:,:) = 1;
    end 
    % -------- Enface 2D maps over [surf : surf+depth] --------
    
        % Pre-allocate slices per XY on demand
        if strlength(aip)>0 || strlength(mip)>0
            % AIP/MIP use dBI
            [aipMap, mipMap] = enfaceStat(dBI3D_vol, surf, stopIdx, ...
                                          strlength(aip)>0, strlength(mip)>0);
            writeIfPath(aip, aipMap, shrinkHeader(infoIn));
            writeIfPath(mip, mipMap, shrinkHeader(infoIn));
        end

        if strlength(ret)>0
            retMap = enfaceMean(R3D_vol, surf, stopIdx);      % degrees
            writeIfPath(ret, retMap, shrinkHeader(infoIn));
        end

        if strlength(ori)>0
            
            % if (unwrap)
            %     stopIdx(:,:) = 100;
            % end
            if (oriMethod == "new")
                oriMap = enfaceOrientation(O3D_vol, surf, stopIdx);
            else
                oriMap = orien_enface(O3D_vol,5);
            end
            writeIfPath(ori, oriMap, shrinkHeader(infoIn));
        end

        if strlength(biref)>0
            if ~(isscalar(zSize) && zSize>0)
                error('zSize must be provided and > 0 (micrometers) to compute biref.');
            end

            switch birefMethod
                case "new"
                    birefMap = fitBirefringenceNew(R3D_vol, dBI3D_vol, surf, stopIdx,zSize,  lambda_um);
                case "diff"
                    birefMap = diff_bi(R3D_vol, surf, stopIdx);
                case "fft"
                    birefMap = diff_fft(R3D_vol, surf, stopIdx,zSize,  lambda_um);
                case "unwrap_old"
                    birefMap = unwarp_old_fitting(R3D_vol, O3D_vol, dBI3D_vol, surf, stopIdx,zSize,  lambda_um);
                case "unwrap_new"
                    birefMap = unwarp_new_fitting(R3D_vol, O3D_vol, dBI3D_vol, surf, stopIdx,zSize,  lambda_um);
                case "exp"
                    birefMap = unwarp_exp(R3D_vol, O3D_vol, dBI3D_vol, surf, stopIdx,zSize,  lambda_um);
                case "exp2"
                    birefMap = unwarp_exp_new_fitting(R3D_vol, O3D_vol, dBI3D_vol, surf, stopIdx,zSize,  lambda_um);
                case ""
                    birefMap = fitBirefringence(R3D_vol, surf, stopIdx, zSize, lambda_um);
            end 
            
            writeIfPath(biref, birefMap, shrinkHeader(infoIn));
        end

    
end

% ================== Helpers ==================
function writeIfPath(pathStr, data, infoLike)
    if strlength(pathStr) == 0 || isempty(pathStr), return; end

    % ---- Normalize class (NIfTI has no logical) ----
    if islogical(data)
        data = uint8(data);  % 0/1
    end

    % ---- Build output header from input ----
    infoOut = infoLike;

    % Dimension fixups
    sz = size(data);
    nDims = ndims(data);
    infoOut.ImageSize = sz;

    % PixelDimensions length must match dims
    if isfield(infoOut, 'PixelDimensions')
        pd = infoOut.PixelDimensions;
        if numel(pd) < nDims, pd(end+1:nDims) = 1; end
        if numel(pd) > nDims, pd = pd(1:nDims); end
        infoOut.PixelDimensions = pd;
    end

    % ---- Datatype/BitsPerPixel must match class(data) ----
    [dtype, bpp, dtcode] = class2niftiMeta(class(data));
    infoOut.Datatype     = dtype;
    infoOut.BitsPerPixel = bpp;

    % Raw fields
    if ~isfield(infoOut,'Raw'), infoOut.Raw = struct; end
    if ~isfield(infoOut.Raw,'dim'),    infoOut.Raw.dim    = ones(1,8); end
    if ~isfield(infoOut.Raw,'pixdim'), infoOut.Raw.pixdim = ones(1,8); end

    infoOut.Raw.dim(:) = 1;
    infoOut.Raw.dim(1) = nDims;                 % number of dims
    infoOut.Raw.dim(2:1+numel(sz)) = sz;

    infoOut.Raw.pixdim(:) = 1;
    if isfield(infoOut,'PixelDimensions') && ~isempty(infoOut.PixelDimensions)
        infoOut.Raw.pixdim(2:1+numel(infoOut.PixelDimensions)) = infoOut.PixelDimensions;
    end

    infoOut.Raw.datatype = dtcode;              % NIfTI datatype code (e.g., 16 for FLOAT32)
    infoOut.Raw.bitpix   = bpp;

    % Write
    isgz = endsWith(string(pathStr), ".nii.gz");
    niftiwrite(data, pathStr, infoOut, 'Compressed', isgz);
end

% ---- Helper: map MATLAB class -> NIfTI meta ----
function [dtype, bpp, dtcode] = class2niftiMeta(cls)
    switch cls
        case 'uint8',   dtype='uint8';   bpp=8;  dtcode=2;
        case 'int16',   dtype='int16';   bpp=16; dtcode=4;
        case 'int32',   dtype='int32';   bpp=32; dtcode=8;
        case 'single',  dtype='single';  bpp=32; dtcode=16;   % FLOAT32
        case 'double',  dtype='double';  bpp=64; dtcode=64;   % FLOAT64
        case 'int8',    dtype='int8';    bpp=8;  dtcode=256;
        case 'uint16',  dtype='uint16';  bpp=16; dtcode=512;
        case 'uint32',  dtype='uint32';  bpp=32; dtcode=768;
        case 'int64',   dtype='int64';   bpp=64; dtcode=1024;
        case 'uint64',  dtype='uint64';  bpp=64; dtcode=1280;
        otherwise
            error('Unsupported data class for NIfTI: %s', cls);
    end
end

function info2 = shrinkHeader(infoIn)
    % Make a 2D-compatible header derived from the input header.
    info2 = infoIn;
    info2.ImageSize = infoIn.ImageSize(1:2);
    if isfield(info2,'PixelDimensions') && numel(info2.PixelDimensions)>=2
        info2.PixelDimensions = info2.PixelDimensions(1:2);
    end
    if isfield(info2,'Raw') && isfield(info2.Raw,'dim')
        info2.Raw.dim(1) = 2;          % number of dims
        info2.Raw.dim(2) = infoIn.ImageSize(1);
        info2.Raw.dim(3) = infoIn.ImageSize(2);
        info2.Raw.dim(4) = 1;
        info2.Raw.pixdim(1) = 1;
        info2.Raw.pixdim(2) = info2.PixelDimensions(1);
        info2.Raw.pixdim(3) = info2.PixelDimensions(2);
        info2.Raw.pixdim(4) = 1;
    end
end

function [aipMap, mipMap] = enfaceStat(vol, surf, stopIdx, doAIP, doMIP)
    nx = size(vol,1); ny = size(vol,2);
    if doAIP, aipMap = zeros(nx,ny,'single'); else, aipMap = []; end
    if doMIP, mipMap = zeros(nx,ny,'single'); else, mipMap = []; end

    for x = 1:nx
        for y = 1:ny
            z1 = surf(x,y);
            z2 = stopIdx(x,y);
            if z2 < z1, z2 = z1; end
            slice = vol(x,y,z1:z2);
            if doAIP
                aipMap(x,y) = mean(slice,'omitnan');
            end
            if doMIP
                mipMap(x,y) = max(slice,[],'omitnan');
            end
        end
    end
end

function retMap = enfaceMean(volDeg, surf, stopIdx)
    nx = size(volDeg,1); ny = size(volDeg,2);
    retMap = zeros(nx,ny,'single');
    for x = 1:nx
        for y = 1:ny
            z1 = surf(x,y); z2 = stopIdx(x,y);
            if z2 < z1, z2 = z1; end
            retMap(x,y) = mean( volDeg(x,y,z1:z2), 'omitnan' );
        end
    end
end

function oriMap = enfaceOrientation(O3D_deg, surf, stopIdx)
    % Circular mean of 180°-periodic orientations using doubled-angle trick.
    nx = size(O3D_deg,1); ny = size(O3D_deg,2);
    oriMap = zeros(nx,ny,'single');
    disp("new orientation method")
    for i = 1:nx
        for j = 1:ny
            z1 = surf(i,j); z2 = stopIdx(i,j);
            if z2 < z1, z2 = z1; end
            theta = 2*deg2rad(squeeze(O3D_deg(i,j,z1:z2))); % why multiplied by 2
            x = cos(theta);
            y = sin(theta);                     
            mean_angle = atan2(sum(y), sum(x));
            oriMap(i,j) = mean_angle / 2 / pi * 180;
        end
    end
end

function birefMap = fitBirefringence(R3D_deg, surf, stopIdx, zSize_um, lambda_um)
    % Fit slope of OPD (cycles*lambda) vs depth to estimate Δn.
    % R3D_deg is retardance in degrees; convert to cycles: R/360.
    % OPD (um) = (R/360)*lambda_um. Slope(OPD vs depth) ≈ Δn.
    nx = size(R3D_deg,1); ny = size(R3D_deg,2);
    birefMap = zeros(nx,ny,'single'); % single again
    
    for x = 1:nx
        for y = 1:ny
            z1 = surf(x,y); z2 = stopIdx(x,y);
            if z2 < z1, z2 = z1; end
            rp = squeeze(R3D_deg(x,y,z1:z2));
            % Stop early if zeros (e.g., crop) appear
            zZeros = find(rp==0,1,'first');
            if ~isempty(zZeros)
                rp = rp(1:zZeros);
                z2 = z1 + numel(rp) - 1;
            end
            cycles = rp / 360;
            OPD = cycles * lambda_um;                 % micrometers
            depth_um = zSize_um * (0:numel(OPD)-1)';  % relative to z1

            if numel(OPD) >= 3 && any(OPD) && any(depth_um)
                p = polyfit(double(depth_um), double(OPD), 1);  % slope ~ Δn (unitless)
                birefMap(x,y) = single(p(1));
            else
                birefMap(x,y) = 0;
            end
        end
    end
end

function birefMap = fitBirefringenceNew(R3D_deg, inten, surf, stopIdx,zSize_um, lambda_um)
    % Fit slope of OPD (cycles*lambda) vs depth to estimate Δn.
    % R3D_deg is retardance in degrees; convert to cycles: R/360.
    % OPD (um) = (R/360)*lambda_um. Slope(OPD vs depth) ≈ Δn.
    [nx, ny, nz] = size(R3D_deg);
    birefMap = zeros(nx,ny,'single');
    RET = R3D_deg / 180 * pi;
    depth_per_pixel = zSize_um;
    for i = 1:nx
        for j = 1:ny
            z1 = surf(i,j); z2 = stopIdx(i,j);
            depth = z2-z1;
            if z2 < z1, z2 = z1; end
            remaining = sum(inten(i,j,:) > 0.01) - surf(i,j);
            if remaining > depth
                base_len = 40;
                iter_len = 60;
                endind = base_len + iter_len;
            elseif remaining > 40
                base_len = 40;
                iter_len = remaining - 40;
                endind = base_len + iter_len - 1;
            elseif remaining > 0
                base_len = remaining;
                iter_len = 5;
                endind = base_len - 1;
            else
                biref(i,j) = 0;
                continue;
            end
            start_idx = max(1, z1);
            end_idx = min(nz, z1 + endind);
            ret_line = squeeze(RET(i,j, start_idx+1:end_idx));
            slopes = [];
            for tempi = 0:5:(iter_len-1)
                endcut = base_len + tempi;
                endcut = min(endcut, length(ret_line));
                y = squeeze(ret_line(1:endcut)) * lambda_um / (2 * pi * zSize_um);
                sy=size(y);
                if sy(2)==1;
                    y=y';
                end
                x = 0:(length(y)-1);

                y_mean = mean(y);
                x_mean = mean(x);
                numer = sum( squeeze(x - x_mean) .* squeeze(y - y_mean) );

                denom = sum((x - x_mean).^2);
                slope = abs(numer / denom);
                slopes(end+1) = slope;
            end
    
            if ~isempty(slopes)
                birefMap(i,j) = prctile(slopes, 95);  % Use 95th percentile
            else
                birefMap(i,j) = 0;
            end
        end
    end
end

function birefMap = diff_bi(R3D_deg, surf, stopIdx)
    % Fit slope of OPD (cycles*lambda) vs depth to estimate Δn.
    % R3D_deg is retardance in degrees; convert to cycles: R/360.
    % OPD (um) = (R/360)*lambda_um. Slope(OPD vs depth) ≈ Δn.
    nx = size(R3D_deg,1); ny = size(R3D_deg,2);
    birefMap = zeros(nx,ny,'single'); % single again
    R3D = medfilt3(R3D_deg, [3 3 3]);
    for x = 1:nx
        for y = 1:ny
            z1 = surf(x,y); z2 = stopIdx(x,y);
            if z2 < z1, z2 = z1; end
            rp = squeeze(R3D_deg(x,y,z1:z2));
            % Stop early if zeros (e.g., crop) appear
            zZeros = find(rp==0,1,'first');
            if ~isempty(zZeros)
                rp = rp(1:zZeros);
                z2 = z1 + numel(rp) - 1;
            end
            cycles = rp / 180*pi/2.2;
            bi = diff(cycles, 1,1);
            bi(bi<0)  = 1e-9;
            birefMap(x,y) = nansum(bi);
            % OPD = cycles * lambda_um;                 % micrometers
            % depth_um = zSize_um * (0:numel(OPD)-1)';  % relative to z1
            % 
            % if numel(OPD) >= 3 && any(OPD) && any(depth_um)
            %     p = polyfit(double(depth_um), double(OPD), 1);  % slope ~ Δn (unitless)
            %     birefMap(x,y) = single(p(1));
            % else
            %     birefMap(x,y) = 0;
            % end
        end
    end
end

function birefMap = diff_fft(R3D_deg, surf, stopIdx,zSize_um, lambda_um)
    nx = size(R3D_deg,1); ny = size(R3D_deg,2);
    birefMap = zeros(nx,ny,'single'); % single again
    
    for x = 1:nx
        for y = 1:ny
            % if x== 175 && y==175
            %     disp(x)
            % end 
            z1 = surf(x,y); z2 = stopIdx(x,y);
            if z2 < z1, z2 = z1; end
            rp = squeeze(R3D_deg(x,y,z1:end));
            % Stop early if zeros (e.g., crop) appear
            zZeros = find(rp==0,1,'first');
            if ~isempty(zZeros)
                rp = rp(1:zZeros);
                z2 = z1 + numel(rp) - 1;
            end
            rp;
            rp = transform_dominant_component_trig(rp, 1, 0);
            if size(rp) > 110
                rp = rp(11:110);
            else
                rp = rp(11:end);
            end
            cycles = rp / 360;
            OPD = cycles * lambda_um;                 % micrometers
            depth_um = zSize_um * (0:numel(OPD)-1)';  % relative to z1

            if numel(OPD) >= 3 && any(OPD) && any(depth_um)
                p = polyfit(double(depth_um), double(OPD), 1);  % slope ~ Δn (unitless)
                birefMap(x,y) = single(p(1));
            else
                birefMap(x,y) = 0;
            end
        end
    end

end
function x_modified = transform_dominant_component_trig(x, fs, keep_bandwidth_bins)
% TRANSFORM_DOMINANT_COMPONENT_TRIG
%   x_modified = transform_dominant_component_trig(x, fs, keep_bandwidth_bins)
%
% Identifies the dominant (non-DC) FFT bin, synthesizes its analytic sinusoid
% A*cos(omega*t + phi), constructs a closed-form monotone (non-decreasing)
% transform of that sinusoid using trig properties (no numerical segmentation),
% and reconstructs the full signal:
%   x_modified = x - isolated_component + transformed_component.
%
% Inputs:
%   x                    - real-valued vector (time series)
%   fs                   - sampling frequency (default = 1)
%   keep_bandwidth_bins  - integer >=0, include +/- this many FFT bins when
%                          isolating the component for replacement (default = 0).
%                          If >0 the isolated component is multi-bin but the
%                          analytic mapping is applied to the principal bin.
%
% Output:
%   x_modified           - reconstructed time series (same size as x)
%
% Notes:
% - For best exactness set keep_bandwidth_bins = 0 (single-bin exact transform).
% - For even-length signals, Nyquist bin is handled by limiting search to positive
%   frequency bins (exclude DC).
%
% Example:
%   x = sin(2*pi*3*(0:999)/200) + 0.4*sin(2*pi*7*(0:999)/200);
%   y = transform_dominant_component_trig(x, 200, 0);

if nargin < 2 || isempty(fs)
    fs = 1;
end
if nargin < 3 || isempty(keep_bandwidth_bins)
    keep_bandwidth_bins = 0;
end

x = double(x(:));               % force column vector
N = numel(x);
if N <= 1
    x_modified = x;
    return
end

% --- FFT and dominant-bin selection (positive frequencies only) ---
X = fft(x);
% Power spectrum
power = abs(X).^2;

% positive frequency bins correspond to k = 1 .. floor(N/2)+1 (MATLAB 1-based)
% exclude DC (k = 1)
k_pos_max = floor(N/2) + 1;
k_search = 2:k_pos_max;  % exclude DC

% find dominant bin in the positive-frequency range
[~, idx_rel] = max(power(k_search));
dom_k = k_search(idx_rel);      % MATLAB 1-based index of dominant bin
freq_dom = (dom_k - 1) * fs / N;   % frequency in Hz
if freq_dom > 0.01
    % Too high-frequency dominant component: do nothing
    x_modified = x;
    return
end
% Optionally build mask that includes neighbors
lo_k = max(1, dom_k - keep_bandwidth_bins);
hi_k = min(N, dom_k + keep_bandwidth_bins);

X_masked = zeros(size(X));
X_masked(lo_k:hi_k) = X(lo_k:hi_k);

% isolated component in time domain (from masked FFT)
component = real(ifft(X_masked));

% --- derive amplitude, omega, phase for the single dominant bin (exact for single bin) ---
Xk = X(dom_k);
% For k not DC or Nyquist, time-domain amplitude A = 2*|Xk|/N
A = 2 * abs(Xk) / N;
omega = 2 * pi * freq_dom;
phi = angle(Xk);

% time vector
t = (0:(N-1))' / fs;

% represent as sine: s(t) = A * sin(theta_sin) where theta_sin = omega*t + phi + pi/2
theta = omega * t + phi;
theta_sin = theta + 0.5 * pi;

cos_theta_sin = cos(theta_sin);
sin_theta_sin = sin(theta_sin);

% raw mapping: if ascending (cos >= 0) keep A*sin; else reflect -> A*(2 - sin)
raw = zeros(size(sin_theta_sin));
asc_mask = (cos_theta_sin >= 0);
raw(asc_mask) = A * sin_theta_sin(asc_mask);
raw(~asc_mask) = A * (2 - sin_theta_sin(~asc_mask));

% analytic offsets: each completed descending interval increases baseline by 4A
count_completed_desc = floor((theta_sin + 0.5 * pi) / (2 * pi));
offsets = 4 * A * count_completed_desc;

transformed_single = raw + offsets;

% --- Reconstruct final signal ---
% Replace the isolated masked component with transformed_single.
% Note: if keep_bandwidth_bins > 0, the masked component may be multi-bin but
% we are replacing it with the transformed principal sinusoid approximation.
x_modified = x - component + transformed_single;

% restore shape
if isrow(x)
    x_modified = x_modified.';
    x_modified = x_modified.';
end

end

function [Q,U,V,norms] = stokes_from_ori_ret(O3D_deg, R3D_deg, sigma)
%STOKES_FROM_ORI_RET Build smoothed, normalized Stokes volumes from ORI/RET (deg).
%   [Q,U,V,norms] = stokes_from_ori_ret(O3D_deg, R3D_deg, sigma)
%   sigma can be scalar or 3-element vector for imgaussfilt3.

if nargin < 3, sigma = 3; end
ORI = deg2rad(O3D_deg);         % radians
RET = deg2rad(R3D_deg);

Q = imgaussfilt3( sin(2*ORI) .* sin(2*RET), sigma );
U = imgaussfilt3( cos(2*ORI) .* sin(2*RET), sigma );
V = imgaussfilt3( cos(2*RET),               sigma );

norms = sqrt(Q.^2 + U.^2 + V.^2) + eps('single');
Q = Q ./ norms;
U = U ./ norms;
V = V ./ norms;
end


function volume_ori = compute_volume_ori(Q, U, V, ORI, inten, surfaceIdx)
% COMPUTE_VOLUME_ORI  Build a {ny x nx} cell array of orientation profiles.
%
%   volume_ori = COMPUTE_VOLUME_ORI(U, Q, V, ORI, inten, surfaceIdx)
%
%   Inputs
%   ------
%   U, Q, V : 3D arrays sized [nx, ny, nz]
%       Stokes components (or related volumes). Only V is used for local
%       retardance; Q, U are used for phase selection.
%
%   ORI : 3D array [nx, ny, nz]
%       Reference orientation volume (used for initial segments and fallback).
%
%   inten : 3D array [nx, ny, nz]
%       Intensity volume used to determine valid length per A-line.
%
%   surfaceIdx : 2D array [nx, ny]
%       Surface index (per X,Y). NOTE: named surfaceIdx to avoid clashing
%       with MATLAB's SURF() plotting function.
%
%   Output
%   ------
%   volume_ori : {ny x nx} cell
%       Each cell contains a column vector of orientations for the [X,Y]
%       A-line after phase-flip correction and boundary enforcement.
%
%   Notes
%   -----
%   - This function removes the unused 'inputori' and the 'volume_ori_ref'
%     return. Behavior matches your original script.
%   - Uses prctile (Statistics & ML Toolbox). If unavailable, replace with
%     a simple percentile approximation.
%

    % Validate inputs (light)
    if ndims(U) ~= 3 || ~isequal(size(U), size(Q), size(V), size(ORI), size(inten))
        error('U, Q, V, ORI, inten must be 3D arrays of identical size [nx, ny, nz].');
    end
    if ~isequal(size(surfaceIdx), size(U(:,:,1)))
        error('surfaceIdx must be sized [nx, ny].');
    end

    [nx, ny, nz] = size(U);

    % Preallocate output; cell order is {Y, X} to match your comment
    volume_ori = cell(ny, nx);   % [Y, X]

    % Loop over Y (lays_a) and X (lays)
    for lays_a = 1:ny
        % Local retardance per X over Z for this Y
        inputret = acos(squeeze(V(:, lays_a, :)));   % [X, Z]

        for lays = 1:nx
            inten_line = squeeze(inten(lays, lays_a, :));  % [Z, 1]
            valid_len  = sum(inten_line > 0.01);

            % Surface index for this (X,Y)
            s = surfaceIdx(lays, lays_a);

            % Start index heuristic
            if (valid_len - s) > 10
                starts_ = round(s + 10);
            else
                starts_ = round(s);
            end

            % Preserve original quirk: special-case 10 => 0 (then clamped to 1)
            if starts_ == 10
                starts_ = 0;
            end

            % Boundaries
            starts_ = max(1, starts_);
            seg_len = min(valid_len - starts_, 120);
            ends_   = min(nz, starts_ + seg_len);

            if ends_ < starts_
                % Nothing valid; fall back to empty
                volume_ori{lays_a, lays} = [];
                continue;
            end

            % Extract slices
            actual_ori = squeeze(ORI(lays, lays_a, starts_:ends_));   % column
            q_seg      = squeeze(Q(lays, lays_a, starts_:ends_));
            u_seg      = squeeze(U(lays, lays_a, starts_:ends_));

            % Pick +/- based on dynamic range
            if (max(q_seg - u_seg) - min(q_seg - u_seg)) > (max(q_seg + u_seg) - min(q_seg + u_seg))
                pick_ = q_seg - u_seg;
            else
                pick_ = q_seg + u_seg;
            end

            % Local retardance and its (forward) gradient
            localret     = squeeze(inputret(lays, starts_:ends_));    % [Zseg, 1]
            localret     = localret(:);
            gradients_ret = [diff(localret); 0];                      % pad 1 at end

            % Phase flip logic
            if mean(pick_(gradients_ret > 0), 'omitnan') > 0
                idx = pick_ < 0;
                actual_ori(idx) = actual_ori(idx) + pi/2;
                over = actual_ori >  pi/2;
                actual_ori(over) = actual_ori(over) - pi;
            else
                idx = pick_ > 0;
                actual_ori(idx) = actual_ori(idx) + pi/2;
                over = actual_ori >  pi/2;
                actual_ori(over) = actual_ori(over) - pi;
            end

            % Enforce first 20 values from ORI
            copy_len = min(20, ends_ - starts_ + 1);
            actual_ori(1:copy_len) = squeeze(ORI(lays, lays_a, starts_:(starts_ + copy_len - 1)));

            % Fallback if local retardance is low
            % (using your original thresholding formula)
            if mean(localret(:) - prctile(localret(:), 1)) / 2 < pi/6
                actual_ori = squeeze(ORI(lays, lays_a, starts_:ends_));
            end

            % Store (note the {Y, X} order)
            volume_ori{lays_a, lays} = actual_ori(:);
        end
    end
    A = volume_ori;
    [ny, nx] = size(A);

% Find maximum length across all cells
maxLen = max(max(cellfun(@(c) size(c,1), A)));

% Preallocate numeric array with padding (NaN here)
M = nan(nx, ny, maxLen, 'single');

% Fill in values
for i = 1:nx
    for j = 1:ny
        v = A{j,i};
        L = length(v);
        M(i,j,1:L) = v;   % pad the rest with NaN
    end
end
volume_ori = M;
end



function ret_cell = compute_ret_lines(V, RET, surfaceIdx, winLen, pctLow, thresh)
% COMPUTE_RET_LINES  Build {ny x nx} cell of retardance lines near a surface.
%
%   ret_cell = COMPUTE_RET_LINES(V, RET, surfaceIdx, winLen, pctLow, thresh)
%
%   Inputs
%   ------
%   V          : [nx, ny, nz] volume
%   RET        : [nx, ny, nz] reference/estimated retardance (same size)
%   surfaceIdx : [nx, ny] start index per (x,y) A-line (1-based)
%   winLen     : (optional) number of samples after the surface (default 100)
%   pctLow     : (optional) percentile for low-end removal (default 1)
%   thresh     : (optional) mean(ret_raw - prctile) threshold (default pi/8)
%
%   Output
%   ------
%   ret_cell   : {ny x nx}, each cell is a column vector ret_line
%
%   Notes
%   -----
%   - Clamps V to [-1, 1] before acos to avoid NaNs from tiny numeric drift.
%   - If the computed end index < start, returns [] for that A-line.

    if nargin < 4 || isempty(winLen), winLen = 100; end
    if nargin < 5 || isempty(pctLow), pctLow = 1;   end
    if nargin < 6 || isempty(thresh), thresh = pi/8; end

    % Basic checks
    if ~isequal(size(V), size(RET))
        error('V and RET must have identical size [nx, ny, nz].');
    end
    [nx, ny, nz] = size(V);
    if ~isequal(size(surfaceIdx), [nx, ny])
        error('surfaceIdx must be [nx, ny].');
    end

    % Output (noting your original {Y, X} storage)
    ret_cell = cell(ny, nx);

    % Helper for safe acos
    safe_acos = @(x) acos(max(-1, min(1, x)));

    for i = 1:nx
        for j = 1:ny
            start_idx = round(surfaceIdx(i, j));
            if ~isfinite(start_idx)
                ret_cell{j, i} = [];
                continue;
            end

            % Boundaries
            start_idx = max(1, min(nz, start_idx));
            end_idx   = min(nz, start_idx + winLen);

            if end_idx < start_idx
                ret_cell{i, j} = [];
                continue;
            end

            % Segments
            Vseg   = squeeze(V(i, j, start_idx:end_idx));               % [Lx1]
            retRaw = safe_acos(Vseg) / 2;

            % Branch on low-variance criterion
            if mean(retRaw - prctile(retRaw, pctLow), 'omitnan') < thresh
                % Use RET directly (note the +1 shift like your original)
                if start_idx + 1 <= end_idx
                    ret_line = squeeze(RET(i, j, start_idx+1:end_idx));
                else
                    ret_line = []; % not enough samples
                end
            else
                % Vectorized cumulative build
                if start_idx + 1 <= end_idx
                    Vseg1 = squeeze(V(i, j, start_idx+1:end_idx));
                    Vseg0 = squeeze(V(i, j, start_idx:end_idx-1));
                    diffs = abs((safe_acos(Vseg1) - safe_acos(Vseg0)) / 2);
                    rstret = safe_acos(V(i, j, start_idx)) / 2;

                    % ret_build = [rstret; rstret + cumsum(diffs)]
                    ret_build = [rstret; rstret + cumsum(diffs(:))];

                    % Align and blend like your original expression
                    RETseg = squeeze(RET(i, j, start_idx:end_idx));
                    ret_line = ret_build(:) + RETseg(:) - retRaw(:);
                else
                    % If the window is a single point, mirror the original behavior
                    rstret  = safe_acos(V(i, j, start_idx)) / 2;
                    RETseg  = squeeze(RET(i, j, start_idx));
                    ret_line = rstret + RETseg - retRaw;
                end
            end

            % Store as column vector
            ret_cell{j, i} = ret_line(:);
        end
    end
    A=ret_cell;
    [ny, nx] = size(A);

% Find maximum length across all cells
maxLen = max(max(cellfun(@(c) size(c,1), A)));

% Preallocate numeric array with padding (NaN here)
M = nan(nx, ny, maxLen, 'single');

% Fill in values
for i = 1:nx
    for j = 1:ny
        v = A{j,i};
        L = length(v);
        M(i,j,1:L) = v;   % pad the rest with NaN
    end
end
ret_cell = M;
end

function birefMap = unwarp_old_fitting(R3D_deg, O3D_deg, inten, surf, stopIdx,zSize_um, lambda_um)
    % Fit slope of OPD (cycles*lambda) vs depth to estimate Δn.
    % R3D_deg is retardance in degrees; convert to cycles: R/360.
    % OPD (um) = (R/360)*lambda_um. Slope(OPD vs depth) ≈ Δn.
    [nx, ny, nz] = size(R3D_deg);
    birefMap = zeros(nx,ny,'single');
    RET = R3D_deg / 180 * pi;
    ORI = O3D_deg / 180 * pi;
    depth_per_pixel = zSize_um;
    Q = imgaussfilt3(sin(2 * ORI) .* sin(2 * RET), [1 1 5]);
    U = imgaussfilt3(cos(2 * ORI) .* sin(2 * RET), [1 1 5]);
    V = imgaussfilt3(cos(2 * RET), [1 1 5]);
    % Normalize the Stokes vectors
    norms = sqrt(Q.^2 + U.^2 + V.^2) + eps;  % eps to avoid divide-by-zero
    Q = Q ./ norms;
    U = U ./ norms;
    V = V ./ norms;
    for i = 1:nx
        for j = 1:ny
            surf_ij = round(surf(i,j));

            % Ensure we don’t go out of bounds
            start_idx = max(1, surf_ij);
            end_idx = min(nz, stopIdx(i,j));

            % Compute V-based retardance
            Vseg = squeeze(V(i, j, start_idx:end_idx));
            ret_raw = acos(Vseg) / 2;

            % Use RET directly if mean retardance < π/5
            if mean(ret_raw-prctile(ret_raw,1), 'omitnan') < pi/8
                % ret_line = squeeze(RET(i,j, start_idx+1:end_idx));
                ret_line = ret_raw;

            else
                Vseg1 = squeeze(V(i,j, start_idx+1:end_idx));
                Vseg0 = squeeze(V(i,j, start_idx:(end_idx-1)));
                diffs = abs((acos(Vseg1) - acos(Vseg0)) / 2);
                rstret = acos(V(i,j,start_idx)) / 2;
                ret_build = zeros(size(diffs)+[1,0]);
                ret_build(1) = rstret;

                for k = 1:length(diffs)
                    ret_build(k+1) = ret_build(k) + diffs(k);
                end

                % ret_line = reshape( ret_build(:) ,[],1) + ...
                %     reshape( squeeze(RET(i,j,start_idx:end_idx))',[],1 ) - reshape( (acos(Vseg)/2),[],1);
                ret_line = reshape( ret_build(:) ,[],1) ;
            end
            rp = squeeze(ret_line(1:end));
            cycles = rp / pi / 2;
            OPD = cycles * lambda_um;                 % micrometers
            depth_um = zSize_um * (0:numel(OPD)-1)';  % relative to z1

            if numel(OPD) >= 3 && any(OPD) && any(depth_um)
                p = polyfit(double(depth_um), double(OPD), 1);  % slope ~ Δn (unitless)
                birefMap(i,j) = single(p(1));
            else
                birefMap(i,j) = 0;
            end

            % slopes = [];
            % for tempi = 0:5:(iter_len-1)
            %     endcut = base_len + tempi;
            %     endcut = min(endcut, length(ret_line));
            %     y = squeeze(ret_line(1:endcut)) * lambda / (2 * pi * depth_per_pixel);
            %     sy=size(y);
            %     if sy(2)==1;
            %         y=y';
            %     end
            %     x = 0:(length(y)-1);

            %     y_mean = mean(y);
            %     x_mean = mean(x);
            %     numer = sum( squeeze(x - x_mean) .* squeeze(y - y_mean) );

            %     denom = sum((x - x_mean).^2);
            %     slope = abs(numer / denom);
            %     slopes(end+1) = slope;
            % end

            % if ~isempty(slopes)
            %     biref(i,j) = prctile(slopes, 95);  % Use 80th percentile
            % else
            %     biref(i,j) = 0;
            % end
        end
    end
end



function birefMap = unwarp_exp(R3D_deg, O3D_deg, inten, surf, stopIdx,zSize_um, lambda_um)
    % Fit slope of OPD (cycles*lambda) vs depth to estimate Δn.
    % R3D_deg is retardance in degrees; convert to cycles: R/360.
    % OPD (um) = (R/360)*lambda_um. Slope(OPD vs depth) ≈ Δn.
    [nx, ny, nz] = size(R3D_deg);
    birefMap = zeros(nx,ny,'single');
    RET = R3D_deg / 180 * pi;
    ORI = O3D_deg / 180 * pi;
    depth_per_pixel = zSize_um;
    Q = imgaussfilt3(sin(2 * ORI) .* sin(2 * RET), [1 1 5]);
    U = imgaussfilt3(cos(2 * ORI) .* sin(2 * RET), [1 1 5]);
    V = imgaussfilt3(cos(2 * RET), [1 1 5]);
    V_raw = cos(2 * RET);
    % Normalize the Stokes vectors
    norms = sqrt(Q.^2 + U.^2 + V.^2) + eps;  % eps to avoid divide-by-zero
    Q = Q ./ norms;
    U = U ./ norms;
    V = V ./ norms;
    V_raw = V_raw ./ norms;
    for i = 1:nx
        for j = 1:ny
            surf_ij = round(surf(i,j));

            % Ensure we don’t go out of bounds
            start_idx = max(1, surf_ij);
            end_idx = min(nz, stopIdx(i,j));

            % Compute V-based retardance
            Vseg = squeeze(V_raw(i, j, start_idx:end_idx));
            ret_raw = acos(Vseg) / 2;
            
            % Use RET directly if mean retardance < π/5
            if false
                % ret_line = squeeze(RET(i,j, start_idx+1:end_idx));
                ret_line = ret_raw;

            else
                Vseg1 = squeeze(V(i,j, start_idx+1:end_idx));
                Vseg0 = squeeze(V(i,j, start_idx:(end_idx-1)));
                raw_diff = (acos(Vseg1) - acos(Vseg0)) / 2;
                diffs = abs(raw_diff);
                changed = (diffs - raw_diff);
                rstret = acos(V_raw(i,j,start_idx)) / 2;
                ret_build = zeros(size(diffs)+[1,0]);
                ret_build(1) = rstret;
                
                for k = 2:length(ret_raw)
                    ret_build(k) = ret_raw(k) + changed(k-1);
                end

                % ret_line = reshape( ret_build(:) ,[],1) + ...
                %     reshape( squeeze(RET(i,j,start_idx:end_idx))',[],1 ) - reshape( (acos(Vseg)/2),[],1);
                ret_line = reshape( ret_build(:) ,[],1) ;
            end
            rp = squeeze(ret_line(1:end));
            cycles = rp / pi / 2;
            OPD = cycles * lambda_um;                 % micrometers
            depth_um = zSize_um * (0:numel(OPD)-1)';  % relative to z1

            if numel(OPD) >= 3 && any(OPD) && any(depth_um)
                p = polyfit(double(depth_um), double(OPD), 1);  % slope ~ Δn (unitless)
                birefMap(i,j) = single(p(1));
            else
                birefMap(i,j) = 0;
            end

            % slopes = [];
            % for tempi = 0:5:(iter_len-1)
            %     endcut = base_len + tempi;
            %     endcut = min(endcut, length(ret_line));
            %     y = squeeze(ret_line(1:endcut)) * lambda / (2 * pi * depth_per_pixel);
            %     sy=size(y);
            %     if sy(2)==1;
            %         y=y';
            %     end
            %     x = 0:(length(y)-1);

            %     y_mean = mean(y);
            %     x_mean = mean(x);
            %     numer = sum( squeeze(x - x_mean) .* squeeze(y - y_mean) );

            %     denom = sum((x - x_mean).^2);
            %     slope = abs(numer / denom);
            %     slopes(end+1) = slope;
            % end

            % if ~isempty(slopes)
            %     biref(i,j) = prctile(slopes, 95);  % Use 80th percentile
            % else
            %     biref(i,j) = 0;
            % end
        end
    end
end



function birefMap = unwarp_new_fitting(R3D_deg, O3D_deg, inten, surf, stopIdx,zSize_um, lambda_um)
    % Fit slope of OPD (cycles*lambda) vs depth to estimate Δn.
    % R3D_deg is retardance in degrees; convert to cycles: R/360.
    % OPD (um) = (R/360)*lambda_um. Slope(OPD vs depth) ≈ Δn.
    [nx, ny, nz] = size(R3D_deg);
    birefMap = zeros(nx,ny,'single');
    RET = R3D_deg / 180 * pi;
    ORI = O3D_deg / 180 * pi;
    depth_per_pixel = zSize_um;
    lambda = lambda_um;
    Q = imgaussfilt3(sin(2 * ORI) .* sin(2 * RET), [3 3 10]);
    U = imgaussfilt3(cos(2 * ORI) .* sin(2 * RET), [3 3 10]);
    V = imgaussfilt3(cos(2 * RET), [3 3 10]);
    
    % Normalize the Stokes vectors
    norms = sqrt(Q.^2 + U.^2 + V.^2) + eps;  % eps to avoid divide-by-zero
    Q = Q ./ norms;
    U = U ./ norms;
    V = V ./ norms;

    for i = 1:nx
        for j = 1:ny
            surf_ij = round(surf(i,j));
            base_len = 40;
            iter_len = 40;
            % Ensure we don’t go out of bounds
            start_idx = max(1, surf_ij);
            end_idx = min(nz, stopIdx(i,j));

            % Compute V-based retardance
            Vseg = squeeze(V(i, j, start_idx:end_idx));
            ret_raw = acos(Vseg) / 2;

            % Use RET directly if mean retardance < π/5
            if mean(ret_raw-prctile(ret_raw,1), 'omitnan') < pi/8
                % ret_line = squeeze(RET(i,j, start_idx+1:end_idx));
                ret_line = ret_raw;

            else
                Vseg1 = squeeze(V(i,j, start_idx+1:end_idx));
                Vseg0 = squeeze(V(i,j, start_idx:(end_idx-1)));
                diffs = abs((acos(Vseg1) - acos(Vseg0)) / 2);
                rstret = acos(V(i,j,start_idx)) / 2;
                ret_build = zeros(size(diffs)+[1,0]);
                ret_build(1) = rstret;

                for k = 1:length(diffs)
                    ret_build(k+1) = ret_build(k) + diffs(k);
                end

                % ret_line = reshape( ret_build(:) ,[],1) + ...
                %     reshape( squeeze(RET(i,j,start_idx:end_idx))',[],1 ) - reshape( (acos(Vseg)/2),[],1);
                ret_line = reshape( ret_build(:) ,[],1) ;
            end

            slopes = [];
            for tempi = 0:5:(iter_len-1)
                endcut = base_len + tempi;
                endcut = min(endcut, length(ret_line));
                y = squeeze(ret_line(1:endcut)) * lambda / (2 * pi )/depth_per_pixel;
                sy=size(y);
                if sy(2)==1;
                    y=y';
                end
                x = 0:(length(y)-1);

                y_mean = mean(y);
                x_mean = mean(x);
                numer = sum( squeeze(x - x_mean) .* squeeze(y - y_mean) );

                denom = sum((x - x_mean).^2);
                slope = abs(numer / denom);
                slopes(end+1) = slope;
            end

            if ~isempty(slopes)
                birefMap(i,j) = prctile(slopes, 95);  % Use 80th percentile
            else
                birefMap(i,j) = 0;
            end
        end
    end
end





function birefMap = unwarp_exp_new_fitting(R3D_deg, O3D_deg, inten, surf, stopIdx,zSize_um, lambda_um)
    % Fit slope of OPD (cycles*lambda) vs depth to estimate Δn.
    % R3D_deg is retardance in degrees; convert to cycles: R/360.
    % OPD (um) = (R/360)*lambda_um. Slope(OPD vs depth) ≈ Δn.
    [nx, ny, nz] = size(R3D_deg);
    birefMap = zeros(nx,ny,'single');
    RET = R3D_deg / 180 * pi;
    ORI = O3D_deg / 180 * pi;
    depth_per_pixel = zSize_um;
    lambda = lambda_um;
    Q = imgaussfilt3(sin(2 * ORI) .* sin(2 * RET), [1 1 5]);
    U = imgaussfilt3(cos(2 * ORI) .* sin(2 * RET), [1 1 5]);
    V = imgaussfilt3(cos(2 * RET), [1 1 5]);
    V_raw = cos(2 * RET);
    % Normalize the Stokes vectors
    norms = sqrt(Q.^2 + U.^2 + V.^2) + eps;  % eps to avoid divide-by-zero
    Q = Q ./ norms;
    U = U ./ norms;
    V = V ./ norms;
    V_raw = V_raw ./ norms;
    for i = 1:nx
        for j = 1:ny
            surf_ij = round(surf(i,j));

            base_len = 80;
            iter_len = 30;
            % Ensure we don’t go out of bounds
            start_idx = max(1, surf_ij);
            end_idx = min(nz, stopIdx(i,j));

            % Compute V-based retardance
            Vseg = squeeze(V_raw(i, j, start_idx:end_idx));
            ret_raw = acos(Vseg) / 2;
            
            % Use RET directly if mean retardance < π/5
            if false
                % ret_line = squeeze(RET(i,j, start_idx+1:end_idx));
                ret_line = ret_raw;

            else
                Vseg1 = squeeze(V(i,j, start_idx+1:end_idx));
                Vseg0 = squeeze(V(i,j, start_idx:(end_idx-1)));
                raw_diff = (acos(Vseg1) - acos(Vseg0)) / 2;
                diffs = abs(raw_diff);
                changed = (diffs - raw_diff);
                rstret = acos(V_raw(i,j,start_idx)) / 2;
                ret_build = zeros(size(diffs)+[1,0]);
                ret_build(1) = rstret;
                
                for k = 2:length(ret_raw)
                    ret_build(k) = ret_raw(k) + changed(k-1);
                end

                % ret_line = reshape( ret_build(:) ,[],1) + ...
                %     reshape( squeeze(RET(i,j,start_idx:end_idx))',[],1 ) - reshape( (acos(Vseg)/2),[],1);
                ret_line = reshape( ret_build(:) ,[],1) ;
            end

            slopes = [];
            for tempi = 0:5:(iter_len-1)
                endcut = base_len + tempi;
                endcut = min(endcut, length(ret_line));
                y = squeeze(ret_line(1:endcut)) * lambda / (2 * pi )* depth_per_pixel;
                sy=size(y);
                if sy(2)==1;
                    y=y';
                end
                x = 0:(length(y)-1);

                y_mean = mean(y);
                x_mean = mean(x);
                numer = sum( squeeze(x - x_mean) .* squeeze(y - y_mean) );

                denom = sum((x - x_mean).^2);
                slope = abs(numer / denom);
                slopes(end+1) = slope;
            end

            if ~isempty(slopes)
                birefMap(i,j) = prctile(slopes, 95);  % Use 80th percentile
            else
                birefMap(i,j) = 0;
            end
        end
    end
end
