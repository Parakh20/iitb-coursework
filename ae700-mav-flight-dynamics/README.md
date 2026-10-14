# AE700_Project

Reorganized MATLAB + Simulink AE700 MAV project with modular folders for dynamics, forces, wind, trim, linearization, autopilot, data, and models.

## Quick Start

```matlab
cd('/home/parakh/Desktop/AE700_PROJECT/AE700_Project')
run('matlab/main/run_simulation.m')
```

Optional Simulink architecture run:

```matlab
run('matlab/main/run_simulation_simulink.m')
```

## Outputs

- `results/trim_results.mat`
- `results/linear_models.mat`
- `results/autopilot_results.mat`

## Notes

- `matlab/main/init_params.m` adds all required paths and initializes base-workspace variables (`P`, `SIM`, `WIND`, `AP`, `x0`).
- Main Simulink models are in `simulink/main_models/`.
- File migration trace is in `docs/moved_files.tsv`.
