function futures = appendWriteFuture(futures, future)
% psoct.internal.nifti.appendWriteFuture
% Append non-empty write futures to a cell array.
    if ~isempty(future)
        futures{end+1, 1} = future; %#ok<AGROW>
    end
end
