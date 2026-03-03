clear all;
setenv('TMPDIR','/scratch/');
setenv('TEMP','/scratch/');
setenv('TMP','/scratch/');
addpath(genpath('/autofs/space/megaera_001/users/kchai/code/psoct-renew'));
gamma = -15;
%% 
% 
% source = '/space/zircon/5/users/kchai/I55_1119/';
% basename = '/space/zircon/5/users/kchai/I55_1119/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "", "")
% stitch_section(basename, [14 31;23 31])
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_003','mosaic_004'} )
% thruplane(basename, gamma, [1 2])
% RGB_3Daxis(basename, [1 2])
% 
% %% 
% source = '/space/zircon/5/users/kchai/I55_1120/';
% basename = '/space/zircon/5/users/kchai/I55_1120/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31])
% % stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_003','mosaic_004'} )
% thruplane(basename, gamma, [1 2])
% RGB_3Daxis(basename, [1 2])
% 
% 
% %% 
% source = '/space/zircon/5/users/kchai/I55_1120_uint16/';
% basename = '/space/zircon/5/users/kchai/I55_1120_uint16/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31])
% thruplane(basename, gamma, [1])
% RGB_3Daxis(basename, [1])

%%
tic;
%all_s2c('/local_mount/space/zircon/6/users/data/I55_spectralraw_slice5_20251124','/local_mount/space/zircon/6/users/data/I55_slice5_complex','mosaic_001*.nii','mosaic_002*.nii');
%t1=toc
%source = '/space/zircon/6/users/data/I55_slice5_complex/';
%basename = '/space/zircon/5/users/kchai/I55_slice5/';
%batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
%t2=toc
% stitch_section(basename, [14 31;23 31])
% thruplane(basename, gamma, [1])
% RGB_3Daxis(basename, [1])
% t3=toc
% disp(t1)
% disp(t2)
% disp(t3)

%% 

% % all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6_complex','mosaic_003*.nii','mosaic_004*.nii');
% % all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6_complex','mosaic_005*.nii','mosaic_006*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice6_complex/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice6_complex/analysis/';
% % batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% % stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_003','mosaic_004'} )
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_005','mosaic_006'} )
% thruplane(basename, gamma, [2,3],"aip")
% RGB_3Daxis(basename, [2,3])

%% 


% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6_complex','mosaic_007*.nii','mosaic_008*.nii');
% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6_complex','mosaic_009*.nii','mosaic_010*.nii');
% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6_complex','mosaic_011*.nii','mosaic_012*.nii');
% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6_complex','mosaic_013*.nii','mosaic_014*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice6_complex/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice6_complex/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_007','mosaic_008'} )
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_009','mosaic_010'} )
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_011','mosaic_012'} )
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_013','mosaic_014'} )
% thruplane(basename, gamma, [8],"aip")
% RGB_3Daxis(basename, [8])

%%
%all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice12','mosaic_015*.nii','mosaic_016*.nii');
%source = '/local_mount/space/zircon/5/users/kchai/I55_slice12';
%basename = '/space/zircon/5/users/kchai/I55_slice12/analysis/';
%batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
%stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_015','mosaic_016'} )
%thruplane(basename, gamma, [8],"aip")
%RGB_3Daxis(basename, [8])

