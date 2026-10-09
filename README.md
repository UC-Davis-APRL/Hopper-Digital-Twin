# TVC^2

This is the APRL repository for the controls subteam digital twin model for the hopper.

## Project overview

- Top-level simulation model: `CompleteSystem.slx`
- Core maathematical dynamics model: `Dynamics.m`
- System update/link script: `UpdateSystem.m`
- Rocket parameters: `Params/`
- Multibody CAD and Simscape assembly library: `Multibody/`

## Project structure

```text
TVC^2/
├── CompleteSystem.slx              # Main Simulink system model
├── Dynamics.m                      # Nonlinear rocket dynamics equations
├── UpdateSystem.m                  # Connects the library model into the top-level system and configures init data
├── TVC^2.prj                      # MATLAB project file
├── README.md                      # Project documentation
├── Params/
│   ├── InitialConditions.m        # Initial state for simulation
│   └── RocketParameter.m          # Physical constants, inertia, mass, and gimbal tuning
├── Multibody/
│   ├── BuildLibrary.m             # Builds/updates the multibody library
│   ├── LoadOnshape.m              # Loads CAD model data from Onshape export
│   ├── ReimportFromCache.m        # Reimports cached CAD data
│   ├── SetupModel.m               # Configures the Simscape multibody model and signal wiring
│   ├── rocket_multibody_lib.slx   # Multibody library for reusable model blocks
│   ├── rocket_multibody.slx       # Editable multibody assembly model
│   ├── cad_export/                # Exported STEP/CAD geometry and generated data files
│   │
│   ├── rocket_multibody_pristine.slx  # Clean/reference multibody version
│   ├── cad_export_backup/         # Backup copy of CAD export files 
│   │
│   └── ...
│
├── resources/
│   └── project/
│       └── ...                    # MATLAB project resources / internal metadata
│
├── .gitignore
└── .git/
```

## Key files and responsibilities

### `Dynamics.m`
Contains the state-space nonlinear dynamics used by the rocket simulation. It computes:

- translational motion
- rotational dynamics
- Euler angle kinematics
- gimbal actuator dynamics
- thrust vector effect from the motor and TVC commands

### `UpdateSystem.m`
This script links the `rocket_multibody_lib.slx` model into `CompleteSystem.slx` and sets the initialization callback so the model loads:

- generated CAD data
- parameter definitions
- initial conditions

This is the usual setup step when the model libraries or references need to be refreshed.

### `Params/`
This folder stores model constants and initialization data:

- `RocketParameter.m`: mass, inertia, gravity, thrust-related parameters, and gimbal gains
- `InitialConditions.m`: starting position, attitude, velocity, and actuation state

### `Multibody/`
This folder contains the generated multibody representation of the rocket and associated CAD assembly files. It includes the Simscape model wiring and library setup scripts used to rebuild the reusable multibody block.

## Typical workflow

1. Open MATLAB Project
2. Run `UpdateSystem.m` to ensure the top-level system references the correct multibody library block.
3. Open `CompleteSystem.slx` and run the simulation.
4. If the CAD or multibody assembly changes, update the library by running the scripts in `Multibody/` as needed.

## Library Update Guide

On first install, and any time the CAD changes, you must regenerate the multibody model and rebuild the Simulink library before the top-level system will reflect the latest geometry.

1. Open the MATLAB project in this folder.
2. Run `Multibody/LoadOnshape.m` to import the latest assembly from Onshape. This script requires an Onshape account and the document URL in the script. It clears the current CAD export folder, re-imports the STEP/XML files, saves a working `rocket_multibody.slx`, and optionally updates `cad_export_backup` and `rocket_multibody_pristine.slx` which can be loaded later.

   > **⚠️ Onshape rate limits:** the Onshape export API can rate-limit fairly easily, especially if you re-run `LoadOnshape.m` repeatedly in a short period (e.g. while debugging an import issue). If you hit a rate limit, wait a while before retrying rather than repeatedly re-running the script, and prefer `ReimportFromCache.m` (step 3) whenever you don't actually need fresh geometry from Onshape.

3. If the Onshape import fails or you just want to restore the last known-good CAD export without hitting the API, run `Multibody/ReimportFromCache.m` instead. This reuses the cached backup under `Multibody/cad_export_backup` and restores the simulink from `Multibody/rocket_multibody_pristine.slx`.
4. Run `Multibody/SetupModel.m` to configure the Simscape model: set gravity, add the 6-DOF joint, connect the transform sensor, create the gimbal inputs, wire the signal outputs, and configure the motor force path.
5. Run `Multibody/BuildLibrary.m` to rebuild the library model `rocket_multibody_lib.slx` from the working multibody model.

this will also require the running of `UpdateSystem.m` for `CompleteSystem.slx` to reflect the updates.

If something goes wrong during the Onshape import, the usual recovery path is:

- check that the Onshape document URL is still valid
- confirm that the CAD export folder is writable
- run `LoadOnshape.m` in load-from-cache mode
- rebuild the library folowing the guide from step 4 and rerun `UpdateSystem.m`

In practice, the easiest workflow is to run the import/build/setup sequence in order whenever the CAD geometry changes, and then run `UpdateSystem.m` before testing the full system model.