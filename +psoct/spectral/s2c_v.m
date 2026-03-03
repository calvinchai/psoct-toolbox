function [Jstack_all, J1_split, J2_split] = s2c_v(filename, dispCompFile, Aline_length, Bline_length, output_path)
% s2c_vectorized  -- vectorized file loading variant of your original s2c
% - removes group loop (assumes one file at a time)
% - reads the whole file once then reshapes into channel1/channel2 per B-line
% - preserves existing processing and output format
%
% Usage:
%   [Jstack_all, J1_split, J2_split] = s2c_vectorized(filename, FileNum, dispCompFile, Aline_length, Bline_length, output_path)
%
% Notes:
% - FileNum is ignored for grouping (kept in signature for compatibility).
% - This function reads the entire data region after the 352-byte header into memory.
% - If Buffer2Jones supports batch processing you can remove the final per-Bline loop
%   and call Buffer2Jones on a 2D matrix of size (paddingLength x (Aline * Bline)).

tic
warning off MATLAB:polyfit:RepeatedPointsOrRescale

Aline = Aline_length;
Bline = Bline_length;
fprintf('aline = %i; bline = %i \n',Aline,Bline)

% parameters (copied from original)
AutoCorrPeakCut = 24; % multiple of 8
AlineLength = 2048;
DepthL=  1024- AutoCorrPeakCut; %%%
offset = 100/180*pi;

PaddingFactor=1;
PaddingLength = 2048*PaddingFactor;
OriginalLineLength1 = 2048;
OriginalLineLength2 = 2048;
Start1=1;
Start2=1;
InterpolationParameters = [PaddingFactor,PaddingLength,OriginalLineLength1,Start1,OriginalLineLength2,Start2];
[Wavelengths_l, Wavelengths_r,InterpolatedWavelengths2, Ks] = interpolationwave_101620 (InterpolationParameters);
InterpolatedWavelengths = InterpolatedWavelengths2;

% read dispersion correction file(s)
dispCompFile1 = dispCompFile;
dispCompFile2 = dispCompFile;

fiddc1 = fopen(dispCompFile1, 'rb');
phaseDispersion1 = fread(fiddc1, inf, 'real*8');
fclose(fiddc1);
phaseCorrection1 = exp(-1i .* reshape(phaseDispersion1,AlineLength*PaddingFactor,[]));
phaseCorrection1 = repmat(phaseCorrection1, 1, Aline);

fiddc2 = fopen(dispCompFile2, 'rb');
phaseDispersion2 = fread(fiddc2, inf, 'real*8');
fclose(fiddc2);
phaseCorrection2 = exp(-1i .* reshape(phaseDispersion2,AlineLength*PaddingFactor,[]));
phaseCorrection2 = repmat(phaseCorrection2, 1, Aline);

% -------------------------------------------------------------------------
% Vectorized file read: read whole file at once (single fopen)
% -------------------------------------------------------------------------
fid = fopen(filename, 'rb');
if fid < 0
    error('Could not open %s for reading', filename);
end

% Seek past header (352 bytes), then read all remaining uint16 samples
fseek(fid, 352, 'bof');
raw_uint16 = fread(fid, inf, 'uint16');
fclose(fid);

% Expected total samples after header: 2 * AlineLength * Aline * Bline
expected_samples = 2 * AlineLength * Aline * Bline;
if numel(raw_uint16) < expected_samples
    error('File seems too short: expected at least %d uint16 after header, got %d', expected_samples, numel(raw_uint16));
end
% If file contains extra padding at end that's okay: we'll only use the needed samples.
raw_uint16 = raw_uint16(1:expected_samples);

% Reshape into (2048) x (Aline) x (2 channels) x (Bline)
% The file layout was: for FileInd=1..Bline: [data1(block) (2048*Aline) , data2(block) (2048*Aline)] ...
raw_uint16 = reshape(raw_uint16, AlineLength, Aline, 2, Bline); % dims: 2048 x Aline x 2 x Bline

% Extract channel1 and channel2 buffers, applying the flip for channel2 as original code
% channel dims: 2048 x Aline x Bline
WavelengthBuffer1_all = squeeze(raw_uint16(:,:,1,:)); % size 2048 x Aline x Bline
WavelengthBuffer2_all = squeeze(raw_uint16(:,:,2,:));
% Original code did flipud on reshaped data2 for each FileInd
for k = 1:Bline
    WavelengthBuffer2_all(:,:,k) = flipud(WavelengthBuffer2_all(:,:,k));
end

% Convert to double for processing
WavelengthBuffer1_all = double(WavelengthBuffer1_all);
WavelengthBuffer2_all = double(WavelengthBuffer2_all);

% Preallocate complex stacks for Jones1 and Jones2:
% We'll build as Bline x Aline x Depth, then permute later
Jones1_3D = complex(zeros(Bline, Aline, DepthL));
Jones2_3D = complex(zeros(Bline, Aline, DepthL));

% ----------------------------
% Vectorized per-Bline preprocessing (mean subtraction)
% ----------------------------
% Compute mean across Aline (dim 2) for each (2048 x 1 x Bline)
refdata1_all = mean(WavelengthBuffer1_all, 2); % 2048 x 1 x Bline
refdata2_all = mean(WavelengthBuffer2_all, 2);

% Subtract mean for each Aline (implicit expansion)
MeanScan1_all = WavelengthBuffer1_all - refdata1_all;  % 2048 x Aline x Bline
MeanScan2_all = WavelengthBuffer2_all - refdata2_all;

% Extract original buffers (Start/OriginalLineLength)
OriginalBuffer1_all = MeanScan1_all(Start1:OriginalLineLength1-1+Start1, :, :); % 2048 x Aline x Bline
OriginalBuffer2_all = MeanScan2_all(Start2:OriginalLineLength2-1+Start2, :, :);

