function s2c_raw(filename, FileNum, dispCompFile, Aline_length, Bline_length, output_path)

% if isdeployed
% else
%     addpath('/autofs/cluster/octdata2/users/Hui/PSCalibration/code');
%     addpath('/autofs/cluster/octdata2/users/Hui/tools/rob_utils');
%     addpath('/autofs/cluster/octdata2/users/Chao/code/telesto');
%     addpath('/autofs/cluster/octdata2/users/Chao/code/tools/freesurfer')
% end

% -------------------------------------------------------------------------
% Generate output filename
% -------------------------------------------------------------------------

[input_path, base_name, ext] = fileparts(filename);

% Detect the spectral filename pattern and replace suffix
% Example input: spectral_xxx_xxx.nii  →  processed_cropped.nii.gz
%
% If filename ends with ".nii", we replace that whole basename.
%

% Replace anything starting with 'spectral' and ending before extension
new_base = regexprep(base_name, 'spectral.*$', 'complex');

% If new_base matches 'mosaic_\d{3}_image_\d{3}_complex'
% pad image number to four digits for consistent output filename
tokens = regexp(new_base, '^mosaic_(\d{3})_image_(\d{3})_complex$', 'tokens', 'once');
if ~isempty(tokens)
    % reconstruct with 4-digit image index
    mosaic_str = tokens{1};
    image_idx = str2double(tokens{2});
    image_str = sprintf('%04d', image_idx);
    new_base = sprintf('mosaic_%s_image_%s_complex', mosaic_str, image_str);
end


% Compose output file path
output_file = fullfile(output_path, [new_base '.nii']);

tic
warning off MATLAB:polyfit:RepeatedPointsOrRescale

Aline = Aline_length;
Bline = Bline_length;
fprintf('aline = %i; bline = %i \n',Aline,Bline)

% parameters copied from original script
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
% Packed 12-bit: 1.5 bytes per sample, no header; buffer1 then buffer2 per B-line
bytesPerBuffer = AlineLength * Aline * 3 / 2;
InterpolationParameters = [PaddingFactor,PaddingLength,OriginalLineLength1,Start1,OriginalLineLength2,Start2];
[Wavelengths_l, Wavelengths_r,InterpolatedWavelengths2, Ks] = interpolationwave_20201130 (InterpolationParameters);
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

% Preallocate complex stacks for Jones1 and Jones2:
% dimensions: Bline x Aline x DepthL (complex)
Jones1_3D = complex(zeros(Bline, Aline, DepthL));
Jones2_3D = complex(zeros(Bline, Aline, DepthL));

