## 0.1.7
- Code Clean-up:
  Unused variables, indentation, etc...
- Hierarchy implementation:
  Params (Default Configurations) -> Scaleio (User Configurations) -> Modules (inherits)
- Configuration check:
  Array, string, integer, boolean, etc...
- install.pp
  Installation of ScaleIO packages adopting O.S Repository
- Created Vagrant for testbed under tests folder

## 0.1.2

Bugfixes:

- Updated device.pp to ensure all types of files are checked before trying to truncate

## 0.1.1

Bugfixes:

- Fixed scaleio_state.rb fact to use pgrep
- Removed sio_volume since not used
- Removed unnecessary parameters
- Updated README file for examples