% Zero pad (call ZeroPadBuffer for each Bline separately if it expects 2D)
% ZeroPadBuffer likely accepts 2D matrix 2048 x Aline -> returns padded 2048*PaddingFactor x Aline
% We'll loop over Bline for this step (cheap compared to repeated file IO).
ZeroPaddedBuffer1_all = zeros(PaddingLength, Aline, Bline);
ZeroPaddedBuffer2_all = zeros(PaddingLength, Aline, Bline);

for k = 1:Bline
    ZeroPaddedBuffer1_all(:,:,k) = ZeroPadBuffer(squeeze(OriginalBuffer1_all(:,:,k)), PaddingFactor);
    ZeroPaddedBuffer2_all(:,:,k) = ZeroPadBuffer(squeeze(OriginalBuffer2_all(:,:,k)), PaddingFactor);
end

% Interpolate: interp1 supports matrix inputs; we'll reshape to 2D: (L) x (Aline*Bline)
L_in = size(ZeroPaddedBuffer1_all,1);
Z1_2D = reshape(ZeroPaddedBuffer1_all, L_in, Aline*Bline); % L_in x (Aline*Bline)
Z2_2D = reshape(ZeroPaddedBuffer2_all, L_in, Aline*Bline);

% Perform interpolation along first dimension
Interp1_2D = interp1(Wavelengths_l, Z1_2D, InterpolatedWavelengths2,'linear','extrap'); % newLen x (Aline*Bline)
Interp2_2D = interp1(Wavelengths_r, Z2_2D, InterpolatedWavelengths2,'linear','extrap');

newLen = size(Interp1_2D,1);
% reshape back to (newLen) x Aline x Bline
InterpolatedBuffer1_all = reshape(Interp1_2D, newLen, Aline, Bline);
InterpolatedBuffer2_all = reshape(Interp2_2D, newLen, Aline, Bline);

% subtract median across each column (axis 2) for each Bline
for k = 1:Bline
    med1 = median(InterpolatedBuffer1_all(:,:,k),2); % newLen x 1
    med2 = median(InterpolatedBuffer2_all(:,:,k),2);
    InterpolatedBuffer1_all(:,:,k) = InterpolatedBuffer1_all(:,:,k) - repmat(med1,1,Aline);
    InterpolatedBuffer2_all(:,:,k) = InterpolatedBuffer2_all(:,:,k) - repmat(med2,1,Aline);
end

% Apply phase corrections (phaseCorrection1/2 are newLen x 1 replicated to Aline)
% phaseCorrection? was shaped AlineLength*PaddingFactor x [] then repmat to 1 x Aline
% phaseCorrection1 is (newLen) x Aline (already), so:
for k = 1:Bline
    InterpolatedBuffer1_all(:,:,k) = InterpolatedBuffer1_all(:,:,k) .* phaseCorrection1;
    InterpolatedBuffer2_all(:,:,k) = InterpolatedBuffer2_all(:,:,k) .* phaseCorrection2;
end

% ----------------------------
% Compute Jones vectors per B-line
% ----------------------------
% Buffer2Jones expects (InterpolatedBuffer (newLen x Aline), PaddingFactor, AutoCorrPeakCut)
% We call it per-Bline. If Buffer2Jones supports processing multiple Aline groups at once,
% you can batch-call it by reshaping into newLen x (Aline*Bline) and splitting outputs accordingly.
for FileInd = 1:Bline
    if mod(FileInd,50)==0, disp([' bline ' num2str(FileInd)]); end
    
    InterpBuf1 = squeeze(InterpolatedBuffer1_all(:,:,FileInd)); % newLen x Aline
    InterpBuf2 = squeeze(InterpolatedBuffer2_all(:,:,FileInd));
    
    Jones1 = Buffer2Jones(InterpBuf1, PaddingFactor, AutoCorrPeakCut); % Depth x Aline (as before)
    Jones2 = Buffer2Jones(InterpBuf2, PaddingFactor, AutoCorrPeakCut);
    
    % store as Bline x Aline x Depth
    % original code transposed Jones (Depth x Aline -> Aline x Depth) and assigned Jones1_3D(FileInd,:,:) = Jones1'
    Jones1_3D(FileInd,:,:) = Jones1';
    Jones2_3D(FileInd,:,:) = Jones2';
end

% permute to Aline x Bline x Depth to match downstream processing
Jones1_3D = permute(Jones1_3D, [2 1 3]); % Aline x Bline x Depth
Jones2_3D = permute(Jones2_3D, [2 1 3]);

% Now split each Jones stack into real and imaginary parts and concat along dim 1
J1_real = real(Jones1_3D);
J1_imag = imag(Jones1_3D);
J1_split = cat(1, J1_real, J1_imag);   % (2*Aline) x Bline x Depth

J2_real = real(Jones2_3D);
J2_imag = imag(Jones2_3D);
J2_split = cat(1, J2_real, J2_imag);   % (2*Aline) x Bline x Depth

% Final concatenation: [J1_split; J2_split] -> (4*Aline) x Bline x Depth
Jstack_all = cat(1, J1_split, J2_split);

[input_path, base_name, ext] = fileparts(filename);
new_base = regexprep(base_name, 'spectral.*$', 'complex');
output_file = fullfile(output_path, [new_base '.nii']);

fprintf('Saving output to: %s\n', output_file);
Jstack_all = flip(Jstack_all,3);
niftiwrite(single(Jstack_all),output_file);

fprintf('Done. Elapsed time: %.1f s\n', toc);

end
