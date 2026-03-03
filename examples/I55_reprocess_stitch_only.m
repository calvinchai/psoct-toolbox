clear all;
setenv('TMPDIR','/scratch/');
setenv('TEMP','/scratch/');
setenv('TMP','/scratch/');
addpath(genpath('/autofs/space/megaera_001/users/kchai/code/psoct-renew'));
source = '/local_mount/space/zircon/5/users/kchai/I55_slice22/';
basename = '/local_mount/space/zircon/5/users/kchai/I55_slice22/analysis/';
RGB_3Daxis(basename, [18])
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice23/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice23/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_037','mosaic_038'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice20/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice20/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_031','mosaic_032'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice19';
% basename = '/space/zircon/5/users/kchai/I55_slice19/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_029','mosaic_030'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice18';
% basename = '/space/zircon/5/users/kchai/I55_slice18/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_027','mosaic_028'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice17';
% basename = '/space/zircon/5/users/kchai/I55_slice17/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_025','mosaic_026'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice16';
% basename = '/space/zircon/5/users/kchai/I55_slice16/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_023','mosaic_024'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice15';
% basename = '/space/zircon/5/users/kchai/I55_slice15/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_021','mosaic_022'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice14';
% basename = '/space/zircon/5/users/kchai/I55_slice14/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_019','mosaic_020'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice13';
% basename = '/space/zircon/5/users/kchai/I55_slice13/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_017','mosaic_018'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice12';
% basename = '/space/zircon/5/users/kchai/I55_slice12/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_015','mosaic_016'}, 'Modalities', {'ret'} );
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice6/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice6/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_007','mosaic_008'}, 'Modalities', {'ret'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_009','mosaic_010'}, 'Modalities', {'ret'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_011','mosaic_012'}, 'Modalities', {'ret'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_013','mosaic_014'}, 'Modalities', {'ret'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_003','mosaic_004'}, 'Modalities', {'ret'} );
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_005','mosaic_006'}, 'Modalities', {'ret'} );
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice5/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice5/analysis/';
% stitch_section(basename, [14 31;23 31], 'Modalities', {'ret'} );

% source = '/local_mount/space/zircon/5/users/kchai/I55_slice24/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice24/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_039','mosaic_040'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice25/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice25/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_041','mosaic_042'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice26/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice26/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_043','mosaic_044'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice27/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice27/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_045','mosaic_046'}, 'Modalities', {'ret'} )
% 
% source = '/local_mount/space/zircon/5/users/kchai/I55_slice28/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice28/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_047','mosaic_048'}, 'Modalities', {'ret'} )

% source = '/local_mount/space/zircon/5/users/kchai/I55_slice21/';
% basename = '/local_mount/space/zircon/5/users/kchai/I55_slice21/analysis/';
% stitch_section(basename, [14 31;23 31], 'Mosaics', {'mosaic_033','mosaic_034'}, 'Modalities', {'ret'} )

