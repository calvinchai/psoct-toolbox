function [ZeroPaddedBuffer]=ZeroPadBuffer(OriginalBuffer, PaddingFactor)
% [ZeroPadBuffer] = ZeroPadBuffer(OriginalBuffer, PaddingFactor)

%disp(sprintf('zero-padding (factor=%d)', PaddingFactor));

AlineLength = size(OriginalBuffer, 1);
NumberAlines = size(OriginalBuffer, 2);
MidLength = AlineLength / 2 + 1;
TransformedBuffer = fft(OriginalBuffer);

TransformedBuffer(MidLength)=TransformedBuffer(MidLength)/2;

PaddedTransformedBuffer = zeros(PaddingFactor*AlineLength, NumberAlines);
PaddedTransformedBuffer(1:MidLength, :) = TransformedBuffer(1:MidLength, :);
PaddedTransformedBuffer(end-MidLength+2:end, :) = TransformedBuffer(end-MidLength+2:end, :);
ZeroPaddedBuffer = real(ifft(PaddedTransformedBuffer)) * PaddingFactor;