%%
% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice13','mosaic_017*.nii','mosaic_018*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice13';
% basename = '/space/zircon/5/users/kchai/I55_slice13/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_017','mosaic_018'} )
% thruplane(basename, gamma, [9],"aip")
% RGB_3Daxis(basename, [9])
%%
%source = '/local_mount/space/zircon/5/users/kchai/I55_slice13/';
%basename = '/autofs/space/megaera_001/users/kchai/project/psoct-analysis/I55_slice13_150/';
%batch_process_cc(source, [basename 'processed/'], "find", 150, "new", "")
%stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_017','mosaic_018'} )
%thruplane(basename, gamma, [9],"aip")
%RGB_3Daxis(basename, [9])
%%
source = '/local_mount/space/zircon/5/users/kchai/I55_slice13/';
basename = '/autofs/space/megaera_001/users/kchai/project/psoct-analysis/I55_slice13_150/';
% batch_process_cc(source, [basename 'processed/'], "find", 150, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_017','mosaic_018'} )
%thruplane(basename, gamma, [9],"aip")
%RGB_3Daxis(basename, [9])
%%
%all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice14','mosaic_019*.nii','mosaic_020*.nii');
source = '/local_mount/space/zircon/5/users/kchai/I55_slice14';
basename = '/space/zircon/5/users/kchai/I55_slice14/analysis/';
%batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
%stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_019','mosaic_020'} )
% thruplane(basename, gamma, [10],"aip")
% RGB_3Daxis(basename, [10])

% %%
% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice15','mosaic_021*.nii','mosaic_022*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice15';
% basename = '/space/zircon/5/users/kchai/I55_slice15/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_021','mosaic_022'} )
% thruplane(basename, gamma, [11],"aip")
% RGB_3Daxis(basename, [11])

% %%
% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice16','mosaic_023*.nii','mosaic_024*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice16';
% basename = '/space/zircon/5/users/kchai/I55_slice16/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_023','mosaic_024'} )
% thruplane(basename, gamma, [12],"aip")
% RGB_3Daxis(basename, [12])

% %%
% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice17','mosaic_025*.nii','mosaic_026*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice17';
% basename = '/space/zircon/5/users/kchai/I55_slice17/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_025','mosaic_026'} )
% thruplane(basename, gamma, [13],"aip")
% RGB_3Daxis(basename, [13])

% %%
% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice18','mosaic_027*.nii','mosaic_028*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice18';
% basename = '/space/zircon/5/users/kchai/I55_slice18/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_027','mosaic_028'} )
% thruplane(basename, gamma, [14],"aip")
% RGB_3Daxis(basename, [14])
% %%
% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice19','mosaic_029*.nii','mosaic_030*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice19';
% basename = '/space/zircon/5/users/kchai/I55_slice19/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_029','mosaic_030'} )
% thruplane(basename, gamma, [15],"aip")
% RGB_3Daxis(basename, [15])

% %%
% all_s2c('/mnt/sas/I55_test_spectralraw_20251201/','/local_mount/space/zircon/5/users/kchai/I55_1201','mosaic_001*.nii','mosaic_002*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_1201/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_1201/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [10 10;10 10], 'Mosaics', {'mosaic_001','mosaic_002'} );
% thruplane(basename, gamma, [1],"aip");
% RGB_3Daxis(basename, [1]);
% %%
% 
% source = '/mnt/sas/I55_test_processed_20251201/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_1201_complex/';
% batch_process_cc(source, [basename 'processed/'], 0, 80, "new", "")
% stitch_section(basename, [10 10;10 10], 'Mosaics', {'mosaic_001','mosaic_002'} );
% % thruplane(basename, gamma, [1],"aip");
% % RGB_3Daxis(basename, [1]);


% source = '/mnt/sas/I55_test_processed_20251202/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_1202_complex/';
% batch_process_cc(source, [basename 'processed/'], 15, 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_001','mosaic_002'} );

% thruplane(basename, gamma, [1],"aip");
% RGB_3Daxis(basename, [1]);

% all_s2c('/mnt/sas/I55_slice21_20251202/', '/local_mount/space/zircon/5/users/kchai/I55_slice21','mosaic_033*spectral*.nii','mosaic_034*spectral*.nii');
source = '/local_mount/space/zircon/5/users/kchai/I55_slice21/';
basename = '/local_mount/space/zircon/5/users/kchai/I55_slice21/analysis/';
batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_033','mosaic_034'} )
thruplane(basename, gamma, [17],"aip")
RGB_3Daxis(basename, [17])
