
BaseDir = fileparts(mfilename('fullpath'));
parentModel = 'CompleteSystem';
parentPath = fullfile(BaseDir, [parentModel '.slx']);


libDir = [BaseDir '/' 'Multibody']
libName = 'rocket_multibody_lib.slx';
libPath = fullfile(libDir, libName);
libSubsysName = 'rocket_multibody'; 

paramsDir = [BaseDir '/' 'Params']
paramsFile = 'RocketParameter.m'
paramsPath = fullfile(paramsDir,paramsFile)
ICFile = 'InitialConditions.m'
ICPath = fullfile(paramsDir, ICFile)


refBlock = [libName '/' libSubsysName];

targetBlockPath = [parentModel '/' libSubsysName];

if bdIsLoaded(parentModel), bdclose(parentModel); end
load_system(parentPath);

if ~bdIsLoaded(libName)
    load_system(libPath);   % library must be open for the link to resolve
end

if blockExists(targetBlockPath)
    existingRef = get_param(targetBlockPath, 'ReferenceBlock');
    if strcmp(existingRef, refBlock)
        fprintf('[SKIP] %s already linked to %s\n', targetBlockPath, refBlock);
    else
        fprintf('[REPLACE] %s exists but is not linked correctly (was: %s)\n', ...
            targetBlockPath, existingRef);
        pos = get_param(targetBlockPath, 'Position');
        delete_block(targetBlockPath);
        add_block(refBlock, targetBlockPath, 'Position', pos);
        fprintf('[OK] Re-added as library-linked block\n');
    end
else
    add_block(refBlock, targetBlockPath, 'Position', [300 150 450 350]);
    fprintf('[OK] Added new library-linked block: %s\n', targetBlockPath);
end

cadExportDir = [libDir '/' 'cad_export'];
modelScript = [cadExportDir '/' 'FullAssembly_DataFile.m'];   % <-- now points at Multibody/


if ~exist(cadExportDir, 'dir')
    warning('cad_export not found at expected path: %s', cadExportDir);
end
if ~exist(modelScript, 'file')
    warning('Model script not found at expected path: %s', modelScript);
end
if ~exist(paramsPath, 'file')
    warning('Params script not found at expected path: %s', paramsPath);
end
if ~exist(ICPath, 'file')
    warning('Initial conditions script not found at expected path: %s', ICPath);
end

initFcn = [ ...
    'addpath(''' strrep(cadExportDir, '\', '/') ''');' newline ...
    'run(''' strrep(modelScript, '\', '/') ''');' newline ...
    'addpath(''' strrep(paramsDir, '\', '/') ''');' newline ...
    'run(''' strrep(paramsPath, '\', '/') ''');' newline ...
    'run(''' strrep(ICPath, '\', '/') ''');' ...
];

set_param(parentModel, 'InitFcn', initFcn);
save_system(parentModel);
close_system(libName);   % keep it loaded only as long as needed; comment out if you want it to stay open

function tf = blockExists(blockPath)
try
    get_param(blockPath, 'Handle');
    tf = true;
catch
    tf = false;
end
end