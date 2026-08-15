BaseDir = fileparts(mfilename('fullpath'));
modelName = 'rocket_multibody';
modelPath = fullfile(BaseDir, [modelName '.slx']);

if ~exist(modelPath, 'file')
    error('SetupModel:NotFound', '%s not found. Run ImportFromOnshape.m first.', modelPath);
end

if bdIsLoaded(modelName), bdclose(modelName); end
load_system(modelPath);

%% Base Setup
set_param(modelName, 'InitFcn', "addpath(fullfile(fileparts(which(bdroot)), 'cad_export'));");

set_param(modelName, 'SimscapeLogType', 'None');
mechConfigPath = [modelName '/MechanismConfiguration'];
if blockExists(mechConfigPath)
    set_param(mechConfigPath, 'UniformGravity', 'Constant', 'GravityVector', '[0,0,-9.81]');
    fprintf('[OK] Gravity set to [0,0,-9.81] on %s\n', mechConfigPath);
else
    warning('SetupModel:NoMechConfig', '%s not found — gravity not set.', mechConfigPath);
end

%% 6-DOF Joint + Transform Sensor (measuring across the joint)
transformPath = [modelName '/Transform'];
worldHandles = get_param(transformPath, 'PortHandles');

imuSubsys = 'rocket_multibody/IMU_2_RIGID';
imuHandles = get_param(imuSubsys, 'PortHandles');

deleteAllLinesOnPort(worldHandles.RConn(1), 'Transform RConn(1)');
deleteAllLinesOnPort(imuHandles.LConn(2), 'IMU LConn(2)');



% Re-fetch after delete_line before using worldHandles again
worldHandles = get_param(transformPath, 'PortHandles');

% Insert 6-DOF Joint between Transform and IMU
sixDofPath = [modelName '/World_6DOF'];
addBlockIfAbsent('sm_lib/Joints/6-DOF Joint', sixDofPath, 'Position', [-360   830  -300   890]);
sixDofHandles = get_param(sixDofPath, 'PortHandles');

addLineIfAbsent(modelName, worldHandles.RConn(1), sixDofHandles.LConn(1), 'autorouting', 'on');
addLineIfAbsent(modelName, sixDofHandles.RConn(1), imuHandles.LConn(2), 'autorouting', 'on');

% Re-fetch all handles fresh after the structural changes above
worldHandles = get_param(transformPath, 'PortHandles');
sixDofHandles = get_param(sixDofPath, 'PortHandles');
imuHandles = get_param(imuSubsys, 'PortHandles');

% Transform Sensor measures across the joint: base = Transform output, follower = IMU input
sensorPath = [modelName '/TransformSensor_Body'];
addBlockIfAbsent('sm_lib/Frames and Transforms/Transform Sensor', sensorPath, 'Position', [190 332 205 420]);
set_param(sensorPath, 'SenseXYZ', 'on', 'SenseXYZDot', 'on', 'SenseRotationSequence', 'on', ...
                       'SenseOmega', 'on', 'RotationSequence', 'XYZ');
sensorHandles = get_param(sensorPath, 'PortHandles');
% Branch base connection off Transform's output port (world side of 6DOF)
if get_param(sensorHandles.LConn(1), 'Line') == -1
    add_line(modelName, worldHandles.RConn(1), sensorHandles.LConn(1), 'autorouting', 'on');
    fprintf('[OK]   line   Transform (branch) -> TransformSensor base\n');
else
    fprintf('[SKIP] line   TransformSensor base already connected\n');
end

% Branch follower connection off the 6DOF->IMU port (follower side of 6DOF)
if get_param(sensorHandles.RConn(1), 'Line') == -1
    add_line(modelName, sixDofHandles.RConn(1), sensorHandles.RConn(1), 'autorouting', 'on');
    fprintf('[OK]   line   6DOF/IMU (branch) -> TransformSensor follower\n');
else
    fprintf('[SKIP] line   TransformSensor follower already connected\n');
end

%% Revolutes (alpha, beta)
jointNames = {'Revolute1', 'Revolute2'};
inputNames = {'alpha_cmd', 'beta_cmd'};
convNames  = {'PS_Alpha', 'PS_Beta'};
gimbalPath = [modelName '/Gimbal_Assembly_1'];

