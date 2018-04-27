function [] = IIR_approx_testbench()
close all;
clc;

try
    IIR_approx_subFunctionsIndicator;
catch
    [funcPath, ~, ~] = fileparts(mfilename('fullpath'));
    addpath(genpath(fullfile(funcPath,'subFunctions')));
    addpath(genpath(fullfile(funcPath,'theory')));
    IIR_approx_subFunctionsIndicator;
end

%% tbCfg
tbCfg.nAzimuth                      = 36;
tbCfg.simDuration                   = 10;
tbCfg.lambdaToSensorDistanceFactor  = 1/10;
tbCfg.enableFeedback                = 1;
tbCfg.enablePhaseCorrection         = 1;
tbCfg.enableLimiter                 = 0;
tbCfg.limiterMaxDb                  = 20;
tbCfg.simulateSpatialFIR            = 0;

%% generate simCfg
simCfg.scriptEnables.plotOutput = 0;

%% run simulation
arrayReponse_maxAmpMat          = [];
arrayReponse_temporalMat        = [];
azimuthVec                      = linspace(0,2*pi,tbCfg.nAzimuth);
enablePhaseCorrection           = tbCfg.enablePhaseCorrection;
enableLimiter                   = tbCfg.enableLimiter;
lambdaToSensorDistanceFactor    = tbCfg.lambdaToSensorDistanceFactor;
limiterMaxDb                    = tbCfg.limiterMaxDb;
simDuration                     = tbCfg.simDuration;

overrideCfg                                 = [];
overrideCfg.simDuration                     = simDuration;
overrideCfg.enablePhaseCorrection           = enablePhaseCorrection;
overrideCfg.enableLimiter                   = enableLimiter;
overrideCfg.limiterMaxDb                    = limiterMaxDb;
overrideCfg.lambdaToSensorDistanceFactor    = lambdaToSensorDistanceFactor;
overrideCfg.nAzimuth                        = tbCfg.nAzimuth;
overrideCfg.azimuthVec                      = azimuthVec;
overrideCfg.enableFeedback                  = tbCfg.enableFeedback;
overrideCfg.simulateSpatialFIR              = tbCfg.simulateSpatialFIR;

parfor azimuthId=1:tbCfg.nAzimuth
    curOverrideCfg                              = overrideCfg;
    curOverrideCfg.firstObj.initAzimuth         = azimuthVec(azimuthId);
    simCfg                                      = spatialIIR_getDefaultSimCfg(curOverrideCfg);
    simCfg.scriptEnables.plotOutput             = 0;
    [simOutput_CELL{azimuthId},~]               = IIR_approx_simulation(simCfg);
end

simCfg                  = spatialIIR_getDefaultSimCfg(overrideCfg);

minSimLength            = min(reshape(cellfun(@(simOut) length(simOut.yOut(:)), simOutput_CELL),[],1));
arrayReponse_amp        = cellfun(@(simOut) abs(simOut.yOut(end)), simOutput_CELL);
arrayReponse_temporal   = ... this is the max value across all azimuths
    max(...
    cell2mat(...
    reshape(...
    cellfun(...
    @(simOut) reshape(abs(simOut.yOut(1:minSimLength)),[],1), ...
    simOutput_CELL, 'UniformOutput', false ...
    )...cellfun
    ,1,[]) ...reshape
    ) ...cell2mat
    ,[],2) ...
    ;

arrayReponse_temporalMat        = [arrayReponse_temporalMat arrayReponse_temporal(1:minSimLength)];
arrayReponse_amp_normalized     = arrayReponse_amp/max(arrayReponse_amp(:));
arrayReponse_maxAmpMat          = [arrayReponse_maxAmpMat arrayReponse_amp_normalized(:)];

timeVec = linspace(0,tbCfg.simDuration,size(arrayReponse_temporalMat,1));
figure;plot(timeVec,db(arrayReponse_temporalMat));
title('Max array gain (sweeped through all azimuths) vs. time - single speaker scenario');
ylabel('dB');
xlabel('time[Sec]');

if ~tbCfg.simulateSpatialFIR
    expectedResponse        = 1./simCfg.filter.expectedResponse;
else
    expectedResponse        = simCfg.filter.expectedResponse;
end
expectedResponseNorm    = expectedResponse/max(abs(expectedResponse));
expectedResponseNormAbs = abs(expectedResponseNorm);

figure;
plot(azimuthVec/pi,db([expectedResponseNormAbs(:) arrayReponse_maxAmpMat(:)]));
legend({'expected response', 'simulation response'});
title('Array temporal response complex amplitude (sweeped through all azimuths) - single speaker scenario');
ylabel('dB');
xlabel('azimuth[Rad]');

end