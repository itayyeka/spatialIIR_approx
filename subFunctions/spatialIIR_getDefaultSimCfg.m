function [simCfg] = spatialIIR_getDefaultSimCfg(overrideCfg)
%% sim
try
    simDuration = overrideCfg.simDuration;%sec
catch
    simDuration = 2;%sec
end

simCfg.sim.simDuration = simDuration;
%% scenario
objCfgVec = cell(0);
if true
    %% obj1
    try
        initDistance             = overrideCfg.firstObj.initDistance;%RAD
    catch
        initDistance             = 100;%meter
    end
    
    try
        initAzimuth              = overrideCfg.firstObj.initAzimuth;%RAD
    catch
        initAzimuth              = 0;%RAD
    end
    
    radialVelocity              = 0;%m/s
    complexXyPos                = @(t) exp(1i*initAzimuth)*(initDistance+t*radialVelocity).*ones(size(t));
    cartesianPosition           = @(t) [real(complexXyPos(t(:))), imag(complexXyPos(t(:))), zeros(length(t),1)];
    try
        amplitude               = double(overrideCfg.simulateSpatialFIR);
    catch
        amplitude               = 0; % in default simulation, only the array generate signals.
    end
    sourceMinFreq               = 2e3;%Hz
    sourceMaxFreq               = 2e3;
    sourceSignal                = @(tVec) amplitude*(tVec>0).*exp(1i*2*pi*sourceMinFreq*tVec);
    
    objCfg.sourceMinFreq            = sourceMinFreq;
    objCfg.sourceMaxFreq            = sourceMaxFreq;
    objCfg.sourceSignalAmplitude    = sourceSignal;
    objCfg.sourceSignal             = sourceSignal;
    objCfg.initDistance             = initDistance;
    objCfg.initAzimuth              = initAzimuth;
    objCfg.complexXyPos             = complexXyPos;
    objCfg.cartesianPosition        = cartesianPosition;
    
    objCfgVec{1} = objCfg;
    %     objCfgVec{2} = objCfg;
end

simCfg.scenario.objCfgVec = objCfgVec;
%% physical
propagationVelocity     = 343;%m/s
txPropagationVeclocity  = 343;%m/s
systemLatency           = 0;  %sec
nSensors                = 3;
singleTransmitterFlag   = 1;
syncSigBaseFreq         = 10e3;
nCommunicationChannels  = 3;
syncSigAmp              = 1;

try
    enableFeedback  = overrideCfg.enableFeedback;
catch
    enableFeedback  = 1;
end

try
    enableObjectsReflectors     = overrideCfg.enableObjectsReflectors;
catch
    enableObjectsReflectors     = 1;
end

try
    if overrideCfg.simulateSpatialFIR
        enableFeedback  = 0;
    end
catch
end

enableAttenuation   = 0;

try
    lambdaToSensorDistanceFactor = overrideCfg.lambdaToSensorDistanceFactor;
catch
    lambdaToSensorDistanceFactor = 1/2;
end

maxObjectsFreq              = max(cellfun(@(objCfg) objCfg.sourceMaxFreq,objCfgVec));
try
    if overrideCfg.simulateSpatialFIR
        maxSimulatedFreq    = maxObjectsFreq;
    else
        maxSimulatedFreq    = syncSigBaseFreq;
    end
catch
    maxSimulatedFreq        = max(maxObjectsFreq,syncSigBaseFreq);
end
fSampleFactor = 3;
try
    fSampleFactor = fSampleFactor*max(1,1/overrideCfg.sensorDistanceModFactor);
catch
end

fSample                     = fSampleFactor*maxSimulatedFreq;
distanceBetweenSensors      = (propagationVelocity/maxSimulatedFreq)*lambdaToSensorDistanceFactor;
syncSigDuration             = inf;
try
    syncSigDuration         = overrideCfg.syncSigduration;
catch
end
f_syncSig_singleFreq        = @(tVec,f) syncSigAmp*(tVec>0).*(tVec<syncSigDuration).*exp(1i*2*pi*f*tVec);
dF                          = 100; 
f_syncSig_singleFreq1       = @(tVec) f_syncSig_singleFreq(tVec,syncSigBaseFreq);
f_syncSig_singleFreq2       = @(tVec) f_syncSig_singleFreq(tVec,syncSigBaseFreq+dF);
f_syncSig                   = @(tVec) f_syncSig_singleFreq(tVec,syncSigBaseFreq) + f_syncSig_singleFreq(tVec,syncSigBaseFreq+dF);
ULA_direction               = pi;

