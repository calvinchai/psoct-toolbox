function [Jones1_3D, Jones2_3D] = spectral2complex(spectralFile, spectralOpts)
%SPECTRAL2COMPLEX Convert spectral data to complex data.
%
%   [Jones1_3D, Jones2_3D] = spectral2complex(spectralFile, spectralOpts)
%
%   Input
%     spectralFile : Path to the spectral data file.
%     spectralOpts : Struct with fields:
%                    - dispCompFile: Path to the dispersion compensation file.
%                    - AlineSize   : Size of the A-line (pixels of X axis).
%                    - BlineSize   : Size of the B-line (pixels of Y axis).
%                    - outputPath  : Path to the output file. If empty, no file is written.
%                    - isRawFormat : Whether input is in packed 12-bit raw format.
%
%   Output
%     Jones1_3D   : Complex Jones volume for channel 1 (Aline x Bline x Depth).
%     Jones2_3D   : Complex Jones volume for channel 2 (Aline x Bline x Depth).
%
%   This function is designed to be numerically equivalent to the legacy
%   s2c_raw implementation when called with the corresponding parameters.
arguments
    spectralFile {mustBeTextScalar, mustBeNonempty}
    spectralOpts.dispCompFile {mustBeTextScalar} = psoct.internal.getDataFile("LSM03_mineral_oil_placecorrectionmeanall2.dat")
    spectralOpts.AlineSize (1,1) int32 {mustBeInteger, mustBePositive} = 200
    spectralOpts.BlineSize (1,1) int32 {mustBeInteger, mustBePositive} = 350
    spectralOpts.outputPath {mustBeTextScalar} = ""
    spectralOpts.isRawFormat (1,1) logical = false
end

% spectralOpts = psoct.internal.validator.spectralOpts(spectralOpts);

dispCompFile = string(spectralOpts.dispCompFile);
AlineSize = spectralOpts.AlineSize;
BlineSize = spectralOpts.BlineSize;
outputPath = string(spectralOpts.outputPath);
isRawFormat = spectralOpts.isRawFormat;

% Constants describing the acquisition format.
HEADER_BYTES = 352;          % Header size of Nifti-1 file
BITS_PER_SAMPLE_RAW = 12;    % Packed 12-bit samples for raw format
BYTES_PER_UINT16 = 2;        % 16-bit unsigned integers

warning off MATLAB:polyfit:RepeatedPointsOrRescale %#ok<WNOFF>

Aline = AlineSize;
Bline = BlineSize;
fprintf('AlineSize = %i; BlineSize = %i \n', AlineSize, BlineSize);

% Parameters copied from original script / s2c_raw
AutoCorrPeakCut = 24;                 % multiple of 8
DepthL          = 1024 - AutoCorrPeakCut;  %#ok<NASGU> kept for compatibility
AlineLength     = 2048;

% Buffer size bookkeeping
numSamplesPerBuffer = AlineLength * AlineSize;
if isRawFormat
    % Packed 12-bit: 3 bytes per 2 samples
    bytesPerBuffer = numSamplesPerBuffer * (BITS_PER_SAMPLE_RAW / 8);
else
    % 16-bit samples
    bytesPerBuffer = numSamplesPerBuffer * BYTES_PER_UINT16;
end

% Depth / interpolation configuration
PaddingFactor       = 1;
PaddingLength       = 2048 * PaddingFactor;
OriginalLineLength1 = 2048;
OriginalLineLength2 = 2048;
Start1              = 1;
Start2              = 1;

InterpolationParameters = [ ...
    PaddingFactor,      PaddingLength, ...
    OriginalLineLength1, Start1, ...
    OriginalLineLength2, Start2];

[Wavelengths_l, Wavelengths_r, InterpolatedWavelengths2, Ks] = ...
    psoct.legacy.interpolationwave_20201130(InterpolationParameters); %#ok<ASGLU>

% Package parameters that are shared across B-lines
params = struct();
params.AlineSize              = AlineSize;
params.BlineSize              = BlineSize;
params.AlineLength            = AlineLength;
params.AutoCorrPeakCut        = AutoCorrPeakCut;
params.PaddingFactor          = PaddingFactor;
params.PaddingLength          = PaddingLength;
params.OriginalLineLength1    = OriginalLineLength1;
params.OriginalLineLength2    = OriginalLineLength2;
params.Start1                 = Start1;
params.Start2                 = Start2;
params.numSamplesPerBuffer    = numSamplesPerBuffer;
params.bytesPerBuffer         = bytesPerBuffer;
params.Wavelengths_l          = Wavelengths_l;
params.Wavelengths_r          = Wavelengths_r;
params.InterpolatedWavelengths = InterpolatedWavelengths2;

% Read dispersion correction file(s)
dispCompFile1 = dispCompFile;
dispCompFile2 = dispCompFile;

