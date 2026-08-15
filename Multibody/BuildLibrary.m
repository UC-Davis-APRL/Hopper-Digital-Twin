%% BuildLibrary.m
BaseDir = fileparts(mfilename('fullpath'));
modelName = 'rocket_multibody';
modelPath = fullfile(BaseDir, [modelName '.slx']);

libName = 'rocket_multibody_lib';
libPath = fullfile(BaseDir, [libName '.slx']);

% --- Force a clean rebuild every run ---
if bdIsLoaded(modelName), bdclose(modelName); end
if bdIsLoaded(libName), bdclose(libName); end
if exist(libPath, 'file')
    delete(libPath);   % remove stale library file so new_system/save_system starts fresh
end

load_system(modelPath);

new_system(libName, 'Library');
open_system(libName);

subsysPath = [libName '/' modelName];
add_block('built-in/Subsystem', subsysPath);

Simulink.BlockDiagram.copyContentsToSubSystem(modelName, subsysPath);

save_system(libName, libPath);
close_system(modelName, 0);
close_system(libName);

fprintf('[OK] Rebuilt library: %s\n', libPath);