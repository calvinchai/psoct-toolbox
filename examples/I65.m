gamma = -15;

%% 
source = '/autofs/cluster/connects1/users/I65testrun_51kHz_11132025/';
basename = '/homes/5/kc1708/project/psoct-analysis/I65_51khz/';
batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "exp2")
% stitch_section(basename, [19 27; 32 27])
% stitch_section(basename, [19 27; 32 27],'Mosaics', {'mosaic_001','mosaic_002'}, 'Modalities', {'aip',})

% thruplane(basename, gamma, [1], "aip", 60)
% RGB_3Daxis(basename, [1])


%% 
source = '/autofs/cluster/connects1/users/I65testrun_76kHz_11132025/';
basename = '/homes/5/kc1708/project/psoct-analysis/I65_76khz/';
% batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "exp2")
% stitch_section(basename, [19 27; 32 27],'Mosaics', {'mosaic_003','mosaic_004'})
thruplane(basename, gamma, [2], "aip")
RGB_3Daxis(basename, [2])

%% 
source = '/autofs/cluster/connects1/users/I65testrun_51kHz_11132025/';
basename = '/homes/5/kc1708/project/psoct-analysis/I65_51khz_legacy/';
% batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "")
% stitch_section(basename, [19 27; 32 27])
thruplane(basename, gamma, [1], "aip")
RGB_3Daxis(basename, [1])
source = '/autofs/cluster/connects1/users/I65testrun_76kHz_11132025/';
basename = '/homes/5/kc1708/project/psoct-analysis/I65_76khz_legacy/';
% batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "")
% stitch_section(basename, [19 27; 32 27],'Mosaics', {'mosaic_003','mosaic_004'})
thruplane(basename, gamma, [2], "aip")
RGB_3Daxis(basename, [2])