%loads full onshape model, make sure all mates are in initial state, and
%make sure that origin is where you want it to be
BaseDir = fileparts(mfilename('fullpath'));
CadDir = fullfile(BaseDir, 'cad_export');
FinalModelName = 'rocket_multibody';
url = 'https://cad.onshape.com/documents/501adf4355cd9ac79cf0b56f/w/dd0f8dc5a40bd6e925b0bd82/e/575d2962d9d3080004691efe';

if ~exist(CadDir, 'dir')
    mkdir(CadDir);
end


if bdIsLoaded(FinalModelName)
    close_system(FinalModelName, 0);  % 0 = don't save
end

delete(fullfile(CadDir, '*.step'))
delete(fullfile(CadDir, '*.xml'))
delete(fullfile(CadDir, '*.m'))
origDir = pwd;
cd(CadDir);
try
    importedName = smimport(smexportonshape(url));
    cd(origDir);
catch ME
    cd(origDir);   % always restore directory, even on error
    rethrow(ME);
end

save_system(importedName, fullfile(BaseDir, [FinalModelName '.slx']));
if ~strcmp(importedName, FinalModelName)
    close_system(importedName, 0);
end

pristineCopy = fullfile(BaseDir, [FinalModelName '_pristine.slx']);
copyfile(fullfile(BaseDir, [FinalModelName '.slx']), pristineCopy, 'f');

cadExportBackup = fullfile(BaseDir, 'cad_export_backup');
if exist(cadExportBackup, 'dir'), rmdir(cadExwportBackup, 's'); end
copyfile(CadDir, cadExportBackup);