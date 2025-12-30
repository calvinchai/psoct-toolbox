
function thruplane(basename, gamma, slice_numbers, mask_file, mask_threshold)
%gamma = -10
arguments
        basename 
        gamma = -15
        slice_numbers {mustBeInteger, mustBeNonnegative} = [1]
        mask_file = ""
        mask_threshold = 55
end
nWorkers = 24;
pool = gcp('nocreate');
    if isempty(pool)
        if isempty(nWorkers)
            pool = parpool; 
        else
            pool = parpool(nWorkers);
        end
    else
        fprintf('Using existing parallel pool with %d workers.\n', pool.NumWorkers);
    end
addpath ('/autofs/cluster/octdata2/users/Chao/code/demon_registration_version_8f');
addpath('/autofs/cluster/octdata2/users/Chao/code/telesto');
addpath ('/space/omega/1/users/3d_axis/PAPER/scripts');

basename1 = basename;
basename2 = basename1;

for slice = slice_numbers
    % % read first set
    slice_id1 = slice*2-1;
    slice_id2 = slice*2;
    
    fixed1 = imread([basename1, 'mosaic_',sprintf('%03d',slice_id1),'_ori.tif']); % orientation fixed
    moving1 = imread([basename2, 'mosaic_',sprintf('%03d',slice_id2),'_ori.tif']);  % orientation moving
    
    fixed2 = imread([basename1,'mosaic_',sprintf('%03d',slice_id1),'_biref.tif']);
    moving2 = imread([basename2, 'mosaic_',sprintf('%03d',slice_id2),'_biref.tif']);


    switch lower(string(mask_file))
        case "aip"
            mask_postfix = '_aip.tif';
        case "mip"
            mask_postfix = '_mip.tif';
        otherwise
            mask_postfix = ""; % no mask
    end

    if mask_postfix ~= ""
        % read mask images for fixed and moving (same slice indices)
        mask1_img = imread([basename1, 'mosaic_', sprintf('%03d', slice_id1), mask_postfix]);
        mask2_img = imread([basename2, 'mosaic_', sprintf('%03d', slice_id2), mask_postfix]);
        mask1_img = imgaussfilt(mask1_img, 5);
        mask2_img = imgaussfilt(mask2_img, 5);
        % create logical masks using provided threshold
        mask1 = mask1_img > mask_threshold;
        mask2 = mask2_img > mask_threshold;

        % --- apply mask directly (same dimensions) ---
        fixed1  = fixed1  .* cast(mask1,  class(fixed1));
        fixed2  = fixed2  .* cast(mask1,  class(fixed2));
        moving1 = moving1 .* cast(mask2,  class(moving1));
        moving2 = moving2 .* cast(mask2,  class(moving2));
    else
        % no mask requested: leave images unchanged
    end

    % TODO: the following is used for exp3. We can remove them after
    % fixed1 = fixed1(:,1:1111);
    % fixed2 = fixed2(:,1:1111);
    fixed2 = imgaussfilt(fixed2,3);
    moving2 = imgaussfilt(moving2,3);
    
    clear moving1_temp moving2_temp
    f1_dims = size(fixed1);
    m1_dims = size(moving1);
    
%     aip1 = imread([basename1, 'mosaic_', sprintf('%03d', slice_id1), '_aip.tif']);
% aip2 = imread([basename2, 'mosaic_', sprintf('%03d', slice_id2), '_aip.tif']);
% 
% mask1 = aip1 > 60;
% mask2 = aip2 > 60;
% applyMask = @(img, m) ...
%     (ndims(img)==3) .* bsxfun(@times, img, cast(repmat(m,[1 1 size(img,3)]), class(img))) + ...
%     (ndims(img)~=3) .* (img .* cast(m, class(img)));
% 
% % --- apply masks ---
% fixed1  = applyMask(fixed1,  mask1);
% fixed2  = applyMask(fixed2,  mask1);   % same mask as fixed1 (same basename/slice)
% moving1 = applyMask(moving1, mask2);
% moving2 = applyMask(moving2, mask2);
    
%     f1_xrange1 = 1;             
%     f1_xrange2 = end; 
% 
%     f1_yrange1 = 1;                  
%     f1_yrange2 = end; 
% 
% 
%     m1_xrange1 = 1;          
%     m1_xrange2 = end; 
% 
%     m1_yrange1 = 1;        
%     m1_yrange2 = end; 
% 
%     fixed_o1 =  -fixed1(f1_xrange1:f1_xrange2,f1_yrange1:f1_yrange2);
%     fixed_bi1 =  fixed2(f1_xrange1:f1_xrange2,f1_yrange1:f1_yrange2);
% %
%     moving_o1 = -moving1(m1_xrange1:m1_xrange2,m1_yrange1:m1_yrange2);
%     moving_bi1 = moving2(m1_xrange1:m1_xrange2,m1_yrange1:m1_yrange2);

    fixed_o1 =  -fixed1;
    fixed_bi1 =  fixed2;
%
    moving_o1 = -moving1;
    moving_bi1 = moving2;
    moving_bi1(~isfinite(moving_bi1)) = 1e-9;
    fixed_bi1(~isfinite(fixed_bi1)) = 1e-9;

    
    %   figure, subplot(1,2,1);imagesc(fixed_bi1);subplot(1,2,2);imagesc(moving_bi1)

%     fixed_o1 = imresize (fixed_o1, [size(fixed_bi1,1) size(fixed_bi1,2)],'nearest');
%     moving_o1 = imresize (moving_o1, [size(moving_bi1,1) size(moving_bi1,2)],'nearest');
    




    thruplane_reg_optiz_tensor_XY_final_par(fixed_bi1,moving_bi1, fixed_o1, moving_o1, gamma, [basename 'par_slice' num2str(slice)])

clear fixed_bi1 moving_bi1 fixed_o1 moving_o1
% delete(poolobj)
end

% rest is done in thruplane_reg_optiz_tensor_XY_final_par_JW

end