modifiedDistanceBetweenSensors = distanceBetweenSensors;
try
    modifiedDistanceBetweenSensors = modifiedDistanceBetweenSensors*overrideCfg.sensorDistanceModFactor;
catch
end

sensorsPosVec               = ...
    modifiedDistanceBetweenSensors*exp(1i*ULA_direction) ...
    * ...
    (0:(nSensors-1));

positionRes                 = 1e-5;

sensorsPos_xVec                                     = real(sensorsPosVec);
sensorsPos_xVec(abs(sensorsPos_xVec)<positionRes)   = 0;
sensorsPos_yVec                                     = imag(sensorsPosVec);
sensorsPos_yVec(abs(sensorsPos_yVec)<positionRes)   = 0;

simCfg.physical.sensorsPos_xVec         = sensorsPos_xVec;
simCfg.physical.sensorsPos_yVec         = sensorsPos_yVec;
simCfg.physical.propagationVelocity     = propagationVelocity;
simCfg.physical.txPropagationVeclocity  = txPropagationVeclocity;
simCfg.physical.systemLatency           = systemLatency;
simCfg.physical.nSensors                = nSensors;
simCfg.physical.singleTransmitterFlag   = singleTransmitterFlag;
simCfg.physical.enableFeedback          = enableFeedback;
simCfg.physical.enableObjectsReflectors = enableObjectsReflectors;
simCfg.physical.enableAttenuation       = enableAttenuation;
simCfg.physical.fSample                 = fSample;
simCfg.physical.distanceBetweenSensors  = distanceBetweenSensors;
simCfg.physical.nCommunicationChannels  = nCommunicationChannels;
simCfg.physical.syncSigBaseFreq         = syncSigBaseFreq;
simCfg.physical.syncSigAmp              = syncSigAmp;
simCfg.physical.f_syncSig               = f_syncSig;
simCfg.physical.f_syncSig_singleFreq    = f_syncSig_singleFreq;
simCfg.physical.f_syncSig_singleFreq1   = f_syncSig_singleFreq1;
simCfg.physical.f_syncSig_singleFreq2   = f_syncSig_singleFreq2;

%% filter
bfCfg.bf_cosPolynomCoefVec      = [0.103 0.484 0.413]; % second order super cardioid
bfCfg.nSensors                  = simCfg.physical.nSensors;
bfCfg.propagationSpeed          = simCfg.physical.propagationVelocity;
bfCfg.distanceBetweenSensors    = simCfg.physical.distanceBetweenSensors;
bfCfg.ULA_direction             = pi;
bfCfg.enablePlot                = 0;
bfCfg.ignoreFirstCoef           = 0;
bfCfg.fSignal                   = maxSimulatedFreq;

try
    bfCfg.nThetaValues          = overrideCfg.nAzimuth;
catch
end
try
    bfCfg.azimuthVec            = overrideCfg.azimuthVec;
catch
end

[...
    sensorCoefVec,...
    hVec_norm,...hVec_norm,...
    ~,...bfNormValues,...
    resultBfNormValues,...resultBfNormValues ...
    ] = ...
    generate_nerrowband_robust_bf(bfCfg);

simCfg.filter.hVec_norm                 = hVec_norm;
simCfg.filter.expectedResponse          = resultBfNormValues;
simCfg.filter.sensorWeights             = sensorCoefVec;
try
    enablePhaseCorrection               = overrideCfg.enablePhaseCorrection;%RAD
catch
    enablePhaseCorrection               = 1;%meter
end
simCfg.filter.enablePhaseCorrection     = enablePhaseCorrection;

try
    enableLimiter                       = overrideCfg.enableLimiter;%RAD
catch
    enableLimiter                       = 1;%meter
end
simCfg.filter.enableLimiter             = enableLimiter;

try
    limiterMaxDb                        = overrideCfg.limiterMaxDb;%RAD
catch
    limiterMaxDb                        = 1;%meter
end
simCfg.filter.limiterMaxDb              = limiterMaxDb;

try
    simulateSpatialFIR                  = overrideCfg.simulateSpatialFIR;%RAD
catch
    simulateSpatialFIR                  = 0;%meter
end
simCfg.filter.simulateSpatialFIR        = simulateSpatialFIR;
end