%loads full onshape model, make sure all mates are in initial state, and
%make sure that origin is where you want it to be
BaseDir = fileparts(mfilename('fullpath'));
CadDir = fullfile(BaseDir, 'cad_export');
ModelDir = fullfile(BaseDir, 'Multibody');
FinalModelName = 'rocket_multibody';
url = 'https://cad.onshape.com/documents/501adf4355cd9ac79cf0b56f/w/dd0f8dc5a40bd6e925b0bd82/e/575d2962d9d3080004691efe';

if ~exist(CadDir, 'dir')
    mkdir(CadDir);
end
if ~exist(ModelDir, 'dir')
    mkdir(ModelDir);
end

delete(fullfile(CadDir, '*.step'))
delete(fullfile(CadDir, '*.xml'))

origDir = pwd;
cd(CadDir);
try
    importedName = smimport(smexportonshape(url));
    cd(origDir);
catch ME
    cd(origDir);   % always restore directory, even on error
    rethrow(ME);
end

% --- THIS is what was missing: actually save it to disk ---
save_system(importedName, fullfile(ModelDir, [FinalModelName '.slx']));
if ~strcmp(importedName, FinalModelName)
    close_system(importedName);
end

SetupModel