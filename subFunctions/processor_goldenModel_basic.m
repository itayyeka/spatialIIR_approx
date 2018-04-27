function [yOut,arrayFeedback] = processor_goldenModel_basic(arrayInput,cfgStruct)
%% range estimation
try
    cfgStruct.filter.enablePhaseCorrection;
catch
    cfgStruct.filter.enablePhaseCorrection = 1;
end
correctionPhase = ...
    -cfgStruct.filter.enablePhaseCorrection ...
    *mod(...
    2*pi...
    *cfgStruct.physical.syncSigBaseFreq ...
    *cfgStruct.IdealEstimation.firstObjectInitialDistance ...
    *(1/cfgStruct.physical.propagationVelocity+1/cfgStruct.physical.txPropagationVeclocity)...
    ,2*pi);

%% feedback synthesis
sensorFeedbackWeights           = cfgStruct.filter.sensorWeights;
arrayFeedback                   = zeros(size(arrayInput));
arrayFeedback_basic             = ...
    exp(1i*correctionPhase) ...
    *squeeze(arrayInput(:,:,1)) ...
    *sensorFeedbackWeights(:);


try
    enableLimiter   = cfgStruct.filter.enableLimiter;
catch
    enableLimiter   = 1;
end

try
    maxAmp_dB       = cfgStruct.filter.limiterMaxDb;
catch
    maxAmp_dB       = 10;
end

maxAmp                          = 10^(maxAmp_dB/20);

if enableLimiter
    
    f_limiter                       = @(x,maxAmp) min(abs(x),maxAmp).*exp(1i*angle(x));
    
    arrayFeedback_basic_truncated   = f_limiter(arrayFeedback_basic,maxAmp);
    
    arrayFeedback(:,1,1)            = arrayFeedback_basic_truncated;
    
else
    
    arrayFeedback(:,1,1)            = arrayFeedback_basic;
    
end

if false
    figure;
    plot(real([arrayFeedback_basic_truncated arrayFeedback_basic]),'*-');
    hold on;
    plot(real(arrayInput(:,:,1)));
    close all;
end

%% array output calc
try
    simulateSpatialFIR      = cfgStruct.filter.simulateSpatialFIR;
catch
    simulateSpatialFIR      = 0;
end

if simulateSpatialFIR
    yOut                    = squeeze(arrayInput(:,:,1))*flipud(cfgStruct.filter.hVec_norm(:));
else
    yOut                    = arrayInput(:,1,1);
end
%% DEBUG
if false
    figure;
    plot(real(arrayInput(:,:,1)));
    hold on;
    plot(real(arrayFeedback(:,1,1)),'*-');
    stem(real(yOut(:)));
end
end