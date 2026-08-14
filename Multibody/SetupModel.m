BaseDir = fileparts(mfilename('fullpath'));
modelName = 'rocket_multibody';
modelPath = fullfile(BaseDir, [modelName '.slx']);

if ~exist(modelPath, 'file')
    error('SetupModel:NotFound', '%s not found. Run ImportFromOnshape.m first.', modelPath);
end

if bdIsLoaded(modelName), bdclose(modelName); end
load_system(modelPath);
set_param(modelName, 'InitFcn', "addpath(fullfile(fileparts(which(bdroot)), 'cad_export'));");

%% IMU Frame
imuSubsys = 'rocket_multibody/IMU_2_RIGID';
imuPort = [imuSubsys '/IMU_RefFrame'];
addBlockIfAbsent('nesl_utility/Connection Port', imuPort, 'Position', [400 200 440 240]);
refH = get_param([imuSubsys '/ReferenceFrame'], 'PortHandles');
portH = get_param(imuPort, 'PortHandles');
addLineIfAbsent(imuSubsys, refH.RConn(1), portH.RConn(1), 'autorouting', 'on');
imuHandles = get_param(imuSubsys, 'PortHandles');

%% Transform Sensor
sensorPath = [modelName '/TransformSensor_Body'];
addBlockIfAbsent('sm_lib/Frames and Transforms/Transform Sensor', sensorPath, 'Position', [190 332 205 420]);
set_param(sensorPath, 'SenseXYZ', 'on', 'SenseXYZDot', 'on', 'SenseRotationSequence', 'on', ...
                       'SenseOmega', 'on', 'RotationSequence', 'XYZ');
sensorHandles = get_param(sensorPath, 'PortHandles');
worldHandles = get_param('rocket_multibody/Transform', 'PortHandles');
addLineIfAbsent(modelName, worldHandles.RConn(1), sensorHandles.LConn(1), 'autorouting', 'on');
addLineIfAbsent(modelName, sensorHandles.RConn(1), imuHandles.LConn(end), 'autorouting', 'on');

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
addBlockIfAbsent('simulink/Signal Routing/Mux', muxPath, 'Inputs', '4', 'Position', [400 380 430 500]);
muxHandles = get_param(muxPath, 'PortHandles');

for i = 1:numel(outputs)
    convPath = [modelName '/' outputs(i).Name];
    addBlockIfAbsent('nesl_utility/PS-Simulink Converter', convPath, ...
        'Position', [260 330+(i-1)*70 300 360+(i-1)*70]);
    convH = get_param(convPath, 'PortHandles');
    addLineIfAbsent(modelName, sensorHandles.RConn(outputs(i).Port), convH.LConn(1), 'autorouting', 'on');
    addLineIfAbsent(modelName, convH.Outport(1), muxHandles.Inport(i), 'autorouting', 'on');
end

outPath = [modelName '/X'];
addBlockIfAbsent('simulink/Sinks/Out1', outPath, 'Position', [500 420 530 450]);
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
addBlockIfAbsent('simulink/Sources/In1', fPort2Path, 'Position', [405   400   445   430])
fPort2H = get_param(fPort2Path, 'PortHandles');

gimbalHandles = get_param(gimbalPath, 'PortHandles');

addLineIfAbsent( ...
    modelName, ...
    fPort2H.Outport(1), ...
    gimbalHandles.Inport(3), ...
    'autorouting', 'on');


save_system(modelName);
open_system(modelPath);

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