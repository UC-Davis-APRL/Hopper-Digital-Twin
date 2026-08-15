%% ReimportFromCache.m — zero Onshape API calls
BaseDir = fileparts(mfilename('fullpath'));
cadExportBackup = fullfile(BaseDir, 'Multibody', 'cad_export_backup');
ModelDir = fullfile(BaseDir, 'Multibody');
FinalModelName = 'rocket_multibody';

if bdIsLoaded(FinalModelName), bdclose(FinalModelName); end

stepFiles = dir(fullfile(cadExportBackup, '*.step'));
xmlFiles = dir(fullfile(cadExportBackup, '*.xml'));
importedName = smimport(fullfile(cadExportBackup, stepFiles(1).name));  % adjust as needed for your smimport signature

save_system(importedName, fullfile(ModelDir, [FinalModelName '.slx']));
if ~strcmp(importedName, FinalModelName)
    close_system(importedName);
end