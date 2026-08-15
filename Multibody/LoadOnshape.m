%loads full onshape model, make sure all mates are in initial state, and
%make sure that origin is where you want it to be
BaseDir = fileparts(mfilename('fullpath'));
CadDir = fullfile(BaseDir, 'cad_export');
FinalModelName = 'rocket_multibody';
url = 'https://cad.onshape.com/documents/501adf4355cd9ac79cf0b56f/w/dd0f8dc5a40bd6e925b0bd82/e/575d2962d9d3080004691efe';
cadExportBackup = fullfile(BaseDir, 'cad_export_backup');

if ~exist(CadDir, 'dir')
    mkdir(CadDir);
end

if bdIsLoaded(FinalModelName)
    close_system(FinalModelName, 0);  % 0 = don't save
end

%% Ask whether to reuse a cached backup instead of re-importing from Onshape
useCache = false;
if exist(cadExportBackup, 'dir')
    answer = input('A cached CAD export backup already exists.\nUse cached backup instead of re-importing from Onshape? [y/N]: ', 's');
    useCache = strcmpi(strtrim(answer), 'y');
end

pristineCopy = fullfile(BaseDir, [FinalModelName '_pristine.slx']);
finalSlxPath = fullfile(BaseDir, [FinalModelName '.slx']);

if useCache
    fprintf('[CACHE] Using cached backup from %s (no re-import, backup left untouched).\n', cadExportBackup);

    % Restore cad_export from the cached backup
    delete(fullfile(CadDir, '*.step'))
    delete(fullfile(CadDir, '*.xml'))
    delete(fullfile(CadDir, '*.m'))
    copyfile(cadExportBackup, CadDir, 'f');

    if ~exist(pristineCopy, 'file')
        error('ImportFromOnshape:MissingPristineCopy', ...
            ['Cached backup found but %s does not exist. ' ...
             'Cannot use cache -- rerun without caching to perform a fresh import.'], pristineCopy);
    end

    % Reset the working model back to the pristine reference copy
    if bdIsLoaded(FinalModelName)
        close_system(FinalModelName, 0);   % 0 = don't save whatever changes were in memory
    end
    copyfile(pristineCopy, finalSlxPath, 'f');
    fprintf('[CACHE] Reset %s from pristine copy: %s\n', finalSlxPath, pristineCopy);

else
    %% Fresh import from Onshape
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

    

    %% Ask before overwriting the existing backup
    overwriteBackup = true;
    if exist(cadExportBackup, 'dir')
        answer = input('An existing cad_export_backup was found.\nOverwrite it with this new import? [y/N]: ', 's');
        overwriteBackup = strcmpi(strtrim(answer), 'y');
    end

    if overwriteBackup
        if exist(cadExportBackup, 'dir'), rmdir(cadExportBackup, 's'); end
        copyfile(CadDir, cadExportBackup);
        copyfile(fullfile(BaseDir, [FinalModelName '.slx']), pristineCopy, 'f');
        fprintf('[OK] Backup updated at %s\n', cadExportBackup);
    else
        fprintf('[SKIP] Backup left untouched at %s (new import NOT cached).\n', cadExportBackup);
    end
end

%% Load the working model (pristine copy stays on disk, untouched, as a reference)
if bdIsLoaded(FinalModelName)
    close_system(FinalModelName, 0);
end
load_system(finalSlxPath);
fprintf('[OK] Loaded working model: %s\n', finalSlxPath);