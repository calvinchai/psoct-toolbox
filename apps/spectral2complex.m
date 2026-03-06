

function spectral2complex(filename, Aline_length, Bline_length, output_path)
if isdeployed
else
    
end
dispCompFile = '/autofs/cluster/octdata2/users/Hui/tools/dg_utils/spectralprocess/dispComp/mineraloil_LSM03/dispersion_compensation_LSM03_mineraloil_20240829/LSM03_mineral_oil_placecorrectionmeanall2.dat';

% -------------------------------------------------------------------------
% Generate output filename
% -------------------------------------------------------------------------
[input_path, base_name, ext] = fileparts(filename);
if (endsWith(output_path, '.nii', 'IgnoreCase', true) || endsWith(output_path, '.nii.gz', 'IgnoreCase', true))
    output_file = output_path;
else
    % Detect the spectral filename pattern and replace suffix
    % Example input: spectral_xxx_xxx.nii  →  processed_cropped.nii.gz
    %
    % If filename ends with ".nii", we replace that whole basename.
    %

    % Replace anything starting with 'spectral' and ending before extension
    new_base = regexprep(base_name, 'spectral.*$', 'processed_cropped');

    % Compose output file path
    output_file = fullfile(output_path, [new_base '.nii']);
end

tic
warning off MATLAB:polyfit:RepeatedPointsOrRescale

Aline = str2num(Aline_length);
Bline = str2num(Bline_length);
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



for FileInd = 1:Bline
    if mod(FileInd,50)==0, disp([' bline ' num2str(FileInd)]); end
    
    % Read buffers (kept identical to original)
    fid=fopen(filename, 'rb');
    fseek(fid,(FileInd-1)*AlineLength*Aline*2*2+352,'bof');
    data1=fread(fid, AlineLength*Aline, 'uint16');
    fclose(fid);
    WavelengthBuffer1=reshape(data1,2048,[]);
    % WavelengthBuffer1=flipud(reshape(data1,2048,[]));
    fid=fopen(filename, 'rb');
    fseek(fid,(FileInd-1)*AlineLength*Aline*2*2+AlineLength*Aline*2+352,'bof');
    data2=fread(fid, AlineLength*Aline, 'uint16');
    fclose(fid);
    WavelengthBuffer2=flipud(reshape(data2,2048,[]));
    % WavelengthBuffer2=reshape(data2,2048,[]);
    
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

Jones1_3D = permute(Jones1_3D, [2 1 3]);
Jones2_3D = permute(Jones2_3D, [2 1 3]);
% Now split each Jones stack into real and imaginary parts and concat along dim 1
% real_J1: Bline x Aline x Depth  -> we'll stack along dim 1, so cat(1, real, imag) -> (2*Bline) x Aline x Depth
J1_real = real(Jones1_3D);
J1_imag = imag(Jones1_3D);
J1_split = cat(1, J1_real, J1_imag);   % (2*Aline) x Bline x Depth

J2_real = real(Jones2_3D);
J2_imag = imag(Jones2_3D);
J2_split = cat(1, J2_real, J2_imag);   % (2*Aline) x Bline x Depth

% Final concatenation: [J1_split; J2_split] -> (4*Aline) x Bline x Depth
Jstack_all = cat(1, J1_split, J2_split);


fprintf('Saving output to: %s\n', output_file);
Jstack_all = flip(Jstack_all,3);
niftiwrite(single(Jstack_all),output_file);


end