for i = 1:numel(jointNames)
    jointPath = [gimbalPath '/' jointNames{i}];
    inPath = [gimbalPath '/' inputNames{i}];
    convPath = [gimbalPath '/' convNames{i}];

    set_param(jointPath, 'LowerLimitSpecify', 'on', 'LowerLimitBound', '-15', 'LowerLimitBoundUnits', 'deg', ...
                          'UpperLimitSpecify', 'on', 'UpperLimitBound', '15', 'UpperLimitBoundUnits', 'deg', ...
                          'MotionActuationMode', 'InputMotion', 'TorqueActuationMode', 'ComputedTorque');

    addBlockIfAbsent('simulink/Sources/In1', inPath, 'Position', [50 100+i*80 90 130+i*80]);
    addBlockIfAbsent('nesl_utility/Simulink-PS Converter', convPath, 'Position', [150 100+i*80 190 130+i*80]);

    inH = get_param(inPath, 'PortHandles');
    convH = get_param(convPath, 'PortHandles');
    jointH = get_param(jointPath, 'PortHandles');

    addLineIfAbsent(gimbalPath, inH.Outport(1), convH.Inport(1), 'autorouting', 'on');
    addLineIfAbsent(gimbalPath, convH.RConn(1), jointH.LConn(end), 'autorouting', 'on');
end

gimbalHandles = get_param(gimbalPath, 'PortHandles');

%% Top-level gimbal command inputs
for i = 1:2
    inPath = [modelName '/' inputNames{i}];
    addBlockIfAbsent('simulink/Sources/In1', inPath, 'Position', [50 100+(i-1)*100 80 130+(i-1)*100]);
    inH = get_param(inPath, 'PortHandles');
    addLineIfAbsent(modelName, inH.Outport(1), gimbalHandles.Inport(i), 'autorouting', 'on');
end

%% Transform Sensor Outputs -> Mux -> X
outputs = struct('Name', {'PS_XYZ', 'PS_XYZDot', 'PS_Rotation', 'PS_Omega'}, 'Port', {4, 5, 2, 3});

muxPath = [modelName '/TransformSensor_Mux'];
addBlockIfAbsent('simulink/Signal Routing/Mux', muxPath, 'Inputs', '4', 'Position', [-110   680   -80   800]);
muxHandles = get_param(muxPath, 'PortHandles');

for i = 1:numel(outputs)
    convPath = [modelName '/' outputs(i).Name];
    addBlockIfAbsent('nesl_utility/PS-Simulink Converter', convPath, ...
        'Position', [-260 640+(i-1)*70 -300 650+(i-1)*70]);
    convH = get_param(convPath, 'PortHandles');
    addLineIfAbsent(modelName, sensorHandles.RConn(outputs(i).Port), convH.LConn(1), 'autorouting', 'on');
    addLineIfAbsent(modelName, convH.Outport(1), muxHandles.Inport(i), 'autorouting', 'on');
end

outPath = [modelName '/X'];
addBlockIfAbsent('simulink/Sinks/Out1', outPath, 'Position', [-25   725     5   755]);
outH = get_param(outPath, 'PortHandles');
addLineIfAbsent(modelName, muxHandles.Outport(1), outH.Inport(1), 'autorouting', 'on');

%% Motor Thrust
motorPath = [modelName '/Gimbal_Assembly_1/Motor_Assembly_1_RIGID'];

connPath = [motorPath '/ExternalForce_Frame'];
addBlockIfAbsent('nesl_utility/Connection Port', connPath, 'Position', [450 200 490 240]);

xformH = get_param([motorPath '/Transform2'], 'PortHandles');
connH = get_param(connPath, 'PortHandles');
addLineIfAbsent(motorPath, xformH.RConn(1), connH.RConn(1), 'autorouting', 'on');

forcePath = [gimbalPath '/' 'Motor_ExternalForce'];
addBlockIfAbsent('sm_lib/Forces and Torques/External Force and Torque', forcePath, 'Position', [700 300 860 880]);
set_param(forcePath, 'EnableForceZ', 'on');

fConvPath = [gimbalPath '/' 'PS_MotorForce'];
addBlockIfAbsent('nesl_utility/Simulink-PS Converter', fConvPath, 'Position', [500 400 540 430]);

fPortPath = [gimbalPath '/' 'In_MotorForce'];
addBlockIfAbsent('simulink/Sources/In1', fPortPath, 'Position', [405   400   445   430])


fPortH = get_param(fPortPath, 'PortHandles');
fConvH = get_param(fConvPath, 'PortHandles');
forceH = get_param(forcePath, 'PortHandles');
addLineIfAbsent(gimbalPath, fConvH.RConn(1), forceH.LConn(1), 'autorouting', 'on');
addLineIfAbsent(gimbalPath, fPortH.Outport(1), fConvH.Inport(1), 'autorouting', 'on');


