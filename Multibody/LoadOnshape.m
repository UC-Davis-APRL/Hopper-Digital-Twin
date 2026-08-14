%loads full onshape model, make sure all mates are in initial state, and
%make sure that origin is where you want it to be
BaseDir = fileparts(mfilename('fullpath'));
CadDir = fullfile(BaseDir, 'cad_export');
ModelDir = BaseDir;

FinalModelName = 'rocket_multibody';

url = 'https://cad.onshape.com/documents/501adf4355cd9ac79cf0b56f/w/dd0f8dc5a40bd6e925b0bd82/e/575d2962d9d3080004691efe';


if ~exist(CadDir, 'dir')
    mkdir(CadDir);
end
if bdIsLoaded('rocket_multibody')
    bdclose('rocket_multibody');
end

delete(fullfile(CadDir, '*.step'))
delete(fullfile(CadDir, '*.xml'))
delete(fullfile(CadDir, '*.m'))


BaseDir = fileparts(mfilename('fullpath'));
delete(fullfile(BaseDir, '*.step'))
delete(fullfile(BaseDir, '*.xml'))
%
origDir = pwd;
cd(CadDir);
try
    modelName = smimport(smexportonshape(url))
    cd(origDir);
    addpath(fullfile(BaseDir, 'cad_export'));


    


catch ME
    cd(origDir);   % always restore directory, even on error
    rethrow(ME);
end

save_system(modelName, fullfile(ModelDir, [FinalModelName '.slx']));
if ~strcmp(importedName, FinalModelName)
    close_system(importedName);
end