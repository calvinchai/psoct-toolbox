function out = decode_fp16_uint16(arr)
    % If the input is uint16, reinterpret as float16 bit patterns
    if all(mod(arr(:),1)==0)
        out = single(typecast(uint16(arr(:)),'half'));
    else 
        out =arr;
    end
    out = reshape(out, size(arr));
    % if isa(arr, 'uint16')
    %     % reinterpret bits as half precision (fp16)
    %     arr_fp16 = half(arr);      % half() constructor accepts uint16 bit-patterns
    %     out = single(arr_fp16);    % convert fp16 -> float32
    % else
    %     % if array already float32 or float64, do nothing
    %     out = arr;
    % end
end