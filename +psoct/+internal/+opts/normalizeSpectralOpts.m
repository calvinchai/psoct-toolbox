function spectralOpts = validateSpectralOpts(spectralOpts)
    nargs = namedargs2cell(spectralOpts);
    spectralOpts = iNormalizeSpectralOpts(nargs{:});
end

function nargs = iNormalizeSpectralOpts(nargs)
    arguments
        nargs.dispCompFile {mustBeTextScalar} = psoct.internal.getDataFile("LSM03_mineral_oil_placecorrectionmeanall2.dat")
        nargs.AlineSize (1,1) int32 {mustBeInteger, mustBePositive} = 200
        nargs.BlineSize (1,1) int32 {mustBeInteger, mustBePositive} = 350
        nargs.isRawFormat (1,1) logical = false
    end
end