phaseDispersion1 = readDispersionFile(dispCompFile1, AlineLength, PaddingFactor);
phaseDispersion2 = readDispersionFile(dispCompFile2, AlineLength, PaddingFactor);

phaseCorrection1 = exp(-1i .* reshape(phaseDispersion1, AlineLength * PaddingFactor, []));
phaseCorrection2 = exp(-1i .* reshape(phaseDispersion2, AlineLength * PaddingFactor, []));

% Replicate along A-line dimension to match interpolated buffer size
phaseCorrection1 = repmat(phaseCorrection1, 1, Aline);
phaseCorrection2 = repmat(phaseCorrection2, 1, Aline);

% Preallocate complex stacks for Jones1 and Jones2:
% dimensions: Bline x Aline x DepthL (complex)
Jones1_3D = complex(zeros(Bline, Aline, DepthL));
Jones2_3D = complex(zeros(Bline, Aline, DepthL));

% Basic validation of input file size (best-effort check)
fileInfo = dir(spectralFile);
if ~isempty(fileInfo)
    expectedBytes = Bline * (2 * bytesPerBuffer);
    if ~isRawFormat
        expectedBytes = expectedBytes + HEADER_BYTES;
    end
    if fileInfo.bytes < expectedBytes
        warning('spectral2complex:FileTooSmall', ...
            'Spectral file "%s" appears smaller (%d bytes) than expected (~%d bytes).', ...
            spectralFile, fileInfo.bytes, expectedBytes);
    end
end

fid = fopen(spectralFile, 'rb');
if fid == -1
    error('spectral2complex:FileOpenFailed', ...
        'Could not open spectral data file "%s".', spectralFile);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

for blineIndex = 1:Bline
    if mod(blineIndex, 50) == 0
        disp([' bline ' num2str(blineIndex)]);
    end

    % Read raw wavelength buffers for both polarization channels
    [WavelengthBuffer1, WavelengthBuffer2] = readBlineBuffers( ...
        fid, blineIndex, params, isRawFormat, HEADER_BYTES);

    % Convert spectral buffers into Jones vectors for this B-line
    [Jones1, Jones2] = processBlineBuffers( ...
        WavelengthBuffer1, WavelengthBuffer2, params, ...
        phaseCorrection1, phaseCorrection2);

    % Store into the stack. Jones returned as Depth x Aline -> transpose to Aline x Depth
    % We want shape Bline x Aline x Depth, so transpose Jones and assign:
    Jones1_3D(blineIndex,:,:) = Jones1';   % Bline x Aline x Depth
    Jones2_3D(blineIndex,:,:) = Jones2';
end % for blineIndex

Jones1_3D = permute(Jones1_3D, [2 1 3]);
Jones2_3D = permute(Jones2_3D, [2 1 3]);

if outputPath ~= ""
    % real_J1: Bline x Aline x Depth  -> we'll stack along dim 1,
    % so cat(1, real, imag) -> (2*Bline) x Aline x Depth
    Jstack_all = cat(1, ...
        real(Jones1_3D), imag(Jones1_3D), ...
        real(Jones2_3D), imag(Jones2_3D));

    fprintf('Saving output to: %s\n', outputPath);
    Jstack_all = single(flip(Jstack_all, 3));
    %psoct.internal.nifti.writeNiftiIfPath(outputPath, Jstack_all, infoIn);

    niftiwrite(Jstack_all, outputPath);
end

end

% -------------------------------------------------------------------------
% Local helpers
% -------------------------------------------------------------------------

function phaseDispersion = readDispersionFile(dispCompFile, AlineLength, PaddingFactor)
%READDISPERSIONFILE Read and validate dispersion compensation vector.

fid = fopen(dispCompFile, 'rb');
if fid == -1
    error('spectral2complex:DispersionOpenFailed', ...
        'Could not open dispersion compensation file "%s".', dispCompFile);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

phaseDispersion = fread(fid, inf, 'real*8');

expectedLen = AlineLength * PaddingFactor;
if mod(numel(phaseDispersion), expectedLen) ~= 0
    error('spectral2complex:BadDispersionLength', ...
        'Dispersion file "%s" has %d elements, which is not a multiple of %d.', ...
        dispCompFile, numel(phaseDispersion), expectedLen);
end
end

function [WavelengthBuffer1, WavelengthBuffer2] = readBlineBuffers( ...
    fid, blineIndex, params, isRawFormat, headerBytes)
%READBLINEBUFFERS Read both polarization buffers for a single B-line.

offsetBase = (blineIndex - 1) * (2 * params.bytesPerBuffer); % two buffers (channels) per B-line
if ~isRawFormat
    offsetBase = offsetBase + headerBytes; % header is present once at the beginning
