%loads full onshape model, make sure all mates are in initial state, and
%make sure that origin is where you want it to be


BaseDir = fileparts(mfilename('fullpath'));
delete(fullfile(BaseDir, '*.step'))
delete(fullfile(BaseDir, '*.xml'))
%
smimport(smexportonshape('https://cad.onshape.com/documents/501adf4355cd9ac79cf0b56f/w/dd0f8dc5a40bd6e925b0bd82/e/575d2962d9d3080004691efe'))

