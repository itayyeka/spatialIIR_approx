function [simOutput,presentationOutput] = IIR_approx_simulation(cfgStruct)
clc;

%% configuration
try
    %% external config
    cfgStruct;
catch
    %% standalone
    if true
        %% sim
        simDuration = 20;%sec
        
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
        systemLatency          = 0;  %sec
        nSensors               = 5;  %must be 2^integer + 1 (without loss of generality)
        singleTransmitterFlag  = 1;
        minLambda              = min(cellfun(@(objCfg) propagationVelocity/objCfg.sourceMaxFreq,objCfgVec));
        maxInputFreq           = propagationVelocity/nSensors;
        fSample                = 2.5*maxInputFreq;
        distanceBetweenSensors = minLambda/2;
        
        cfgStruct.physical.propagationVelocity    = propagationVelocity;
        cfgStruct.physical.txPropagationVeclocity = txPropagationVeclocity;
        cfgStruct.physical.systemLatency          = systemLatency;
        cfgStruct.physical.nSensors               = nSensors;
        cfgStruct.physical.singleTransmitterFlag  = singleTransmitterFlag;
        cfgStruct.physical.minLambda              = minLambda;
        cfgStruct.physical.maxInputFreq           = maxInputFreq;
        cfgStruct.physical.fSample                = fSample;
        cfgStruct.physical.distanceBetweenSensors = distanceBetweenSensors;
        %% filter
        syms z;
        
        polesRadious      = 0.9;
        denominatorOrder  = nSensors - 1;        
        polePositions     = repmat(polesRadious*[exp(1i*pi/4) exp(-1i*pi/4)], 1, denominatorOrder/2);
        denominatorCoeffs = fliplr(eval(coeffs(prod(z-polePositions),z)));
        sensorWeights     = -denominatorCoeffs(2:end);
        filterGroupDelay  = max(grpdelay(1,denominatorCoeffs));
        nFilterRounds     = 2*ceil(filterGroupDelay);
        
        cfgStruct.filter.z                 = z;
        cfgStruct.filter.denominatorOrder  = denominatorOrder;
        cfgStruct.filter.polesRadious      = polesRadious;
        cfgStruct.filter.polePositions     = polePositions;
        cfgStruct.filter.denominatorCoeffs = denominatorCoeffs;
        cfgStruct.filter.sensorWeights     = sensorWeights;
        cfgStruct.filter.nFilterRounds     = nFilterRounds;
    end
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

presentationOutput = presentSimOutput(cfgStruct,simOutput);
end