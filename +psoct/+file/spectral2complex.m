function [J1, J2, outPath] = spectral2complex(spectralFile, spectralOpts)
% psoct.file.spectral2complex
% Path-based wrapper around psoct.spectral.spectral2complex.
%
%   [J1, J2, outPath] = psoct.file.spectral2complex(spectralFile, spectralOpts)
%
% Required
%   spectralFile       : Path to the spectral data file.
%
% spectralOpts struct fields (all optional)
%   dispCompFile       : Path to dispersion compensation file. If empty,
%                        uses toolbox default via psoct.internal.getDataFile.
%   AlineSize          : A-line size (pixels of X axis). Default = 200.
%   BlineSize          : B-line size (pixels of Y axis). Default = 350.
%   isRawFormat        : Logical flag indicating packed 12-bit raw format.
%                        Default = false.
%   outputPath         : If non-empty, write complex NIfTI to this path.
%                        If empty, no file is written.
%
% Output
%   J1, J2             : Complex Jones volumes (X × Y × Z).
%   outPath            : Resolved output path as string ("" if not written).

arguments
    spectralFile {mustBeTextScalar, mustBeNonempty}
    spectralOpts.dispCompFile {mustBeTextScalar} = psoct.internal.getDataFile("LSM03_mineral_oil_placecorrectionmeanall2.dat")
    spectralOpts.AlineSize (1,1) integer {mustBePositive} = 200
    spectralOpts.BlineSize (1,1) integer {mustBePositive} = 350
    spectralOpts.outputPath {mustBeTextScalar} = ""
    spectralOpts.isRawFormat (1,1) logical = false
end

spectralFile = string(spectralFile);
spectralOpts.dispCompFile = string(spectralOpts.dispCompFile);
spectralOpts.outputPath = string(spectralOpts.outputPath);

[J1, J2] = psoct.spectral.spectral2complex(spectralFile, spectralOpts);
outPath = string(spectralOpts.outputPath);
end