port = get_param(motorPath, 'PortHandles')
addLineIfAbsent(gimbalPath, forceH.RConn(1), port.LConn(2), 'autorouting', 'on')

fPort2Path = [modelName '/' 'In_MotorForce']
addBlockIfAbsent('simulink/Sources/In1', fPort2Path, 'Position', [90   145   130   175])
fPort2H = get_param(fPort2Path, 'PortHandles');

gimbalHandles = get_param(gimbalPath, 'PortHandles');

addLineIfAbsent( ...
    modelName, ...
    fPort2H.Outport(1), ...
    gimbalHandles.Inport(3), ...
    'autorouting', 'on');


%% Fix PS Converter input derivatives (Alpha/Beta gimbal commands)
psConvertersNeedingDerivs = {'PS_Alpha', 'PS_Beta'};
filterTimeConstant = '1e-3';   % adjust based on your control bandwidth

for i = 1:numel(psConvertersNeedingDerivs)
    convPath = [gimbalPath '/' psConvertersNeedingDerivs{i}];
    if blockExists(convPath)
        set_param(convPath, ...
            'FilteringAndDerivatives', 'filter', ...
            'InputFilterTimeConstant', filterTimeConstant);
        fprintf('[OK] Input filtering enabled on %s\n', convPath);
    else
        warning('SetupModel:NoPSConverter', '%s not found.', convPath);
    end
end


save_system(modelName);




%% Local helper functions

function addBlockIfAbsent(blockType, blockPath, varargin)
% Add blockPath only if it doesn't already exist; leaves existing blocks untouched.
% Prints [OK]/[SKIP]/[FAIL] so status is visible without stopping the script.
    if blockExists(blockPath)
        fprintf('[SKIP] block  %s already exists\n', blockPath);
        return;
    end
    try
        add_block(blockType, blockPath, varargin{:});
        fprintf('[OK]   block  %s\n', blockPath);
    catch ME
        fprintf('[FAIL] block  %s -- %s\n', blockPath, ME.message);
    end
end

function addLineIfAbsent(sysPath, srcPort, dstPort, varargin)
% Wire srcPort -> dstPort only if dstPort has no incoming line yet.
% srcPort/dstPort must be numeric port handles (get_param(block,'PortHandles')).
% Prints [OK]/[SKIP]/[FAIL] so status is visible without stopping the script.
    dstBlock = get_param(dstPort, 'Parent');
    existingLine = get_param(dstPort, 'Line');
    if existingLine ~= -1
        fprintf('[SKIP] line   -> %s already connected\n', dstBlock);
        return;
    end
    try
        add_line(sysPath, srcPort, dstPort, varargin{:});
        fprintf('[OK]   line   -> %s\n', dstBlock);
    catch ME
        fprintf('[FAIL] line   -> %s -- %s\n', dstBlock, ME.message);
    end
end

function tf = blockExists(blockPath)
% Returns true if blockPath resolves to an existing block, false otherwise.
try
    get_param(blockPath, 'Handle');
    tf = true;
catch
    tf = false;
end
end

function deleteAllLinesOnPort(portHandle, label)
% Deletes the primary line on a port AND any branch lines hanging off it.
    ln = get_param(portHandle, 'Line');
    if ln == -1
        fprintf('[SKIP] no line on %s\n', label);
        return;
    end

    linesToDelete = collectLineAndBranches(ln, containers.Map('KeyType','double','ValueType','logical'));

    % Delete children before parents so we don't hit invalid-handle errors
    % from a parent delete cascading and removing its own children first.
    for i = numel(linesToDelete):-1:1
        try
            delete_line(linesToDelete(i));
            fprintf('[OK]   deleted line %g on %s\n', linesToDelete(i), label);
        catch ME
            fprintf('[FAIL] could not delete line %g on %s -- %s\n', linesToDelete(i), label, ME.message);
        end
    end
end

function allLines = collectLineAndBranches(lineHandle, visited)
% Recursively gathers a line and all of its branch children.
% Guards against cycles using a visited-set keyed on line handle.
    if isKey(visited, lineHandle)
        allLines = [];   % already visited -- stop here, avoid infinite loop
        return;
    end
    visited(lineHandle) = true;

    allLines = lineHandle;
    children = get_param(lineHandle, 'LineChildren');
    for i = 1:numel(children)
        allLines = [allLines, collectLineAndBranches(children(i), visited)]; %#ok<AGROW>
    end
end