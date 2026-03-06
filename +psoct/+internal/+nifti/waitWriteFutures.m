function waitWriteFutures(futures)
% psoct.internal.nifti.waitWriteFutures
% Block until all queued write futures complete.
    for i = 1:numel(futures)
        fetchOutputs(futures{i});
    end
end
