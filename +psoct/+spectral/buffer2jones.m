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