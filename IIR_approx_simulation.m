function [] = IIR_approx_simulation(cfgStruct)
clc;

%% configuration
try
    %% external config
    cfgStruct;
catch
    %% standalone
    if true
        %% sim
        simDuration = 100;%sec
        
        cfgStruct.sim.simDuration = simDuration;
        %% scenario
        objCfgVec = cell(0);
        if true
            %% obj1
            initDistance             = 100;%meter
            initAzimuth              = pi/4;%RAD
            complexXyPos             = @(t) initDistance*exp(1i*initAzimuth);
            cartesianPosition        = @(t) [real(complexXyPos(t)), imag(complexXyPos(t)), 0];
            sourceMinFreq            = 2e3;%Hz
            sourceMaxFreq            = 2e3;
            sourceSignal             = @(t) cos(2*pi*sourceMinFreq);
            
            objCfg.sourceMinFreq     = sourceMinFreq;
            objCfg.sourceMaxFreq     = sourceMaxFreq;
            objCfg.sourceSignal      = sourceSignal;
            objCfg.initDistance      = initDistance;
            objCfg.initAzimuth       = initAzimuth;
            objCfg.complexXyPos      = complexXyPos;
            objCfg.cartesianPosition = cartesianPosition;
            
            objCfgVec{end+1} = objCfg;
            %% obj2
            initDistance             = 80;%meter
            initAzimuth              = 3*pi/8;%RAD
            complexXyPos             = @(t) initDistance*exp(1i*initAzimuth);
            cartesianPosition        = @(t) [real(complexXyPos(t)), imag(complexXyPos(t)), 0];
            sourceMinFreq            = 2e3;%Hz
            sourceMaxFreq            = 2e3;
            sourceSignal             = @(t) cos(2*pi*sourceMinFreq);
            
            objCfg.sourceMinFreq     = sourceMinFreq;
            objCfg.sourceMaxFreq     = sourceMaxFreq;
            objCfg.sourceSignal      = sourceSignal;
            objCfg.initDistance      = initDistance;
            objCfg.initAzimuth       = initAzimuth;
            objCfg.complexXyPos      = complexXyPos;
            objCfg.cartesianPosition = cartesianPosition;
            
            objCfgVec{end+1} = objCfg;
        end
        
        cfgStruct.scenario.objCfgVec = objCfgVec;
        %% physical
        propagationVelocity    = 343;%m/s
        txPropagationVeclocity = 3e8;%m/s
        nSensors               = 5;  %must be 2^integer + 1 (without loss of generality)
        minLambda              = min(cellfun(@(objCfg) propagationVelocity/objCfg.sourceMaxFreq,objCfgVec));
        distanceBetweenSensors = minLambda/2;
        singleTransmitterFlag  = 1;
        
        cfgStruct.physical.propagationVelocity    = propagationVelocity;
        cfgStruct.physical.txPropagationVeclocity = txPropagationVeclocity;
        cfgStruct.physical.nSensors               = nSensors;
        cfgStruct.physical.minLambda              = minLambda;
        cfgStruct.physical.distanceBetweenSensors = distanceBetweenSensors;
        cfgStruct.physical.singleTransmitterFlag  = singleTransmitterFlag;
        %% filter
        syms z;
        
        denominatorOrder  = nSensors - 1;
        polesRadious      = 0.9;
        polePositions     = repmat(polesRadious*[exp(1i*pi/4) exp(-1i*pi/4)], 1, denominatorOrder/2);
        denominatorCoeffs = fliplr(eval(coeffs(prod(z-polePositions),z)));
        sensorWeights     = -denominatorCoeffs(2:end);
        
        cfgStruct.filter.z                 = z;
        cfgStruct.filter.denominatorOrder  = denominatorOrder;
        cfgStruct.filter.polesRadious      = polesRadious;
        cfgStruct.filter.polePositions     = polePositions;
        cfgStruct.filter.denominatorCoeffs = denominatorCoeffs;
        cfgStruct.filter.sensorWeights     = sensorWeights;
    end
end
%% simulation
%{

%}
end