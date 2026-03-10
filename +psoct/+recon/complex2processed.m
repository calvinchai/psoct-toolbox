function out = complex2processed(J1, J2, surfaceOpts, enfaceOpts, acquisitionOpts, outputOpts, volumeOpts)
    % complex2processed
    % Compute 3D metrics (dBI3D, R3D, O3D) and optional enface 2D maps (AIP, MIP, RET, ORI),
    % plus optional birefringence from a single complex PS-OCT volume in memory.
    %
    %   out = psoct.recon.complex2processed(J1, J2)
    %
    % Inputs
    %   J1, J2       : complex 3D arrays (X × Y × Z), Jones vector components.
    %   surfaceOpts    : surface options struct.
    %                    surfaceOpts.Spec: specification for psoct.surface.findSurface
    %                      (numeric index, NIfTI path, or method name such as "gradient").
    %                    surfaceOpts.Args: optional cell array of extra args
    %                      forwarded to algorithmic surface methods.
    %   enfaceOpts     : struct passed to psoct.enface.vol2enface. Fields:
    %                    Offset, Depth, OriMethod, OriMethodArgs,
    %                    BirefMethod, BirefMethodArgs, Compute, Save2DAs3D.
    %   acquisitionOpts: struct passed to psoct.enface.vol2enface and used for 3D header.
    %                    Fields: ZSizeUm, WavelengthUm, SliceThicknessUm.
    %
    % Name-value options (outputOpts.*):
    %   outputOpts.Paths     : struct of output paths for each modality. Fields:
    %                          dBI3D, R3D, O3D, biref, aip, mip, ret, ori, surf.
    %                          Leave empty or "" to skip writing that modality.
    %
    % Volume options (volumeOpts.*):
    %   volumeOpts.flipPhase   : logical flag to flip optic-axis phase sign.
    %   volumeOpts.phaseOffset : scalar phase offset in radians.
    %   volumeOpts.flipZ       : logical flag to flip reconstructed Z direction.
    %
    % Output
    %   out.dBI3D, out.R3D, out.O3D : reconstructed 3D modalities.
    %   out.aip, out.mip, out.ret, out.ori, out.biref : enface modalities.
    %   out.surf                     : surface map used for processing (nx-by-ny).
    %   out.paths                    : resolved output paths.
    %   out.compute                  : resolved enface compute flags.
    %
    arguments
        J1 (:,:,:) {mustBeNumeric, mustBeNonempty}
        J2 (:,:,:) {mustBeNumeric, mustBeNonempty}
        surfaceOpts struct = struct()
        enfaceOpts struct = struct()
        acquisitionOpts struct = struct()
        outputOpts struct = struct()
        volumeOpts struct = struct()
    end

    % -------- Resolve output paths into a struct --------
    % if isfield(outputOpts, "Paths") && isstruct(outputOpts.Paths)
    %     paths = outputOpts.Paths;
    % else
    %     paths = struct();
    % end
    volumeOpts = psoct.internal.opts.normalizeVolumeOpts(volumeOpts);
    outputOpts = psoct.internal.opts.normalizeOutputOpts(outputOpts);
    [dBI3D_vol, R3D_vol, O3D_vol] = psoct.complex.complex2volumes( ...
        J1, J2, volumeOpts, outputOpts);
    % % -------- Convert complex stack into PS-OCT metric volumes --------
    % [dBI3D_vol, R3D_vol, O3D_vol] = psoct.complex.complex2volumes( ...
    %     J1, J2, volumeOpts, outputOpts);

    [~, ~, nz] = size(dBI3D_vol);
    % -------- Surface and window indices --------
    surfaceOpts = namedargs2cell(surfaceOpts);
    surf = psoct.surface.findSurface(dBI3D_vol, surfaceOpts{:});
    surf = max(1, min(nz, round(surf)));

    % -------- Enface wrapper (compute + write) --------
    enfaceOpts = psoct.internal.opts.normalizeEnfaceOpts(enfaceOpts);
    acquisitionOpts = psoct.internal.opts.normalizeAcquisitionOpts(acquisitionOpts);
    enfaceOut = psoct.enface.vol2enface( ...
        dBI3D_vol, R3D_vol, O3D_vol, surf, enfaceOpts, acquisitionOpts, outputOpts);

    % -------- Package outputs --------
    out = struct();
    out.dBI3D = dBI3D_vol;
    out.R3D = R3D_vol;
    out.O3D = O3D_vol;
    out.surf = surf;
    out.aip = enfaceOut.aip;
    out.mip = enfaceOut.mip;
    out.ret = enfaceOut.ret;
    out.ori = enfaceOut.ori;
    out.biref = enfaceOut.biref;
    out.compute = enfaceOut.compute;

    if isfield(enfaceOut, "paths") && isstruct(enfaceOut.paths)
        out.paths = enfaceOut.paths;
    else
        out.paths = paths;
    end
    
end
