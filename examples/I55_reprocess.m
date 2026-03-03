clear all;
setenv('TMPDIR','/scratch/');
setenv('TEMP','/scratch/');
setenv('TMP','/scratch/');
addpath(genpath('/autofs/space/megaera_001/users/kchai/code/psoct-renew'));
gamma = -15;

%all_s2c('/mnt/sas/I55_slice21_20251202/', '/local_mount/space/zircon/5/users/kchai/I55_slice22','mosaic_035*spectral*.nii','mosaic_036*spectral*.nii');
%source = '/local_mount/space/zircon/5/users/kchai/I55_slice22/';
%basename = '/local_mount/space/zircon/5/users/kchai/I55_slice22/analysis/';
%batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
%stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_035','mosaic_036'} )
%thruplane(basename, gamma, [18],"aip")
%RGB_3Daxis(basename, [18])

% all_s2c('/mnt/sas/I55_slice21_20251202/', '/local_mount/space/zircon/5/users/kchai/I55_slice23','mosaic_037*spectral*.nii','mosaic_038*spectral*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice23/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice23/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_037','mosaic_038'} )
% thruplane(basename, gamma, [19],"aip")
% RGB_3Daxis(basename, [19])

% all_s2c('/mnt/sas/I55_spectralraw_slice20_20251126/', '/local_mount/space/zircon/5/users/kchai/I55_slice20','mosaic_031*spectral*.nii','mosaic_032*spectral*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice20/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice20/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_031','mosaic_032'} )
% thruplane(basename, gamma, [16],"aip")
% RGB_3Daxis(basename, [16])

% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice19','mosaic_029*.nii','mosaic_030*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice19';
% basename = '/space/zircon/5/users/kchai/I55_slice19/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_029','mosaic_030'} )
% thruplane(basename, gamma, [15],"aip")
% RGB_3Daxis(basename, [15])

% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice18','mosaic_027*.nii','mosaic_028*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice18';
% basename = '/space/zircon/5/users/kchai/I55_slice18/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_027','mosaic_028'} )
% thruplane(basename, gamma, [14],"aip")
% RGB_3Daxis(basename, [14])

% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice17','mosaic_025*.nii','mosaic_026*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice17';
% basename = '/space/zircon/5/users/kchai/I55_slice17/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_025','mosaic_026'} )
% thruplane(basename, gamma, [13],"aip")
% RGB_3Daxis(basename, [13])

% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice16','mosaic_023*.nii','mosaic_024*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice16';
% basename = '/space/zircon/5/users/kchai/I55_slice16/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_023','mosaic_024'} )
% thruplane(basename, gamma, [12],"aip")
% RGB_3Daxis(basename, [12])

% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice15','mosaic_021*.nii','mosaic_022*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice15';
% basename = '/space/zircon/5/users/kchai/I55_slice15/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_021','mosaic_022'} )
% thruplane(basename, gamma, [11],"aip")
% RGB_3Daxis(basename, [11])

% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice14','mosaic_019*.nii','mosaic_020*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice14';
% basename = '/space/zircon/5/users/kchai/I55_slice14/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_019','mosaic_020'} )
% thruplane(basename, gamma, [10],"aip")
% RGB_3Daxis(basename, [10])

% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice13','mosaic_017*.nii','mosaic_018*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice13';
% basename = '/space/zircon/5/users/kchai/I55_slice13/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_017','mosaic_018'} )
% thruplane(basename, gamma, [9],"aip")
% RGB_3Daxis(basename, [9])

% all_s2c('/mnt/sas/I55_spectralraw_slice12_20251125/','/local_mount/space/zircon/5/users/kchai/I55_slice12','mosaic_015*.nii','mosaic_016*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice12';
% basename = '/space/zircon/5/users/kchai/I55_slice12/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_015','mosaic_016'} )
% thruplane(basename, gamma, [8],"aip");
% RGB_3Daxis(basename, [8]);

% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6','mosaic_007*.nii','mosaic_008*.nii');
% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6','mosaic_009*.nii','mosaic_010*.nii');
% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6','mosaic_011*.nii','mosaic_012*.nii');
% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6','mosaic_013*.nii','mosaic_014*.nii');
% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6','mosaic_003*.nii','mosaic_004*.nii');
% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice6','mosaic_005*.nii','mosaic_006*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice6/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice6/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_007','mosaic_008'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_009','mosaic_010'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_011','mosaic_012'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_013','mosaic_014'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_003','mosaic_004'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_005','mosaic_006'} );
% thruplane(basename, gamma, [2 3 4 5 6 7],"aip");
% RGB_3Daxis(basename, [2 3 4 5 6 7]);



% all_s2c('/mnt/sas/I55_spectralraw_slice5_20251124/','/local_mount/space/zircon/5/users/kchai/I55_slice5','mosaic_001*.nii','mosaic_002*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice5/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice5/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "");
% stitch_section(basename, [14 31;23 31]);
% thruplane(basename, gamma, [1]);
% RGB_3Daxis(basename, [1]);


% all_s2c('/mnt/sas/I55_slice24_20251203/', '/local_mount/space/zircon/5/users/kchai/I55_slice24','mosaic_039*spectral*.nii','mosaic_040*spectral*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice24/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice24/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_039','mosaic_040'} )
% thruplane(basename, gamma, [20],"aip")
% RGB_3Daxis(basename, [20])


% all_s2c('/mnt/sas/I55_slice24_20251203/', '/local_mount/space/zircon/5/users/kchai/I55_slice25','mosaic_041*spectral*.nii','mosaic_042*spectral*.nii');
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice25/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice25/analysis/';
% batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_041','mosaic_042'} )
% thruplane(basename, gamma, [21],"aip")
% RGB_3Daxis(basename, [21])

all_s2c('/mnt/sas/I55_slice24_20251203/', '/local_mount/space/zircon/5/users/kchai/I55_slice26','mosaic_043*spectral*.nii','mosaic_044*spectral*.nii');
source = '/local_mount/space/zircon/5/users/kchai/I55_slice26/';
basename = '/local_mount/space/zircon/5/users/kchai/I55_slice26/analysis/';
batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_043','mosaic_044'} )
thruplane(basename, gamma, [22],"aip")
RGB_3Daxis(basename, [22])

all_s2c('/mnt/sas/I55_slice24_20251203/', '/local_mount/space/zircon/5/users/kchai/I55_slice27','mosaic_045*spectral*.nii','mosaic_046*spectral*.nii');
source = '/local_mount/space/zircon/5/users/kchai/I55_slice27/';
basename = '/local_mount/space/zircon/5/users/kchai/I55_slice27/analysis/';
batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_045','mosaic_046'} )
thruplane(basename, gamma, [23],"aip")
RGB_3Daxis(basename, [23])

all_s2c('/mnt/sas/I55_slice24_20251203/', '/local_mount/space/zircon/5/users/kchai/I55_slice28','mosaic_047*spectral*.nii','mosaic_048*spectral*.nii');
source = '/local_mount/space/zircon/5/users/kchai/I55_slice28/';
basename = '/local_mount/space/zircon/5/users/kchai/I55_slice28/analysis/';
batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_047','mosaic_048'} )
thruplane(basename, gamma, [24],"aip")
RGB_3Daxis(basename, [24])


all_s2c('/mnt/sas/I55_spectralraw_slice20_20251126/', '/local_mount/space/zircon/5/users/kchai/I55_slice20','mosaic_031*spectral*.nii','mosaic_032*spectral*.nii');

source = '/local_mount/space/zircon/5/users/kchai/I55_slice21/';
basename = '/local_mount/space/zircon/5/users/kchai/I55_slice21/analysis/';
%batch_process_cc(source, [basename 'processed/'], "find", 80, "new", "")
%stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_033','mosaic_034'} )
%thruplane(basename, gamma, [17],"aip")
%RGB_3Daxis(basename, [17])
