function [simOutput,presentationOutput] = IIR_approx_simulation(cfgStruct)
clc;
close all;
[funcPath,~,~] = fileparts(mfilename('fullpath'));
cd(funcPath);
try
    IIR_approx_subFunctionsIndicator;
catch
    addpath(genpath(fullfile(funcPath,'subFunctions')));
end
%% configuration
try
    %% external config
    cfgStruct;
catch
    %% standalone
    overrideCfg                         = [];
    overrideCfg.firstObj.initAzimuth    = pi/8;
    overrideCfg.filter.polesRadious     = 0.7;
    overrideCfg.filter.polesAzimuth     = pi/4;
    cfgStruct = spatialIIR_getDefaultSimCfg(overrideCfg);
end

%% simulation
%{

Simulation logic:

*   First, the temporal positions of each object will be calculated.

*   The minimal distance to the sensors will determine the "tau_feedback".

*   A delayed (by "tau_feedback") version of the objects positions will be
    converted to delays.
    These delays will serve as an offset from the current time when
    fetching samples from the object's transmitters to the sensors inputs.

*   The simulation will be segmented according to the minimal "tau_feedback"
    so that each segment can be calculated indepedently due to the fact
    that each sample in the segment depends only on "tau_feedback" delayed
    signals.

*   An initial non-feedback signals will be assigned to the sensors inputs
    according to the object positions.

*   In each segment, both the sensor inputs and eahc object's feedback
    signal will be calculated and summed.

*   The feeback cancellation will start after nFilterRounds*tau_feedback.

*   The simulation output will contain :
    *   sensors temporal position

    *   array output
        (starting from t=0)

    *   delayed array output
        (starting from the moment of feedback cancellation execution)
        will serve as an "temporal-aligned-to-objects-position" array
        output.

%}

simOutput          = simulate_IIR_approx_singleScenario(cfgStruct);

try
    cfgStruct.scriptEnables.plotOutput;
catch
    cfgStruct.scriptEnables.plotOutput=1;
end

presentationOutput=[];
if cfgStruct.scriptEnables.plotOutput
    presentationOutput = presentSimOutput(cfgStruct,simOutput);
end