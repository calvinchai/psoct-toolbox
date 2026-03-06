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
    %   oriMethod    : "circularMean" (preferred) or "legacy" (mean fallback).
    %   birefMethod  : "legacy"(default),"fft","unwrap\_old","unwrap\_new","exp","".
    %
    % Name-value options (options.*):
    %   options.OutputPrefix : string prefix used to auto-generate output paths when
    %                          options.Paths.<modality> is not provided.
    %   options.Paths        : struct of output paths for each modality. Fields:
    %                          dBI3D, R3D, O3D, biref, aip, mip, ret, ori, surf.
    %                          Leave empty or "" to skip writing that modality.
%   options.Save2DAs3D   : if true, write 2D outputs (e.g., surf/enface maps)
%                          as X-by-Y-by-1 NIfTI.
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
        birefMethod = "legacy"
        options.OutputPrefix string = ""
        options.Paths struct = struct()
        options.Save2DAs3D (1,1) logical = false
    end

    % -------- Resolve wavelength/zSize to numeric --------
    if isstring(wavelength) || ischar(wavelength)
        wavelengthUm = str2double(wavelength);
    else
        wavelengthUm = double(wavelength);
    end

    if isnumeric(zSize)
        zSizeUm = double(zSize);
    else
        zSizeUm = str2double(zSize);
    end

    % -------- Convert complex stack into PS-OCT metric volumes --------
    [dBI3D_vol, R3D_vol, O3D_vol] = psoct.complex.complex2volumes(J1, J2);
    inten = dBI3D_vol;
    [~, ~, nz] = size(dBI3D_vol);

    % -------- Surface and window indices --------
    surf = psoct.surface.findSurface(surface, inten);
    surf = max(1, min(nz, round(surf)));

    % -------- Build minimal header template --------
    infoIn = psoct.internal.nifti.defaultNiftiHeader( ...
        struct(), size(dBI3D_vol), [0.01 0.01 zSizeUm/1000]);

    % -------- Resolve output paths into a struct --------
    paths = options.Paths;
    prefix = options.OutputPrefix;

    paths = psoct.internal.paths.ensurePathField(paths, "dBI3D", autoPath(prefix, "_dBI.nii"));
    paths = psoct.internal.paths.ensurePathField(paths, "R3D", autoPath(prefix, "_R3D.nii"));
    paths = psoct.internal.paths.ensurePathField(paths, "O3D", autoPath(prefix, "_O3D.nii"));
    paths = psoct.internal.paths.ensurePathField(paths, "biref", autoPath(prefix, "_biref.nii"));
    paths = psoct.internal.paths.ensurePathField(paths, "aip", autoPath(prefix, "_aip.nii"));
    paths = psoct.internal.paths.ensurePathField(paths, "mip", autoPath(prefix, "_mip.nii"));
    paths = psoct.internal.paths.ensurePathField(paths, "ret", autoPath(prefix, "_ret.nii"));
    paths = psoct.internal.paths.ensurePathField(paths, "ori", autoPath(prefix, "_ori.nii"));
    paths = psoct.internal.paths.ensurePathField(paths, "surf", autoPath(prefix, "_surf.nii"));

    % -------- Write requested 3D outputs --------
    writeOpts = struct("Expand2DTo3D", options.Save2DAs3D);
    writeFutures = {};
    writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
        psoct.internal.nifti.writeNiftiIfPath(paths.surf, surf, shrinkHeader(infoIn), writeOpts));
    writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
        psoct.internal.nifti.writeNiftiIfPath(paths.dBI3D, dBI3D_vol, infoIn, writeOpts));
    writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
        psoct.internal.nifti.writeNiftiIfPath(paths.R3D, R3D_vol, infoIn, writeOpts));
    writeFutures = psoct.internal.nifti.appendWriteFuture(writeFutures, ...
        psoct.internal.nifti.writeNiftiIfPath(paths.O3D, O3D_vol, infoIn, writeOpts));

    % -------- Enface wrapper (compute + write) --------
    enfaceOpts = struct();
    enfaceOpts.OriMethod = oriMethod;
    enfaceOpts.BirefMethod = birefMethod;
    enfaceOpts.InfoLike = infoIn;
    enfaceOpts.Save2DAs3D = options.Save2DAs3D;
    enfaceOpts.Paths = struct( ...
        "aip", paths.aip, ...
        "mip", paths.mip, ...
        "ret", paths.ret, ...
        "ori", paths.ori, ...
        "biref", paths.biref);
    enfaceOpts.Compute = struct( ...
        "aip", strlength(paths.aip) > 0, ...
        "mip", strlength(paths.mip) > 0, ...
        "ret", strlength(paths.ret) > 0, ...
        "ori", strlength(paths.ori) > 0, ...
        "biref", strlength(paths.biref) > 0);

    psoct.enface.vol2enface( ...
        dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOffset, enfaceDepth, zSizeUm, wavelengthUm, enfaceOpts);

    psoct.internal.nifti.waitWriteFutures(writeFutures);

    % -------- Package outputs --------
    out.paths = paths;
    out.surf  = surf;
    
    % ================== Helpers ==================
    function pathOut = autoPath(prefix, suffix)
        if strlength(prefix) > 0
            pathOut = prefix + suffix;
        else
            pathOut = "";
        end
    end
    function info2 = shrinkHeader(infoIn)
        % Make a 2D-compatible header derived from the input header.
        info2 = infoIn;
        expand2DTo3D = writeOpts.Expand2DTo3D;
        if expand2DTo3D
            info2.ImageSize = [infoIn.ImageSize(1:2), 1];
        else
            info2.ImageSize = infoIn.ImageSize(1:2);
        end
        if isfield(info2,'PixelDimensions') && numel(info2.PixelDimensions)>=2
            pd = info2.PixelDimensions(1:2);
        else
            pd = [1 1];
        end
        if expand2DTo3D
            if isfield(infoIn,'PixelDimensions') && numel(infoIn.PixelDimensions)>=3
                pd(3) = infoIn.PixelDimensions(3);
            else
                pd(3) = 1;
            end
        end
        info2.PixelDimensions = pd;
        if isfield(info2,'Raw') && isfield(info2.Raw,'dim')
            if expand2DTo3D
                info2.Raw.dim(1) = 3;          % number of dims
                info2.Raw.dim(2) = infoIn.ImageSize(1);
                info2.Raw.dim(3) = infoIn.ImageSize(2);
                info2.Raw.dim(4) = 1;
            else
                info2.Raw.dim(1) = 2;          % number of dims
                info2.Raw.dim(2) = infoIn.ImageSize(1);
                info2.Raw.dim(3) = infoIn.ImageSize(2);
                info2.Raw.dim(4) = 1;
            end
            info2.Raw.pixdim(1) = 1;
            info2.Raw.pixdim(2) = info2.PixelDimensions(1);
            info2.Raw.pixdim(3) = info2.PixelDimensions(2);
            if expand2DTo3D
                info2.Raw.pixdim(4) = info2.PixelDimensions(3);
            else
                info2.Raw.pixdim(4) = 1;
            end
        end
    end
end