end

fseekStatus = fseek(fid, offsetBase, 'bof');
if fseekStatus ~= 0
    error('spectral2complex:SeekFailed', ...
        'Failed to seek to offset %d in spectral file.', offsetBase);
end

if ~isRawFormat
    data1 = fread(fid, params.numSamplesPerBuffer, 'uint16');
    data2 = fread(fid, params.numSamplesPerBuffer, 'uint16');
else
    raw1 = fread(fid, params.bytesPerBuffer, 'uint8=>uint8');
    raw2 = fread(fid, params.bytesPerBuffer, 'uint8=>uint8');
    if numel(raw1) < params.bytesPerBuffer || numel(raw2) < params.bytesPerBuffer
        error('spectral2complex:UnexpectedEOF', ...
            'Reached end of file while reading raw buffers for B-line %d.', blineIndex);
    end
    data1 = psoct.spectral.unpack12bits(raw1);
    data2 = psoct.spectral.unpack12bits(raw2);
end

if numel(data1) ~= params.numSamplesPerBuffer || numel(data2) ~= params.numSamplesPerBuffer
    error('spectral2complex:UnexpectedSampleCount', ...
        'Expected %d samples per buffer but read %d and %d.', ...
        params.numSamplesPerBuffer, numel(data1), numel(data2));
end

WavelengthBuffer1 = reshape(data1, params.AlineLength, []);
WavelengthBuffer2 = flipud(reshape(data2, params.AlineLength, []));
end

function [Jones1, Jones2] = processBlineBuffers( ...
    WavelengthBuffer1, WavelengthBuffer2, params, ...
    phaseCorrection1, phaseCorrection2)
%PROCESSBLINEBUFFERS Convert spectral buffers into Jones vectors.

Aline               = params.AlineSize;
PaddingFactor       = params.PaddingFactor;
OriginalLineLength1 = params.OriginalLineLength1;
OriginalLineLength2 = params.OriginalLineLength2;
Start1              = params.Start1;
Start2              = params.Start2;

% Remove reference (mean across A-lines)
refdata1  = mean(WavelengthBuffer1, 2);
refdata2  = mean(WavelengthBuffer2, 2);
MeanScan1 = WavelengthBuffer1 - refdata1;
MeanScan2 = WavelengthBuffer2 - refdata2;

% Crop to original line length
OriginalBuffer1 = MeanScan1(Start1:OriginalLineLength1 - 1 + Start1, :);
OriginalBuffer2 = MeanScan2(Start2:OriginalLineLength2 - 1 + Start2, :);

% Zero padding
ZeroPaddedBuffer1 = psoct.legacy.ZeroPadBuffer(OriginalBuffer1, PaddingFactor);
ZeroPaddedBuffer2 = psoct.legacy.ZeroPadBuffer(OriginalBuffer2, PaddingFactor);

% Interpolation onto k-space grid
InterpolatedBuffer1 = interp1(params.Wavelengths_l, ZeroPaddedBuffer1, ...
    params.InterpolatedWavelengths, 'linear', 'extrap');
InterpolatedBuffer2 = interp1(params.Wavelengths_r, ZeroPaddedBuffer2, ...
    params.InterpolatedWavelengths, 'linear', 'extrap');

% Remove DC component using median across A-lines
InterpolatedBuffer1 = InterpolatedBuffer1 - median(InterpolatedBuffer1, 2);
InterpolatedBuffer2 = InterpolatedBuffer2 - median(InterpolatedBuffer2, 2);

% Apply dispersion correction
InterpolatedBuffer1 = InterpolatedBuffer1 .* phaseCorrection1;
InterpolatedBuffer2 = InterpolatedBuffer2 .* phaseCorrection2;

% Obtain Jones vectors (complex) for this B-line (size: Depth x Aline)
Jones1 = buffer2jones(InterpolatedBuffer1, PaddingFactor, params.AutoCorrPeakCut);
Jones2 = buffer2jones(InterpolatedBuffer2, PaddingFactor, params.AutoCorrPeakCut);
end

function [Jones]=buffer2jones(OriginalBuffer, PaddingFactor, AutoCorrPeakCut)
% [Jones]=Buffer2JonesDispComp(OriginalBuffer, PaddingFactor, AutoCorrPeakCut)

% % upsampling
% AlineLength = size(OriginalBuffer, 1) / (2*PaddingFactor)*4;
% Jones = fft(OriginalBuffer,4*size(OriginalBuffer,1));
AlineLength = size(OriginalBuffer, 1) / (2*PaddingFactor);
Jones = (fft(OriginalBuffer,size(OriginalBuffer,1)));
Jones(AlineLength+1:end, :) = [];
Jones(1:AutoCorrPeakCut, :) = []; % Cut out autocorrelation peak
end