for groupIndex = 1 : length(FileNum)
    fprintf('\n -- -- TileNb / FileNum %g -- \n\n',FileNum(groupIndex));
    
    for FileInd = 1:Bline
        if mod(FileInd,50)==0, disp([' bline ' num2str(FileInd)]); end
        
        % Read buffers: packed 12-bit (1.5 bytes per sample), no header
        fid = fopen(filename, 'rb');
        fseek(fid, (FileInd-1) * (bytesPerBuffer*2), 'bof');
        raw1 = fread(fid, bytesPerBuffer, 'uint8');
        fclose(fid);
        data1 = unpack12bit(raw1);
        WavelengthBuffer1 = reshape(data1, 2048, []);

        fid = fopen(filename, 'rb');
        fseek(fid, (FileInd-1) * (bytesPerBuffer*2) + bytesPerBuffer, 'bof');
        raw2 = fread(fid, bytesPerBuffer, 'uint8');
        fclose(fid);
        data2 = unpack12bit(raw2);
        WavelengthBuffer2 = flipud(reshape(data2, 2048, []));
        
        refdata1=mean(WavelengthBuffer1,2);
        refdata2=mean(WavelengthBuffer2,2);
        
        MeanScan1=WavelengthBuffer1-repmat(refdata1,1,Aline);
        MeanScan2=WavelengthBuffer2-repmat(refdata2,1,Aline);
        
        OriginalBuffer1 = MeanScan1(Start1:OriginalLineLength1-1+Start1,:);
        OriginalBuffer2 = MeanScan2(Start2:OriginalLineLength2-1+Start2,:);
        
        ZeroPaddedBuffer1 = ZeroPadBuffer(OriginalBuffer1, PaddingFactor);
        ZeroPaddedBuffer2 = ZeroPadBuffer(OriginalBuffer2, PaddingFactor);
        
        InterpolatedBuffer1 = interp1(Wavelengths_l, ZeroPaddedBuffer1, InterpolatedWavelengths2,'linear','extrap');
        InterpolatedBuffer2 = interp1(Wavelengths_r, ZeroPaddedBuffer2, InterpolatedWavelengths2,'linear','extrap');
        InterpolatedBuffer1 = InterpolatedBuffer1 - repmat(median(InterpolatedBuffer1,2),1,Aline);
        InterpolatedBuffer2 = InterpolatedBuffer2 - repmat(median(InterpolatedBuffer2,2),1,Aline);
        
        InterpolatedBuffer1 = InterpolatedBuffer1 .* phaseCorrection1;
        InterpolatedBuffer2 = InterpolatedBuffer2 .* phaseCorrection2;
        
        % Obtain Jones vectors (complex) for this B-line (size: Depth x Aline)
        Jones1 = Buffer2Jones(InterpolatedBuffer1, PaddingFactor, AutoCorrPeakCut);
        Jones2 = Buffer2Jones(InterpolatedBuffer2, PaddingFactor, AutoCorrPeakCut);
        
        % Store into the stack. Original code transposed depth vs alines for dBI3D,
        % so we keep the same orientation: Jones returned as Depth x Aline -> transpose to Aline x Depth
        % We want shape Bline x Aline x Depth, so transpose Jones and assign:
        Jones1_3D(FileInd,:,:) = Jones1';   % now FileInd x Aline x Depth
        Jones2_3D(FileInd,:,:) = Jones2';
        
        % NOTE: we stop here — no dBI3D/R3D/O3D computations or saving
    end % for FileInd
end % for groupIndex

Jones1_3D = permute(Jones1_3D, [2 1 3]);
Jones2_3D = permute(Jones2_3D, [2 1 3]);
% Now split each Jones stack into real and imaginary parts and concat along dim 1
% real_J1: Bline x Aline x Depth  -> we'll stack along dim 1, so cat(1, real, imag) -> (2*Bline) x Aline x Depth
Jstack_all = cat(1, ...
    real(Jones1_3D), imag(Jones1_3D), ...
    real(Jones2_3D), imag(Jones2_3D));

fprintf('Saving output to: %s\n', output_file);
Jstack_all = flip(Jstack_all,3);
niftiwrite(single(Jstack_all),output_file);


end

function data = unpack12bit(raw)
% Unpack 12-bit format from Raw12BitWriter (12bit.c): 3 bytes -> 2 samples (0-4095).
% Writer does: ((uint32_t*)fb)[0] = (p[i]&0xFFF) | ((p[i+1]&0xFFF)<<12); fb+=3;
% So 32-bit LE word has bits 0-11 = sample0, bits 12-23 = sample1; low 24 bits written.
%   Byte 0: bits 0-7 of sample0
%   Byte 1: bits 8-11 of sample0 (low nibble) | bits 0-3 of sample1 (high nibble)
%   Byte 2: bits 4-11 of sample1
nn = numel(raw) * 2 / 3;
b0 = double(raw(1:3:end));
b1 = double(raw(2:3:end));
b2 = double(raw(3:3:end));
data = zeros(nn, 1, 'double');
data(1:2:end) = b0 + mod(b1, 16) * 256;   % sample0: low 8 from b0, high 4 from low nibble of b1
data(2:2:end) = floor(b1 / 16) + b2 * 16; % sample1: low 4 from high nibble of b1, high 8 from b2
end