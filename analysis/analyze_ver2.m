%% ========================================================================
% USER INSTRUCTIONS
%
% This script processes PS-OCT 3D tile datasets using the following steps:
%   1. batch_process_cc      – compute en-face projections for each tile
%   2. stitch_section        – stitch the tiles for normal / tilted illumination
%   3. thruplane             – generate thru-plane visualizations
%   4. RGB_3Daxis            – generate RGB-encoded 3D axis plots
%
% Before running the script, the user must provide:
%
% ------------------------------------------------------------------------
% 1) SOURCE DIRECTORY  (source)
%    • Folder containing the 3D tiles from the PS-OCT scan.
%    • Example:
%          source = '/path/to/your/tiles/';
%
% 2) OUTPUT DIRECTORY / BASENAME  (basename)
%    • Directory where all processing results will be saved.
%    • The script will create an internal “processed/” folder.
%    • Example:
%          basename = '/path/to/output/EXP1/';
%
% 3) EN-FACE PARAMETERS for batch_process_cc
%    • beginZ      – starting z-depth for en-face calculation
%    • depthRange  – depth thickness to average for en-face projection
%    • Example:
%          batch_process_cc(source, [basename 'processed/'], beginZ, depthRange)
%
% 4) TILE CONFIGURATION for stitch_section
%    • A 2×2 matrix specifying tile positions for:
%        [ normal_illumination ; tilted_illumination ]
%    • Example:
%          stitch_section(basename, [5 6; 8 6])
%    • Optional: specify mosaics if needed:
%          stitch_section(basename, tileConfig, 'Mosaics', {'mosaic_001','mosaic_003'})
%
% 5) SLICE NUMBER for registration in thruplane / RGB_3Daxis
%    • Example:
%          thruplane(basename, gamma, [sliceNumber])
%          RGB_3Daxis(basename, [sliceNumber])
%
% ------------------------------------------------------------------------
% After filling in the above parameters for each dataset,
% run the script to process all experiments listed below.
% ------------------------------------------------------------------------
% Some naming convention is hard coded, for example this needs to be
% modified to be used on I80 data, as the tile number in the file name is
% padded to 4 digits
% ========================================================================

gamma = -15;

%% 
source = '/vast/fiber/projects/20250919_CCtest/';
basename = '/homes/5/kc1708/project/psoct-analysis/EXP1_11-90_test/';
batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "exp2")
stitch_section(basename, [5 6; 8 6])
thruplane(basename, gamma, [1])
RGB_3Daxis(basename, [1])
%% 
source = '/vast/fiber/projects/20250919_CCtest2_15degree/';
basename = '/homes/5/kc1708/project/psoct-analysis/EXP2_11-90_test/';
batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "exp2")
stitch_section(basename, [7 6; 5 6])
thruplane(basename, gamma, [1])
RGB_3Daxis(basename, [1])
%% 
source = '/vast/fiber/projects/20250920_CCtest3_15degrees_CCW/';
basename = '/homes/5/kc1708/project/psoct-analysis/EXP3_11-90_test/';
batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "exp2")
stitch_section(basename, [9 5; 13 5])
thruplane(basename, gamma, [1])
RGB_3Daxis(basename, [1])
%% 
source = '/vast/fiber/projects/20250920_CCtest4_30degrees_CW/';
basename = '/homes/5/kc1708/project/psoct-analysis/EXP4_11-90_test/';
batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "exp2")
stitch_section(basename, [13 5; 9 5])
thruplane(basename, gamma, [1])
RGB_3Daxis(basename, [1])
%% 
source = '/vast/fiber/projects/20250920_3d_axis_3_illuminations/';
basename = '/homes/5/kc1708/project/psoct-analysis/EXP5_11-90_test/';
gamma = 10;
% batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "exp2")
% stitch_section(basename, [6 5; 8 5], 'Mosaics', {'mosaic_001','mosaic_003'})
thruplane(basename, gamma, [1])
RGB_3Daxis(basename, [1])
%% 
source = '/vast/fiber/projects/20250920_3d_axis_3_illuminations/';
basename = '/homes/5/kc1708/project/psoct-analysis/EXP5-2_11-90_test/';
batch_process_cc(source, [basename 'processed/'], 11, 80, "new", "exp2")
stitch_section(basename, [6 5; 11 5],'Mosaics', {'mosaic_001','mosaic_002'})
thruplane(basename, gamma, [1])
RGB_3Daxis(basename, [1])