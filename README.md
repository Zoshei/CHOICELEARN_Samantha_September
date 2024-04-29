# Redundant Learning Experiments    
This repository keeps track of the redundant learning experiments. Initially human behavior.        
Questions: Chris Klink (c.klink@nin.knaw.nl)
   
People involved:
- Samantha Wolff
- Chris Klink
- Paolo Papale
- Owen Dorlandt (student)

## How to run     
This experiment has been set up in Matlab using PTB-3 and the Eyelink toolbox to interact with the Eyelink 1000 eyetracker. To run the experiment you minimally need 2 files:
- `CL_run.m` is a function that runs the actual experiment
- `SettingsFile.m` is a file that defines all experimental parameters

You can execute `CL_run()` with several arguments `CL_run(SettingsFile,Debug,WLOG)` that can also all be omitted for defaults.
- `SettingsFile` is a string indicating which settings file to load. Default = `'CL_settings'`.        
- `Debug` is a boolean used for debugging. It sets the screen to a smaller sub-window and skips participant registration. Default - `false`    
- `WLOG` is used when you consecutively run the experiment with multiple settings files using a wrapper script (see below). If this is the case, the wrapper function, e.g. `CL_RunExp` will collect participant data only once and prevent the `CL_run` function to do it again.

## Using a wrapper script     
A wrapper script, e.g. `CL_RunExp`, can be used to run several versions of the experiment consecutively without experimenter interference. It will collect participant data once and then run the experiment as defined. You should consider saving the logs from different 'types' of the experiment in different subfolders using the `HARDWARE.LogLabel` definition from the settings file.