function [yOut,arrayFeedback] = processor_goldenModel_CB(arrayInput,cfgStruct)
%% range estimation
persistent hVec_f1 hVec_f2 f1 f2 fSample nSamples;
if isempty(hVec_f1)
    %% feedback filter
    range       = 90;
    f1          = cfgStruct.physical.syncSigBaseFreq;
    dF          = 100;
    f2          = f1 + dF;
    N           = cfgStruct.physical.nSensors;
    D           = cfgStruct.physical.distanceBetweenSensors;
    dVec_f1     = ones(1,N); % CB steered to pi/2
    c           = cfgStruct.physical.propagationVelocity;
    dOmegaVal   = 2*pi*dF;
    hVec_f1     = (1/N)*reshape(conj(dVec_f1),[],1)*exp(-1i*2*dOmegaVal*range/c);
    hVec_f2     = reshape([1 ; zeros(N-1,1)],[],1);
    fSample     = cfgStruct.physical.fSample;
    nSamples    = size(arrayInput,1);
end
%% stft
stftSig_f1  = exp(-1i*2*pi*f1*(0:(nSamples-1))/fSample);
stftSig_f2  = exp(-1i*2*pi*f2*(0:(nSamples-1))/fSample);

%% feedback synthesis
arrayFeedback_f1    = ...
    squeeze(arrayInput(:,:,1)) ...
    * ...
    hVec_f1;

arrayFeedback_f2    = ...
    squeeze(arrayInput(:,:,2)) ...
    * ...
    hVec_f2;

arrayFeedback           = zeros(size(arrayInput));
arrayFeedback(:,1,1)    = arrayFeedback_f1;
arrayFeedback(:,1,2)    = arrayFeedback_f2;

try
    if ~cfgStruct.physical.enableFeedback
        arrayFeedback     = zeros(size(arrayFeedback));
    end
catch
end

%% array output calc
if true
    %% calculated STFT
    h1  = reshape(arrayFeedback_f1,1,[])*stftSig_f1(:);
    h2  = reshape(arrayFeedback_f2,1,[])*stftSig_f2(:);
    if h1==0 || h2==0
        h =0;
    else
        h   = 1/((1/h1)-(1/h2));
    end
    yOut = h*ones(nSamples,1);
end

end