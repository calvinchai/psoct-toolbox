function ensureParpool(numWorkers, poolType)
%ENSUREPARPOOL Ensure a parallel pool exists with the requested type/size.
%
%   psoct.file.internal.ensureParpool(numWorkers, poolType)
%
%   numWorkers : [] (use default) or positive integer.
%   poolType   : "process" or "thread".

arguments
    numWorkers int16 {mustBePositive, mustBeInteger} = int16(4)
    poolType string {mustBeMember(poolType, ["process","thread"])} = "process"
end

poolobj = gcp("nocreate");
if ~isempty(poolobj)
    return;
end

if numWorkers < 2
    return;
end


if poolType == "process"
    if isempty(numWorkers)
        parpool("local");
    else
        parpool("local", numWorkers);
    end
else
    if isempty(numWorkers)
        parpool("threads");
    else
        parpool("threads", numWorkers);
    end
end

end

