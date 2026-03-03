function out = complex2processed(J1, J2, surface, enfaceOffset, enfaceDepth, zSize, wavelength, oriMethod, birefMethod, options)
    % complex2processed
    % Compute 3D metrics (dBI3D, R3D, O3D) and optional enface 2D maps (AIP, MIP, RET, ORI),
    % plus optional birefringence from a single complex PS-OCT volume in memory.
    %
    %   out = psoct.recon.complex2processed(J1, J2)
    %
    % Inputs
    %   J1, J2       : complex 3D arrays (X × Y × Z), Jones vector components.
    %   surface      : surface specification understood by psoct.surface.findSurface
    %                  (numeric index, NIfTI path, or method name such as "gradient").
    %   enfaceOffset : starting offset (pixels) below the surface for enface/biref window.
    %   enfaceDepth  : window depth (pixels) for enface/biref calculations.
    %   zSize        : axial voxel size in micrometers (used for birefringence, NIfTI header).
    %   wavelength   : wavelength in micrometers for birefringence fit of retardance.
    %   oriMethod    : "circularMean"/"new" (preferred) or "legacy" (orien\_enface-based).
    %   birefMethod  : "new","diff","fft","unwrap\_old","unwrap\_new","exp","exp2","".
    %
    % Name-value options (options.*):
    %   options.OutputPrefix : string prefix used to auto-generate output paths when
    %                          options.Paths.<modality> is not provided.
    %   options.Paths        : struct of output paths for each modality. Fields:
    %                          dBI3D, R3D, O3D, biref, aip, mip, ret, ori, surf.
    %                          Leave empty or "" to skip writing that modality.
    %
    % Output
    %   out.paths : struct of resolved output paths for each modality.
    %   out.surf  : surface map used for processing (nx-by-ny).
    %
    arguments
        J1 (:,:,:) {mustBeNumeric, mustBeNonempty}
        J2 (:,:,:) {mustBeNumeric, mustBeNonempty}
        surface = "gradient"
        enfaceOffset = 0
        enfaceDepth = 70
        zSize = 0.025
        wavelength = 1.3
        oriMethod = "circularMean"
        birefMethod = "new"
        options.OutputPrefix string = ""
        options.Paths struct = struct()
    end

    % -------- Resolve wavelength/zSize to numeric --------
    if isstring(wavelength) || ischar(wavelength)
        lambda_um = str2double(wavelength);
    else
        lambda_um = double(wavelength);
    end

    if isnumeric(zSize)
        zSize_um = double(zSize);
    else
        zSize_um = str2double(zSize);
    end

    % -------- Convert complex stack into PS-OCT metric volumes --------
    [dBI3D_vol, R3D_vol, O3D_vol] = psoct.complex.complex2volumes(J1, J2);
    inten = dBI3D_vol;
    [nx, ny, nz] = size(dBI3D_vol);

    % -------- Surface and window indices --------
    surf = psoct.surface.findSurface(surface, inten);
    surf = max(1, min(nz, round(surf)));

    startIdx = surf + enfaceOffset;
    startIdx = max(1, min(nz, startIdx));
    stopIdx  = startIdx + enfaceDepth;
    stopIdx  = max(startIdx, min(nz, stopIdx));

    % -------- Build minimal header template --------
    infoIn = struct();
    infoIn.ImageSize = size(dBI3D_vol);
    infoIn.PixelDimensions = [1 1 zSize_um];

    % -------- Resolve output paths into a struct --------
    paths = options.Paths;
    prefix = options.OutputPrefix;

    paths = ensurePathField(paths, "dBI3D",  prefix, "_dBI.nii");
    paths = ensurePathField(paths, "R3D",    prefix, "_R3D.nii");
    paths = ensurePathField(paths, "O3D",    prefix, "_O3D.nii");
    paths = ensurePathField(paths, "biref",  prefix, "_biref.nii");
    paths = ensurePathField(paths, "aip",    prefix, "_aip.nii");
    paths = ensurePathField(paths, "mip",    prefix, "_mip.nii");
    paths = ensurePathField(paths, "ret",    prefix, "_ret.nii");
    paths = ensurePathField(paths, "ori",    prefix, "_ori.nii");
    paths = ensurePathField(paths, "surf",   prefix, "_surf.nii");

    % -------- Write requested 3D outputs --------
    writeIfPath(paths.surf,  surf,      shrinkHeader(infoIn));
    writeIfPath(paths.dBI3D, dBI3D_vol, infoIn);
    writeIfPath(paths.R3D,   R3D_vol,   infoIn);
    writeIfPath(paths.O3D,   O3D_vol,   infoIn);

    % -------- Enface 2D maps over [startIdx : stopIdx] --------

    if strlength(paths.aip) > 0 || strlength(paths.mip) > 0
        [aipMap, mipMap] = enfaceStat(dBI3D_vol, startIdx, stopIdx, ...
                                      strlength(paths.aip) > 0, ...
                                      strlength(paths.mip) > 0);
        writeIfPath(paths.aip, aipMap, shrinkHeader(infoIn));
        writeIfPath(paths.mip, mipMap, shrinkHeader(infoIn));
    end

    if strlength(paths.ret) > 0
        retMap = enfaceMean(R3D_vol, startIdx, stopIdx);      % degrees
        writeIfPath(paths.ret, retMap, shrinkHeader(infoIn));
    end

    if strlength(paths.ori) > 0
        if (oriMethod == "circularMean" || oriMethod == "new")
            oriMap = psoct.enface.stat.enfaceCircularMean(O3D_vol, startIdx, stopIdx);
        else
            for i = 1:nx
                for j = 1:ny
                    O3D_vol_tmp(i,j,:) = squeeze(O3D_vol(i,j,startIdx(i,j):stopIdx(i,j)));
                end
            end
            oriMap = orien_enface(O3D_vol_tmp, 3);
        end
        writeIfPath(paths.ori, oriMap, shrinkHeader(infoIn));
    end

    if strlength(paths.biref) > 0
        if ~(isscalar(zSize_um) && zSize_um > 0)
            error('zSize must be provided and > 0 (micrometers) to compute biref.');
        end

        switch birefMethod
            case "new"
                birefMap = fitBirefringenceNew(R3D_vol, dBI3D_vol, startIdx, stopIdx, zSize_um, lambda_um);
            case "diff"
                birefMap = diff_bi(R3D_vol, startIdx, stopIdx);
            case "fft"
                birefMap = diff_fft(R3D_vol, startIdx, stopIdx, zSize_um, lambda_um);
            case "unwrap_old"
                birefMap = unwarp_old_fitting(R3D_vol, O3D_vol, dBI3D_vol, startIdx, stopIdx, zSize_um, lambda_um);
            case "unwrap_new"
                birefMap = unwarp_new_fitting(R3D_vol, O3D_vol, dBI3D_vol, startIdx, stopIdx, zSize_um, lambda_um);
            case "exp"
                birefMap = unwarp_exp(R3D_vol, O3D_vol, dBI3D_vol, startIdx, stopIdx, zSize_um, lambda_um);
            case "exp2"
                birefMap = unwarp_exp_new_fitting(R3D_vol, O3D_vol, dBI3D_vol, startIdx, stopIdx, zSize_um, lambda_um);
            case ""
                birefMap = fitBirefringence(R3D_vol, startIdx, stopIdx, zSize_um, lambda_um);
            otherwise
                error('Unknown birefMethod "%s".', birefMethod);
        end
        writeIfPath(paths.biref, birefMap, shrinkHeader(infoIn));
    end

    % -------- Package outputs --------
    out.paths = paths;
    out.surf  = surf;
    
    % ================== Helpers ==================
    function paths = ensurePathField(paths, fieldName, prefix, suffix)
        if ~isfield(paths, fieldName) || strlength(string(paths.(fieldName))) == 0
            if strlength(prefix) > 0
                paths.(fieldName) = prefix + suffix;
            else
                paths.(fieldName) = "";
            end
        end
    end
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
    
    % enfaceOrientation has been refactored into the shared helper
    % psoct.enface.stat.enfaceCircularMean.
    
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
    